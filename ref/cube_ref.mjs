#!/usr/bin/env node
/**
 * CFOP_ABAP 参考实现（JavaScript）
 *
 * 用途：在没有 SAP 运行时的环境下，验证魔方三维坐标模型、转动引擎、
 *       合法性校验（奇偶/朝向不变量）与 LBL 初级法求解器的正确性。
 *       ABAP 端 (src/*.abap) 逐逻辑对照移植本文件。
 *
 * 固定坐标系（与 ABAP 端一致）：
 *   x 轴：+1 = R(橙)  -1 = L(红)
 *   y 轴：+1 = U(黄)  -1 = D(白)
 *   z 轴：+1 = F(绿)  -1 = B(蓝)
 *   魔方状态 = 27 槽位数组（下标 pidx = (x+1)*9+(y+1)*3+(z+1)，核心块槽位 13 恒为 null）
 *   每个小块 {cx,cy,cz}：该轴向暴露面的颜色，无暴露面为 null。
 *   白色在 D、黄色在 U（求解全程固定坐标系，不做整体旋转）。
 */

'use strict';

// ---------------------------------------------------------------------------
// 基础常量
// ---------------------------------------------------------------------------
const FACE_OF_COLOR = { Y: 'U', W: 'D', G: 'F', B: 'B', R: 'L', O: 'R' };
const COLOR_OF_FACE = { U: 'Y', D: 'W', F: 'G', B: 'B', R: 'O', L: 'R' };
const COLOR_SET = new Set(Object.keys(FACE_OF_COLOR));

// 面网格 (r,c ∈ 0..2，从该面外侧看，行自上而下、列自左到右) → 小块坐标 + 贴纸轴向
const FACE_GRID = {
  U: (r, c) => ({ x: c - 1, y: 1, z: r - 1, a: 'cy' }),
  D: (r, c) => ({ x: c - 1, y: -1, z: 1 - r, a: 'cy' }),
  F: (r, c) => ({ x: c - 1, y: 1 - r, z: 1, a: 'cz' }),
  B: (r, c) => ({ x: 1 - c, y: 1 - r, z: -1, a: 'cz' }),
  R: (r, c) => ({ x: 1, y: 1 - r, z: 1 - c, a: 'cx' }),
  L: (r, c) => ({ x: -1, y: 1 - r, z: c - 1, a: 'cx' }),
};

const pidx = (x, y, z) => (x + 1) * 9 + (y + 1) * 3 + (z + 1);
const coordOf = (i) => ({ x: Math.floor(i / 9) - 1, y: Math.floor((i % 9) / 3) - 1, z: (i % 3) - 1 });

// 转法定义：axis 转轴、layers 参与转动的层坐标、cw 绕 +轴顺时针的 90° 次数 (1,2,3)
// 面转以"从该面外侧看顺时针"为准；D/L/B 位于负轴，故 cw = 3。
const MOVE_DEF = {
  U: { axis: 'y', layers: [1], cw: 1 }, U2: { axis: 'y', layers: [1], cw: 2 }, "U'": { axis: 'y', layers: [1], cw: 3 },
  D: { axis: 'y', layers: [-1], cw: 3 }, D2: { axis: 'y', layers: [-1], cw: 2 }, "D'": { axis: 'y', layers: [-1], cw: 1 },
  R: { axis: 'x', layers: [1], cw: 1 }, R2: { axis: 'x', layers: [1], cw: 2 }, "R'": { axis: 'x', layers: [1], cw: 3 },
  L: { axis: 'x', layers: [-1], cw: 3 }, L2: { axis: 'x', layers: [-1], cw: 2 }, "L'": { axis: 'x', layers: [-1], cw: 1 },
  F: { axis: 'z', layers: [1], cw: 1 }, F2: { axis: 'z', layers: [1], cw: 2 }, "F'": { axis: 'z', layers: [1], cw: 3 },
  B: { axis: 'z', layers: [-1], cw: 3 }, B2: { axis: 'z', layers: [-1], cw: 2 }, "B'": { axis: 'z', layers: [-1], cw: 1 },
};
const BASIC_18 = ['U', "U'", 'U2', 'D', "D'", 'D2', 'R', "R'", 'R2', 'L', "L'", 'L2', 'F', "F'", 'F2', 'B', "B'", 'B2'];

// ---------------------------------------------------------------------------
// 状态构造 / 拷贝 / 哈希
// ---------------------------------------------------------------------------
function solvedState() {
  const st = new Array(27).fill(null);
  for (let i = 0; i < 27; i++) {
    const { x, y, z } = coordOf(i);
    if (x === 0 && y === 0 && z === 0) continue;
    const c = { cx: null, cy: null, cz: null };
    if (x === 1) c.cx = 'O'; if (x === -1) c.cx = 'R';
    if (y === 1) c.cy = 'Y'; if (y === -1) c.cy = 'W';
    if (z === 1) c.cz = 'G'; if (z === -1) c.cz = 'B';
    st[i] = c;
  }
  return st;
}
const cloneState = (st) => st.map((c) => (c ? { cx: c.cx, cy: c.cy, cz: c.cz } : null));
const hashState = (st) => st.map((c) => `${c ? c.cx || '.' : '#'}${c ? c.cy || '.' : '#'}${c ? c.cz || '.' : '#'}`).join('');

