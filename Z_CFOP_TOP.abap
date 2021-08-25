*&---------------------------------------------------------------------*
*& 包含               Z_CFOP_TOP
*&---------------------------------------------------------------------*
  DATA: GV_CUBE TYPE C LENGTH 54.

  TYPES: BEGIN OF TY_CUBE,
           FACE  TYPE C,
           COLOR TYPE C LENGTH 9,
         END OF TY_CUBE.
  DATA: SIX_FACE TYPE TABLE OF TY_CUBE.

*converted_perm
  TYPES: BEGIN OF TY_LINE,
           0 TYPE C,
           1 TYPE C,
           2 TYPE C,
         END OF TY_LINE.

  TYPES: BEGIN OF TY_FACE,
           0 TYPE TY_LINE,
           1 TYPE TY_LINE,
           2 TYPE TY_LINE,
         END OF TY_FACE.

  TYPES: BEGIN OF TY_PERM,
           0 TYPE TY_FACE,
           1 TYPE TY_FACE,
           2 TYPE TY_FACE,
           3 TYPE TY_FACE,
           4 TYPE TY_FACE,
           5 TYPE TY_FACE,
         END OF TY_PERM.
  DATA: CONVERTED_PERM TYPE TABLE OF TY_PERM.
*converted_perm

  "三维存储
  TYPES:BEGIN OF TY_CUBE_DICT,
          X       TYPE I,
          Y       TYPE I,
          Z       TYPE I,
          X_COLOR TYPE C,
          Y_COLOR TYPE C,
          Z_COLOR TYPE C,
        END OF TY_CUBE_DICT,
        TT_CUBE_DICT TYPE TABLE OF TY_CUBE_DICT.
  DATA: CUBE_DICT TYPE TABLE OF TY_CUBE_DICT.

*---------------------------------------------------------*
*	ALG DICT
*---------------------------------------------------------*
* Used in Cube's turn_rotate method to use the correct indices of the cube when
* applying a turn or rotation.
*TYPES: BEGIN OF TY_DICT,
*
*PARAM_DICT = {
*    # Clockwise turns
*    'cw': {
*        'u': [1, 1, -1, 2,  1, 1,  1, 0], 'd': [1, -1,  1, 2,  1, 1, -1, 0],
*        'r': [0, 1,  1, 0,  1, 2, -1, 1], 'l': [0, -1,  1, 0, -1, 2,  1, 1],
*        'f': [2, 1,  1, 1, -1, 0,  1, 2], 'b': [2, -1, -1, 1,  1, 0,  1, 2]},
*
*    # Counterclockwise turns
*    'ccw': {
*        'u': [1, 1,  1, 2,  1, 1, -1, 0], 'd': [1, -1, -1, 2,  1, 1,  1, 0],
*        'r': [0, 1,  1, 0, -1, 2,  1, 1], 'l': [0, -1,  1, 0,  1, 2, -1, 1],
*        'f': [2, 1, -1, 1,  1, 0,  1, 2], 'b': [2, -1,  1, 1, -1, 0,  1, 2]},
*
*    # Double turns (180 degrees)
*    'dt': {
*        'u': [1, 1, -1, 0,  1, 1, -1, 2], 'd': [1, -1, -1, 0,  1, 1, -1, 2],
*        'r': [0, 1,  1, 0, -1, 1, -1, 2], 'l': [0, -1,  1, 0, -1, 1, -1, 2],
*        'f': [2, 1, -1, 0, -1, 1,  1, 2], 'b': [2, -1, -1, 0, -1, 1,  1, 2]}
*}
