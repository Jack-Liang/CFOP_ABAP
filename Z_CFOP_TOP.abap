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
  TYPES: BEGIN OF TY_SCODE,
           0 TYPE I,
           1 TYPE I,
           2 TYPE I,
           3 TYPE I,
           4 TYPE I,
           5 TYPE I,
           6 TYPE I,
           7 TYPE I,
         END OF TY_SCODE.
  TYPES: BEGIN OF TY_DICT,
           TTYPE TYPE STRING,
           SIDE  TYPE STRING,
           SCODE TYPE TY_SCODE,
         END OF TY_DICT.

  DATA: PARAM_DICT TYPE TABLE OF TY_DICT.

  PARAM_DICT[] = VALUE #(
  "# Clockwise turns
  ( TTYPE = 'cw' SIDE = 'u'
    SCODE-0 = 1 SCODE-1 = 1 SCODE-2 = -1 SCODE-3 = 2 SCODE-4 = 1 SCODE-5 = 1 SCODE-6 = 1 SCODE-7 = 1 )
  ( TTYPE = 'cw' SIDE = 'd'
    SCODE-0 = 1 SCODE-1 = -1 SCODE-2 = 1 SCODE-3 = 2 SCODE-4 = 1 SCODE-5 = 1 SCODE-6 = -1 SCODE-7 = 0 )
  ( TTYPE = 'cw' SIDE = 'r'
    SCODE-0 = 0 SCODE-1 = 1 SCODE-2 = 1 SCODE-3 = 0 SCODE-4 = 1 SCODE-5 = 2 SCODE-6 = -1 SCODE-7 = 1  )
  ( TTYPE = 'cw' SIDE = 'l'
    SCODE-0 = 0 SCODE-1 = -1 SCODE-2 = 1 SCODE-3 = 0 SCODE-4 = -1 SCODE-5 = 2 SCODE-6 = 1 SCODE-7 = 1 )
  ( TTYPE = 'cw' SIDE = 'f'
    SCODE-0 = 2 SCODE-1 = 1 SCODE-2 = 1 SCODE-3 = 1 SCODE-4 = -1 SCODE-5 = 0 SCODE-6 = 1 SCODE-7 = 2  )
  ( TTYPE = 'cw' SIDE = 'b'
    SCODE-0 = 2 SCODE-1 = -1 SCODE-2 = -1 SCODE-3 = 1 SCODE-4 = 1 SCODE-5 = 0 SCODE-6 = 1 SCODE-7 = 2 )
"# Counterclockwise turns
  ( TTYPE = 'ccw' SIDE = 'u'
    SCODE-0 = 1 SCODE-1 = 1 SCODE-2 = 1 SCODE-3 = 2 SCODE-4 = 1 SCODE-5 = 1 SCODE-6 = -1 SCODE-7 = 0 )
  ( TTYPE = 'ccw' SIDE = 'd'
    SCODE-0 = 1 SCODE-1 = -1 SCODE-2 = -1 SCODE-3 = 2 SCODE-4 = 1 SCODE-5 = 1 SCODE-6 = 1 SCODE-7 = 0 )
  ( TTYPE = 'ccw' SIDE = 'r'
    SCODE-0 = 0 SCODE-1 = 1 SCODE-2 = 1 SCODE-3 = 0 SCODE-4 = -1 SCODE-5 = 2 SCODE-6 = 1 SCODE-7 = 1 )
  ( TTYPE = 'ccw' SIDE = 'l'
    SCODE-0 = 0 SCODE-1 = 1 SCODE-2 = 1 SCODE-3 = 0 SCODE-4 = 1 SCODE-5 = 2 SCODE-6 = -1 SCODE-7 = 1 )
  ( TTYPE = 'ccw' SIDE = 'f'
    SCODE-0 = 2 SCODE-1 = 1 SCODE-2 = -1 SCODE-3 = 1 SCODE-4 = 1 SCODE-5 = 0 SCODE-6 = 1 SCODE-7 = 2 )
  ( TTYPE = 'ccw' SIDE = 'b'
    SCODE-0 = 2 SCODE-1 = -1 SCODE-2 = 1 SCODE-3 = 1 SCODE-4 = -1 SCODE-5 = 0 SCODE-6 = 1 SCODE-7 = 2 )
