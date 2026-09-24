*&---------------------------------------------------------------------*
*& 包含 Z_CFOP_SEARCH：lcl_solver 实现（LBL 初级法求解器）
*&---------------------------------------------------------------------*
*& 逻辑与参考实现 ref/cube_ref.mjs 逐段对应（该实现已通过 2000 次随机
*& 打乱回归测试）。七个阶段，每阶段结束即断言成果，失败记录到 mv_error。
CLASS lcl_solver IMPLEMENTATION.

  METHOD solve.
    CLEAR: mt_steps, mv_error.
    mt_cubies = it_cubies.

    mv_stage = '1/7 白色十字（花瓣 BFS + 对齐插入）'.
    stage_cross( ).
    IF mv_error IS NOT INITIAL.
      CLEAR et_steps.
      RETURN.
    ENDIF.
    mv_stage = '2/7 第一层角块（触发公式插入）'.
    stage_corners( ).
    IF mv_error IS NOT INITIAL.
      CLEAR et_steps.
      RETURN.
    ENDIF.
    mv_stage = '3/7 第二层棱块（左/右插入）'.
    stage_second_layer( ).
    IF mv_error IS NOT INITIAL.
      CLEAR et_steps.
      RETURN.
    ENDIF.
    mv_stage = '4/7 顶层十字（2-look OLL）'.
    stage_top_cross( ).
    IF mv_error IS NOT INITIAL.
      CLEAR et_steps.
      RETURN.
    ENDIF.
    mv_stage = '5/7 顶层角块定向（R''D''RD 逐角）'.
    stage_top_corner_orient( ).
    IF mv_error IS NOT INITIAL.
      CLEAR et_steps.
      RETURN.
    ENDIF.
    mv_stage = '6/7 顶层角块排列（纯 3-cycle + 奇偶预判）'.
    stage_corner_perm( ).
    IF mv_error IS NOT INITIAL.
      CLEAR et_steps.
      RETURN.
    ENDIF.
    mv_stage = '7/7 顶层棱块排列（3-cycle 共轭）'.
    stage_edge_perm( ).

    IF mv_error IS INITIAL AND lcl_cube=>is_solved( mt_cubies ) = abap_false.
      fail( '求解器内部错误：最终状态不是复原态' ).
    ENDIF.
    IF mv_error IS NOT INITIAL.
      CLEAR et_steps.
      RETURN.
    ENDIF.
    et_steps = mt_steps.
  ENDMETHOD.

  METHOD fail.
    IF mv_error IS INITIAL.
      mv_error = iv_msg.
    ENDIF.
  ENDMETHOD.

  METHOD run.
    IF mv_error IS NOT INITIAL OR lcl_cube=>sv_error IS NOT INITIAL.
      IF lcl_cube=>sv_error IS NOT INITIAL.
        fail( lcl_cube=>sv_error ).
      ENDIF.
      RETURN.
    ENDIF.
    mt_cubies = lcl_cube=>apply_move( it_cubies = mt_cubies iv_move = iv_move ).
    IF lcl_cube=>sv_error IS NOT INITIAL.
      fail( lcl_cube=>sv_error ).
      RETURN.
    ENDIF.
    APPEND VALUE #( stage = mv_stage move = |{ iv_move }| ) TO mt_steps.
  ENDMETHOD.

  METHOD run_alg.
    SPLIT iv_alg AT space INTO TABLE DATA(lt_move).
    LOOP AT lt_move INTO DATA(lv_move).
      IF lv_move IS INITIAL.
        CONTINUE.
      ENDIF.
      run( lv_move ).
    ENDLOOP.
  ENDMETHOD.

  " ============================================================= 阶段 1
  METHOD stage_cross.
    DATA lt_cross TYPE tt_slots.
    " —— 1) 花瓣：4 条白棱全部上到 U 层且白贴朝上（BFS，保持已放花瓣）——
    DATA lt_petals TYPE tt_colors.
    DATA lt_sides TYPE STANDARD TABLE OF ty_c1 WITH EMPTY KEY.
    lt_sides = VALUE #( ( 'G' ) ( 'R' ) ( 'B' ) ( 'O' ) ).
    LOOP AT lt_sides INTO DATA(lv_side).
      DATA(lv_target) = lcl_cube=>sort_colors( |W{ lv_side }| ).
      run_alg( bfs_daisy( iv_target = lv_target it_petals = lt_petals ) ).
      APPEND lv_target TO lt_petals.
    ENDLOOP.

    " —— 2) 对齐 + 180° 插入 ×4 ——
    DO 4 TIMES.
      DATA(lv_petal) = -1.
      LOOP AT lt_sides INTO lv_side.
        DATA(lv_idx) = lcl_cube=>find_cubie( it_cubies = mt_cubies iv_colors = |W{ lv_side }| ).
        CLEAR ls_cubie.
        IF lv_idx >= 0 AND lcl_cube=>y_of( lv_idx ) = 1.
          READ TABLE mt_cubies INTO DATA(ls_cubie) WITH KEY idx = lv_idx.
          IF ls_cubie-cy = 'W'.
            lv_petal = lv_idx.
            EXIT.
          ENDIF.
        ENDIF.
      ENDLOOP.
      IF lv_petal < 0.
        fail( 'cross: 找不到花瓣' ).
    RETURN.
      ENDIF.
      READ TABLE mt_cubies INTO ls_cubie WITH KEY idx = lv_petal.
      DATA(lv_scolor) = COND #( WHEN ls_cubie-cx IS NOT INITIAL THEN ls_cubie-cx ELSE ls_cubie-cz ).
      DO 4 TIMES.
        lv_idx = lcl_cube=>find_cubie( it_cubies = mt_cubies iv_colors = |W{ lv_scolor }| ).
        DATA(lv_x) = lcl_cube=>x_of( lv_idx ).
        DATA(lv_z) = lcl_cube=>z_of( lv_idx ).
        DATA(lv_adj) = COND #( WHEN lv_x = 1 THEN 'R'
                               WHEN lv_x = -1 THEN 'L'
                               WHEN lv_z = 1 THEN 'F'
                               ELSE 'B' ).
        IF lv_adj = face_of_side( lv_scolor ).
          run( |{ lv_adj }2| ).
          EXIT.
        ENDIF.
        run( 'U' ).
      ENDDO.
    ENDDO.

    " —— 断言：底层白十字 ——
    lt_cross = VALUE #( ( lcl_cube=>idx_of( iv_x = 0  iv_y = -1 iv_z = 1 ) )
                        ( lcl_cube=>idx_of( iv_x = 1  iv_y = -1 iv_z = 0 ) )
                        ( lcl_cube=>idx_of( iv_x = 0  iv_y = -1 iv_z = -1 ) )
                        ( lcl_cube=>idx_of( iv_x = -1 iv_y = -1 iv_z = 0 ) ) ).
    IF count_solved( it_cubies = mt_cubies it_slots = lt_cross ) <> 4.
      fail( 'cross: 底层白十字未完成' ).
      RETURN.
    ENDIF.
  ENDMETHOD.

  " ============================================================= 阶段 2
  METHOD stage_corners.
    DATA: lt_targets TYPE tt_colors,
          lt_slots   TYPE tt_slots,
          lt_side    TYPE STANDARD TABLE OF ty_c1 WITH EMPTY KEY.
    lt_targets = VALUE #( ( 'GRW' ) ( 'BRW' ) ( 'BOW' ) ( 'GOW' ) ).
    LOOP AT lt_targets INTO DATA(lv_key).
      DO 8 TIMES.
        DATA(lv_idx) = lcl_cube=>find_cubie( it_cubies = mt_cubies iv_colors = lv_key ).
        IF lcl_cube=>solved_at( it_cubies = mt_cubies iv_idx = lv_idx ) = abap_true.
          EXIT.
        ENDIF.
        IF lcl_cube=>y_of( lv_idx ) = -1.
          " 卡在底层：用所在槽位的触发公式弹出
          run_alg( slot_trigger( iv_x = lcl_cube=>x_of( lv_idx ) iv_z = lcl_cube=>z_of( lv_idx ) ) ).
          CONTINUE.
        ENDIF.
        " 在 U 层：转到家的正上方，反复触发直到归位
        READ TABLE mt_cubies INTO DATA(ls_cubie) WITH KEY idx = lv_idx.
        DATA(lv_hx) = 0.
        DATA(lv_hz) = 0.
        CLEAR lt_side.
        APPEND ls_cubie-cx TO lt_side.
        APPEND ls_cubie-cy TO lt_side.
        APPEND ls_cubie-cz TO lt_side.
        LOOP AT lt_side INTO DATA(lv_sc).
          IF lv_sc IS INITIAL OR lv_sc = 'W'.
            CONTINUE.
          ENDIF.
          CASE face_of_side( lv_sc ).
            WHEN 'R'.
              lv_hx = 1.
            WHEN 'L'.
              lv_hx = -1.
            WHEN 'F'.
              lv_hz = 1.
            WHEN 'B'.
              lv_hz = -1.
          ENDCASE.
        ENDLOOP.
        DO 4 TIMES.
          DATA(lv_j) = lcl_cube=>find_cubie( it_cubies = mt_cubies iv_colors = lv_key ).
          IF lcl_cube=>x_of( lv_j ) = lv_hx AND lcl_cube=>z_of( lv_j ) = lv_hz.
            EXIT.
          ENDIF.
          run( 'U' ).
        ENDDO.
        DATA(lv_trig) = slot_trigger( iv_x = lv_hx iv_z = lv_hz ).
        DO 6 TIMES.
          run_alg( lv_trig ).
          IF lcl_cube=>solved_at( it_cubies = mt_cubies
                                  iv_idx = lcl_cube=>find_cubie( it_cubies = mt_cubies iv_colors = lv_key ) ) = abap_true.
            EXIT.
          ENDIF.
        ENDDO.
        IF lcl_cube=>solved_at( it_cubies = mt_cubies
                                iv_idx = lcl_cube=>find_cubie( it_cubies = mt_cubies iv_colors = lv_key ) ) = abap_false.
          fail( |corners: 角 { lv_key } 插入失败| ).
    RETURN.
        ENDIF.
        EXIT.
      ENDDO.
    ENDLOOP.
    " 断言：第一层四角
    lt_slots = VALUE #( ( lcl_cube=>idx_of( iv_x = 1  iv_y = -1 iv_z = 1 ) )
                        ( lcl_cube=>idx_of( iv_x = 1  iv_y = -1 iv_z = -1 ) )
                        ( lcl_cube=>idx_of( iv_x = -1 iv_y = -1 iv_z = -1 ) )
                        ( lcl_cube=>idx_of( iv_x = -1 iv_y = -1 iv_z = 1 ) ) ).
    IF count_solved( it_cubies = mt_cubies it_slots = lt_slots ) <> 4.
      fail( 'corners: 第一层角未全部归位' ).
      RETURN.
    ENDIF.
  ENDMETHOD.

  " ============================================================= 阶段 3
  METHOD stage_second_layer.
    DATA: lt_targets TYPE tt_colors,
          lt_slots   TYPE tt_slots.
    lt_targets = VALUE #( ( 'GR' ) ( 'BR' ) ( 'BO' ) ( 'GO' ) ).
    LOOP AT lt_targets INTO DATA(lv_key).
      DO 10 TIMES.
        DATA(lv_idx) = lcl_cube=>find_cubie( it_cubies = mt_cubies iv_colors = lv_key ).
        IF lcl_cube=>solved_at( it_cubies = mt_cubies iv_idx = lv_idx ) = abap_true.
          EXIT.
        ENDIF.
        DATA(lv_y) = lcl_cube=>y_of( lv_idx ).
        IF lv_y = 0.
          " 卡在中层：以该槽位为右前的面做一次右插，把它顶出去
          run_alg( right_insert( eject_face( iv_x = lcl_cube=>x_of( lv_idx )
                                             iv_z = lcl_cube=>z_of( lv_idx ) ) ) ).
          CONTINUE.
        ENDIF.
        " 在 U 层：侧面贴纸对上中心后按上贴纸方向左/右插
        DATA(lv_done) = abap_false.
        DO 4 TIMES.
          DATA(lv_j) = lcl_cube=>find_cubie( it_cubies = mt_cubies iv_colors = lv_key ).
          DATA(lv_x) = lcl_cube=>x_of( lv_j ).
          DATA(lv_z) = lcl_cube=>z_of( lv_j ).
          READ TABLE mt_cubies INTO DATA(ls_cubie) WITH KEY idx = lv_j.
          DATA(lv_scolor) = COND #( WHEN lv_x <> 0 THEN ls_cubie-cx ELSE ls_cubie-cz ).
          DATA(lv_adj) = COND #( WHEN lv_x = 1 THEN 'R'
                                 WHEN lv_x = -1 THEN 'L'
                                 WHEN lv_z = 1 THEN 'F'
                                 ELSE 'B' ).
          IF face_of_side( lv_scolor ) = lv_adj.
            DATA(lv_top) = ls_cubie-cy.
            IF u_prev( lv_adj ) = face_of_side( lv_top ).
              run_alg( right_insert( lv_adj ) ).
            ELSEIF u_next( lv_adj ) = face_of_side( lv_top ).
              run_alg( left_insert( lv_adj ) ).
            ELSE.
              fail( 'second layer: 上贴纸颜色异常' ).
    RETURN.
            ENDIF.
            lv_done = abap_true.
            EXIT.
          ENDIF.
          run( 'U' ).
        ENDDO.
        IF lv_done = abap_false.
          fail( 'second layer: 无法对齐棱块' ).
    RETURN.
        ENDIF.
        EXIT.
      ENDDO.
    ENDLOOP.
    " 断言：中层四棱
    lt_slots = VALUE #( ( lcl_cube=>idx_of( iv_x = 1  iv_y = 0 iv_z = 1 ) )
                        ( lcl_cube=>idx_of( iv_x = 1  iv_y = 0 iv_z = -1 ) )
                        ( lcl_cube=>idx_of( iv_x = -1 iv_y = 0 iv_z = -1 ) )
                        ( lcl_cube=>idx_of( iv_x = -1 iv_y = 0 iv_z = 1 ) ) ).
    IF count_solved( it_cubies = mt_cubies it_slots = lt_slots ) <> 4.
      fail( 'second layer: 中层棱未全部归位' ).
      RETURN.
    ENDIF.
  ENDMETHOD.

  " ============================================================= 阶段 4
  METHOD stage_top_cross.
    " 2-look OLL 两个定向公式：线 → 十字用 FRUR'U'F'；L 形 → 十字用 FURU'R'F'
    DATA lt_algs TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    lt_algs = VALUE #( ( `F R U R' U' F'` ) ( `F U R U' R' F'` ) ).
    DO 6 TIMES.
      DATA(lv_cur) = count_y_edges( mt_cubies ).
      IF lv_cur = 4.
        EXIT.
      ENDIF.
      DATA(lv_applied) = abap_false.
      LOOP AT lt_algs INTO DATA(lv_alg).
        DO 4 TIMES.
          DATA(lv_pre) = sy-index - 1.
          DATA(lt_sim) = mt_cubies.
          DO lv_pre TIMES.
            lt_sim = lcl_cube=>apply_move( it_cubies = lt_sim iv_move = 'U' ).
          ENDDO.
          lt_sim = lcl_cube=>apply_alg( it_cubies = lt_sim iv_alg = lv_alg ).
          IF count_y_edges( lt_sim ) > lv_cur.
            DO lv_pre TIMES.
              run( 'U' ).
            ENDDO.
            run_alg( lv_alg ).
            lv_applied = abap_true.
            EXIT.
          ENDIF.
        ENDDO.
        IF lv_applied = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_applied = abap_false.
        fail( 'top cross: 无法增加黄边数量' ).
    RETURN.
      ENDIF.
    ENDDO.
    IF count_y_edges( mt_cubies ) <> 4.
      fail( 'top cross: 顶层十字未完成' ).
      RETURN.
    ENDIF.
  ENDMETHOD.

  " ============================================================= 阶段 5
  METHOD stage_top_corner_orient.
    " 经典逐角法：未定向角转到 UFR，重复 R'D'RD 直到黄贴朝上，U 换下一角。
    " 全部完成后（含 U 轮转）底两层自动复原。
    DATA(lv_ufr) = lcl_cube=>idx_of( iv_x = 1 iv_y = 1 iv_z = 1 ).
    DATA lt_uc TYPE tt_slots.
    lt_uc = VALUE #( ( lcl_cube=>idx_of( iv_x = 1  iv_y = 1 iv_z = 1 ) )
                     ( lcl_cube=>idx_of( iv_x = 1  iv_y = 1 iv_z = -1 ) )
                     ( lcl_cube=>idx_of( iv_x = -1 iv_y = 1 iv_z = -1 ) )
                     ( lcl_cube=>idx_of( iv_x = -1 iv_y = 1 iv_z = 1 ) ) ).

    DATA(lv_any) = abap_false.
    LOOP AT lt_uc INTO DATA(lv_idx).
      READ TABLE mt_cubies INTO DATA(ls_cubie) WITH KEY idx = lv_idx.
      IF ls_cubie-cy <> 'Y'.
        lv_any = abap_true.
      ENDIF.
    ENDLOOP.

    WHILE lv_any = abap_true.
      DO 4 TIMES.
        READ TABLE mt_cubies INTO ls_cubie WITH KEY idx = lv_ufr.
        IF ls_cubie-cy <> 'Y'.
          EXIT.
        ENDIF.
        run( 'U' ).
      ENDDO.
      READ TABLE mt_cubies INTO ls_cubie WITH KEY idx = lv_ufr.
      IF ls_cubie-cy = 'Y'.
        fail( 'corner orient: 无未定向角' ).
    RETURN.
      ENDIF.
      DATA(lv_ok) = abap_false.
      DO 8 TIMES.
        run_alg( `R' D' R D` ).
        READ TABLE mt_cubies INTO ls_cubie WITH KEY idx = lv_ufr.
        IF ls_cubie-cy = 'Y'.
          lv_ok = abap_true.
          EXIT.
        ENDIF.
      ENDDO.
      IF lv_ok = abap_false.
        fail( 'corner orient: 单角定向失败' ).
    RETURN.
      ENDIF.
      lv_any = abap_false.
      LOOP AT lt_uc INTO lv_idx.
        READ TABLE mt_cubies INTO ls_cubie WITH KEY idx = lv_idx.
        IF ls_cubie-cy <> 'Y'.
          lv_any = abap_true.
        ENDIF.
      ENDLOOP.
    ENDWHILE.

    " 断言：底两层未被破坏
    LOOP AT mt_cubies INTO ls_cubie.
      IF lcl_cube=>y_of( ls_cubie-idx ) <= 0 AND
         lcl_cube=>solved_at( it_cubies = mt_cubies iv_idx = ls_cubie-idx ) = abap_false.
        fail( 'corner orient: 底两层被破坏' ).
    RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  " ============================================================= 阶段 6
  METHOD stage_corner_perm.
    DATA lt_slots TYPE tt_slots.
    " 奇偶预判：奇排列（如两角互换的 T-perm 类状态）无法用偶排列算法还原，
    " 先转一次 U —— U 对角、棱各贡献一个 4-cycle，同时翻转两者奇偶。
    IF corner_perm_parity_odd( ) = abap_true.
      run( 'U' ).
    ENDIF.
    lt_slots = VALUE #( ( lcl_cube=>idx_of( iv_x = 1  iv_y = 1 iv_z = 1 ) )
                        ( lcl_cube=>idx_of( iv_x = 1  iv_y = 1 iv_z = -1 ) )
                        ( lcl_cube=>idx_of( iv_x = -1 iv_y = 1 iv_z = -1 ) )
                        ( lcl_cube=>idx_of( iv_x = -1 iv_y = 1 iv_z = 1 ) ) ).
    " R' F R' B2 R F' R' B2 R2 为纯角位置 3-cycle（保持朝向，UFL 不动）
    top_permute( it_slots = lt_slots iv_alg = `R' F R' B2 R F' R' B2 R2` ).
    IF count_solved( it_cubies = mt_cubies it_slots = lt_slots ) <> 4.
      fail( 'corner perm: 顶层角排列未完成' ).
      RETURN.
    ENDIF.
  ENDMETHOD.

  " ============================================================= 阶段 7
  METHOD stage_edge_perm.
    DATA lt_slots TYPE tt_slots.
    lt_slots = VALUE #( ( lcl_cube=>idx_of( iv_x = 0  iv_y = 1 iv_z = 1 ) )
                        ( lcl_cube=>idx_of( iv_x = 1  iv_y = 1 iv_z = 0 ) )
                        ( lcl_cube=>idx_of( iv_x = 0  iv_y = 1 iv_z = -1 ) )
                        ( lcl_cube=>idx_of( iv_x = -1 iv_y = 1 iv_z = 0 ) ) ).
    " R U' R U R U R U' R' U' R2 保持 UB 不动，轮换其余三棱
    top_permute( it_slots = lt_slots iv_alg = `R U' R U R U R U' R' U' R2` ).
    IF count_solved( it_cubies = mt_cubies it_slots = lt_slots ) <> 4.
      fail( 'edge perm: 顶层棱排列未完成' ).
      RETURN.
    ENDIF.
  ENDMETHOD.

  " ============================================================= 花瓣 BFS
  METHOD bfs_daisy.
    " 目标：iv_target（及 it_petals 中每朵）位于 U 层且白贴朝上；深度 ≤5；
    " 节点上限 30 万（参考实现实测最深 4 层、典型数千节点）。
    TYPES: BEGIN OF ty_node,
             state  TYPE ty_cstate,
             parent TYPE i,
             move   TYPE c LENGTH 2,
             depth  TYPE i,
           END OF ty_node.
    DATA: lt_queue   TYPE STANDARD TABLE OF ty_node WITH EMPTY KEY,
          lt_visited TYPE HASHED TABLE OF ty_cstate WITH UNIQUE KEY table_line,
          lv_head    TYPE i VALUE 1.

    DATA(lv_start) = lcl_cube=>to_state( mt_cubies ).
    IF bfs_goal( iv_state = lv_start iv_target = iv_target it_petals = it_petals ) = abap_true.
      RETURN.
    ENDIF.
    INSERT lv_start INTO TABLE lt_visited.
    APPEND VALUE #( state = lv_start parent = 0 move = space depth = 0 ) TO lt_queue.

    DATA lt_moves18 TYPE STANDARD TABLE OF ty_c2 WITH EMPTY KEY.
    lt_moves18 = VALUE #( ( 'U' ) ( `U'` ) ( 'U2' ) ( 'D' ) ( `D'` ) ( 'D2' )
                          ( 'R' ) ( `R'` ) ( 'R2' ) ( 'L' ) ( `L'` ) ( 'L2' )
                          ( 'F' ) ( `F'` ) ( 'F2' ) ( 'B' ) ( `B'` ) ( 'B2' ) ).

    WHILE lv_head <= lines( lt_queue ).
      READ TABLE lt_queue INTO DATA(ls_node) INDEX lv_head.
      IF ls_node-depth >= 5.
        EXIT.
      ENDIF.
      LOOP AT lt_moves18 INTO DATA(lv_mv).
        " 同面连续转动剪枝
        IF ls_node-move IS NOT INITIAL AND ls_node-move(1) = lv_mv(1).
          CONTINUE.
        ENDIF.
        DATA(lt_cubies) = lcl_cube=>from_state( ls_node-state ).
        lt_cubies = lcl_cube=>apply_move( it_cubies = lt_cubies iv_move = lv_mv ).
        DATA(lv_child) = lcl_cube=>to_state( lt_cubies ).
        READ TABLE lt_visited TRANSPORTING NO FIELDS WITH KEY table_line = lv_child.
        IF sy-subrc = 0.
          CONTINUE.
        ENDIF.
        INSERT lv_child INTO TABLE lt_visited.
        IF bfs_goal( iv_state = lv_child iv_target = iv_target it_petals = it_petals ) = abap_true.
          " 回溯重构路径（子 → 根）
          DATA lt_rev TYPE STANDARD TABLE OF ty_c2 WITH EMPTY KEY.
          APPEND lv_mv TO lt_rev.
          DATA(lv_p) = lv_head.
          WHILE lv_p > 1.
            READ TABLE lt_queue INTO DATA(ls_p) INDEX lv_p.
            APPEND ls_p-move TO lt_rev.
            lv_p = ls_p-parent.
          ENDWHILE.
          DATA(lv_n_rev) = lines( lt_rev ).
          DO lv_n_rev TIMES.
            READ TABLE lt_rev INTO DATA(lv_m) INDEX lv_n_rev - sy-index + 1.
            rv_moves = COND #( WHEN rv_moves IS INITIAL THEN |{ lv_m }|
                               ELSE |{ rv_moves } { lv_m }| ).
          ENDDO.
          RETURN.
        ENDIF.
        IF lines( lt_queue ) >= 300000.
          fail( '花瓣 BFS 节点超限（30 万），疑似异常状态' ).
    RETURN.
        ENDIF.
        APPEND VALUE #( state = lv_child parent = lv_head move = lv_mv depth = ls_node-depth + 1 ) TO lt_queue.
      ENDLOOP.
      lv_head = lv_head + 1.
    ENDWHILE.
    fail( '花瓣 BFS 在深度 5 内未找到解' ).
    RETURN.
  ENDMETHOD.

  METHOD bfs_goal.
    DATA lt_need TYPE tt_colors.
    APPEND |{ iv_target }| TO lt_need.
    LOOP AT it_petals INTO DATA(lv_col).
      APPEND lv_col TO lt_need.
    ENDLOOP.
    LOOP AT lt_need INTO lv_col.
      DATA(lv_idx) = lcl_cube=>state_find( iv_state = iv_state iv_colors = lv_col ).
      IF lv_idx < 0.
        rv_ok = abap_false.
        RETURN.
      ENDIF.
      IF lcl_cube=>y_of( lv_idx ) <> 1 OR substring( val = iv_state off = lv_idx * 3 + 1 len = 1 ) <> 'W'.
        rv_ok = abap_false.
        RETURN.
      ENDIF.
    ENDLOOP.
    rv_ok = abap_true.
  ENDMETHOD.

  " ============================================================= 工具
  METHOD corner_perm_parity_odd.
    DATA: lt_uc     TYPE tt_slots,
          lt_perm   TYPE STANDARD TABLE OF i WITH EMPTY KEY,
          lv_inv    TYPE i VALUE 0,
          lv_n_perm TYPE i,
          lv_i      TYPE i,
          lv_je     TYPE i,
          lv_pi     TYPE i,
          lv_pj     TYPE i.
    lt_uc = VALUE #( ( lcl_cube=>idx_of( iv_x = 1  iv_y = 1 iv_z = 1 ) )
                     ( lcl_cube=>idx_of( iv_x = 1  iv_y = 1 iv_z = -1 ) )
                     ( lcl_cube=>idx_of( iv_x = -1 iv_y = 1 iv_z = -1 ) )
                     ( lcl_cube=>idx_of( iv_x = -1 iv_y = 1 iv_z = 1 ) ) ).
    DATA lt_homes TYPE STANDARD TABLE OF ty_c3 WITH EMPTY KEY.
    lt_homes = VALUE #( ( 'BOY' ) ( 'BRY' ) ( 'GOY' ) ( 'GRY' ) ).
    SORT lt_homes.
    CLEAR lt_perm.
    LOOP AT lt_uc INTO DATA(lv_idx).
      READ TABLE mt_cubies INTO DATA(ls_cubie) WITH KEY idx = lv_idx.
      READ TABLE lt_homes TRANSPORTING NO FIELDS WITH KEY table_line = lcl_cube=>cubie_colors( ls_cubie ).
      APPEND sy-tabix TO lt_perm.
    ENDLOOP.
    CLEAR lv_inv.
    lv_n_perm = lines( lt_perm ).
    DO lv_n_perm TIMES.
      lv_i = sy-index.
      lv_je = lv_n_perm - lv_i.
      DO lv_je TIMES.
        READ TABLE lt_perm INTO lv_pi INDEX lv_i.
        READ TABLE lt_perm INTO lv_pj INDEX lv_i + sy-index.
        IF lv_pi > lv_pj.
          lv_inv = lv_inv + 1.
        ENDIF.
      ENDDO.
    ENDDO.
    rv_odd = COND #( WHEN lv_inv MOD 2 = 1 THEN abap_true ELSE abap_false ).
  ENDMETHOD.

  METHOD top_permute.
    " 顶层排列通用程序：归位数只可能为 0/1/4（偶排列）；
    " 0 → 直接应用算法（A4 群中 3-cycle ∘ 双换必得 3-cycle）；
    " 1 → 试 4 种 U 共轭（U^t·alg·U^-t），选归位数最大的提交。
    DO 12 TIMES.
      DATA(lv_cur) = count_solved( it_cubies = mt_cubies it_slots = it_slots ).
      IF lv_cur = 4.
        RETURN.
      ENDIF.
      IF lv_cur = 0.
        run_alg( iv_alg ).
        CONTINUE.
      ENDIF.
      DATA(lv_best_t) = 0.
      DATA(lv_best) = -1.
      DO 4 TIMES.
        DATA(lv_t) = sy-index - 1.
        DATA(lt_sim) = mt_cubies.
        DO lv_t TIMES.
          lt_sim = lcl_cube=>apply_move( it_cubies = lt_sim iv_move = 'U' ).
        ENDDO.
        lt_sim = lcl_cube=>apply_alg( it_cubies = lt_sim iv_alg = iv_alg ).
        DATA(lv_back) = ( 4 - lv_t ) MOD 4.
        DO lv_back TIMES.
          lt_sim = lcl_cube=>apply_move( it_cubies = lt_sim iv_move = 'U' ).
        ENDDO.
        DATA(lv_cnt) = count_solved( it_cubies = lt_sim it_slots = it_slots ).
        IF lv_cnt > lv_best.
          lv_best = lv_cnt.
          lv_best_t = lv_t.
        ENDIF.
      ENDDO.
      DO lv_best_t TIMES.
        run( 'U' ).
      ENDDO.
      run_alg( iv_alg ).
      lv_back = ( 4 - lv_best_t ) MOD 4.
      DO lv_back TIMES.
        run( 'U' ).
      ENDDO.
    ENDDO.
    IF count_solved( it_cubies = mt_cubies it_slots = it_slots ) <> 4.
      fail( 'permute: 排列未完成' ).
      RETURN.
    ENDIF.
  ENDMETHOD.

  METHOD count_solved.
    LOOP AT it_slots INTO DATA(lv_idx).
      IF lcl_cube=>solved_at( it_cubies = it_cubies iv_idx = lv_idx ) = abap_true.
        rv_cnt = rv_cnt + 1.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD count_y_edges.
    DATA lt_ue TYPE tt_slots.
    lt_ue = VALUE #( ( lcl_cube=>idx_of( iv_x = 0  iv_y = 1 iv_z = 1 ) )
                     ( lcl_cube=>idx_of( iv_x = 1  iv_y = 1 iv_z = 0 ) )
                     ( lcl_cube=>idx_of( iv_x = 0  iv_y = 1 iv_z = -1 ) )
                     ( lcl_cube=>idx_of( iv_x = -1 iv_y = 1 iv_z = 0 ) ) ).
    LOOP AT lt_ue INTO DATA(lv_idx).
      READ TABLE it_cubies INTO DATA(ls_cubie) WITH KEY idx = lv_idx.
      IF ls_cubie-cy = 'Y'.
        rv_cnt = rv_cnt + 1.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD slot_trigger.
    " 角块插入触发公式（按槽位 (x,z)），重复执行直到目标角归位；
    " 只影响该槽位与 U 层（discover 实测确认）。
    CASE |{ iv_x },{ iv_z }|.
      WHEN '1,1'.
        rv_alg = `R U R' U'`.
      WHEN '1,-1'.
        rv_alg = `B U B' U'`.
      WHEN '-1,-1'.
        rv_alg = `L U L' U'`.
      WHEN '-1,1'.
        rv_alg = `F U F' U'`.
      WHEN OTHERS.
        rv_alg = `R U R' U'`.
    ENDCASE.
  ENDMETHOD.

  METHOD right_insert.
    DATA(lv_r) = u_prev( iv_face ).
    rv_alg = |U { lv_r } U' { lv_r }' U' { iv_face }' U { iv_face }|.
  ENDMETHOD.

  METHOD left_insert.
    DATA(lv_l) = u_next( iv_face ).
    rv_alg = |U' { lv_l }' U { lv_l } U { iv_face } U' { iv_face }'|.
  ENDMETHOD.

  METHOD u_prev.
    " U' 方向的相邻面（f 面的右侧）：F→R→B→L→F
    rv_face = SWITCH #( iv_face WHEN 'F' THEN 'R'
                                   WHEN 'R' THEN 'B'
                                   WHEN 'B' THEN 'L'
                                   WHEN 'L' THEN 'F'
                                   ELSE iv_face ).
  ENDMETHOD.

  METHOD u_next.
    " U 方向的相邻面（f 面的左侧）：F→L→B→R→F
    rv_face = SWITCH #( iv_face WHEN 'F' THEN 'L'
                                     WHEN 'L' THEN 'B'
                                     WHEN 'B' THEN 'R'
                                     WHEN 'R' THEN 'F'
                                   ELSE iv_face ).
  ENDMETHOD.

  METHOD face_of_side.
    rv_face = SWITCH #( iv_side WHEN 'G' THEN 'F'
                                    WHEN 'R' THEN 'R'
                                    WHEN 'B' THEN 'B'
                                    WHEN 'O' THEN 'L'
                                    ELSE iv_side ).
  ENDMETHOD.

  METHOD eject_face.
    " 中层槽位 (x,z) 作为"右前"时对应的前面
    CASE |{ iv_x },{ iv_z }|.
      WHEN '1,1'.
        rv_face = 'F'.
      WHEN '1,-1'.
        rv_face = 'R'.
      WHEN '-1,-1'.
        rv_face = 'B'.
      WHEN OTHERS.
        rv_face = 'L'.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
