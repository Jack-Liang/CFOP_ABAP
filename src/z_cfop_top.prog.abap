*&---------------------------------------------------------------------*
*& 包含 Z_CFOP_TOP：数据类型与类声明
*&---------------------------------------------------------------------*
* 固定坐标系（与参考实现 ref/cube_ref.mjs 完全一致）：
*   x 轴：+1 = R(红)  -1 = L(橙)
*   y 轴：+1 = U(黄)  -1 = D(白)
*   z 轴：+1 = F(绿)  -1 = B(蓝)
*   槽位下标 idx = (x+1)*9 + (y+1)*3 + (z+1)，核心块槽位 13 恒不存在。
*   小块记录三个轴向暴露面的颜色（cx/cy/cz），无暴露面为 SPACE。
*   白色在 D、黄色在 U，求解全程固定坐标系。
*
* 转动引擎（绕 +轴顺时针一次 90°）：
*   x 轴: y'=z  z'=-y   交换 cy,cz
*   y 轴: z'=x  x'=-z   交换 cz,cx
*   z 轴: x'=y  y'=-x   交换 cx,cy
*   面转以"从该面外侧看顺时针"为准，D/L/B 位于负轴，故 cw = 3。

TYPES: BEGIN OF ty_cubie,
         idx TYPE i,
         cx  TYPE c LENGTH 1,
         cy  TYPE c LENGTH 1,
         cz  TYPE c LENGTH 1,
       END OF ty_cubie.
TYPES tt_cubie TYPE SORTED TABLE OF ty_cubie WITH UNIQUE KEY idx.
" BFS 用紧凑状态串：idx*3 + 0/1/2 位对应 cx/cy/cz，'.' 表示无暴露面
TYPES ty_cstate TYPE c LENGTH 81.
TYPES: BEGIN OF ty_msg,
         text TYPE string,
       END OF ty_msg.
TYPES tt_msg TYPE STANDARD TABLE OF ty_msg WITH EMPTY KEY.
TYPES: BEGIN OF ty_facestr,
         color TYPE c LENGTH 1,
         face  TYPE c LENGTH 9,
       END OF ty_facestr.
TYPES tt_facestr TYPE STANDARD TABLE OF ty_facestr WITH EMPTY KEY.
TYPES: BEGIN OF ty_solve_step,
         stage TYPE string,
         move  TYPE string,
       END OF ty_solve_step.
TYPES tt_solve_step TYPE STANDARD TABLE OF ty_solve_step WITH EMPTY KEY.
TYPES: BEGIN OF ty_move_spec,
         axis  TYPE i,            " 1=x 2=y 3=z
         layer TYPE i,            " 参与转动的层坐标（±1）
         cw    TYPE i,            " 绕 +轴顺时针 90° 的次数 1..3
       END OF ty_move_spec.
TYPES: ty_c1 TYPE c LENGTH 1,
       ty_c2 TYPE c LENGTH 2,
       ty_c3 TYPE c LENGTH 3.
TYPES tt_colors TYPE STANDARD TABLE OF ty_c3 WITH EMPTY KEY.
TYPES tt_slots  TYPE STANDARD TABLE OF i WITH EMPTY KEY.

*---------------------------------------------------------*
* 魔方模型与转动引擎（纯静态工具类）
*---------------------------------------------------------*
CLASS lcl_cube DEFINITION FINAL.
  PUBLIC SECTION.
    " 最近一次引擎错误（apply_alg 入口清空；非初始表示公式含无法识别的转法）
    CLASS-DATA sv_error TYPE string READ-ONLY.

    " —— 构造 ——
    CLASS-METHODS solved_state
      RETURNING VALUE(rt_cubies) TYPE tt_cubie.

    CLASS-METHODS from_faces
      IMPORTING it_faces       TYPE tt_facestr
      EXPORTING et_cubies      TYPE tt_cubie
                et_msg         TYPE tt_msg.

    " —— 转动引擎 ——
    CLASS-METHODS move_spec
      IMPORTING iv_move        TYPE clike
      RETURNING VALUE(rs_spec) TYPE ty_move_spec.

    CLASS-METHODS apply_move
      IMPORTING it_cubies      TYPE tt_cubie
                iv_move        TYPE clike
      RETURNING VALUE(rt_cubies) TYPE tt_cubie.

    CLASS-METHODS apply_alg
      IMPORTING it_cubies      TYPE tt_cubie
                iv_alg         TYPE string
      RETURNING VALUE(rt_cubies) TYPE tt_cubie.

    " —— 状态编码 / 展示 ——
    CLASS-METHODS to_state
      IMPORTING it_cubies      TYPE tt_cubie
      RETURNING VALUE(rv_state) TYPE ty_cstate.

    CLASS-METHODS from_state
      IMPORTING iv_state       TYPE ty_cstate
      RETURNING VALUE(rt_cubies) TYPE tt_cubie.

    CLASS-METHODS to_faces
      IMPORTING it_cubies      TYPE tt_cubie
      RETURNING VALUE(rt_faces) TYPE tt_facestr.   " 按 Y,O,B,R,G,W 顺序输出

    " —— 查询 ——
    CLASS-METHODS is_solved
      IMPORTING it_cubies      TYPE tt_cubie
      RETURNING VALUE(rv_ok)   TYPE abap_bool.

    CLASS-METHODS solved_at
      IMPORTING it_cubies      TYPE tt_cubie
                iv_idx         TYPE i
      RETURNING VALUE(rv_ok)   TYPE abap_bool.

    CLASS-METHODS find_cubie
      IMPORTING it_cubies      TYPE tt_cubie
                iv_colors      TYPE clike      " 颜色集合串（任意顺序）
      RETURNING VALUE(rv_idx)  TYPE i.         " 找不到返回 -1

    CLASS-METHODS check
      IMPORTING it_cubies      TYPE tt_cubie
      RETURNING VALUE(rt_msg)  TYPE tt_msg.    " 空 = 合法（可解）

    " —— 坐标工具 ——
    CLASS-METHODS idx_of
      IMPORTING iv_x           TYPE i
                iv_y           TYPE i
                iv_z           TYPE i
      RETURNING VALUE(rv_idx)  TYPE i.

    CLASS-METHODS x_of
      IMPORTING iv_idx         TYPE i
      RETURNING VALUE(rv_x)    TYPE i.

    CLASS-METHODS y_of
      IMPORTING iv_idx         TYPE i
      RETURNING VALUE(rv_y)    TYPE i.

    CLASS-METHODS z_of
      IMPORTING iv_idx         TYPE i
      RETURNING VALUE(rv_z)    TYPE i.

    " 小块颜色集合（排序后拼接，用于匹配）
    CLASS-METHODS cubie_colors
      IMPORTING is_cubie       TYPE ty_cubie
      RETURNING VALUE(rv_col)  TYPE ty_c3.

    " 颜色集合串排序（忽略空格，最多 3 色）
    CLASS-METHODS sort_colors
      IMPORTING iv_colors      TYPE clike
      RETURNING VALUE(rv_col)  TYPE ty_c3.

    " 在状态串中按颜色集合定位小块，找不到返回 -1
    CLASS-METHODS state_find
      IMPORTING iv_state       TYPE ty_cstate
                iv_colors      TYPE clike
      RETURNING VALUE(rv_idx)  TYPE i.

    " 随机打乱公式（长度 iv_len，同面不连续）
    CLASS-METHODS random_scramble
      IMPORTING iv_len         TYPE i
      RETURNING VALUE(rv_alg)  TYPE string.