"# Double turns (180 degrees)

  ).
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

  TYPES: BEGIN OF TY_TURN_DICT,
           CODE  TYPE C,
           TTYPE TYPE STRING,
           SIDE  TYPE C,
           BOOL  TYPE ABAP_BOOL,
         END OF TY_TURN_DICT.
  DATA: TURN_DICT TYPE TABLE OF TY_TURN_DICT.
  TURN_DICT[] = VALUE #(
"Single layer turns
  ( CODE = 'U' TTYPE = 'cw'  SIDE =  'u' BOOL = ABAP_FALSE )
  ( CODE = 'T' TTYPE = 'ccw' SIDE =  'u' BOOL = ABAP_FALSE )
  ( CODE = '!' TTYPE = 'dt'  SIDE =  'u' BOOL = ABAP_FALSE )
  ( CODE = 'L' TTYPE = 'cw'  SIDE =  'l' BOOL = ABAP_FALSE )
  ( CODE = 'K' TTYPE = 'ccw' SIDE =  'l' BOOL = ABAP_FALSE )
  ( CODE = '@' TTYPE = 'dt'  SIDE =  'l' BOOL = ABAP_FALSE )
  ( CODE = 'F' TTYPE = 'cw'  SIDE =  'f' BOOL = ABAP_FALSE )
  ( CODE = 'E' TTYPE = 'ccw' SIDE =  'f' BOOL = ABAP_FALSE )
  ( CODE = '#' TTYPE = 'dt'  SIDE =  'f' BOOL = ABAP_FALSE )
  ( CODE = 'R' TTYPE = 'cw'  SIDE =  'r' BOOL = ABAP_FALSE )
  ( CODE = 'Q' TTYPE = 'ccw' SIDE =  'r' BOOL = ABAP_FALSE )
  ( CODE = '$' TTYPE = 'dt'  SIDE =  'r' BOOL = ABAP_FALSE )
  ( CODE = 'B' TTYPE = 'cw'  SIDE =  'b' BOOL = ABAP_FALSE )
  ( CODE = 'A' TTYPE = 'ccw' SIDE =  'b' BOOL = ABAP_FALSE )
  ( CODE = '%' TTYPE = 'dt'  SIDE =  'b' BOOL = ABAP_FALSE )
  ( CODE = 'D' TTYPE = 'cw'  SIDE =  'd' BOOL = ABAP_FALSE )
  ( CODE = 'C' TTYPE = 'ccw' SIDE =  'd' BOOL = ABAP_FALSE )
  ( CODE = '^' TTYPE = 'dt'  SIDE =  'd' BOOL = ABAP_FALSE )
  ( CODE = 'M' TTYPE = 'cw'  SIDE =  'm' BOOL = ABAP_FALSE )
  ( CODE = 'm' TTYPE = 'ccw' SIDE =  'm' BOOL = ABAP_FALSE )
  ( CODE = '7' TTYPE = 'dt'  SIDE =  'm' BOOL = ABAP_FALSE )
  "DOUBLE LAYER TURNS
  ( CODE = 'u' TTYPE = 'cw'   SIDE =  'u' BOOL = ABAP_TRUE )
  ( CODE = 't' TTYPE = 'ccw'  SIDE =  'u' BOOL = ABAP_TRUE )
  ( CODE = '1' TTYPE = 'dt'   SIDE =  'u' BOOL = ABAP_TRUE )
  ( CODE = 'l' TTYPE = 'cw'   SIDE =  'l' BOOL = ABAP_TRUE )
  ( CODE = 'k' TTYPE = 'ccw'  SIDE =  'l' BOOL = ABAP_TRUE )
  ( CODE = '2' TTYPE = 'dt'   SIDE =  'l' BOOL = ABAP_TRUE )
  ( CODE = 'f' TTYPE = 'cw'   SIDE =  'f' BOOL = ABAP_TRUE )
  ( CODE = 'e' TTYPE = 'ccw'  SIDE =  'f' BOOL = ABAP_TRUE )
  ( CODE = '3' TTYPE = 'dt'   SIDE =  'f' BOOL = ABAP_TRUE )
  ( CODE = 'r' TTYPE = 'cw'   SIDE =  'r' BOOL = ABAP_TRUE )
  ( CODE = 'q' TTYPE = 'ccw'  SIDE =  'r' BOOL = ABAP_TRUE )
  ( CODE = '4' TTYPE = 'dt'   SIDE =  'r' BOOL = ABAP_TRUE )
  ( CODE = 'b' TTYPE = 'cw'   SIDE =  'b' BOOL = ABAP_TRUE )
  ( CODE = 'a' TTYPE = 'ccw'  SIDE =  'b' BOOL = ABAP_TRUE )
  ( CODE = '5' TTYPE = 'dt'   SIDE =  'b' BOOL = ABAP_TRUE )
  ( CODE = 'd' TTYPE = 'cw'   SIDE =  'd' BOOL = ABAP_TRUE )
  ( CODE = 'c' TTYPE = 'ccw'  SIDE =  'd' BOOL = ABAP_TRUE )
  ( CODE = '6' TTYPE = 'dt'   SIDE =  'd' BOOL = ABAP_TRUE )
  "ROTATIONS
  ( CODE = 'x' TTYPE = 'cw'    SIDE =  'x' BOOL = ABAP_FALSE )
  ( CODE = 'X' TTYPE = 'ccw'   SIDE =  'x' BOOL = ABAP_FALSE )
  ( CODE = '8' TTYPE = 'dt'    SIDE =  'x' BOOL = ABAP_FALSE )
  ( CODE = 'y' TTYPE = 'cw'    SIDE =  'y' BOOL = ABAP_FALSE )
  ( CODE = 'Y' TTYPE = 'ccw'   SIDE =  'y' BOOL = ABAP_FALSE )
  ( CODE = '9' TTYPE = 'dt'    SIDE =  'y' BOOL = ABAP_FALSE )
  ( CODE = 'z' TTYPE = 'cw'    SIDE =  'z' BOOL = ABAP_FALSE )
  ( CODE = 'Z' TTYPE = 'ccw'   SIDE =  'z' BOOL = ABAP_FALSE )
  ( CODE = '0' TTYPE = 'dt'    SIDE =  'z' BOOL = ABAP_FALSE )
  ).


