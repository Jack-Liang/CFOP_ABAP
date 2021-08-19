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
*    1. 魔方输入
*    1.1 默认中心块
*    1.2 按照正视每个面录入
*    2. 自动建模
*    2. 魔方校验
*=================================================
*  修改日期    请求  版本    修改人      修改描述
*                   1.1
************************************************************************
REPORT Z_CFOP.

INCLUDE Z_CFOP_TOP.
INCLUDE Z_CFOP_CHECK.
INCLUDE Z_CFOP_SEARCH.
INCLUDE Z_CFOP_OPERATE.
PARAMETERS: P_CUBE TYPE C LENGTH 54.

INITIALIZATION.

  P_CUBE = 'WWWWWWWWWGRGOOOOOORGRGGGGGGBBBRRRRRROOOBBBBBBYYYYYYYYY'.

AT SELECTION-SCREEN ON P_CUBE.
  GV_CUBE = P_CUBE.
  PERFORM FRM_TRANSFORM USING 'A'.

  PERFORM FRM_CHECK_INPUT.

START-OF-SELECTION.

  GV_CUBE = P_CUBE.


  PERFORM FRM_CFOP.


  PERFORM FRM_TRANSFORM USING 'A'.
  PERFORM FRM_TRANSFORM USING 'B'.

END-OF-SELECTION.

  WRITE: / '完成'.
