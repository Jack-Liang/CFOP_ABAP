*&---------------------------------------------------------------------*
*& 报表 Z_CFOP：基于 CFOP/LBL 思路的三阶魔方还原
*&---------------------------------------------------------------------*
*& 项目地址：https://github.com/Jack-Liang/CFOP_ABAP
*& 参考实现：ref/cube_ref.mjs（2000 次随机打乱回归全部通过）
*& 实现说明：
*&   魔方以三维坐标建模（26 小块，每块记录三轴向暴露面颜色），
*&   转动 = 槽位按旋转公式换位 + 两个非转轴颜色互换；
*&   求解 = LBL 初级法七个阶段（白十字 → 一层角 → 二层棱 →
*&   顶层十字 → 顶角定向 → 顶角排列 → 顶棱排列），
*&   每阶段结束即断言成果；全部算法公式与参考实现一一对应。
*&-------------------------------------------------
*& 修改日志
*& 2021.07.29  JACK LIANG  初版（录入 / 校验 / 三维模型 / 打乱）
*& 2026.09     JACK LIANG  重构：转动引擎重写、可解性校验、
*&                         LBL 七阶段求解器、自检、abapGit/abaplint
*&---------------------------------------------------------------------*
REPORT z_cfop.

INCLUDE z_cfop_top.
INCLUDE z_cfop_sel.
INCLUDE z_cfop_check.
INCLUDE z_cfop_search.
INCLUDE z_cfop_operate.

INITIALIZATION.
  PERFORM frm_initialization.

AT SELECTION-SCREEN.
  IF sy-ucomm = 'SCRAM'.
    p_scram = lcl_cube=>random_scramble( 25 ).
  ELSEIF sy-ucomm = 'FILL'.
    p_yellow = 'YYYYYYYYY'.
    p_orange = 'OOOOOOOOO'.
    p_blue   = 'BBBBBBBBB'.
    p_red    = 'RRRRRRRRR'.
    p_green  = 'GGGGGGGGG'.
    p_white  = 'WWWWWWWWW'.
  ENDIF.

START-OF-SELECTION.
  IF p_test = 'X'.
    PERFORM frm_self_test.
    RETURN.
  ENDIF.

  DATA: lt_cubies TYPE tt_cubie,
        rv_ok     TYPE abap_bool.

  IF p_scram IS NOT INITIAL.
    " 打乱演示：还原态 + 打乱公式 → 求解
    WRITE: / '打乱公式:', p_scram.
    ULINE.
    lt_cubies = lcl_cube=>apply_alg( it_cubies = lcl_cube=>solved_state( ) iv_alg = CONV string( p_scram ) ).
    IF lcl_cube=>sv_error IS NOT INITIAL.
      WRITE: / '错误:' COLOR COL_NEGATIVE, lcl_cube=>sv_error.
      RETURN.
    ENDIF.
  ELSE.
    PERFORM frm_build_cube CHANGING lt_cubies rv_ok.
    IF rv_ok = abap_false.
      WRITE: / '录入校验未通过，请检查后重试。' COLOR COL_NEGATIVE.
      RETURN.
    ENDIF.
  ENDIF.

  PERFORM frm_show_cube USING lt_cubies.

  IF lcl_cube=>is_solved( lt_cubies ) = abap_true.
    WRITE: / '魔方已处于还原状态，无需求解。' COLOR COL_POSITIVE.
    RETURN.
  ENDIF.

  ULINE.
  DATA lo_solver TYPE REF TO lcl_solver.
  DATA lt_steps TYPE tt_solve_step.
  CREATE OBJECT lo_solver.
  lo_solver->solve(
    EXPORTING it_cubies = lt_cubies
    IMPORTING et_steps  = lt_steps ).
  IF lo_solver->mv_error IS NOT INITIAL.
    WRITE: / '求解失败:' COLOR COL_NEGATIVE, lo_solver->mv_error.
    RETURN.
  ENDIF.

  " 按阶段输出公式
  DATA lv_total TYPE i VALUE 0.
  DATA lv_stage TYPE string.
  LOOP AT lt_steps INTO DATA(ls_step).
    IF ls_step-stage <> lv_stage.
      lv_stage = ls_step-stage.
      WRITE: / |阶段 { lv_stage }| COLOR COL_HEADING.
    ENDIF.
    lv_total = lv_total + 1.
  ENDLOOP.
  ULINE.
  WRITE: / |共 { lv_total } 步，完整公式:|.
  DATA lv_alg TYPE string.
  LOOP AT lt_steps INTO ls_step.
    lv_alg = COND #( WHEN lv_alg IS INITIAL THEN ls_step-move
                     ELSE |{ lv_alg } { ls_step-move }| ).
  ENDLOOP.
  WRITE: / lv_alg.

  " 重放公式，确认复原
  LOOP AT lt_steps INTO ls_step.
    lt_cubies = lcl_cube=>apply_move( it_cubies = lt_cubies iv_move = ls_step-move ).
  ENDLOOP.
  IF lcl_cube=>is_solved( lt_cubies ) = abap_false.
    WRITE: / '警告: 重放公式后未复原（内部错误）' COLOR COL_NEGATIVE.
    RETURN.
  ENDIF.
  ULINE.
  WRITE: / '执行后的魔方（应为复原态）:'.
  PERFORM frm_show_cube USING lt_cubies.

