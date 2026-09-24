*&---------------------------------------------------------------------*
*& 包含 Z_CFOP_OPERATE：lcl_cube 实现（转动引擎）
*&---------------------------------------------------------------------*
CLASS lcl_cube IMPLEMENTATION.

  " ------------------------------------------------------------- 构造
  METHOD solved_state.
    DATA: lv_x TYPE i VALUE -1,
          lv_y TYPE i,
          lv_z TYPE i,
          ls   TYPE ty_cubie.
    DO 3 TIMES.
      lv_y = -1.
      DO 3 TIMES.
        lv_z = -1.
        DO 3 TIMES.
          IF lv_x <> 0 OR lv_y <> 0 OR lv_z <> 0.
            CLEAR ls.
            ls-idx = idx_of( iv_x = lv_x iv_y = lv_y iv_z = lv_z ).
            IF lv_x = 1.
              ls-cx = 'R'.
            ELSEIF lv_x = -1.
              ls-cx = 'O'.
            ENDIF.
            IF lv_y = 1.
              ls-cy = 'Y'.
            ELSEIF lv_y = -1.
              ls-cy = 'W'.
            ENDIF.
            IF lv_z = 1.
              ls-cz = 'G'.
            ELSEIF lv_z = -1.
              ls-cz = 'B'.
            ENDIF.
            INSERT ls INTO TABLE rt_cubies.
          ENDIF.
          lv_z = lv_z + 1.
        ENDDO.
        lv_y = lv_y + 1.
      ENDDO.
      lv_x = lv_x + 1.
    ENDDO.
  ENDMETHOD.

  METHOD from_faces.
    DATA: lt_center TYPE SORTED TABLE OF ty_c1 WITH UNIQUE KEY table_line,
          lt_count  TYPE STANDARD TABLE OF ty_c1 WITH EMPTY KEY,
          lt_tmp    TYPE SORTED TABLE OF ty_cubie WITH UNIQUE KEY idx,
          ls_cubie  TYPE ty_cubie,
          lv_face   TYPE c LENGTH 1,
          lv_char   TYPE c LENGTH 1,
          lv_idx    TYPE i,
          lv_n      TYPE i.

    CLEAR: et_cubies, et_msg.

    " —— 基础校验：长度 / 字符 / 中心色 ——
    LOOP AT it_faces INTO DATA(ls_face).
      IF strlen( ls_face-face ) <> 9.
        APPEND VALUE #( text = |面 { ls_face-color } 长度必须为 9| ) TO et_msg.
        CONTINUE.
      ENDIF.
      DO 9 TIMES.
        lv_char = substring( val = ls_face-face off = sy-index - 1 len = 1 ).
        IF lv_char NA 'YROGBW'.
          APPEND VALUE #( text = |面 { ls_face-color } 含非法字符 { lv_char }| ) TO et_msg.
          EXIT.
        ENDIF.
        APPEND lv_char TO lt_count.
      ENDDO.
      lv_char = substring( val = ls_face-face off = 4 len = 1 ).
      INSERT lv_char INTO TABLE lt_center.
      IF sy-subrc <> 0.
        APPEND VALUE #( text = |中心色 { lv_char } 重复| ) TO et_msg.
      ENDIF.
    ENDLOOP.

    " —— 颜色计数：每种颜色必须恰好 9 个 ——
    DO 6 TIMES.
      lv_char = substring( val = 'YROGBW' off = sy-index - 1 len = 1 ).
      lv_n = 0.
      LOOP AT lt_count TRANSPORTING NO FIELDS WHERE table_line = lv_char.
        lv_n = lv_n + 1.
      ENDLOOP.
      IF lv_n <> 9.
        APPEND VALUE #( text = |颜色 { lv_char } 数量为 { lv_n }，应为 9| ) TO et_msg.
      ENDIF.
    ENDDO.

    " 有录入错误即终止：后续放置阶段要求每面均为合法的 9 贴纸
    IF et_msg IS NOT INITIAL.
      RETURN.
    ENDIF.

    " —— 中心色定面：把 54 张贴纸放到三维槽位 ——
    LOOP AT it_faces INTO ls_face.
      lv_face = SWITCH #( substring( val = ls_face-face off = 4 len = 1 )
                          WHEN 'Y' THEN 'U'
                          WHEN 'W' THEN 'D'
                          WHEN 'G' THEN 'F'
                          WHEN 'B' THEN 'B'
                          WHEN 'R' THEN 'R'
                          WHEN 'O' THEN 'L'
                          ELSE space ).
      IF lv_face IS INITIAL.
        CONTINUE.
      ENDIF.
      DO 9 TIMES.
        DATA(lv_r)    = ( sy-index - 1 ) DIV 3.
        DATA(lv_c)    = ( sy-index - 1 ) MOD 3.
        lv_char       = substring( val = ls_face-face off = sy-index - 1 len = 1 ).
        DATA(lv_x)    = 0.
        DATA(lv_y)    = 0.
        DATA(lv_z)    = 0.
        DATA(lv_axis) = space.
        " 面网格 → 小块坐标 + 贴纸轴向（与参考实现 FACE_GRID 一致）
        CASE lv_face.
          WHEN 'U'.
            lv_x = lv_c - 1.
            lv_y = 1.
            lv_z = lv_r - 1.
            lv_axis = 'Y'.
          WHEN 'D'.
            lv_x = lv_c - 1.
            lv_y = -1.
            lv_z = 1 - lv_r.
            lv_axis = 'Y'.
          WHEN 'F'.
            lv_x = lv_c - 1.
            lv_y = 1 - lv_r.
            lv_z = 1.
            lv_axis = 'Z'.
          WHEN 'B'.
            lv_x = 1 - lv_c.
            lv_y = 1 - lv_r.
            lv_z = -1.
            lv_axis = 'Z'.
          WHEN 'R'.
            lv_x = 1.
            lv_y = 1 - lv_r.
            lv_z = 1 - lv_c.
            lv_axis = 'X'.
          WHEN 'L'.
            lv_x = -1.
            lv_y = 1 - lv_r.
            lv_z = lv_c - 1.
            lv_axis = 'X'.
        ENDCASE.
        lv_idx = idx_of( iv_x = lv_x iv_y = lv_y iv_z = lv_z ).
        READ TABLE lt_tmp INTO ls_cubie WITH KEY idx = lv_idx.
        IF sy-subrc <> 0.
          CLEAR ls_cubie.
          ls_cubie-idx = lv_idx.
        ENDIF.
        CASE lv_axis.
          WHEN 'X'.
          ls_cubie-cx = lv_char.
          WHEN 'Y'.
          ls_cubie-cy = lv_char.
          WHEN 'Z'.
          ls_cubie-cz = lv_char.
        ENDCASE.
        MODIFY TABLE lt_tmp FROM ls_cubie.
        IF sy-subrc <> 0.
          INSERT ls_cubie INTO TABLE lt_tmp.
        ENDIF.
      ENDDO.
    ENDLOOP.

    et_cubies = lt_tmp.
  ENDMETHOD.

  " ------------------------------------------------------------- 转动引擎
  METHOD move_spec.
    DATA lv_move TYPE string.
    lv_move = iv_move.
    CLEAR rs_spec.
    CASE lv_move.
      WHEN 'U'.
      rs_spec = VALUE #( axis = 2 layer =  1 cw = 1 ).
      WHEN 'U2'.
      rs_spec = VALUE #( axis = 2 layer =  1 cw = 2 ).
      WHEN `U'`.
      rs_spec = VALUE #( axis = 2 layer =  1 cw = 3 ).
      WHEN 'D'.
      rs_spec = VALUE #( axis = 2 layer = -1 cw = 3 ).
      WHEN 'D2'.
      rs_spec = VALUE #( axis = 2 layer = -1 cw = 2 ).
      WHEN `D'`.
      rs_spec = VALUE #( axis = 2 layer = -1 cw = 1 ).
      WHEN 'R'.
      rs_spec = VALUE #( axis = 1 layer =  1 cw = 1 ).
      WHEN 'R2'.
      rs_spec = VALUE #( axis = 1 layer =  1 cw = 2 ).
      WHEN `R'`.
      rs_spec = VALUE #( axis = 1 layer =  1 cw = 3 ).
      WHEN 'L'.
      rs_spec = VALUE #( axis = 1 layer = -1 cw = 3 ).
      WHEN 'L2'.
      rs_spec = VALUE #( axis = 1 layer = -1 cw = 2 ).
      WHEN `L'`.
      rs_spec = VALUE #( axis = 1 layer = -1 cw = 1 ).
      WHEN 'F'.
      rs_spec = VALUE #( axis = 3 layer =  1 cw = 1 ).
      WHEN 'F2'.
      rs_spec = VALUE #( axis = 3 layer =  1 cw = 2 ).
      WHEN `F'`.
      rs_spec = VALUE #( axis = 3 layer =  1 cw = 3 ).
      WHEN 'B'.
      rs_spec = VALUE #( axis = 3 layer = -1 cw = 3 ).
      WHEN 'B2'.
      rs_spec = VALUE #( axis = 3 layer = -1 cw = 2 ).
      WHEN `B'`.
      rs_spec = VALUE #( axis = 3 layer = -1 cw = 1 ).
      WHEN OTHERS.
        sv_error = |无法识别的转法: { iv_move }|.
    ENDCASE.
  ENDMETHOD.

  METHOD apply_move.
    DATA(ls_spec) = move_spec( iv_move ).
    IF ls_spec-axis NOT BETWEEN 1 AND 3.
      rt_cubies = it_cubies.
      RETURN.
    ENDIF.
    DATA: lt_keep  TYPE tt_cubie,
          lt_moved TYPE STANDARD TABLE OF ty_cubie WITH EMPTY KEY.
    LOOP AT it_cubies INTO DATA(ls_cubie).
      DATA(lv_coord) = SWITCH #( ls_spec-axis
                                 WHEN 1 THEN x_of( ls_cubie-idx )
                                 WHEN 2 THEN y_of( ls_cubie-idx )
                                 ELSE z_of( ls_cubie-idx ) ).
      IF lv_coord = ls_spec-layer.
        DATA(lv_x) = x_of( ls_cubie-idx ).
        DATA(lv_y) = y_of( ls_cubie-idx ).
        DATA(lv_z) = z_of( ls_cubie-idx ).
        DATA: lv_t TYPE c LENGTH 1,
              lv_n TYPE i.
        DO ls_spec-cw TIMES.
          CASE ls_spec-axis.
            WHEN 1.  " x: y'=z z'=-y，交换 cy,cz
              lv_n = lv_y.
              lv_y = lv_z.
              lv_z = - lv_n.
              lv_t = ls_cubie-cy.
              ls_cubie-cy = ls_cubie-cz.
              ls_cubie-cz = lv_t.
            WHEN 2.  " y: z'=x x'=-z，交换 cz,cx
              lv_n = lv_z.
              lv_z = lv_x.
              lv_x = - lv_n.
              lv_t = ls_cubie-cz.
              ls_cubie-cz = ls_cubie-cx.
              ls_cubie-cx = lv_t.
            WHEN 3.  " z: x'=y y'=-x，交换 cx,cy
              lv_n = lv_x.
              lv_x = lv_y.
              lv_y = - lv_n.
              lv_t = ls_cubie-cx.
              ls_cubie-cx = ls_cubie-cy.
              ls_cubie-cy = lv_t.
          ENDCASE.
        ENDDO.
        ls_cubie-idx = idx_of( iv_x = lv_x iv_y = lv_y iv_z = lv_z ).
        APPEND ls_cubie TO lt_moved.
      ELSE.
        INSERT ls_cubie INTO TABLE lt_keep.
      ENDIF.
    ENDLOOP.
    INSERT LINES OF lt_moved INTO TABLE lt_keep.
    rt_cubies = lt_keep.
  ENDMETHOD.

  METHOD apply_alg.
    CLEAR sv_error.
    rt_cubies = it_cubies.
    SPLIT iv_alg AT space INTO TABLE DATA(lt_move).
    LOOP AT lt_move INTO DATA(lv_move).
      IF lv_move IS INITIAL.
        CONTINUE.
      ENDIF.
      rt_cubies = apply_move( it_cubies = rt_cubies iv_move = lv_move ).
    ENDLOOP.
  ENDMETHOD.

  " ------------------------------------------------------------- 状态编码
  METHOD to_state.
    rv_state = repeat( val = '.' occ = 81 ).
    LOOP AT it_cubies INTO DATA(ls_cubie).
      DATA(lv_off) = ls_cubie-idx * 3.
      DATA(lv_off1) = lv_off + 1.
      DATA(lv_off2) = lv_off + 2.
      rv_state+lv_off(1)  = COND #( WHEN ls_cubie-cx IS INITIAL THEN '.' ELSE ls_cubie-cx ).
      rv_state+lv_off1(1) = COND #( WHEN ls_cubie-cy IS INITIAL THEN '.' ELSE ls_cubie-cy ).
      rv_state+lv_off2(1) = COND #( WHEN ls_cubie-cz IS INITIAL THEN '.' ELSE ls_cubie-cz ).
    ENDLOOP.
  ENDMETHOD.

  METHOD from_state.
    CLEAR rt_cubies.
    DO 27 TIMES.
      DATA(lv_idx) = sy-index - 1.
      DATA(lv_off) = lv_idx * 3.
      DATA(lv_cx) = substring( val = iv_state off = lv_off len = 1 ).
      DATA(lv_cy) = substring( val = iv_state off = lv_off + 1 len = 1 ).
      DATA(lv_cz) = substring( val = iv_state off = lv_off + 2 len = 1 ).
      IF lv_cx = '.' AND lv_cy = '.' AND lv_cz = '.'.
        CONTINUE.
      ENDIF.
      INSERT VALUE #( idx = lv_idx
                      cx = COND #( WHEN lv_cx = '.' THEN space ELSE lv_cx )
                      cy = COND #( WHEN lv_cy = '.' THEN space ELSE lv_cy )
                      cz = COND #( WHEN lv_cz = '.' THEN space ELSE lv_cz ) )
             INTO TABLE rt_cubies.
    ENDDO.
  ENDMETHOD.

  " ------------------------------------------------------------- 展示
  METHOD to_faces.
    DATA: lv_face TYPE c LENGTH 1,
          ls_row  TYPE ty_facestr,
          lv_line TYPE string.
    DATA lt_order TYPE STANDARD TABLE OF ty_c1 WITH EMPTY KEY.
    lt_order = VALUE #( ( 'Y' ) ( 'O' ) ( 'B' ) ( 'R' ) ( 'G' ) ( 'W' ) ).
    LOOP AT lt_order INTO DATA(lv_color).
      lv_face = SWITCH #( lv_color WHEN 'Y' THEN 'U'
                                    WHEN 'W' THEN 'D'
                                    WHEN 'G' THEN 'F'
                                    WHEN 'B' THEN 'B'
                                    WHEN 'R' THEN 'R'
                                    WHEN 'O' THEN 'L' ).
      CLEAR: ls_row, lv_line.
      ls_row-color = lv_color.
      DO 9 TIMES.
        DATA(lv_r)    = ( sy-index - 1 ) DIV 3.
        DATA(lv_c)    = ( sy-index - 1 ) MOD 3.
        DATA(lv_x)    = 0.
        DATA(lv_y)    = 0.
        DATA(lv_z)    = 0.
        DATA(lv_axis) = space.
        CASE lv_face.
          WHEN 'U'.
            lv_x = lv_c - 1.
            lv_y = 1.
            lv_z = lv_r - 1.
            lv_axis = 'Y'.
          WHEN 'D'.
            lv_x = lv_c - 1.
            lv_y = -1.
            lv_z = 1 - lv_r.
            lv_axis = 'Y'.
          WHEN 'F'.
            lv_x = lv_c - 1.
            lv_y = 1 - lv_r.
            lv_z = 1.
            lv_axis = 'Z'.
          WHEN 'B'.
            lv_x = 1 - lv_c.
            lv_y = 1 - lv_r.
            lv_z = -1.
            lv_axis = 'Z'.
          WHEN 'R'.
            lv_x = 1.
            lv_y = 1 - lv_r.
            lv_z = 1 - lv_c.
            lv_axis = 'X'.
          WHEN 'L'.
            lv_x = -1.
            lv_y = 1 - lv_r.
            lv_z = lv_c - 1.
            lv_axis = 'X'.
        ENDCASE.
        READ TABLE it_cubies INTO DATA(ls_cubie)
             WITH KEY idx = idx_of( iv_x = lv_x iv_y = lv_y iv_z = lv_z ).
        IF sy-subrc = 0.
          DATA(lv_char) = SWITCH #( lv_axis
                                    WHEN 'X' THEN ls_cubie-cx
                                    WHEN 'Y' THEN ls_cubie-cy
                                    ELSE ls_cubie-cz ).
          lv_line = |{ lv_line }{ lv_char }|.
        ELSE.
          lv_line = |{ lv_line }?|.
        ENDIF.
      ENDDO.
      ls_row-face = lv_line.
      APPEND ls_row TO rt_faces.
    ENDLOOP.
  ENDMETHOD.

  " ------------------------------------------------------------- 查询
  METHOD is_solved.
    rv_ok = abap_true.
    LOOP AT it_cubies INTO DATA(ls_cubie).
      IF solved_at( it_cubies = it_cubies iv_idx = ls_cubie-idx ) = abap_false.
        rv_ok = abap_false.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD solved_at.
    READ TABLE it_cubies INTO DATA(ls_cubie) WITH KEY idx = iv_idx.
    IF sy-subrc <> 0.
      rv_ok = abap_false.
      RETURN.
    ENDIF.
    DATA(lv_x) = x_of( iv_idx ).
    DATA(lv_y) = y_of( iv_idx ).
    DATA(lv_z) = z_of( iv_idx ).
    rv_ok = abap_true.
    IF lv_x = 1 AND ls_cubie-cx <> 'R'.
      rv_ok = abap_false.
      RETURN.
    ENDIF.
    IF lv_x = -1 AND ls_cubie-cx <> 'O'.
      rv_ok = abap_false.
      RETURN.
    ENDIF.
    IF lv_x = 0 AND ls_cubie-cx IS NOT INITIAL.
      rv_ok = abap_false.
      RETURN.
    ENDIF.
    IF lv_y = 1 AND ls_cubie-cy <> 'Y'.
      rv_ok = abap_false.
      RETURN.
    ENDIF.
    IF lv_y = -1 AND ls_cubie-cy <> 'W'.
      rv_ok = abap_false.
      RETURN.
    ENDIF.
    IF lv_y = 0 AND ls_cubie-cy IS NOT INITIAL.
      rv_ok = abap_false.
      RETURN.
    ENDIF.
    IF lv_z = 1 AND ls_cubie-cz <> 'G'.
      rv_ok = abap_false.
      RETURN.
    ENDIF.
    IF lv_z = -1 AND ls_cubie-cz <> 'B'.
      rv_ok = abap_false.
      RETURN.
    ENDIF.
    IF lv_z = 0 AND ls_cubie-cz IS NOT INITIAL.
      rv_ok = abap_false.
      RETURN.
    ENDIF.
  ENDMETHOD.

  METHOD find_cubie.
    DATA(lv_want) = sort_colors( iv_colors ).
    LOOP AT it_cubies INTO DATA(ls_cubie).
      IF cubie_colors( ls_cubie ) = lv_want.
        rv_idx = ls_cubie-idx.
        RETURN.
      ENDIF.
    ENDLOOP.
    rv_idx = -1.
  ENDMETHOD.

  METHOD check.
    " —— 1) 部件存在性：8 角 + 12 棱颜色组合与标准魔方一致 ——
    DATA lt_corner TYPE STANDARD TABLE OF ty_c3.
    DATA lt_edge   TYPE STANDARD TABLE OF ty_c3.
    LOOP AT it_cubies INTO DATA(ls_cubie).
      DATA(lv_n) = abs( x_of( ls_cubie-idx ) ) + abs( y_of( ls_cubie-idx ) ) + abs( z_of( ls_cubie-idx ) ).
      IF lv_n = 3.
        APPEND cubie_colors( ls_cubie ) TO lt_corner.
      ELSEIF lv_n = 2.
        APPEND cubie_colors( ls_cubie ) TO lt_edge.
      ENDIF.
    ENDLOOP.
    SORT lt_corner.
    SORT lt_edge.
    DATA lt_corner_exp TYPE STANDARD TABLE OF ty_c3 WITH EMPTY KEY.
    DATA lt_edge_exp   TYPE STANDARD TABLE OF ty_c3 WITH EMPTY KEY.
    lt_corner_exp = VALUE #( ( 'BOW' ) ( 'BOY' ) ( 'BRW' ) ( 'BRY' )
                             ( 'GOW' ) ( 'GOY' ) ( 'GRW' ) ( 'GRY' ) ).
    lt_edge_exp   = VALUE #( ( 'BO' ) ( 'BR' ) ( 'BW' ) ( 'BY' )
                             ( 'GO' ) ( 'GR' ) ( 'GW' ) ( 'GY' )
                             ( 'OW' ) ( 'OY' ) ( 'RW' ) ( 'RY' ) ).
    IF lt_corner <> lt_corner_exp.
      APPEND VALUE #( text = '角块颜色组合不符合标准魔方（中心块相对位置或录入有误）' ) TO rt_msg.
    ENDIF.
    IF lt_edge <> lt_edge_exp.
      APPEND VALUE #( text = '棱块颜色组合不符合标准魔方（中心块相对位置或录入有误）' ) TO rt_msg.
    ENDIF.

    " —— 槽位清单（与参考实现一致，排列奇偶校验要求固定顺序）——
    DATA lt_corners TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    lt_corners = VALUE #( ( idx_of( iv_x = 1  iv_y = 1  iv_z = 1 ) )
                          ( idx_of( iv_x = 1  iv_y = 1  iv_z = -1 ) )
                          ( idx_of( iv_x = -1 iv_y = 1  iv_z = -1 ) )
                          ( idx_of( iv_x = -1 iv_y = 1  iv_z = 1 ) )
                          ( idx_of( iv_x = 1  iv_y = -1 iv_z = 1 ) )
                          ( idx_of( iv_x = 1  iv_y = -1 iv_z = -1 ) )
                          ( idx_of( iv_x = -1 iv_y = -1 iv_z = -1 ) )
                          ( idx_of( iv_x = -1 iv_y = -1 iv_z = 1 ) ) ).
    DATA lt_edges TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    lt_edges = VALUE #( ( idx_of( iv_x = 0  iv_y = 1  iv_z = 1 ) )
                        ( idx_of( iv_x = 1  iv_y = 1  iv_z = 0 ) )
                        ( idx_of( iv_x = 0  iv_y = 1  iv_z = -1 ) )
                        ( idx_of( iv_x = -1 iv_y = 1  iv_z = 0 ) )
                        ( idx_of( iv_x = 1  iv_y = 0  iv_z = 1 ) )
                        ( idx_of( iv_x = 1  iv_y = 0  iv_z = -1 ) )
                        ( idx_of( iv_x = -1 iv_y = 0  iv_z = -1 ) )
                        ( idx_of( iv_x = -1 iv_y = 0  iv_z = 1 ) )
                        ( idx_of( iv_x = 0  iv_y = -1 iv_z = 1 ) )
                        ( idx_of( iv_x = 1  iv_y = -1 iv_z = 0 ) )
                        ( idx_of( iv_x = 0  iv_y = -1 iv_z = -1 ) )
                        ( idx_of( iv_x = -1 iv_y = -1 iv_z = 0 ) ) ).

    " —— 2) 棱翻转总和 ≡ 0 (mod 2) ——
    " 槽位主轴：U/D 层槽位为 y，中层槽位为 z；棱参考色优先 Y/W，否则 G/B。
    DATA lv_flip TYPE i VALUE 0.
    LOOP AT lt_edges INTO DATA(lv_eidx).
      READ TABLE it_cubies INTO DATA(ls_edge) WITH KEY idx = lv_eidx.
      DATA(lv_ref) = COND #( WHEN ls_edge-cx = 'Y' OR ls_edge-cx = 'W' THEN ls_edge-cx
                             WHEN ls_edge-cy = 'Y' OR ls_edge-cy = 'W' THEN ls_edge-cy
                             WHEN ls_edge-cz = 'Y' OR ls_edge-cz = 'W' THEN ls_edge-cz
                             WHEN ls_edge-cx = 'G' OR ls_edge-cx = 'B' THEN ls_edge-cx
                             WHEN ls_edge-cy = 'G' OR ls_edge-cy = 'B' THEN ls_edge-cy
                             ELSE ls_edge-cz ).
      DATA(lv_primary) = COND #( WHEN y_of( lv_eidx ) <> 0 THEN ls_edge-cy
                                 ELSE ls_edge-cz ).
      IF lv_ref <> lv_primary.
        lv_flip = lv_flip + 1.
      ENDIF.
    ENDLOOP.
    IF lv_flip MOD 2 <> 0.
      APPEND VALUE #( text = '棱块朝向奇偶性不满足（存在奇数个翻转棱）' ) TO rt_msg.
    ENDIF.

    " —— 3) 角扭转总和 ≡ 0 (mod 3) ——
    " Y/W 参考色在 y 轴 → 0；x 轴 → x*y*z>0 ? 1 : 2；z 轴 → x*y*z>0 ? 2 : 1
    DATA lv_twist TYPE i VALUE 0.
    LOOP AT lt_corners INTO DATA(lv_cidx).
      READ TABLE it_cubies INTO DATA(ls_corn) WITH KEY idx = lv_cidx.
      DATA(lv_cref) = COND #( WHEN ls_corn-cx = 'Y' OR ls_corn-cx = 'W' THEN ls_corn-cx
                              WHEN ls_corn-cy = 'Y' OR ls_corn-cy = 'W' THEN ls_corn-cy
                              ELSE ls_corn-cz ).
      IF lv_cref = ls_corn-cy.
        CONTINUE.
      ENDIF.
      DATA(lv_chir) = COND abap_bool( WHEN x_of( lv_cidx ) * y_of( lv_cidx ) * z_of( lv_cidx ) > 0
                                      THEN abap_true ELSE abap_false ).
      DATA(lv_t) = COND i( WHEN lv_cref = ls_corn-cx
                           THEN COND i( WHEN lv_chir = abap_true THEN 1 ELSE 2 )
                           ELSE COND i( WHEN lv_chir = abap_true THEN 2 ELSE 1 ) ).
      lv_twist = lv_twist + lv_t.
    ENDLOOP.
    IF lv_twist MOD 3 <> 0.
      APPEND VALUE #( text = '角块扭转总和不被 3 整除' ) TO rt_msg.
    ENDIF.

    " —— 4) 排列奇偶一致：角排列与棱排列奇偶必须相同 ——
    DATA lt_chome TYPE STANDARD TABLE OF ty_c3.
    DATA lt_ehome TYPE STANDARD TABLE OF ty_c3.
    lt_chome = lt_corner_exp.
    lt_ehome = lt_edge_exp.
    SORT lt_chome.
    SORT lt_ehome.
    DATA: lt_cperm TYPE STANDARD TABLE OF i WITH EMPTY KEY,
          lt_eperm TYPE STANDARD TABLE OF i WITH EMPTY KEY,
          lv_inv_c TYPE i VALUE 0,
          lv_inv_e TYPE i VALUE 0.
    LOOP AT lt_corners INTO lv_cidx.
      READ TABLE it_cubies INTO ls_corn WITH KEY idx = lv_cidx.
      READ TABLE lt_chome TRANSPORTING NO FIELDS WITH KEY table_line = cubie_colors( ls_corn ).
      APPEND sy-tabix TO lt_cperm.
    ENDLOOP.
    LOOP AT lt_edges INTO lv_eidx.
      READ TABLE it_cubies INTO ls_edge WITH KEY idx = lv_eidx.
      READ TABLE lt_ehome TRANSPORTING NO FIELDS WITH KEY table_line = cubie_colors( ls_edge ).
      APPEND sy-tabix TO lt_eperm.
    ENDLOOP.
    DATA(lv_nc) = lines( lt_cperm ).
    DO lv_nc TIMES.
      DATA(lv_i) = sy-index.
      DATA(lv_je) = lv_nc - lv_i.
      DO lv_je TIMES.
        READ TABLE lt_cperm INTO DATA(lv_pi) INDEX lv_i.
        READ TABLE lt_cperm INTO DATA(lv_pj) INDEX lv_i + sy-index.
        IF lv_pi > lv_pj.
          lv_inv_c = lv_inv_c + 1.
        ENDIF.
      ENDDO.
    ENDDO.
    DATA(lv_ne) = lines( lt_eperm ).
    DO lv_ne TIMES.
      lv_i = sy-index.
      lv_je = lv_ne - lv_i.
      DO lv_je TIMES.
        READ TABLE lt_eperm INTO lv_pi INDEX lv_i.
        READ TABLE lt_eperm INTO lv_pj INDEX lv_i + sy-index.
        IF lv_pi > lv_pj.
          lv_inv_e = lv_inv_e + 1.
        ENDIF.
      ENDDO.
    ENDDO.
    IF ( lv_inv_c MOD 2 ) <> ( lv_inv_e MOD 2 ).
      APPEND VALUE #( text = '角块与棱块排列奇偶性不一致' ) TO rt_msg.
    ENDIF.
  ENDMETHOD.

  " ------------------------------------------------------------- 坐标工具
  METHOD idx_of.
    rv_idx = ( iv_x + 1 ) * 9 + ( iv_y + 1 ) * 3 + ( iv_z + 1 ).
  ENDMETHOD.

  METHOD x_of.
    rv_x = iv_idx DIV 9 - 1.
  ENDMETHOD.

  METHOD y_of.
    rv_y = ( iv_idx MOD 9 ) DIV 3 - 1.
  ENDMETHOD.

  METHOD z_of.
    rv_z = iv_idx MOD 3 - 1.
  ENDMETHOD.

  METHOD cubie_colors.
    DATA lt TYPE STANDARD TABLE OF ty_c1.
    IF is_cubie-cx IS NOT INITIAL.
      APPEND is_cubie-cx TO lt.
    ENDIF.
    IF is_cubie-cy IS NOT INITIAL.
      APPEND is_cubie-cy TO lt.
    ENDIF.
    IF is_cubie-cz IS NOT INITIAL.
      APPEND is_cubie-cz TO lt.
    ENDIF.
    SORT lt.
    CONCATENATE LINES OF lt INTO rv_col.
  ENDMETHOD.

  METHOD sort_colors.
    DATA: lt    TYPE STANDARD TABLE OF ty_c1,
          lv_in TYPE c LENGTH 3,
          lv_o  TYPE i.
    lv_in = iv_colors.
    DO 3 TIMES.
      lv_o = sy-index - 1.
      DATA(lv_char) = lv_in+lv_o(1).
      IF lv_char NA ' .'.
        APPEND lv_char TO lt.
      ENDIF.
    ENDDO.
    SORT lt.
    CONCATENATE LINES OF lt INTO rv_col.
  ENDMETHOD.

  METHOD state_find.
    DATA(lv_target) = sort_colors( iv_colors ).
    rv_idx = -1.
    DO 27 TIMES.
      DATA(lv_idx) = sy-index - 1.
      DATA(lv_off) = lv_idx * 3.
      DATA(lv_seg) = substring( val = iv_state off = lv_off len = 3 ).
      IF lv_seg = '...'.
        CONTINUE.  " 仅核心槽位三轴全无暴露面；棱/中心段可含 '.'（未暴露面）
      ENDIF.
      IF sort_colors( lv_seg ) = lv_target.
        rv_idx = lv_idx.
        RETURN.
      ENDIF.
    ENDDO.
  ENDMETHOD.

  " ------------------------------------------------------------- 随机打乱
  METHOD random_scramble.
    DATA: lo_random TYPE REF TO cl_random_number,
          lv_m      TYPE i,
          lv_face   TYPE c LENGTH 1,
          lv_last   TYPE c LENGTH 1,
          lv_suffix TYPE i.
    DATA lt_faces TYPE STANDARD TABLE OF ty_c1 WITH EMPTY KEY.
    lt_faces = VALUE #( ( 'U' ) ( 'D' ) ( 'R' ) ( 'L' ) ( 'F' ) ( 'B' ) ).
    CREATE OBJECT lo_random.
    lo_random->if_random_number~init( ).
    DO iv_len TIMES.
      DO.
        lo_random->if_random_number~get_random_int(
          EXPORTING i_limit = 18
          RECEIVING r_random = lv_m ).
        READ TABLE lt_faces INTO lv_face INDEX ( ( abs( lv_m ) MOD 6 ) + 1 ).
        IF lv_face <> lv_last.
          EXIT.
        ENDIF.
      ENDDO.
      lv_last = lv_face.
      lo_random->if_random_number~get_random_int(
        EXPORTING i_limit = 3
        RECEIVING r_random = lv_suffix ).
      DATA(lv_mod) = abs( lv_suffix ) MOD 3.
      rv_alg = COND #( WHEN rv_alg IS INITIAL THEN |{ lv_face }|
                       ELSE |{ rv_alg } { lv_face }| ).
      IF lv_mod = 1.
        rv_alg = |{ rv_alg }'|.
      ELSEIF lv_mod = 2.
        rv_alg = |{ rv_alg }2|.
      ENDIF.
    ENDDO.
  ENDMETHOD.

ENDCLASS.
