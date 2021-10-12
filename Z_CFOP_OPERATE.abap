*&---------------------------------------------------------------------*
*& 包含               Z_CFOP_OPERATE
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form FRM_SCRAMBLE
*&---------------------------------------------------------------------*
*& 打乱
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_scramble .
  DATA: string_cube TYPE c LENGTH 54.
  DATA: lt_six_cube TYPE TABLE OF ty_cube.
  DATA: ls_converted_perm TYPE ty_perm.
  DATA: lt_cube_dict TYPE tt_cube_dict.
  DATA: scramble TYPE c LENGTH 20.

  PERFORM fmr_get_scramble USING scramble.

*  scramble = '@Q!^BL%FRDQK^A#$FUK$'.

  CONCATENATE  'YYYYYYYYY'
               'OOOOOOOOO'
               'BBBBBBBBB'
               'RRRRRRRRR'
               'GGGGGGGGG'
               'WWWWWWWWW'
          INTO string_cube .

  PERFORM frm_string_to_six_cube CHANGING string_cube lt_six_cube.

  PERFORM frm_six_cube_to_perm CHANGING lt_six_cube ls_converted_perm.

  PERFORM frm_six_perm_to_dict CHANGING ls_converted_perm lt_cube_dict.

  PERFORM frm_apply_alg USING scramble CHANGING lt_cube_dict.




ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_STRING_TO_TT_CUBE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_CUBE
*&      --> LT_CUBE
*&---------------------------------------------------------------------*
FORM frm_string_to_six_cube  CHANGING string_cube
                                      pt_six_cube LIKE six_face.
  DATA: ls_six_layer TYPE ty_cube.
  DATA: off TYPE i VALUE 0,
        len TYPE i VALUE 9.
  DATA: lv_string_cube TYPE string.

  lv_string_cube = string_cube.

  DO 6 TIMES.
    DATA(lv_face) = lv_string_cube+off(len).
    ls_six_layer-face = lv_face+4(1).
    ls_six_layer-color = lv_face.
    APPEND ls_six_layer TO pt_six_cube.
    off = off + 9.
  ENDDO.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_SIX_CUBE_TO_PERM
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LT_SIX_CUBE
*&      <-- CONVERTED_PERM
*&---------------------------------------------------------------------*
FORM frm_six_cube_to_perm  CHANGING six_cube LIKE six_face
                                    ps_converted_perm TYPE ty_perm.

*  CONSTANTS SORTING TYPE C LENGTH 6 VALUE 'YOBRGW'.
  CONSTANTS sorting TYPE c LENGTH 6 VALUE 'WOGRBY'.
  DATA: lv_index TYPE i VALUE 0.
  DATA: ls_line TYPE ty_line,
        lt_line TYPE TABLE OF ty_line.

  DATA: ls_face TYPE ty_face,
        lt_face TYPE TABLE OF ty_face.
  DATA i  TYPE i.

  DO 6 TIMES.
    i = sy-index.
    lv_index = sy-index - 1.
    DATA(lv_color) = sorting+lv_index(1).
    READ TABLE six_cube ASSIGNING FIELD-SYMBOL(<fs_six>) WITH KEY face = lv_color.
    IF sy-subrc = '0'.
      DO  3 TIMES.
        CASE sy-index.
          WHEN 1.
            ls_line = <fs_six>-color+0(3).
            ls_face-0 = ls_line.
          WHEN 2.
            ls_line = <fs_six>-color+3(3).
            ls_face-1 = ls_line.
          WHEN 3.
            ls_line = <fs_six>-color+6(3).
            ls_face-2 = ls_line.
        ENDCASE.
      ENDDO.
      ASSIGN COMPONENT i OF STRUCTURE ps_converted_perm TO FIELD-SYMBOL(<fs_face>).
      IF sy-subrc = '0'.
        <fs_face> = ls_face.
      ENDIF.
    ENDIF.
  ENDDO.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_SIX_PERM_TO_DICT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LS_CONVERTED_PERM
