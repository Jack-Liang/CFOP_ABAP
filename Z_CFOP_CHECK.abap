*&---------------------------------------------------------------------*
*& 包含               Z_CFOP_CHECK
*&---------------------------------------------------------------------*
*---------------------------------------------------------*
*	检查输入的正确性
*---------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form FRM_CHECK_INPUT
*&---------------------------------------------------------------------*
*& 检查魔方合法性
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_CHECK_INPUT .

  PERFORM FRM_CHECK_LENTH.
  PERFORM FRM_CHECK_COLOR.
  PERFORM FRM_CHECK_COLOR_RELATIONSHIP.
  PERFORM FRM_CHECK_FINISHED.
  IF GV_FINISHED IS NOT INITIAL.
    MESSAGE '魔方已处于还原状态' TYPE 'S'.
    EXIT.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_CHECK_LENTH
*&---------------------------------------------------------------------*
*& 检查输入长度
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_CHECK_LENTH .
  IF STRLEN( GV_CUBE ) NE '54'.
    MESSAGE '请输入完整的结构' TYPE 'E' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_CHECK_COLOR_RELATIONSHIP
*&---------------------------------------------------------------------*
*& 检查颜色关系
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_CHECK_COLOR_RELATIONSHIP .

  PERFORM FRM_CHECK_CENTER_BLOCK.
  PERFORM FRM_CHECK_EDGE_BLOCK.
  PERFORM FRM_CHECK_CORNER_BLOCK.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_CHECK_CENTER_BLOCK
*&---------------------------------------------------------------------*
*& 检查中心块是否满足条件
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_CHECK_CENTER_BLOCK .

  DATA: BEGIN OF LT_COLOR OCCURS 0,
          C5 TYPE C,
        END OF LT_COLOR.

  LOOP AT GT_CUBE ASSIGNING FIELD-SYMBOL(<FS_CUBE>).
    MOVE-CORRESPONDING <FS_CUBE> TO LT_COLOR.
    COLLECT LT_COLOR.
  ENDLOOP.

  IF LINES( LT_COLOR[] ) NE 6.
    MESSAGE '中心块输入有误' TYPE 'E' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_CHECK_EDGE_BLOCK
