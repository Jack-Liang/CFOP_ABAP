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
PARAMETERS p_scram TYPE c LENGTH 60.
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


  param_dict[] = VALUE #(
"# Clockwise turns
( ttype = 'cw' side = 'u'
  scode-0 = 1 scode-1 = 1 scode-2 = -1 scode-3 = 2 scode-4 = 1 scode-5 = 1 scode-6 = 1 scode-7 = 1 )
( ttype = 'cw' side = 'd'
  scode-0 = 1 scode-1 = -1 scode-2 = 1 scode-3 = 2 scode-4 = 1 scode-5 = 1 scode-6 = -1 scode-7 = 0 )
( ttype = 'cw' side = 'r'
  scode-0 = 0 scode-1 = 1 scode-2 = 1 scode-3 = 0 scode-4 = 1 scode-5 = 2 scode-6 = -1 scode-7 = 1  )
( ttype = 'cw' side = 'l'
  scode-0 = 0 scode-1 = -1 scode-2 = 1 scode-3 = 0 scode-4 = -1 scode-5 = 2 scode-6 = 1 scode-7 = 1 )
( ttype = 'cw' side = 'f'
  scode-0 = 2 scode-1 = 1 scode-2 = 1 scode-3 = 1 scode-4 = -1 scode-5 = 0 scode-6 = 1 scode-7 = 2  )
( ttype = 'cw' side = 'b'
  scode-0 = 2 scode-1 = -1 scode-2 = -1 scode-3 = 1 scode-4 = 1 scode-5 = 0 scode-6 = 1 scode-7 = 2 )
"# Counterclockwise turns
( ttype = 'ccw' side = 'u'
  scode-0 = 1 scode-1 = 1 scode-2 = 1 scode-3 = 2 scode-4 = 1 scode-5 = 1 scode-6 = -1 scode-7 = 0 )
( ttype = 'ccw' side = 'd'
  scode-0 = 1 scode-1 = -1 scode-2 = -1 scode-3 = 2 scode-4 = 1 scode-5 = 1 scode-6 = 1 scode-7 = 0 )
( ttype = 'ccw' side = 'r'
  scode-0 = 0 scode-1 = 1 scode-2 = 1 scode-3 = 0 scode-4 = -1 scode-5 = 2 scode-6 = 1 scode-7 = 1 )
( ttype = 'ccw' side = 'l'
  scode-0 = 0 scode-1 = 1 scode-2 = 1 scode-3 = 0 scode-4 = 1 scode-5 = 2 scode-6 = -1 scode-7 = 1 )
( ttype = 'ccw' side = 'f'
  scode-0 = 2 scode-1 = 1 scode-2 = -1 scode-3 = 1 scode-4 = 1 scode-5 = 0 scode-6 = 1 scode-7 = 2 )
( ttype = 'ccw' side = 'b'
  scode-0 = 2 scode-1 = -1 scode-2 = 1 scode-3 = 1 scode-4 = -1 scode-5 = 0 scode-6 = 1 scode-7 = 2 )
"# Double turns (180 degrees)

).


  turn_dict[] = VALUE #(
"Single layer turns
  ( code = 'U' ttype = 'cw'  side =  'u' bool = abap_false )
  ( code = 'T' ttype = 'ccw' side =  'u' bool = abap_false )
  ( code = '!' ttype = 'dt'  side =  'u' bool = abap_false )
  ( code = 'L' ttype = 'cw'  side =  'l' bool = abap_false )
  ( code = 'K' ttype = 'ccw' side =  'l' bool = abap_false )
  ( code = '@' ttype = 'dt'  side =  'l' bool = abap_false )
  ( code = 'F' ttype = 'cw'  side =  'f' bool = abap_false )
  ( code = 'E' ttype = 'ccw' side =  'f' bool = abap_false )
  ( code = '#' ttype = 'dt'  side =  'f' bool = abap_false )
  ( code = 'R' ttype = 'cw'  side =  'r' bool = abap_false )
  ( code = 'Q' ttype = 'ccw' side =  'r' bool = abap_false )
  ( code = '$' ttype = 'dt'  side =  'r' bool = abap_false )
  ( code = 'B' ttype = 'cw'  side =  'b' bool = abap_false )
  ( code = 'A' ttype = 'ccw' side =  'b' bool = abap_false )
  ( code = '%' ttype = 'dt'  side =  'b' bool = abap_false )
  ( code = 'D' ttype = 'cw'  side =  'd' bool = abap_false )
  ( code = 'C' ttype = 'ccw' side =  'd' bool = abap_false )
  ( code = '^' ttype = 'dt'  side =  'd' bool = abap_false )
  ( code = 'M' ttype = 'cw'  side =  'm' bool = abap_false )
  ( code = 'm' ttype = 'ccw' side =  'm' bool = abap_false )
  ( code = '7' ttype = 'dt'  side =  'm' bool = abap_false )
  "DOUBLE LAYER TURNS
  ( code = 'u' ttype = 'cw'   side =  'u' bool = abap_true )
  ( code = 't' ttype = 'ccw'  side =  'u' bool = abap_true )
  ( code = '1' ttype = 'dt'   side =  'u' bool = abap_true )
  ( code = 'l' ttype = 'cw'   side =  'l' bool = abap_true )
  ( code = 'k' ttype = 'ccw'  side =  'l' bool = abap_true )
  ( code = '2' ttype = 'dt'   side =  'l' bool = abap_true )
  ( code = 'f' ttype = 'cw'   side =  'f' bool = abap_true )
  ( code = 'e' ttype = 'ccw'  side =  'f' bool = abap_true )
  ( code = '3' ttype = 'dt'   side =  'f' bool = abap_true )
  ( code = 'r' ttype = 'cw'   side =  'r' bool = abap_true )
  ( code = 'q' ttype = 'ccw'  side =  'r' bool = abap_true )
  ( code = '4' ttype = 'dt'   side =  'r' bool = abap_true )
  ( code = 'b' ttype = 'cw'   side =  'b' bool = abap_true )
  ( code = 'a' ttype = 'ccw'  side =  'b' bool = abap_true )
  ( code = '5' ttype = 'dt'   side =  'b' bool = abap_true )
  ( code = 'd' ttype = 'cw'   side =  'd' bool = abap_true )
  ( code = 'c' ttype = 'ccw'  side =  'd' bool = abap_true )
  ( code = '6' ttype = 'dt'   side =  'd' bool = abap_true )
  "ROTATIONS
  ( code = 'x' ttype = 'cw'    side =  'x' bool = abap_false )
  ( code = 'X' ttype = 'ccw'   side =  'x' bool = abap_false )
  ( code = '8' ttype = 'dt'    side =  'x' bool = abap_false )
  ( code = 'y' ttype = 'cw'    side =  'y' bool = abap_false )
  ( code = 'Y' ttype = 'ccw'   side =  'y' bool = abap_false )
  ( code = '9' ttype = 'dt'    side =  'y' bool = abap_false )
  ( code = 'z' ttype = 'cw'    side =  'z' bool = abap_false )
  ( code = 'Z' ttype = 'ccw'   side =  'z' bool = abap_false )
  ( code = '0' ttype = 'dt'    side =  'z' bool = abap_false )
  ).



ENDFORM.