// ---------------------------------------------------------------------------
// 转动引擎
// 绕 +轴顺时针一次的坐标变换：
//   x 轴: y'=z  z'=-y   交换 cy,cz
//   y 轴: z'=x  x'=-z   交换 cz,cx
//   z 轴: x'=y  y'=-x   交换 cx,cy
// ---------------------------------------------------------------------------
function applyMoveSpec(state, spec) {
  const out = state.slice(); // 浅拷贝：未动的小块对象直接共享（引擎从不原地修改小块）
  for (let i = 0; i < 27; i++) {
    const c = state[i];
    if (!c) continue;
    const { x, y, z } = coordOf(i);
    const v = { x, y, z }[spec.axis];
    if (!spec.layers.includes(v)) continue;
    let nx = x, ny = y, nz = z;
    const n = { cx: c.cx, cy: c.cy, cz: c.cz };
    for (let t = 0; t < spec.cw; t++) {
      if (spec.axis === 'x') { const ty = ny; ny = nz; nz = -ty; const tc = n.cy; n.cy = n.cz; n.cz = tc; }
      else if (spec.axis === 'y') { const tz = nz; nz = nx; nx = -tz; const tc = n.cz; n.cz = n.cx; n.cx = tc; }
      else { const tx = nx; nx = ny; ny = -tx; const tc = n.cx; n.cx = n.cy; n.cy = tc; }
    }
    out[pidx(nx, ny, nz)] = n;
  }
  return out;
}
const applyMove = (state, name) => applyMoveSpec(state, MOVE_DEF[name]);
const applyAlg = (state, alg) => alg.trim().split(/\s+/).filter(Boolean).reduce((s, m) => applyMove(s, m), state);

// ---------------------------------------------------------------------------
// 面贴读取（展示 / 录入解析）
// ---------------------------------------------------------------------------
function facelets(state) {
  const faces = {};
  for (const f of Object.keys(FACE_GRID)) {
    const grid = [];
    for (let r = 0; r < 3; r++) {
      const row = [];
      for (let c = 0; c < 3; c++) {
        const { x, y, z, a } = FACE_GRID[f](r, c);
        row.push(state[pidx(x, y, z)][a]);
      }
      grid.push(row);
    }
    faces[f] = grid;
  }
  return faces;
}

// 录入解析：六面 {Y:..,O:..,B:..,R:..,G:..,W:..}，每面 9 字符，中心色必须等于键
function parseInput(facesByColor) {
  const errs = [];
  const st = new Array(27).fill(null);
  const seen = new Array(27).fill(0);
  for (const [color, str] of Object.entries(facesByColor)) {
    if (typeof str !== 'string' || str.length !== 9) { errs.push(`面 ${color} 长度必须为 9`); continue; }
    if (str[4] !== color) { errs.push(`面 ${color} 的中心色不符`); continue; }
    for (const ch of str) if (!COLOR_SET.has(ch)) { errs.push(`面 ${color} 含非法字符 ${ch}`); break; }
    const face = FACE_OF_COLOR[color];
    for (let r = 0; r < 3; r++) for (let c = 0; c < 3; c++) {
      const { x, y, z, a } = FACE_GRID[face](r, c);
      const p = pidx(x, y, z);
      if (!st[p]) st[p] = { cx: null, cy: null, cz: null };
      st[p][a] = str[r * 3 + c];
      seen[p]++;
    }
  }
  if (errs.length) return { state: null, errs };
  for (let i = 0; i < 27; i++) {
    const { x, y, z } = coordOf(i);
    const expect = Math.abs(x) + Math.abs(y) + Math.abs(z); // 角 3 / 棱 2 / 中心 1 / 核心 0
    if (seen[i] !== expect) errs.push(`槽位 ${i} 贴纸数 ${seen[i]} 异常`);
  }
  return { state: st, errs };
}

// ---------------------------------------------------------------------------
// 合法性校验（可解性不变量）
// ---------------------------------------------------------------------------
// 注意：与 cubieColors() 一致，每个块的颜色串按字母排序
const CORNER_SET = ['YRG', 'YBR', 'YBO', 'YOG', 'WRG', 'WBR', 'WBO', 'WOG'].map((s) => s.split('').sort().join(''));
const EDGE_SET = ['GY', 'GR', 'BY', 'BO', 'GO', 'BR', 'GW', 'BW', 'RW', 'OW', 'OY', 'RY'];
const CORNERS = [[1, 1, 1], [1, 1, -1], [-1, 1, -1], [-1, 1, 1], [1, -1, 1], [1, -1, -1], [-1, -1, -1], [-1, -1, 1]];
const EDGES = [[0, 1, 1], [1, 1, 0], [0, 1, -1], [-1, 1, 0], [1, 0, 1], [1, 0, -1], [-1, 0, -1], [-1, 0, 1], [0, -1, 1], [1, -1, 0], [0, -1, -1], [-1, -1, 0]];

function cubieColors(c) {
  return [c.cx, c.cy, c.cz].filter(Boolean).sort().join('');
}

