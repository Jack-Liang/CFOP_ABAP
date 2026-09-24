*&---------------------------------------------------------------------*
*& 包含 Z_CFOP_SEL：选择屏幕
*&---------------------------------------------------------------------*
* 录入顺序（与展开图一致）：黄、橙、蓝、红、绿、白
* 每面 9 个贴纸：从该面外侧看，行自上而下、列自左到右。
* 面的朝向由中心色决定，系统按标准配色放入固定坐标系
* （白底、黄顶、绿前、蓝后、红右、橙左）。

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE tblock1.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_yellow FOR FIELD p_yellow.
PARAMETERS p_yellow TYPE c LENGTH 9.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_orange FOR FIELD p_orange.
PARAMETERS p_orange TYPE c LENGTH 9.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_blue FOR FIELD p_blue.
PARAMETERS p_blue TYPE c LENGTH 9.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_red FOR FIELD p_red.
PARAMETERS p_red TYPE c LENGTH 9.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_green FOR FIELD p_green.
PARAMETERS p_green TYPE c LENGTH 9.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_white FOR FIELD p_white.
PARAMETERS p_white TYPE c LENGTH 9.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE tblock2.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_test FOR FIELD p_test.
PARAMETERS p_test TYPE c LENGTH 1 AS CHECKBOX.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE tblock3.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON 5(20) bscram USER-COMMAND scram.
SELECTION-SCREEN COMMENT 28(60) t_scrnote FOR FIELD p_scram.
PARAMETERS p_scram TYPE c LENGTH 60 VISIBLE LENGTH 60.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b3.

*&---------------------------------------------------------------------*
*& Form FRM_INITIALIZATION：初始化屏幕文本
*&---------------------------------------------------------------------*
FORM frm_initialization.
  tblock1 = '魔方录入（每面 9 贴纸：黄橙蓝红绿白）'.
  t_yellow = '黄色面'.
  t_orange = '橙色面'.
  t_blue = '蓝色面'.
  t_red = '红色面'.
  t_green = '绿色面'.
  t_white = '白色面'.

  tblock2 = '诊断'.
  t_test = '运行自检（引擎 / 校验 / 求解回归）'.

  tblock3 = '打乱演示'.
  bscram = '生成随机打乱公式'.
  t_scrnote = '生成后回车：还原态 + 打乱公式，直接求解'.
ENDFORM.