*&---------------------------------------------------------------------*
*& 检查棱块
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_CHECK_EDGE_BLOCK .
  DATA: BEGIN OF LT_COLOR_NUM OCCURS 0,
          COLOR     TYPE C,
          COLOR_NUM TYPE I,
          E1        TYPE C, "邻边的颜色
          C1        TYPE CHAR2, "邻边的位置
          E2        TYPE C,
          C2        TYPE CHAR2,
          E3        TYPE C,
          C3        TYPE CHAR2,
          E4        TYPE C,
          C4        TYPE CHAR2,
        END OF LT_COLOR_NUM,
        BEGIN OF LT_EDGE_BLOCK_NUM OCCURS 0,
          NAME TYPE CHAR2,
          SUM  TYPE CHAR2,
          NUM  TYPE I,
        END OF LT_EDGE_BLOCK_NUM.

  LT_COLOR_NUM[] = VALUE #(
       ( COLOR = 'R' COLOR_NUM = '1'   E1 = 'B' C1 = 'C6' E2 = 'Y' C2 = 'C6' E3 = 'G' C3 = 'C4' E4 = 'W' C4 = 'C6' )
       ( COLOR = 'G' COLOR_NUM = '3'   E1 = 'R' C1 = 'C6' E2 = 'Y' C2 = 'C2' E3 = 'O' C3 = 'C4' E4 = 'W' C4 = 'C8')
       ( COLOR = 'B' COLOR_NUM = '7'   E1 = 'O' C1 = 'C6' E2 = 'Y' C2 = 'C8' E3 = 'R' C3 = 'C4' E4 = 'W' C4 = 'C2')
       ( COLOR = 'O' COLOR_NUM = '13'  E1 = 'G' C1 = 'C6' E2 = 'Y' C2 = 'C4' E3 = 'B' C3 = 'C4' E4 = 'W' C4 = 'C4' )
       ( COLOR = 'Y' COLOR_NUM = '21'  E1 = 'O' C1 = 'C2' E2 = 'G' C2 = 'C2' E3 = 'R' C3 = 'C2' E4 = 'B' C4 = 'C2')
       ( COLOR = 'W' COLOR_NUM = '30'  E1 = 'O' C1 = 'C8' E2 = 'B' C2 = 'C8' E3 = 'R' C3 = 'C8' E4 = 'G' C4 = 'C8' )
          ).

  LT_EDGE_BLOCK_NUM[] = VALUE #(
              ( NAME = 'GR' SUM = '4' )
              ( NAME = 'BR' SUM = '8' )
              ( NAME = 'GO' SUM = '16' )
              ( NAME = 'BO' SUM = '20' )
              ( NAME = 'RY' SUM = '22' )
              ( NAME = 'GY' SUM = '24' )
              ( NAME = 'BY' SUM = '28' )
              ( NAME = 'RW' SUM = '31' )
              ( NAME = 'GW' SUM = '33' )
              ( NAME = 'OY' SUM = '34' )
              ( NAME = 'BW' SUM = '37' )
              ( NAME = 'OW' SUM = '43' )
          ).

  " 通过清单检查12个棱块
  DATA: LV_EDGE TYPE CHAR2.
  DATA: LV_CDGE TYPE CHAR2.
  DATA: LV_INDEX TYPE SY-INDEX.
  DATA LV_SUM TYPE I."棱块唯一值
  LOOP AT GT_CUBE ASSIGNING FIELD-SYMBOL(<FS_CUBE>) .
    READ TABLE LT_COLOR_NUM WITH KEY COLOR = <FS_CUBE>-C5.
    IF SY-SUBRC = '0'.
      CLEAR: LV_EDGE, LV_SUM.
      DO 4 TIMES.
        LV_INDEX = SY-INDEX.
        LV_EDGE = 'E' && SY-INDEX .
        LV_CDGE = 'C' && SY-INDEX .
        "侧面中心点 <FV_COLOR_EDGE>
        ASSIGN COMPONENT LV_EDGE OF STRUCTURE LT_COLOR_NUM TO FIELD-SYMBOL(<FV_COLOR_EDGE>).
        "侧面 <FS_CUBE_EDGE>
        READ TABLE GT_CUBE ASSIGNING FIELD-SYMBOL(<FS_CUBE_EDGE>) WITH KEY C5 = <FV_COLOR_EDGE>.
        "对应侧面棱块的存储位置 <FV_COLOR_CDGE>
        ASSIGN COMPONENT LV_CDGE OF STRUCTURE LT_COLOR_NUM TO FIELD-SYMBOL(<FV_COLOR_CDGE>).
        "对应的颜色 <FV_C_VALUE>
        ASSIGN COMPONENT <FV_COLOR_CDGE> OF STRUCTURE <FS_CUBE_EDGE> TO FIELD-SYMBOL(<FV_C_VALUE>).
        CASE LV_INDEX.
          WHEN 1.
            "读当前棱块的色值 COLOR_NUM
            READ TABLE LT_COLOR_NUM ASSIGNING FIELD-SYMBOL(<FS_COLOR_NUM>) WITH KEY COLOR = <FS_CUBE>-C4.
            "侧面棱块的色值
            READ TABLE LT_COLOR_NUM ASSIGNING FIELD-SYMBOL(<FS_COLOR_NUM2>) WITH KEY COLOR = <FV_C_VALUE>.
            LV_SUM = <FS_COLOR_NUM>-COLOR_NUM + <FS_COLOR_NUM2>-COLOR_NUM.
          WHEN 2.
            READ TABLE LT_COLOR_NUM ASSIGNING <FS_COLOR_NUM> WITH KEY COLOR = <FS_CUBE>-C2.
            READ TABLE LT_COLOR_NUM ASSIGNING <FS_COLOR_NUM2> WITH KEY COLOR = <FV_C_VALUE>.
            LV_SUM = <FS_COLOR_NUM>-COLOR_NUM + <FS_COLOR_NUM2>-COLOR_NUM.
          WHEN 3.
            READ TABLE LT_COLOR_NUM ASSIGNING <FS_COLOR_NUM> WITH KEY COLOR = <FS_CUBE>-C6.
            READ TABLE LT_COLOR_NUM ASSIGNING <FS_COLOR_NUM2> WITH KEY COLOR = <FV_C_VALUE>.
            LV_SUM = <FS_COLOR_NUM>-COLOR_NUM + <FS_COLOR_NUM2>-COLOR_NUM.
          WHEN 4.
            READ TABLE LT_COLOR_NUM ASSIGNING <FS_COLOR_NUM> WITH KEY COLOR = <FS_CUBE>-C8.
            READ TABLE LT_COLOR_NUM ASSIGNING <FS_COLOR_NUM2> WITH KEY COLOR = <FV_C_VALUE>.
            LV_SUM = <FS_COLOR_NUM>-COLOR_NUM + <FS_COLOR_NUM2>-COLOR_NUM.
          WHEN OTHERS.
        ENDCASE.
        READ TABLE LT_EDGE_BLOCK_NUM WITH KEY SUM = LV_SUM.
        IF SY-SUBRC = '0'.
          LT_EDGE_BLOCK_NUM-NUM = 1.
          COLLECT LT_EDGE_BLOCK_NUM.
        ELSE.
          BREAK-POINT.
        ENDIF.
      ENDDO.
    ENDIF.
  ENDLOOP.
  LOOP AT LT_EDGE_BLOCK_NUM
    WHERE NUM NE 2.
    MESSAGE '棱块关系有误' TYPE 'E' DISPLAY LIKE 'E'.
    EXIT.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_CHECK_CORNER_BLOCK