/** 完整校验，返回错误信息数组；空数组 = 合法（可解） */
function checkAll(state) {
  const errs = [];
  // 1) 部件存在性：8 角 + 12 棱，颜色组合必须与标准魔方一致（中心关系错误也会在此暴露）
  const corners = [], edges = [];
  for (let i = 0; i < 27; i++) {
    if (!state[i]) continue;
    const { x, y, z } = coordOf(i);
    const n = Math.abs(x) + Math.abs(y) + Math.abs(z);
    if (n === 3) corners.push(cubieColors(state[i]));
    if (n === 2) edges.push(cubieColors(state[i]));
  }
  if (corners.sort().join(',') !== [...CORNER_SET].sort().join(',')) errs.push('角块颜色组合不符合标准魔方（中心块相对位置或录入有误）');
  if (edges.sort().join(',') !== [...EDGE_SET].sort().join(',')) errs.push('棱块颜色组合不符合标准魔方（中心块相对位置或录入有误）');

  // 2) 朝向不变量：棱翻转总和 ≡ 0 (mod 2)
  //    规则（Kociemba 约定）：槽位主轴 = y（U/D 层槽位）或 z（中层槽位）；
  //    棱的参考色 = Y/W（若有），否则 G/B；参考色不在槽位主轴上即计 1 次翻转。
  //    该定义下 R/L/U/D 不翻棱，F/B 翻转其 4 条棱 —— 与魔方群理论一致。
  let flip = 0;
  for (const [x, y, z] of EDGES) {
    const c = state[pidx(x, y, z)];
    const colors = [c.cx, c.cy, c.cz].filter(Boolean);
    const ref = colors.find((v) => 'YW'.includes(v)) || colors.find((v) => 'GB'.includes(v));
    const onPrimary = y !== 0 ? ref === c.cy : ref === c.cz;
    if (!onPrimary) flip++;
  }
  if (flip % 2 !== 0) errs.push('棱块朝向奇偶性不满足（奇数个翻转棱）');

  // 3) 角扭转总和 ≡ 0 (mod 3)：Y/W 参考色所在轴向决定扭转值
  //    约定：y 轴 → 0；x 轴 → x*y*z>0 ? 1 : 2；z 轴 → x*y*z>0 ? 2 : 1（经打乱回归验证）
  let twist = 0;
  for (const [x, y, z] of CORNERS) {
    const c = state[pidx(x, y, z)];
    const ref = [c.cx, c.cy, c.cz].find((v) => v && 'YW'.includes(v));
    const onAxis = ref === c.cy ? 'y' : ref === c.cx ? 'x' : 'z';
    if (onAxis === 'y') continue;
    const chir = x * y * z > 0;
    twist += onAxis === 'x' ? (chir ? 1 : 2) : (chir ? 2 : 1);
  }
  if (twist % 3 !== 0) errs.push('角块扭转总和不被 3 整除');

  // 4) 排列奇偶：角排列与棱排列奇偶性必须一致
  const permParity = (list) => {
    let inv = 0;
    for (let i = 0; i < list.length; i++) for (let j = i + 1; j < list.length; j++) if (list[i] > list[j]) inv++;
    return inv % 2;
  };
  const cHome = [...CORNER_SET].sort();
  const cPerm = CORNERS.map(([x, y, z]) => cHome.indexOf(cubieColors(state[pidx(x, y, z)])));
  const eHome = [...EDGE_SET].sort();
  const ePerm = EDGES.map(([x, y, z]) => eHome.indexOf(cubieColors(state[pidx(x, y, z)])));
  if (permParity(cPerm) !== permParity(ePerm)) errs.push('角块与棱块排列奇偶性不一致');

  return errs;
}

const isSolved = (state) => {
  for (let i = 0; i < 27; i++) {
    if (!state[i]) continue;
    if (!cubieSolvedAt(state, i)) return false;
  }
  return true;
};

// ---------------------------------------------------------------------------
// 工具：定位 / 查询
// ---------------------------------------------------------------------------
function findCubie(state, colorsStr) {
  const want = colorsStr.split('').sort().join('');
  for (let i = 0; i < 27; i++) {
    if (state[i] && cubieColors(state[i]) === want) return i;
  }
  throw new Error(`未找到小块 ${want}`);
}

/** 某槽位小块是否完全归位（贴纸与所在面全部匹配；中心块也适用） */
function cubieSolvedAt(state, i) {
  const { x, y, z } = coordOf(i);
  const c = state[i];
  if (x === 1 && c.cx !== 'O') return false; if (x === -1 && c.cx !== 'R') return false;
  if (y === 1 && c.cy !== 'Y') return false; if (y === -1 && c.cy !== 'W') return false;
  if (z === 1 && c.cz !== 'G') return false; if (z === -1 && c.cz !== 'B') return false;
  if (x === 0 && c.cx !== null) return false;
  if (y === 0 && c.cy !== null) return false;
  if (z === 0 && c.cz !== null) return false;
  return true;
}

// ---------------------------------------------------------------------------
// 公式化简：相邻同面转动合并（UU→U2、UU'→抵消、UUU→U'），语义不变
function simplifyAlg(alg) {
  const stack = []; // { face, turn: 1|2|3 }
  for (const mv of alg.split(/\s+/).filter(Boolean)) {
    const face = mv[0];
    const turn = mv.includes('2') ? 2 : mv.includes("'") ? 3 : 1;
    const top = stack[stack.length - 1];
    if (top && top.face === face) {
      const net = (top.turn + turn) % 4;
      stack.pop();
      if (net === 0) continue;
      stack.push({ face, turn: net });
    } else {
      stack.push({ face, turn });
    }
  }
  return stack.map(({ face, turn }) => face + (turn === 1 ? '' : turn === 2 ? '2' : "'")).join(' ');
}

