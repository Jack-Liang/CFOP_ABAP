*&---------------------------------------------------------------------*
*& Report Z_CFOP
*&---------------------------------------------------------------------*
*& Solve Rubik's Cube By CFOP
*&---------------------------------------------------------------------*
************************************************************************
*  程序名：Z_CFOP
*  程序名称：Z_CFOP
*-------------------------------------------------
*  创建日期         程序员        程序类型
*  2021.07.29      JACK LIANG     REPORT
*-------------------------------------------------
*  描述：
*    通过CFOP方法还原魔方
*    项目地址：https://github.com/Jack-Liang/CFOP_ABAP
*=================================================
*  修改日期    请求  版本    修改人      修改描述
*                   1.1
************************************************************************
REPORT z_cfop.

INCLUDE z_cfop_top.
INCLUDE z_cfop_sel.
INCLUDE z_cfop_check.
INCLUDE z_cfop_search.
INCLUDE z_cfop_operate.


INITIALIZATION.
  PERFORM frm_initialization.

  LOOP AT SCREEN .
    IF screen-name = 'P_SCRAM'.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

AT SELECTION-SCREEN .
  IF sy-ucomm = 'SCRAMBLE'.
    p_white = 'WWWWWW'.

    PERFORM frm_scramble.

    LOOP AT SCREEN .
      IF screen-name = 'P_SCRAM'.
        screen-active = 0.
        screen-input  = 0. "no input
        screen-output  = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
    p_scram = `R B R' L`.
  ENDIF.


START-OF-SELECTION.

  BREAK-POINT.
