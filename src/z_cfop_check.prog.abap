*&---------------------------------------------------------------------*
*& 包含 Z_CFOP_CHECK：录入 / 合法性校验表单
*&---------------------------------------------------------------------*
*& 所有实质性检查在 lcl_cube=>from_faces / lcl_cube=>check 中实现，
*& 本包含只负责采集参数、输出错误信息。
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form FRM_BUILD_CUBE：从六面参数构建魔方状态
*&---------------------------------------------------------------------*
*& --> PT_CUBIES  三维槽位表（成功时填充）
*& <-- RV_OK      构建并全部校验通过
*&---------------------------------------------------------------------*
FORM frm_build_cube CHANGING pt_cubies TYPE tt_cubie
                             rv_ok     TYPE abap_bool.
  DATA lt_faces TYPE tt_facestr.
  lt_faces = VALUE #( ( color = 'Y' face = p_yellow )
                      ( color = 'O' face = p_orange )
                      ( color = 'B' face = p_blue )
                      ( color = 'R' face = p_red )
                      ( color = 'G' face = p_green )
                      ( color = 'W' face = p_white ) ).

  lcl_cube=>from_faces(
    EXPORTING it_faces  = lt_faces
    IMPORTING et_cubies = DATA(lt_cubies)
              et_msg    = DATA(lt_msg) ).

  LOOP AT lt_msg INTO DATA(ls_msg).
    WRITE: / '错误:' COLOR COL_NEGATIVE, ls_msg-text.
  ENDLOOP.
  IF lines( lt_msg ) > 0.
    rv_ok = abap_false.
    RETURN.
  ENDIF.

  " 可解性不变量（棱翻转 / 角扭转 / 排列奇偶）
  DATA(lt_check) = lcl_cube=>check( lt_cubies ).
  LOOP AT lt_check INTO ls_msg.
    WRITE: / '错误:' COLOR COL_NEGATIVE, ls_msg-text.
  ENDLOOP.
  IF lines( lt_check ) > 0.
    rv_ok = abap_false.
    RETURN.
  ENDIF.

  pt_cubies = lt_cubies.
  rv_ok = abap_true.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FRM_SHOW_CUBE：按录入顺序输出六面展开
*&---------------------------------------------------------------------*
FORM frm_show_cube USING pt_cubies TYPE tt_cubie.
  DATA(lt_faces) = lcl_cube=>to_faces( pt_cubies ).
  LOOP AT lt_faces INTO DATA(ls_face).
    CASE ls_face-color.
      WHEN 'Y'.
      WRITE: / '黄色面(U):'.
      WHEN 'O'.
      WRITE: / '橙色面(L):'.
      WHEN 'B'.
      WRITE: / '蓝色面(B):'.
      WHEN 'R'.
      WRITE: / '红色面(R):'.
      WHEN 'G'.
      WRITE: / '绿色面(F):'.
      WHEN 'W'.
      WRITE: / '白色面(D):'.
    ENDCASE.
    DO 3 TIMES.
      DATA(lv_r) = sy-index - 1.
      WRITE: /20 substring( val = ls_face-face off = lv_r * 3 len = 3 ).
    ENDDO.
  ENDLOOP.
ENDFORM.