// 打乱
// ---------------------------------------------------------------------------
function randomScramble(n = 25, rng = Math.random) {
  const faces = ['U', 'D', 'R', 'L', 'F', 'B'];
  const mods = ['', "'", '2'];
  const seq = [];
  let lastFace = '';
  while (seq.length < n) {
    const f = faces[Math.floor(rng() * 6)];
    if (f === lastFace) continue;
    seq.push(f + mods[Math.floor(rng() * 3)]);
    lastFace = f;
  }
  return seq.join(' ');
}

// ---------------------------------------------------------------------------
// 求解器（LBL 初级法，白十字在 D，全程固定坐标系）
// 每个阶段完成后立即断言阶段成果，任何异常都会带阶段名抛出。
// ---------------------------------------------------------------------------
const SIDE_COLORS = ['G', 'R', 'B', 'O']; // F,R,B,L
const faceOfSide = { G: 'F', R: 'L', B: 'B', O: 'R' };
const sideOfFace = { F: 'G', R: 'R', B: 'B', L: 'O' };
// U 顺时针后各面到达的面（F→L→B→R→F）；U_PREV 为 U' 方向
const U_NEXT = { F: 'L', L: 'B', B: 'R', R: 'F' };
const U_PREV = { F: 'R', R: 'B', B: 'L', L: 'F' };

class Solver {
  constructor(state) { this.state = state; this.moves = []; this.stats = { bfsMax: 0 }; }
  run(name) { this.state = applyMove(this.state, name); this.moves.push(name); }
  runAlg(alg) { for (const m of alg.trim().split(/\s+/)) this.run(m); }
}

/** 花瓣 BFS：把目标白棱送到 U 层且白贴朝上，同时不得破坏已放置的花瓣 */
function bfsDaisy(solver, targetColors, petalList) {
  const goal = (st) => {
    for (const cols of [targetColors, ...petalList]) {
      const i = findCubie(st, cols);
      if (!(coordOf(i).y === 1 && st[i].cy === 'W')) return false;
    }
    return true;
  };
  if (goal(solver.state)) return [];
  const seen = new Set([hashState(solver.state)]);
  let frontier = [{ st: solver.state, path: [] }];
  for (let depth = 1; depth <= 6; depth++) {
    const next = [];
    for (const { st, path } of frontier) {
      for (const m of BASIC_18) {
        const nst = applyMove(st, m);
        const h = hashState(nst);
        if (seen.has(h)) continue;
        seen.add(h);
        const npath = [...path, m];
        if (goal(nst)) { solver.stats.bfsMax = Math.max(solver.stats.bfsMax, depth); return npath; }
        next.push({ st: nst, path: npath });
      }
    }
    frontier = next;
  }
  throw new Error('daisy BFS 未找到解（深度>6）');
}

function stageCross(s) {
  // 1) 花瓣：4 条白棱全部上到 U 层且白贴朝上
  const petals = [];
  for (const side of SIDE_COLORS) {
    const target = ['W', side].sort().join('');
    for (const m of bfsDaisy(s, target, petals)) s.run(m);
    petals.push(target);
  }
  // 2) 对齐 + 180° 插入
  for (let k = 0; k < 4; k++) {
    let petalIdx = -1;
    for (const side of SIDE_COLORS) {
      const i = findCubie(s.state, ['W', side].sort().join(''));
      if (coordOf(i).y === 1 && s.state[i].cy === 'W') { petalIdx = i; break; }
    }
    if (petalIdx < 0) throw new Error('cross: 找不到花瓣');
    const sideColor = [s.state[petalIdx].cx, s.state[petalIdx].cz].find(Boolean);
    for (let t = 0; t < 4; t++) {
      const i = findCubie(s.state, ['W', sideColor].sort().join(''));
      const { x, z } = coordOf(i);
      const adjFace = x === 1 ? 'R' : x === -1 ? 'L' : z === 1 ? 'F' : 'B';
      if (adjFace === faceOfSide[sideColor]) { s.run(faceOfSide[sideColor] + '2'); break; }
      s.run('U');
    }
  }
  for (const [x, z] of [[0, 1], [1, 0], [0, -1], [-1, 0]]) {
    if (!cubieSolvedAt(s.state, pidx(x, -1, z))) throw new Error('cross: 底层白十字未完成');
  }
}

// 角块插入触发公式（按槽位 (x,z) 查表）：重复执行直到目标角归位；
// 公式为 [f U f' U'] 型换面共轭，只影响该槽位与 U 层，不破坏其余底层。
// 各槽位使用的面经 discover 实测确认（D 层仅该槽位角块受影响）。
const CORNER_TRIGGER = {
  '1,1': "R U R' U'",
  '1,-1': "B U B' U'",
  '-1,-1': "L U L' U'",
  '-1,1': "F U F' U'",
};