*'''
*Used in Cube's and CrossEdges's apply_alg methods to conver from the code
*syntax for turns to actually applying the turns.
*'''
*TURN_DICT = {
*    # Single layer turns
*    'U': ['cw', 'u'], 'T': ['ccw', 'u'], '!': ['dt', 'u'],
*    'L': ['cw', 'l'], 'K': ['ccw', 'l'], '@': ['dt', 'l'],
*    'F': ['cw', 'f'], 'E': ['ccw', 'f'], '#': ['dt', 'f'],
*    'R': ['cw', 'r'], 'Q': ['ccw', 'r'], '$': ['dt', 'r'],
*    'B': ['cw', 'b'], 'A': ['ccw', 'b'], '%': ['dt', 'b'],
*    'D': ['cw', 'd'], 'C': ['ccw', 'd'], '^': ['dt', 'd'],
*    'M': ['cw', 'm'], 'm': ['ccw', 'm'], '7': ['dt', 'm'],
*
*    # Double layer turns
*    'u': ['cw', 'u', True], 't': ['ccw', 'u', True], '1': ['dt', 'u', True],
*    'l': ['cw', 'l', True], 'k': ['ccw', 'l', True], '2': ['dt', 'l', True],
*    'f': ['cw', 'f', True], 'e': ['ccw', 'f', True], '3': ['dt', 'f', True],
*    'r': ['cw', 'r', True], 'q': ['ccw', 'r', True], '4': ['dt', 'r', True],
*    'b': ['cw', 'b', True], 'a': ['ccw', 'b', True], '5': ['dt', 'b', True],
*    'd': ['cw', 'd', True], 'c': ['ccw', 'd', True], '6': ['dt', 'd', True],
*
*    # Rotations
*    'x': ['cw', 'x'], 'X': ['ccw', 'x'], '8': ['dt', 'x'],
*    'y': ['cw', 'y'], 'Y': ['ccw', 'y'], '9': ['dt', 'y'],
*    'z': ['cw', 'z'], 'Z': ['ccw', 'z'], '0': ['dt', 'z']
*}