ENDCLASS.

*---------------------------------------------------------*
* LBL 初级法求解器（白色十字在 D，全程固定坐标系）
*---------------------------------------------------------*
CLASS lcl_solver DEFINITION FINAL.
  PUBLIC SECTION.
    " 求解失败原因（solve 返回后检查；初始 = 成功）
    DATA mv_error TYPE string READ-ONLY.

    METHODS solve
      IMPORTING it_cubies TYPE tt_cubie
      EXPORTING et_steps  TYPE tt_solve_step.

  PRIVATE SECTION.
    DATA mt_cubies TYPE tt_cubie.
    DATA mt_steps  TYPE tt_solve_step.
    DATA mv_stage  TYPE string.

    METHODS fail
      IMPORTING iv_msg TYPE string.

    METHODS run
      IMPORTING iv_move TYPE clike.

    METHODS run_alg
      IMPORTING iv_alg TYPE string.

    " —— 七个阶段（每个阶段结束即断言阶段成果）——
    METHODS stage_cross.
    METHODS stage_corners.
    METHODS stage_second_layer.
    METHODS stage_top_cross.
    METHODS stage_top_corner_orient.
    METHODS stage_corner_perm.
    METHODS stage_edge_perm.

    " —— 工具 ——
    METHODS bfs_daisy
      IMPORTING iv_target        TYPE clike
                it_petals        TYPE tt_colors
      RETURNING VALUE(rv_moves)  TYPE string.

    METHODS bfs_goal
      IMPORTING iv_state         TYPE ty_cstate
                iv_target        TYPE clike
                it_petals        TYPE tt_colors
      RETURNING VALUE(rv_ok)     TYPE abap_bool.

    METHODS corner_perm_parity_odd
      RETURNING VALUE(rv_odd) TYPE abap_bool.

    METHODS top_permute
      IMPORTING it_slots        TYPE tt_slots
                iv_alg          TYPE string.

    METHODS count_solved
      IMPORTING it_cubies       TYPE tt_cubie
                it_slots        TYPE tt_slots
      RETURNING VALUE(rv_cnt)   TYPE i.

    METHODS count_y_edges
      IMPORTING it_cubies       TYPE tt_cubie
      RETURNING VALUE(rv_cnt)   TYPE i.

    METHODS slot_trigger
      IMPORTING iv_x            TYPE i
                iv_z            TYPE i
      RETURNING VALUE(rv_alg)   TYPE string.

    METHODS right_insert
      IMPORTING iv_face         TYPE clike
      RETURNING VALUE(rv_alg)   TYPE string.

    METHODS left_insert
      IMPORTING iv_face         TYPE clike
      RETURNING VALUE(rv_alg)   TYPE string.

    METHODS u_prev
      IMPORTING iv_face         TYPE clike
      RETURNING VALUE(rv_face)  TYPE ty_c1.

    METHODS u_next
      IMPORTING iv_face         TYPE clike
      RETURNING VALUE(rv_face)  TYPE ty_c1.

    METHODS face_of_side
      IMPORTING iv_side         TYPE clike
      RETURNING VALUE(rv_face)  TYPE ty_c1.

    METHODS eject_face
      IMPORTING iv_x            TYPE i
                iv_z            TYPE i
      RETURNING VALUE(rv_face)  TYPE ty_c1.
ENDCLASS.