function stageCorners(s) {
  const cornerTargets = [['W', 'G', 'R'], ['W', 'R', 'B'], ['W', 'B', 'O'], ['W', 'O', 'G']];
  for (const cols of cornerTargets) {
    const key = cols.slice().sort().join('');
    for (let guard = 0; guard < 8; guard++) {
      const i = findCubie(s.state, key);
      const { x, y, z } = coordOf(i);
      if (cubieSolvedAt(s.state, i)) break;
      if (y === -1) {
        s.runAlg(CORNER_TRIGGER[`${x},${z}`]); // 弹出到 U 层
        continue;
      }
      // 在 U 层：转到家的正上方，反复触发直到归位
      const c = s.state[i];
      let hx = 0, hz = 0;
      for (const sc of [c.cx, c.cy, c.cz].filter((v) => v && v !== 'W')) {
        const f = faceOfSide[sc];
        if (f === 'R') hx = 1; else if (f === 'L') hx = -1; else if (f === 'F') hz = 1; else hz = -1;
      }
      for (let t = 0; t < 4; t++) {
        const j = findCubie(s.state, key);
        const cj = coordOf(j);
        if (cj.x === hx && cj.z === hz) break;
        s.run('U');
      }
      const trig = CORNER_TRIGGER[`${hx},${hz}`];
      let inserted = false;
      for (let rep = 0; rep < 6 && !inserted; rep++) {
        s.runAlg(trig);
        inserted = cubieSolvedAt(s.state, findCubie(s.state, key));
      }
      if (!inserted) throw new Error(`corners: 角 ${key} 插入失败`);
      break;
    }
  }
  for (const [x, y, z] of CORNERS) {
    if (y === -1 && !cubieSolvedAt(s.state, pidx(x, y, z))) throw new Error('corners: 第一层角未全部归位');
  }
}

// 第二层棱插入（f = 前面）：右插 / 左插，均为标准公式
const rightInsert = (f) => { const r = U_PREV[f]; return `U ${r} U' ${r}' U' ${f}' U ${f}`; };
const leftInsert = (f) => { const l = U_NEXT[f]; return `U' ${l}' U ${l} U ${f} U' ${f}'`; };

function stageSecondLayer(s) {
  const targets = [['G', 'R'], ['R', 'B'], ['B', 'O'], ['O', 'G']];
  for (const [a, b] of targets) {
    const key = [a, b].sort().join('');
    for (let guard = 0; guard < 10; guard++) {
      const i = findCubie(s.state, key);
      if (cubieSolvedAt(s.state, i)) break;
      const { x, y, z } = coordOf(i);
      if (y === 0) {
        // 卡在中层：以"该槽位为右前"的前面 f 做一次右插，把它顶出去
        const f = (x === 1 && z === 1) ? 'F' : (x === 1 && z === -1) ? 'R' : (x === -1 && z === -1) ? 'B' : 'L';
        s.runAlg(rightInsert(f));
        continue;
      }
      let done = false;
      for (let t = 0; t < 4 && !done; t++) {
        const j = findCubie(s.state, key);
        const cj = coordOf(j);
        const sideColor = cj.x !== 0 ? s.state[j].cx : s.state[j].cz;
        const adjFace = cj.x === 1 ? 'R' : cj.x === -1 ? 'L' : cj.z === 1 ? 'F' : 'B';
        if (faceOfSide[sideColor] === adjFace) {
          const topColor = s.state[j].cy;
          if (U_PREV[adjFace] === faceOfSide[topColor]) s.runAlg(rightInsert(adjFace));
          else if (U_NEXT[adjFace] === faceOfSide[topColor]) s.runAlg(leftInsert(adjFace));
          else throw new Error('second layer: 上贴纸颜色异常');
          done = true;
        } else {
          s.run('U');
        }
      }
      if (!done) throw new Error('second layer: 无法对齐棱块');
    }
  }
  for (const [x, y, z] of EDGES) {
    if (y === 0 && !cubieSolvedAt(s.state, pidx(x, y, z))) throw new Error('second layer: 中层棱未全部归位');
  }
}

function stageTopCross(s) {
  const countYEdges = (st) => EDGES.filter(([x, y, z]) => y === 1).filter(([x, y, z]) => st[pidx(x, y, z)].cy === 'Y').length;
  // 2-look OLL 的两个定向公式：线 → 十字用 FRUR'U'F'；L 形 → 十字用 FURU'R'F'
  const ALGS = ["F R U R' U' F'", "F U R U' R' F'"];
  for (let guard = 0; guard < 6; guard++) {
    const cur = countYEdges(s.state);
    if (cur === 4) break;
    let applied = false;
    for (const alg of ALGS) {
      for (let pre = 0; pre < 4 && !applied; pre++) {
        let trial = s.state;
        for (let t = 0; t < pre; t++) trial = applyMove(trial, 'U');
        trial = applyAlg(trial, alg);
        if (countYEdges(trial) > cur) {
          for (let t = 0; t < pre; t++) s.run('U');
          s.runAlg(alg);
          applied = true;
        }
      }
    }
    if (!applied) throw new Error('top cross: 无法增加黄边数量');
  }
  if (countYEdges(s.state) !== 4) throw new Error('top cross: 顶层十字未完成');
}

