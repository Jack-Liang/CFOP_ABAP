*&---------------------------------------------------------------------*
*& 包含               Z_CFOP_SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE tblock1.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_yellow.
PARAMETERS: p_yellow TYPE c LENGTH 9.
SELECTION-SCREEN END OF LINE.


SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_orange.
PARAMETERS: p_orange TYPE c LENGTH 9.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_blue.
PARAMETERS: p_blue TYPE c LENGTH 9.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_red.
PARAMETERS: p_red TYPE c LENGTH 9.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_green.
PARAMETERS: p_green TYPE c LENGTH 9.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_white.
PARAMETERS: p_white TYPE c LENGTH 9.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK b1.

SELECTION-SCREEN: BEGIN OF BLOCK b2 WITH FRAME TITLE tblock2.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_detail.
PARAMETERS: details TYPE char1 AS CHECKBOX.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: END OF BLOCK b2.


SELECTION-SCREEN: BEGIN OF LINE,
  PUSHBUTTON 5(23) scramble USER-COMMAND scramble.
SELECTION-SCREEN: END OF LINE.
*&---------------------------------------------------------------------*
*& Form FRM_INITIALIZATION
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_initialization .

  tblock1 = '魔方输入'.
  t_yellow = '黄色面'.
  t_orange = '橙色面'.
  t_blue = '蓝色面'.
  t_red = '红色面'.
  t_green = '绿色面'.
  t_white = '白色面'.

  tblock2 = '详情'.
  t_detail = '输出技术细节'.
  scramble = '生成打乱公式'.

ENDFORM.
