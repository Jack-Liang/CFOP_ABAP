*&---------------------------------------------------------------------*
*& 包含 Z_CFOP_SEL：选择屏幕
*&---------------------------------------------------------------------*
* 录入顺序（与展开图一致）：黄、橙、蓝、红、绿、白
* 每面 9 个贴纸：从该面外侧看，行自上而下、列自左到右。
* 面的朝向由中心色决定，系统按标准配色放入固定坐标系
* （白底、黄顶、绿前、蓝后、红右、橙左）。

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE tblock1.

" —— 录入说明 ——
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(78) t_hint1.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(78) t_hint2.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(78) t_hint3.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.

" —— 六面录入 ——
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

" —— 一键填入复原态 ——
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON 5(20) bfill USER-COMMAND fill.
SELECTION-SCREEN COMMENT 28(60) t_fillnt.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b1.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE tblock2.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) t_test FOR FIELD p_test.
PARAMETERS p_test AS CHECKBOX.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b2.
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE tblock3.

" —— 打乱演示：按钮 + 说明一行，公式单独一行加长显示 ——
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON 5(20) bscram USER-COMMAND scram.
SELECTION-SCREEN COMMENT 28(60) t_note.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(14) t_scr FOR FIELD p_scram.
PARAMETERS p_scram TYPE c LENGTH 100 VISIBLE LENGTH 100.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b3.

*&---------------------------------------------------------------------*
*& Form FRM_INITIALIZATION：初始化屏幕文本
*&---------------------------------------------------------------------*
FORM frm_initialization.
  tblock1 = '魔方录入（每面 9 贴纸：黄橙蓝红绿白）'.
  t_hint1 = '录入说明：每面输入 9 个颜色字母（Y=黄 O=橙 B=蓝 R=红 G=绿 W=白），'.
  t_hint2 = '从该面正对魔方观察：行自上而下、列从左到右；中心贴纸决定面的朝向。'.
  t_hint3 = '示例：复原态黄色面 YYYYYYYYY；也可点下方按钮一键填入复原态。'.
  t_yellow = '黄色面'.
  t_orange = '橙色面'.
  t_blue = '蓝色面'.
  t_red = '红色面'.
  t_green = '绿色面'.
  t_white = '白色面'.
  bfill = '填入复原态示例'.
  t_fillnt = '六面填入复原态贴纸，可在此基础上修改'.

  tblock2 = '诊断'.
  t_test = '运行自检（引擎 / 校验 / 求解回归）'.

  tblock3 = '打乱演示'.
  bscram = '生成随机打乱公式'.
  t_note = '生成后回车：从复原态打乱后直接求解'.
  t_scr = '打乱公式:'.
ENDFORM.