function stageTopCornerOrient(s) {
  // 经典逐角法：把未定向角转到 UFR，重复 R' D' R D 直到黄贴朝上，U 换下一角。
  // 全部完成（含 U 轮转）后底层自动复原 —— 由回归测试验证。
  const oriented = (i) => coordOf(i).y === 1 && s.state[i].cy === 'Y';
  const anyUnoriented = () => CORNERS.some(([x, y, z]) => y === 1 && !oriented(pidx(x, y, z)));
  for (let guard = 0; guard < 30 && anyUnoriented(); guard++) {
    for (let t = 0; t < 4; t++) {
      if (!oriented(pidx(1, 1, 1))) break;
      s.run('U');
    }
    if (oriented(pidx(1, 1, 1))) throw new Error('corner orient: 无未定向角');
    let ok = false;
    for (let rep = 0; rep < 8 && !ok; rep++) {
      s.runAlg("R' D' R D");
      ok = oriented(pidx(1, 1, 1));
    }
    if (!ok) throw new Error('corner orient: 单角定向失败');
  }
  for (const [x, y, z] of CORNERS) {
    if (y === 1 && s.state[pidx(x, y, z)].cy !== 'Y') throw new Error('corner orient: 顶层角未全部定向');
  }
  for (let i = 0; i < 27; i++) {
    if (s.state[i] && coordOf(i).y <= 0 && !cubieSolvedAt(s.state, i)) {
      throw new Error('corner orient: 底两层被破坏');
    }
  }
}

/**
 * 顶层排列通用程序（共轭法）：
 *   alg 为保持 fixedSlot 不动、轮换其余三块的排列公式。
 *   - 归位数只可能为 0 / 1 / 4（偶置换结构）；
 *   - 0：直接应用 alg（A4 群中 3-cycle ∘ 对换必得 3-cycle → 归位数变 1）；
 *   - 1：转 U 把已归位的块送到 fixedSlot，应用 alg，再转回（共轭），
 *     净效果 = 仅轮换其余三槽位，不动已归位块。
 */
function topPermute(s, slots, fixedSlot, alg, label) {
  const countCorrect = (st) => slots.filter((i) => cubieSolvedAt(st, i)).length;
  void fixedSlot;
  for (let guard = 0; guard < 12; guard++) {
    const cur = countCorrect(s.state);
    if (cur === 4) return;
    if (cur === 0) { s.runAlg(alg); continue; }
    // cur ≥ 1：试 4 种 U 共轭（U^t · alg · U^-t），选归位数最大的提交。
    // 保持不动位的共轭计数不降；排列方向一致时一步到 4，相反时至多两步。
    let bestT = 0, bestCount = -1;
    for (let t = 0; t < 4; t++) {
      let sim = s.state;
      for (let r = 0; r < t; r++) sim = applyMove(sim, 'U');
      sim = applyAlg(sim, alg);
      for (let r = 0; r < (4 - t) % 4; r++) sim = applyMove(sim, 'U');
      const cnt = countCorrect(sim);
      if (cnt > bestCount) { bestCount = cnt; bestT = t; }
    }
    for (let r = 0; r < bestT; r++) s.run('U');
    s.runAlg(alg);
    for (let r = 0; r < (4 - bestT) % 4; r++) s.run('U');
  }
  if (countCorrect(s.state) !== 4) throw new Error(`${label}: 排列未完成`);
}

/** U 层角排列的奇偶（true = 奇排列）。奇排列时 3-cycle 类算法无法归位，需先转 U 翻转奇偶 */
function cornerPermutationParityOdd(state) {
  const slots = CORNERS.filter(([x, y, z]) => y === 1).map(([x, y, z]) => pidx(x, y, z));
  const homes = slots.map((i) => { const { x, y, z } = coordOf(i); return cubieColors(solvedState()[pidx(x, y, z)]); });
  const perm = slots.map((i) => homes.indexOf(cubieColors(state[i])));
  let inv = 0;
  for (let i = 0; i < perm.length; i++) for (let j = i + 1; j < perm.length; j++) if (perm[i] > perm[j]) inv++;
  return inv % 2 === 1;
}

function stageCornerPerm(s) {
  // 奇偶预判：奇排列（如两角互换的 T-perm 类状态）无法用偶排列算法还原，
  // 先转一次 U —— U 对角、棱各贡献一个 4-cycle，同时翻转两者奇偶，化奇为偶。
  if (cornerPermutationParityOdd(s.state)) s.run('U');
  const slots = CORNERS.filter(([x, y, z]) => y === 1).map(([x, y, z]) => pidx(x, y, z));
  // R' F R' B2 R F' R' B2 R2 为纯角位置 3-cycle：保持朝向，UFL (-1,1,1) 不动（discover 实测）。
  // 注意不能使用 U R U' L' U R' U' L —— 它会破坏角块朝向。
  topPermute(s, slots, pidx(-1, 1, 1), "R' F R' B2 R F' R' B2 R2", 'corner perm');
}

function stageEdgePerm(s) {
  const slots = EDGES.filter(([x, y, z]) => y === 1).map(([x, y, z]) => pidx(x, y, z));
  // R U' R U R U R U' R' U' R2 保持 UB (0,1,-1) 不动，轮换其余三棱（discover 实测）
  topPermute(s, slots, pidx(0, 1, -1), "R U' R U R U R U' R' U' R2", 'edge perm');
}