*&---------------------------------------------------------------------*
*& Form FRM_SELF_TEST：自检（引擎 / 录入 / 校验 / 求解 回归）
*&---------------------------------------------------------------------*
FORM frm_self_test.
  DATA: lv_pass TYPE i VALUE 0,
        lv_fail TYPE i VALUE 0.

  WRITE: / '==== Z_CFOP 自检 ===='.

  " —— 0) 复原态判定 ——
  DATA lt_solved TYPE tt_cubie.
  lt_solved = lcl_cube=>solved_state( ).
  DATA lv_b TYPE abap_bool.
  lv_b = boolc( lcl_cube=>is_solved( lt_solved ) = abap_true ).
  PERFORM frm_report USING '引擎：复原态判定' lv_b CHANGING lv_pass lv_fail.

  " —— 1) 18 种基本转动均为 4 阶、逆转动抵消 ——
  DATA lt_moves TYPE STANDARD TABLE OF ty_c2 WITH EMPTY KEY.
  lt_moves = VALUE #( ( 'U' ) ( 'U''' ) ( 'U2' ) ( 'D' ) ( 'D''' ) ( 'D2' )
                      ( 'R' ) ( 'R''' ) ( 'R2' ) ( 'L' ) ( 'L''' ) ( 'L2' )
                      ( 'F' ) ( 'F''' ) ( 'F2' ) ( 'B' ) ( 'B''' ) ( 'B2' ) ).

  DATA lv_ok TYPE abap_bool VALUE abap_true.
  LOOP AT lt_moves INTO DATA(lv_mv).
    DATA(lt_c) = lt_solved.
    DO 4 TIMES.
      lt_c = lcl_cube=>apply_move( it_cubies = lt_c iv_move = lv_mv ).
    ENDDO.
    IF lcl_cube=>is_solved( lt_c ) = abap_false.
      lv_ok = abap_false.
    ENDIF.
    " 逆抵消
    DATA(lv_inv) = COND #( WHEN lv_mv CA `'` THEN replace( val = lv_mv sub = `'` with = `` occ = 0 )
                           WHEN lv_mv CA '2' THEN lv_mv
                           ELSE |{ lv_mv }'| ).
    lt_c = lcl_cube=>apply_move( it_cubies = lt_solved iv_move = lv_mv ).
    lt_c = lcl_cube=>apply_move( it_cubies = lt_c iv_move = lv_inv ).
    IF lcl_cube=>is_solved( lt_c ) = abap_false.
      lv_ok = abap_false.
    ENDIF.
  ENDLOOP.
  PERFORM frm_report USING '引擎：18 种转动 4 阶 / 逆抵消' lv_ok CHANGING lv_pass lv_fail.

  " —— 2) 转动方向抽检：R 把 F 面右列送到 U 面右列 ——
  lt_c = lcl_cube=>apply_move( it_cubies = lt_solved iv_move = 'R' ).
  DATA(lt_faces) = lcl_cube=>to_faces( lt_c ).
  READ TABLE lt_faces INTO DATA(ls_fy) WITH KEY color = 'Y'.
  DATA(lv_u) = ls_fy-face.
  lv_ok = boolc( substring( val = lv_u off = 2 len = 1 ) = 'G' AND
                 substring( val = lv_u off = 5 len = 1 ) = 'G' AND
                 substring( val = lv_u off = 8 len = 1 ) = 'G' ).
  PERFORM frm_report USING '引擎：R 转方向抽检（U 面右列 = 绿）' lv_ok CHANGING lv_pass lv_fail.

  " —— 3) 面贴 ↔ 状态 往返一致 ——
  lv_ok = abap_true.
  DO 5 TIMES.
    DATA(lv_scr) = lcl_cube=>random_scramble( 20 ).
    lt_c = lcl_cube=>apply_alg( it_cubies = lt_solved iv_alg = lv_scr ).
    DATA(lv_s1) = lcl_cube=>to_state( lt_c ).
    DATA(lt_f) = lcl_cube=>to_faces( lt_c ).
    lcl_cube=>from_faces( EXPORTING it_faces  = lt_f
                          IMPORTING et_cubies = DATA(lt_back)
                                    et_msg    = DATA(lt_msg) ).
    IF lines( lt_msg ) > 0 OR lcl_cube=>to_state( lt_back ) <> lv_s1.
      lv_ok = abap_false.
      EXIT.
    ENDIF.
  ENDDO.
  PERFORM frm_report USING '录入：面贴 ↔ 状态往返一致（5 次随机打乱）' lv_ok CHANGING lv_pass lv_fail.

  " —— 4) 校验：打乱应通过，篡改应失败 ——
  lv_ok = abap_true.
  DO 10 TIMES.
    lv_scr = lcl_cube=>random_scramble( 30 ).
    lt_c = lcl_cube=>apply_alg( it_cubies = lt_solved iv_alg = lv_scr ).
    IF lines( lcl_cube=>check( lt_c ) ) > 0.
      lv_ok = abap_false.
      EXIT.
    ENDIF.
  ENDDO.
  PERFORM frm_report USING '校验：随机打乱无误报（10 次）' lv_ok CHANGING lv_pass lv_fail.

  " 篡改 1：翻一条棱（交换两条贴纸）
  lt_c = lcl_cube=>apply_alg( it_cubies = lt_solved iv_alg = lcl_cube=>random_scramble( 20 ) ).
  DATA(lv_eidx) = lcl_cube=>idx_of( iv_x = 0 iv_y = 1 iv_z = 1 ).
  READ TABLE lt_c INTO DATA(ls_cu) WITH KEY idx = lv_eidx.
  DATA(lv_tmp) = ls_cu-cy.
  ls_cu-cy = ls_cu-cz.
  ls_cu-cz = lv_tmp.
  MODIFY TABLE lt_c FROM ls_cu.
  lv_ok = boolc( lines( lcl_cube=>check( lt_c ) ) > 0 ).
  PERFORM frm_report USING '校验：翻棱被检出' lv_ok CHANGING lv_pass lv_fail.

  " 篡改 2：扭一个角
  lt_c = lcl_cube=>apply_alg( it_cubies = lt_solved iv_alg = lcl_cube=>random_scramble( 20 ) ).
  READ TABLE lt_c INTO ls_cu WITH KEY idx = lcl_cube=>idx_of( iv_x = 1 iv_y = 1 iv_z = 1 ).
  lv_tmp = ls_cu-cx.
  ls_cu-cx = ls_cu-cy.
  ls_cu-cy = ls_cu-cz.
  ls_cu-cz = lv_tmp.
  MODIFY TABLE lt_c FROM ls_cu.
  lv_ok = boolc( lines( lcl_cube=>check( lt_c ) ) > 0 ).
  PERFORM frm_report USING '校验：扭角被检出' lv_ok CHANGING lv_pass lv_fail.

  " 篡改 3：对换两条棱
  lt_c = lcl_cube=>apply_alg( it_cubies = lt_solved iv_alg = lcl_cube=>random_scramble( 20 ) ).
  READ TABLE lt_c INTO DATA(ls_a) WITH KEY idx = lcl_cube=>idx_of( iv_x = 0 iv_y = 1 iv_z = 1 ).
  READ TABLE lt_c INTO DATA(ls_b) WITH KEY idx = lcl_cube=>idx_of( iv_x = 1 iv_y = 1 iv_z = 0 ).
  DATA(lv_ai) = ls_a-idx.
  ls_a-idx = ls_b-idx.
  ls_b-idx = lv_ai.
  MODIFY TABLE lt_c FROM ls_a.
  MODIFY TABLE lt_c FROM ls_b.
  lv_ok = boolc( lines( lcl_cube=>check( lt_c ) ) > 0 ).
  PERFORM frm_report USING '校验：棱对换被检出' lv_ok CHANGING lv_pass lv_fail.

  " —— 5) 端到端：打乱 → 求解 → 复原（2 次随机 + 1 次固定）——
  DO 3 TIMES.
    IF sy-index = 3.
      lv_scr = `R U R' U'`.
    ELSE.
      lv_scr = lcl_cube=>random_scramble( 25 ).
    ENDIF.
    lt_c = lcl_cube=>apply_alg( it_cubies = lt_solved iv_alg = lv_scr ).
    DATA lo_solver TYPE REF TO lcl_solver.
    CREATE OBJECT lo_solver.
    lv_ok = abap_false.
    lo_solver->solve( EXPORTING it_cubies = lt_c
                      IMPORTING et_steps  = DATA(lt_steps) ).
    IF lo_solver->mv_error IS NOT INITIAL.
      WRITE: / '   求解异常:', lo_solver->mv_error, '打乱:', lv_scr.
    ELSE.
      " 重放全部步骤后必须复原
      LOOP AT lt_steps INTO DATA(ls_step).
        lt_c = lcl_cube=>apply_move( it_cubies = lt_c iv_move = ls_step-move ).
      ENDLOOP.
      lv_ok = lcl_cube=>is_solved( lt_c ).
    ENDIF.
    DATA(lv_title) = |端到端：打乱→求解→复原（{ lv_scr }）|.
    PERFORM frm_report USING lv_title lv_ok CHANGING lv_pass lv_fail.
  ENDDO.

  ULINE.
  IF lv_fail = 0.
    WRITE: / |自检全部通过（{ lv_pass } 项）| COLOR COL_POSITIVE.
  ELSE.
    WRITE: / |自检失败：{ lv_fail } 项未通过| COLOR COL_NEGATIVE.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FRM_REPORT：单项结果输出
*&---------------------------------------------------------------------*
FORM frm_report USING pv_name TYPE string
                      pv_ok   TYPE abap_bool
                 CHANGING cv_pass TYPE i
                          cv_fail TYPE i.
  IF pv_ok = abap_true.
    WRITE: / '  通过' COLOR COL_POSITIVE, pv_name.
    cv_pass = cv_pass + 1.
  ELSE.
    WRITE: / '  失败' COLOR COL_NEGATIVE, pv_name.
    cv_fail = cv_fail + 1.
  ENDIF.
ENDFORM.
