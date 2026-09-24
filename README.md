# CFOP_ABAP

本程序基于 ABAP 实现，使用 [CFOP](https://www.speedsolving.com/wiki/index.php/CFOP_method) / LBL（层先法）的思路还原三阶魔方。

**当前状态：v2.0 重构版** —— 三维坐标模型 + LBL 七阶段求解器已完整实现，附带可在 SAP 内运行的自检程序。

## 1. 总体设计

### 1.1 三维坐标模型

魔方状态 = 26 个小块（不含核心块），每个小块记录：

- 槽位坐标 `(x, y, z)`，各分量 ∈ {-1, 0, 1}，槽位下标 `idx = (x+1)*9 + (y+1)*3 + (z+1)`
- 三个轴向暴露面的颜色 `cx / cy / cz`（无暴露面为空）

固定坐标系与标准配色：

```
        Y(黄) U  y=+1
O(橙) L x=-1    G(绿) F z=+1
B(蓝) B z=-1    R(红) R x=+1
        W(白) D  y=-1
```

执行 R、F 等转法时，转层内的小块按三维旋转公式换位，同时两个非转轴颜色互换（±90°），例如绕 x 轴顺时针一次：

```
y' = z    z' = -y    交换 cy, cz
```

 <img src="https://github.com/Jack-Liang/CFOP_ABAP/blob/main/pic/三维坐标系.jpeg" alt="三维坐标系" align=center />

### 1.2 录入方式

 <img src="https://github.com/Jack-Liang/CFOP_ABAP/blob/main/pic/%E5%B1%95%E5%BC%80%E5%9B%BE.png" width = "622" height = "460.5" alt="魔方展开图" align=center />

按黄、橙、蓝、红、绿、白依次录入六面，每面 9 个贴纸（从该面外侧看，行自上而下、列自左到右）：

```
YYYYYYYYY
OOOOOOOOO
BBBBBBBBB
RRRRRRRRR
GGGGGGGGG
WWWWWWWWW
```

面的朝向由中心色决定，系统按标准配色校验并放入固定坐标系。

### 1.3 合法性校验（可解性不变量）

录入后依次校验：颜色数量、部件组合（8 角 + 12 棱）、棱翻转奇偶（Σflip ≡ 0 mod 2）、
角扭转总和（Σtwist ≡ 0 mod 3）、角/棱排列奇偶一致性——手工贴错纸也能检出。

### 1.4 LBL 七阶段求解器

| 阶段 | 方法 |
|------|------|
| 1. 白色十字 | 花瓣 BFS（宽度优先搜索把白棱逐条翻到顶层）+ 对齐 180° 插入 |
| 2. 第一层角块 | 触发公式 `f U f' U'`（按槽位换面共轭）重复至归位 |
| 3. 第二层棱块 | 标准左/右插入公式 |
| 4. 顶层十字 | 2-look OLL（`F R U R' U' F'` / `F U R U' R' F'`）贪心定向 |
| 5. 顶层角定向 | 经典 `R' D' R D` 逐角法 |
| 6. 顶层角排列 | 奇偶预判 + 纯角 3-cycle `R' F R' B2 R F' R' B2 R2` + U 共轭 |
| 7. 顶层棱排列 | 3-cycle `R U' R U R U R U' R' U' R2` + U 共轭 |

每个阶段结束即断言成果，失败会给出明确的阶段名与原因。
求解输出按阶段分组的完整公式（典型 150~300 步）。

## 2. 仓库结构（abapGit 格式）

```
src/
  z_cfop.prog.abap          主程序：事件、流程编排、自检
  z_cfop_top.prog.abap      类型定义 + 类声明（lcl_cube / lcl_solver）
  z_cfop_sel.prog.abap      选择屏幕
  z_cfop_check.prog.abap    录入 / 校验表单
  z_cfop_operate.prog.abap  lcl_cube 实现：三维模型 + 转动引擎 + 校验
  z_cfop_search.prog.abap   lcl_solver 实现：LBL 七阶段求解器
ref/cube_ref.mjs            JavaScript 参考实现（逻辑一一对应，2000 次随机打乱回归通过）
pic/                        示意图
```

**ref/cube_ref.mjs 是本项目的正确性基石**：ABAP 端无法在本机运行，所有算法
（转动公式、奇偶校验约定、七阶段流程、公式表）先在参考实现上通过 2000 次随机
打乱回归，再逐段移植为 ABAP。修改求解逻辑时请两处同步。

## 3. 安装与使用

### 3.1 安装（abapGit）

仓库为标准 abapGit 格式（`src/` + `.abapgit.xml`），用 abapGit 插件在线安装即可，
对象均为 `Z_CFOP*` 报表与包含程序。

### 3.2 使用

- **求解录入的魔方**：六面参数按展开图录入 → 执行 → 输出分阶段公式
- **打乱演示**：点"生成随机打乱公式"→ 回车，从复原态打乱后直接求解
- **自检**：勾选"运行自检"→ 执行。自检包含：18 种转动 4 阶/逆抵消、方向抽检、
  面贴↔状态往返、校验误报/篡改检出、打乱→求解→复原端到端（SAP 内的完整回归）

### 3.3 语法检查（abaplint）

```bash
npm install
npm run lint    # abaplint，0 issue
npm test        # 运行 JS 参考实现的回归测试
```

## 4. 转法记号

标准 Singmaster 记号：`U D L R F B` 六个面，`'` 逆时针，`2` 转 180°，
如 `R U R' U'`。程序内部即按此记号解析与输出。

## 其他

- 因个人习惯，原作者使用 CFOP 时先白心朝上还原白色 Cross，再旋转 180° 继续；
  本程序全程固定坐标系（白底黄顶），由程序代为处理视角。
- 后续计划：F2L/OLL/PLL 完整 CFOP 算法表（当前为 LBL 初级法，结构上已支持扩展）。

---

# 参考文献

1. https://github.com/crumpstrr33/CFOP-cube-solver
2. https://www.speedsolving.com/wiki/index.php/CFOP_method
3. https://juejin.cn/post/6970700421035884558
4. http://kociemba.org/cube.htm

谨对以上文献的作者表示感谢，未竟之处，敬请谅解，欢迎交流指正。