function solveCube(startState) {
  const s = new Solver(startState);
  stageCross(s);
  stageCorners(s);
  stageSecondLayer(s);
  stageTopCross(s);
  stageTopCornerOrient(s);
  stageCornerPerm(s);
  stageEdgePerm(s);
  if (!isSolved(s.state)) throw new Error('solver: 最终状态不是复原态');
  return s;
}

// ---------------------------------------------------------------------------
// 测试
// ---------------------------------------------------------------------------
function assert(cond, msg) { if (!cond) throw new Error(`ASSERT FAIL: ${msg}`); }

function runTests() {
  let pass = 0, fail = 0;
  const t = (name, fn) => {
    try { fn(); console.log(`  ok  ${name}`); pass++; }
    catch (e) { console.log(`FAIL  ${name}: ${e.message}`); fail++; }
  };

  console.log('== 引擎基础 ==');
  t('复原态判定', () => assert(isSolved(solvedState())));
  t('18 种基本转动均为 4 阶（转 4 次回复原）', () => {
    for (const m of BASIC_18) {
      let st = solvedState();
      for (let k = 0; k < 4; k++) st = applyMove(st, m);
      assert(isSolved(st), `${m} 转 4 次未复原`);
    }
  });
  t('逆转动抵消', () => {
    for (const m of BASIC_18) {
      const mi = m.includes("'") ? m.replace("'", '') : m.includes('2') ? m : m + "'";
      assert(isSolved(applyMove(applyMove(solvedState(), m), mi)), `${m} ${mi} 未抵消`);
    }
  });
  t('R 转把 F 面右列送到 U 面右列', () => {
    const fl = facelets(applyMove(solvedState(), 'R'));
    assert(fl.U[0][2] === 'G' && fl.U[1][2] === 'G' && fl.U[2][2] === 'G', `U 右列应为 G: ${JSON.stringify(fl.U)}`);
    assert(fl.F[0][2] === 'W' && fl.F[1][2] === 'W', 'F 右列应为 W');
  });
  t('U 转把 F 面顶行送到 L 面', () => {
    const fl = facelets(applyMove(solvedState(), 'U'));
    assert(fl.L[0][0] === 'G' && fl.L[0][1] === 'G' && fl.L[0][2] === 'G', 'L 顶行应为 G');
  });
  t('F 转把 U 面底行送到 R 面左列', () => {
    const fl = facelets(applyMove(solvedState(), 'F'));
    assert(fl.R[0][0] === 'Y' && fl.R[1][0] === 'Y' && fl.R[2][0] === 'Y', 'R 左列应为 Y');
  });

  console.log('== 录入解析 ==');
  const sampleInput = () => {
    const fl = facelets(solvedState());
    const input = {};
    for (const f of Object.keys(fl)) input[COLOR_OF_FACE[f]] = fl[f].map((r) => r.join('')).join('');
    return input;
  };
  t('面贴 ↔ 状态 往返一致（含打乱态）', () => {
    for (let k = 0; k < 20; k++) {
      const st = applyAlg(solvedState(), randomScramble(20));
      const fl = facelets(st);
      const input = {};
      for (const f of Object.keys(fl)) input[COLOR_OF_FACE[f]] = fl[f].map((r) => r.join('')).join('');
      const { state: back, errs } = parseInput(input);
      assert(errs.length === 0, `解析错误: ${errs.join(';')}`);
      assert(hashState(back) === hashState(st), '往返状态不一致');
    }
  });
  t('非法输入被拒绝（长度/字符/中心色）', () => {
    assert(parseInput({ ...sampleInput(), Y: 'YYYYYYYY' }).errs.length > 0, '长度 8 未拒绝');
    assert(parseInput({ ...sampleInput(), G: 'GGGGGGGGX' }).errs.length > 0, '非法字符未拒绝');
    assert(parseInput({ ...sampleInput(), G: 'GGGGYGGGG' }).errs.length > 0, '中心色错误未拒绝');
  });

  console.log('== 合法性不变量 ==');
  t('随机打乱全部通过校验', () => {
    for (let k = 0; k < 300; k++) {
      const errs = checkAll(applyAlg(solvedState(), randomScramble(30)));
      assert(errs.length === 0, `第 ${k} 次打乱误报: ${errs.join(';')}`);
    }
  });
  t('翻一个棱 → 校验失败', () => {
    const st = applyAlg(solvedState(), randomScramble(20));
    const c = st[pidx(...EDGES[3])];
    const ks = ['cx', 'cy', 'cz'].filter((k2) => c[k2]);
    const tmp = c[ks[0]]; c[ks[0]] = c[ks[1]]; c[ks[1]] = tmp;
    assert(checkAll(st).length > 0, '翻棱未被检出');
  });
  t('扭一个角 → 校验失败', () => {
    const st = applyAlg(solvedState(), randomScramble(20));
    const c = st[pidx(1, 1, 1)];
    const tmp = c.cx; c.cx = c.cy; c.cy = c.cz; c.cz = tmp;
    assert(checkAll(st).length > 0, '扭角未被检出');
  });
  t('对换两条棱 → 校验失败', () => {
    const st = applyAlg(solvedState(), randomScramble(20));
    const a = pidx(...EDGES[0]), b = pidx(...EDGES[5]);
    const tmp = st[a]; st[a] = st[b]; st[b] = tmp;
    assert(checkAll(st).length > 0, '棱对换未被检出');
  });
  t('贴纸对调（含 Y 棱与含 W 棱互换贴纸 → 出现非法棱）→ 检出', () => {
    const st = applyAlg(solvedState(), randomScramble(20));
    // 找一条含 Y 的棱和一条含 W 的棱，交换它们的一条贴纸：必产生不存在的 {Y,W} 棱
    let eY = null, eW = null;
    for (const [x, y, z] of EDGES) {
      const c = st[pidx(x, y, z)];
      if (!eY && (c.cx === 'Y' || c.cy === 'Y' || c.cz === 'Y')) eY = c;
      if (!eW && (c.cx === 'W' || c.cy === 'W' || c.cz === 'W')) eW = c;
    }
    const kY = ['cx', 'cy', 'cz'].find((k2) => eY[k2]);
    const kW = ['cx', 'cy', 'cz'].find((k2) => eW[k2]);
    const tmp = eY[kY]; eY[kY] = eW[kW]; eW[kW] = tmp;
    assert(checkAll(st).length > 0, '贴纸对调未被检出');
  });

  console.log('== 求解器 ==');
  const stats = { n: 0, total: 0, max: 0, bfsMax: 0 };
  t('随机打乱 500 次全部复原成功', () => {
    for (let k = 0; k < 500; k++) {
      const scr = randomScramble(25);
      const st = applyAlg(solvedState(), scr);
      const solver = solveCube(st);
      let st2 = st;
      for (const m of solver.moves) st2 = applyMove(st2, m);
      assert(isSolved(st2), `第 ${k} 次求解失败, scramble=${scr}`);
      stats.n++; stats.total += solver.moves.length;
      stats.max = Math.max(stats.max, solver.moves.length);
      stats.bfsMax = Math.max(stats.bfsMax, solver.stats.bfsMax);
    }
  });
  t('公式化简：语义不变且能消除冗余', () => {
    assert(simplifyAlg("U U") === 'U2', 'UU');
    assert(simplifyAlg("U U'") === '', "UU'");
    assert(simplifyAlg("U U U") === "U'", 'UUU');
    assert(simplifyAlg("U U' R R'") === '', '全消');
    assert(simplifyAlg("R U R'") === "R U R'", '不同面不动');
    let saved = 0, n = 0;
    for (let k = 0; k < 200; k++) {
      const scr = randomScramble(25);
      const st = applyAlg(solvedState(), scr);
      const solver = solveCube(st);
      const simple = simplifyAlg(solver.moves.join(' '));
      let st2 = st;
      for (const m of simple.split(/\s+/).filter(Boolean)) st2 = applyMove(st2, m);
      assert(isSolved(st2), `第 ${k} 次化简公式未复原: ${simple}`);
      saved += solver.moves.length - simple.split(/\s+/).filter(Boolean).length;
      n++;
    }
    console.log(`    化简平均节省 ${(saved / n).toFixed(1)} 步`);
  });
  t('浅打乱 / 已复原态也能处理', () => {
    solveCube(solvedState());
    const st = applyAlg(solvedState(), "R U R' U'");
    const solver = solveCube(st);
    let st2 = st;
    for (const m of solver.moves) st2 = applyMove(st2, m);
    assert(isSolved(st2), '浅打乱求解失败');
  });

  console.log(`\n求解统计: ${stats.n} 次, 平均 ${stats.n ? (stats.total / stats.n).toFixed(1) : 0} 步, 最长 ${stats.max} 步, 花瓣BFS最深 ${stats.bfsMax} 层`);
  console.log(`\n结果: ${pass} 通过, ${fail} 失败`);
  if (fail > 0) process.exitCode = 1;
}

