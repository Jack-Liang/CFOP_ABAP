*&---------------------------------------------------------------------*
*& 包含               Z_CFOP_OPERATE
*&---------------------------------------------------------------------*
*---------------------------------------------------------*
* 右侧顺时针90度
*---------------------------------------------------------*
FORM FRM_R.
  DATA: LS_CUBE TYPE TY_CUBE_9,
        LT_CUBE TYPE TABLE OF TY_CUBE_9.
  FIELD-SYMBOLS: <FS_CUBE> TYPE TY_CUBE_9.
  PERFORM FRM_SERIALIZATION.

*WOGRBY

  LOOP AT GT_CUBE INTO LS_CUBE.
    CASE LS_CUBE-C5 .
      WHEN 'W'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'G'.
        IF SY-SUBRC = '0'.
          LS_CUBE-C3 = <FS_CUBE>-C7.
          LS_CUBE-C6 = <FS_CUBE>-C4.
          LS_CUBE-C9 = <FS_CUBE>-C1.
        ENDIF.
      WHEN 'O'.

      WHEN 'G'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'Y'.
        IF SY-SUBRC = '0'.
          LS_CUBE-C1 = <FS_CUBE>-C9.
          LS_CUBE-C4 = <FS_CUBE>-C6.
          LS_CUBE-C7 = <FS_CUBE>-C3.
        ENDIF.
      WHEN 'R'.
      WHEN 'B'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'W'.
        IF SY-SUBRC = '0'.
          LS_CUBE-C3 = <FS_CUBE>-C3.
          LS_CUBE-C6 = <FS_CUBE>-C6.
          LS_CUBE-C9 = <FS_CUBE>-C9.
        ENDIF.
      WHEN 'Y'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'B'.
        IF SY-SUBRC = '0'.
          LS_CUBE-C3 = <FS_CUBE>-C3.
          LS_CUBE-C6 = <FS_CUBE>-C6.
          LS_CUBE-C9 = <FS_CUBE>-C9.
        ENDIF.
    ENDCASE.

    APPEND LS_CUBE TO LT_CUBE.
  ENDLOOP.

  CLEAR: GT_CUBE.
  GT_CUBE = LT_CUBE.

ENDFORM.
*---------------------------------------------------------*
*
*---------------------------------------------------------*
FORM FRM_L.
  DATA: LS_CUBE TYPE TY_CUBE_9,
        LT_CUBE TYPE TABLE OF TY_CUBE_9.
  FIELD-SYMBOLS: <FS_CUBE> TYPE TY_CUBE_9.
  PERFORM FRM_SERIALIZATION.

  LOOP AT GT_CUBE INTO LS_CUBE.
    CASE LS_CUBE-C5 .
      WHEN 'W'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'B'.
        IF SY-SUBRC = '0'.
          LS_CUBE-C1 = <FS_CUBE>-C1.
          LS_CUBE-C4 = <FS_CUBE>-C4.
          LS_CUBE-C7 = <FS_CUBE>-C7.
        ENDIF.
      WHEN 'O'.

      WHEN 'G'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'W'.
        IF SY-SUBRC = '0'.
          LS_CUBE-C3 = <FS_CUBE>-C7.
          LS_CUBE-C6 = <FS_CUBE>-C4.
          LS_CUBE-C9 = <FS_CUBE>-C1.
        ENDIF.
      WHEN 'R'.
      WHEN 'B'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'Y'.
        IF SY-SUBRC = '0'.
          LS_CUBE-C1 = <FS_CUBE>-C1.
          LS_CUBE-C4 = <FS_CUBE>-C4.
          LS_CUBE-C7 = <FS_CUBE>-C7.
        ENDIF.
      WHEN 'Y'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'G'.
        IF SY-SUBRC = '0'.
          LS_CUBE-C1 = <FS_CUBE>-C9.
          LS_CUBE-C4 = <FS_CUBE>-C6.
          LS_CUBE-C7 = <FS_CUBE>-C3.
        ENDIF.
    ENDCASE.

    APPEND LS_CUBE TO LT_CUBE.
  ENDLOOP.

  CLEAR: GT_CUBE.
  GT_CUBE = LT_CUBE.
ENDFORM.
*---------------------------------------------------------*
*
*---------------------------------------------------------*
FORM FRM_U.
  DATA: LS_CUBE TYPE TY_CUBE_9,
        LT_CUBE TYPE TABLE OF TY_CUBE_9.
  FIELD-SYMBOLS: <FS_CUBE> TYPE TY_CUBE_9.
  PERFORM FRM_SERIALIZATION.

  LOOP AT GT_CUBE INTO LS_CUBE.
    CASE LS_CUBE-C5 .
      WHEN 'W'.

      WHEN 'O'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'B'.
      WHEN 'G'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'O'.
      WHEN 'R'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'G'.
      WHEN 'B'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'R'.
      WHEN 'Y'.

    ENDCASE.
    IF SY-SUBRC = '0'.
      LS_CUBE-C1 = <FS_CUBE>-C1.
      LS_CUBE-C2 = <FS_CUBE>-C2.
      LS_CUBE-C3 = <FS_CUBE>-C3.
    ENDIF.

    APPEND LS_CUBE TO LT_CUBE.
  ENDLOOP.

  CLEAR: GT_CUBE.
  GT_CUBE = LT_CUBE.