*&      <-- LT_CUBE_DICT
*&---------------------------------------------------------------------*
FORM frm_six_perm_to_dict  CHANGING ps_converted_perm TYPE ty_perm
                                    pt_cube_dict TYPE tt_cube_dict.

  DATA: x TYPE i,
        y TYPE i,
        z TYPE i.
  DATA: i TYPE c,
        j TYPE c,
        k TYPE c.
  DATA: ls_cube_dict TYPE ty_cube_dict.

  FIELD-SYMBOLS:<fs_face>,
                <fs_line>,
                <fs_c>.

  DEFINE macro_to_dict.
    ASSIGN COMPONENT i OF STRUCTURE ps_converted_perm TO <fs_face>.
    IF sy-subrc = '0'.
      ASSIGN COMPONENT j OF STRUCTURE <fs_face> TO <fs_line>.
      IF sy-subrc = '0'.
        ASSIGN COMPONENT k OF STRUCTURE <fs_line> TO <fs_c>.
        IF sy-subrc = '0'.
          &1 = <fs_c> .
        ENDIF.
      ENDIF.
    ENDIF.
  END-OF-DEFINITION.

  x = -1.
  DO 3 TIMES.
    y = -1.
    DO 3 TIMES.
      z = -1.
      DO 3 TIMES.
        ls_cube_dict-x = x.
        ls_cube_dict-y = y.
        ls_cube_dict-z = z.
        CLEAR: i, j, k.
        IF ls_cube_dict-x = 1.
          i = 3.
          j = abs( ls_cube_dict-y - 1 ).
          k = abs( ls_cube_dict-z - 1 ).
          macro_to_dict ls_cube_dict-x_color  .
        ELSEIF ls_cube_dict-x = -1.
          i = 1.
          j = abs( ls_cube_dict-y - 1 ).
          k = abs( ls_cube_dict-z + 1 ).
          macro_to_dict ls_cube_dict-x_color.
        ENDIF.
        IF ls_cube_dict-y = 1.
          i = 0.
          j = abs( ls_cube_dict-z + 1 ).
          k = abs( ls_cube_dict-x + 1 ).
          macro_to_dict ls_cube_dict-y_color.
        ELSEIF ls_cube_dict-y = -1.
          i = 5.
          j = abs( ls_cube_dict-z - 1 ).
          k = abs( ls_cube_dict-x + 1 ).
          macro_to_dict ls_cube_dict-y_color.
        ENDIF.
        IF ls_cube_dict-z = 1.
          i = 2.
          j = abs( ls_cube_dict-y - 1 ).
          k = abs( ls_cube_dict-x + 1 ).
          macro_to_dict ls_cube_dict-z_color.
        ELSEIF ls_cube_dict-z = -1.
          i = 4.
          j = abs( ls_cube_dict-y - 1 ).
          k = abs( ls_cube_dict-x - 1 ).
          macro_to_dict ls_cube_dict-z_color.
        ENDIF.
        APPEND ls_cube_dict TO pt_cube_dict.
        CLEAR: ls_cube_dict.
        z = z + 1.
      ENDDO.
      y = y + 1.
    ENDDO.
    x = x + 1.
  ENDDO.
  SORT pt_cube_dict BY x y z ASCENDING.
  DELETE pt_cube_dict WHERE x = 0 AND y = 0 AND z = 0 .
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_APPLY_ALG
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> SCRAMBLE
*&      <-- LT_CUBE_DICT
*&---------------------------------------------------------------------*
FORM frm_apply_alg  USING    pv_alg TYPE char20
                    CHANGING pt_cube_dict TYPE tt_cube_dict.
  DATA: lt_alg TYPE TABLE OF c WITH HEADER LINE.
  DATA charlen TYPE i VALUE 0.

  WHILE charlen LT strlen( pv_alg ).
    MOVE pv_alg+charlen(1) TO lt_alg.
    APPEND lt_alg.
    ADD 1 TO charlen .
  ENDWHILE.

  LOOP AT lt_alg.
    PERFORM frm_turn_rotate USING lt_alg CHANGING pt_cube_dict.
  ENDLOOP.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_TURN_ROTATE
*&---------------------------------------------------------------------*
*& 转动
*&---------------------------------------------------------------------*
*&      --> LT_ALG
*&      <-- PT_CUBE_DICT
*&---------------------------------------------------------------------*
FORM frm_turn_rotate  USING    pv_turn TYPE c
                      CHANGING pt_cube_dict TYPE tt_cube_dict.
  DATA: lv_sin TYPE i .
  DATA: lt_cube_dict TYPE TABLE OF ty_cube_dict WITH HEADER LINE.

  READ TABLE turn_dict ASSIGNING FIELD-SYMBOL(<fs_turn_dict>) WITH KEY code = pv_turn.
  IF sy-subrc = '0'.
*  ( CODE = 'R' TTYPE = 'cw'  SIDE =  'r' BOOL = ABAP_FALSE )
    CASE <fs_turn_dict>-ttype.
      WHEN 'cw'.
*        LV_DO = 1.
        lv_sin = 1.
      WHEN 'ccw'.
        lv_sin = -1.
      WHEN 'dt'.

    ENDCASE.

    CASE <fs_turn_dict>-side.
      WHEN 'l' OR 'r'.
        DATA(lv_a) = 'X'.
      WHEN 'u' OR 'd'.
        lv_a = 'Y'.
      WHEN 'f' OR 'b'.
        lv_a = 'Z'.


      WHEN 'm'.
      WHEN 'x'.
      WHEN 'y'.
      WHEN 'z'.
      WHEN OTHERS.
    ENDCASE.

    LOOP AT pt_cube_dict INTO lt_cube_dict .
      ASSIGN COMPONENT lv_a OF STRUCTURE lt_cube_dict TO FIELD-SYMBOL(<fv_a>).
      IF <fv_a> IS ASSIGNED .
        lt_cube_dict-x = lv_sin * lt_cube_dict-y.
        lt_cube_dict-y = - ( lv_sin * lt_cube_dict-x ) .
      ENDIF.

      APPEND lt_cube_dict.
    ENDLOOP.
    pt_cube_dict = lt_cube_dict[].
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FMR_GET_SCRAMBLE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> SCRAMBLE
*&---------------------------------------------------------------------*
FORM fmr_get_scramble  USING    p_scramble TYPE char20.
  DATA: cl_random TYPE REF TO cl_random_number,
        m         TYPE i.

  CREATE OBJECT cl_random.
  CALL METHOD cl_random->if_random_number~init .
  DO 12 TIMES.
    CALL METHOD cl_random->if_random_number~get_random_int
      EXPORTING
        i_limit  = 21
      RECEIVING
        r_random = m.

    READ TABLE turn_dict ASSIGNING FIELD-SYMBOL(<fs_dict>) INDEX m.
    IF sy-subrc = '0'.
      CONCATENATE p_scramble <fs_dict>-code INTO p_scramble.
    ENDIF.
  ENDDO.
ENDFORM.