*&---------------------------------------------------------------------*
*& 检查角块
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_CHECK_CORNER_BLOCK .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_CHECK_FINISHED
*&---------------------------------------------------------------------*
*& 完成度检查
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_CHECK_FINISHED .

  DATA: OFF TYPE I,
        LEN TYPE I.
  DATA: LV_FINISHED1 TYPE I,
        LV_FINISHED2 TYPE I,
        LV_FINISHED3 TYPE I,
        LV_FINISHED4 TYPE I,
        LV_FINISHED5 TYPE I,
        LV_FINISHED6 TYPE I.

  CLEAR: GV_FINISHED.
  LOOP AT GT_CUBE ASSIGNING FIELD-SYMBOL(<FS_CUBE>).
    IF  <FS_CUBE>-C1 EQ <FS_CUBE>-C5 AND
        <FS_CUBE>-C2 EQ <FS_CUBE>-C5 AND
        <FS_CUBE>-C3 EQ <FS_CUBE>-C5 AND
        <FS_CUBE>-C4 EQ <FS_CUBE>-C5 AND
        <FS_CUBE>-C6 EQ <FS_CUBE>-C5 AND
        <FS_CUBE>-C7 EQ <FS_CUBE>-C5 AND
        <FS_CUBE>-C8 EQ <FS_CUBE>-C5 AND
        <FS_CUBE>-C9 EQ <FS_CUBE>-C5.
      CASE SY-INDEX.
        WHEN 1.
          LV_FINISHED1 = 1.
        WHEN 2.
          LV_FINISHED2 = 1.
        WHEN 3.
          LV_FINISHED3 = 1.
        WHEN 4.
          LV_FINISHED4 = 1.
        WHEN 5.
          LV_FINISHED5 = 1.
        WHEN 6.
          LV_FINISHED6 = 1.
      ENDCASE.
    ENDIF.
  ENDLOOP.
  IF LV_FINISHED1 +
     LV_FINISHED2 +
     LV_FINISHED3 +
     LV_FINISHED4 +
     LV_FINISHED5 +
     LV_FINISHED6
      = 6.
    GV_FINISHED ='X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_CHECK_COLOR
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_CHECK_COLOR .
  DATA: OFF TYPE I,
        LEN TYPE I VALUE 1.
  DATA: LV_COLOR TYPE C.
  DATA: R TYPE I,
        G TYPE I,
        B TYPE I,
        O TYPE I,
        Y TYPE I,
        W TYPE I.


  IF GV_CUBE CN 'RGBOYW'.
    MESSAGE '输入包含不能识别的字符' TYPE 'E' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
  DO 54 TIMES.
    LV_COLOR = GV_CUBE+OFF(LEN).

    CASE LV_COLOR.
      WHEN RED    .
        R = R + 1.
      WHEN GREEN  .
        G = G + 1.
      WHEN BLUE   .
        B = B + 1.
      WHEN ORANGE .
        O = O + 1.
      WHEN YELLOW .
        Y = Y + 1.
      WHEN WHITE  .
        W = W + 1.
    ENDCASE.
    OFF = OFF + 1.
  ENDDO.
  IF R NE 9 OR
    G NE 9 OR
    B NE 9 OR
    O NE 9 OR
    Y NE 9 OR
    W NE 9.
    MESSAGE '色彩数量分布不满足要求' TYPE 'E' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
ENDFORM.
