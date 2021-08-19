*&---------------------------------------------------------------------*
*& 包含               Z_CFOP_TOP
*&---------------------------------------------------------------------*
*---------------------------------------------------------*
*	常量
*---------------------------------------------------------*
  "色彩
  CONSTANTS: COLOR_RED    TYPE CHAR6 VALUE 'C41E3A',
             COLOR_GREEN  TYPE CHAR6 VALUE '009E60',
             COLOR_BLUE   TYPE CHAR6 VALUE '0051BA',
             COLOR_ORANGE TYPE CHAR6 VALUE 'FF5800',
             COLOR_YELLOW TYPE CHAR6 VALUE 'FFD500',
             COLOR_WHITE  TYPE CHAR6 VALUE 'FFFFFF'.
  "色块
  CONSTANTS: RED    TYPE CHAR1 VALUE 'R',
             GREEN  TYPE CHAR1 VALUE 'G',
             BLUE   TYPE CHAR1 VALUE 'B',
             ORANGE TYPE CHAR1 VALUE 'O',
             YELLOW TYPE CHAR1 VALUE 'Y',
             WHITE  TYPE CHAR1 VALUE 'W'.

  TYPES: BEGIN OF TY_CUBE_9,"9乘6表示
           C1 TYPE CHAR1,
           C2 TYPE CHAR1,
           C3 TYPE CHAR1,
           C4 TYPE CHAR1,
           C5 TYPE CHAR1,
           C6 TYPE CHAR1,
           C7 TYPE CHAR1,
           C8 TYPE CHAR1,
           C9 TYPE CHAR1,
         END OF TY_CUBE_9.
  DATA: GT_CUBE TYPE TABLE OF TY_CUBE_9,
        GS_CUBE TYPE TY_CUBE_9.

  TYPES: BEGIN OF TY_CUBE3,"3乘3表示
           C1 TYPE CHAR1,
           C2 TYPE CHAR1,
           C3 TYPE CHAR1,
         END OF TY_CUBE3,
         BEGIN OF TY_CUBE3_3, "3乘3表示
           FACE1 TYPE TY_CUBE3,
           FACE2 TYPE TY_CUBE3,
           FACE3 TYPE TY_CUBE3,
           FACE4 TYPE TY_CUBE3,
           FACE5 TYPE TY_CUBE3,
           FACE6 TYPE TY_CUBE3,
         END OF TY_CUBE3_3.
  DATA: GT_CUBE3_3 TYPE TABLE OF TY_CUBE3_3.
*  APPEND INITIAL LINE TO GT_CUBE3_3.


  DATA GV_CUBE TYPE C LENGTH 54."一条龙表示

  DATA GV_FINISHED TYPE C ."完整



*---------------------------------------------------------*
* CFOP
*---------------------------------------------------------*