ENDFORM.
*---------------------------------------------------------*
*
*---------------------------------------------------------*
FORM FRM_D.
  DATA: LS_CUBE TYPE TY_CUBE_9,
        LT_CUBE TYPE TABLE OF TY_CUBE_9.
  FIELD-SYMBOLS: <FS_CUBE> TYPE TY_CUBE_9.
  PERFORM FRM_SERIALIZATION.

  LOOP AT GT_CUBE INTO LS_CUBE.
    CASE LS_CUBE-C5 .
      WHEN 'W'.

      WHEN 'O'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'G'.
      WHEN 'G'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'R'.
      WHEN 'R'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'B'.
      WHEN 'B'.
        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'O'.
      WHEN 'Y'.

    ENDCASE.
    IF SY-SUBRC = '0'.
      LS_CUBE-C1 = <FS_CUBE>-C1.
      LS_CUBE-C2 = <FS_CUBE>-C2.
      LS_CUBE-C3 = <FS_CUBE>-C3.
    ENDIF.

    APPEND LS_CUBE TO LT_CUBE.
  ENDLOOP.

  CLEAR: GT_CUBE.
  GT_CUBE = LT_CUBE.
ENDFORM.
*---------------------------------------------------------*
*
*---------------------------------------------------------*
FORM FRM_F.
  DATA: LS_CUBE TYPE TY_CUBE_9,
        LT_CUBE TYPE TABLE OF TY_CUBE_9.
  FIELD-SYMBOLS: <FS_CUBE> TYPE TY_CUBE_9.
  PERFORM FRM_SERIALIZATION.

  LOOP AT GT_CUBE INTO LS_CUBE.
*    CASE LS_CUBE-C5 .
*      WHEN 'W'.
*
*      WHEN 'O'.
*        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'G'.
*      WHEN 'G'.
*        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'R'.
*      WHEN 'R'.
*        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'B'.
*      WHEN 'B'.
*        READ TABLE GT_CUBE ASSIGNING <FS_CUBE> WITH KEY C5 = 'O'.
*      WHEN 'Y'.
*
*    ENDCASE.
*    IF SY-SUBRC = '0'.
*      LS_CUBE-C1 = <FS_CUBE>-C1.
*      LS_CUBE-C2 = <FS_CUBE>-C2.
*      LS_CUBE-C3 = <FS_CUBE>-C3.
*    ENDIF.
*
*    APPEND LS_CUBE TO LT_CUBE.
  ENDLOOP.

  CLEAR: GT_CUBE.
  GT_CUBE = LT_CUBE.
ENDFORM.


*---------------------------------------------------------*
*	链式记录与表式记录转换
*---------------------------------------------------------*
*	 PV_TYPE 以某一个格式为准
*---------------------------------------------------------*
FORM FRM_TRANSFORM USING PV_TYPE.

  CASE PV_TYPE.
    WHEN 'A'."
      PERFORM FRM_TRANSFORM_54_9.
    WHEN 'B'.
      PERFORM FRM_TRANSFORM_9_54.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_TRANSFORM_54_9
*&---------------------------------------------------------------------*
*& 由一条龙模式转换为9*6表格
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_TRANSFORM_54_9 .
  DATA: LS_CUBE TYPE TY_CUBE_9.
  DATA: OFF TYPE I VALUE 0,
        LEN TYPE I VALUE 9.
  CLEAR: GT_CUBE.
  DO 6 TIMES.
    CLEAR: LS_CUBE.
    LS_CUBE = GV_CUBE+OFF(LEN).
    APPEND LS_CUBE TO GT_CUBE.
    OFF = OFF + 9.
  ENDDO.

*  PERFORM FRM_SERIALIZATION.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_TRANSFORM_9_54
*&---------------------------------------------------------------------*
*& 由9*6表格转换为一条龙模式
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_TRANSFORM_9_54 .
*  PERFORM FRM_SERIALIZATION.
  CLEAR: GV_CUBE.
  LOOP AT GT_CUBE ASSIGNING FIELD-SYMBOL(<FS_CUBE>).
    CONCATENATE GV_CUBE <FS_CUBE> INTO GV_CUBE.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_CROSS
*&---------------------------------------------------------------------*
*& CROSS
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_CROSS .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_F2L
*&---------------------------------------------------------------------*
*& FIRST 2 LAYERS
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_F2L .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_OLL
*&---------------------------------------------------------------------*
*& ORIENTATION OF LAST LAYERS
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_OLL .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_PLL
*&---------------------------------------------------------------------*
*& PERNUTARION OF LAST LAYERS
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_PLL .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_CFOP
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_CFOP .
  PERFORM FRM_CROSS.
  PERFORM FRM_F2L.
  PERFORM FRM_OLL.
  PERFORM FRM_PLL.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_SERIALIZATION
*&---------------------------------------------------------------------*
*&   "按颜色排序
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_SERIALIZATION .
  DATA: LS_CUBE TYPE TY_CUBE_9,
        LT_CUBE TYPE TABLE OF TY_CUBE_9.
  DATA: LV_INDEX TYPE I VALUE 0.
  CONSTANTS SORTING TYPE C LENGTH 6 VALUE 'WOGRBY'.

  CLEAR: LS_CUBE.

  LT_CUBE = GT_CUBE.

  CLEAR: GT_CUBE.

  DO 6 TIMES.
    DATA(LV_COLOR) = SORTING+LV_INDEX(1).
    CLEAR LS_CUBE.
    READ TABLE LT_CUBE INTO LS_CUBE WITH KEY C5 = LV_COLOR.
    IF SY-SUBRC = '0'.
      APPEND LS_CUBE TO GT_CUBE.
    ELSE.
      MESSAGE '请检查中心块' && LV_COLOR && '是否正确' TYPE 'E'.
    ENDIF.
    LV_INDEX = LV_INDEX + 1.
  ENDDO.
ENDFORM.