// 算法效果探查（开发调试用）：node cube_ref.mjs discover
function discover() {
  const report = (label, alg) => {
    const st = applyAlg(solvedState(), alg);
    const moved = [];
    for (let i = 0; i < 27; i++) {
      if (st[i] && !cubieSolvedAt(st, i)) moved.push(JSON.stringify(coordOf(i)));
    }
    console.log(`${label} [${alg}] 影响槽位: ${moved.join(' ')}`);
  };
  report('角触发DFR', "R U R' U'");
  report('角触发DRB', "F U F' U'");
  report('角触发DBL', "L U L' U'");
  report('角触发DLF', "B U B' U'");
  report('角排列A', "U R U' L' U R' U' L");
  report('棱排列Ua', "R U' R U R U R U' R' U' R2");
  report('OLL十字', "F R U R' U' F'");
  report('单角定向RDRD', "R' D' R D");
  const st = applyAlg(solvedState(), "R U R' U'");
  console.log('\n样例求解:', solveCube(st).moves.join(' '));
}

if (process.argv[2] === 'discover') discover();
else if (process.argv[1] && process.argv[1].endsWith('cube_ref.mjs')) runTests();

export {
  solvedState, cloneState, hashState, applyMove, applyAlg, simplifyAlg, facelets, parseInput,
  checkAll, isSolved, findCubie, cubieSolvedAt, randomScramble, solveCube,
  pidx, coordOf, BASIC_18, MOVE_DEF, Solver,
  stageCross, stageCorners, stageSecondLayer, stageTopCross, stageTopCornerOrient, stageCornerPerm, stageEdgePerm,
};
