*&---------------------------------------------------------------------*
*& 包含               Z_CFOP_TOP
*&---------------------------------------------------------------------*
  DATA: gv_cube TYPE c LENGTH 54.

  TYPES: BEGIN OF ty_cube,
           face  TYPE c,
           color TYPE c LENGTH 9,
         END OF ty_cube.
  DATA: six_face TYPE TABLE OF ty_cube.

*converted_perm
  TYPES: BEGIN OF ty_line,
           0 TYPE c,
           1 TYPE c,
           2 TYPE c,
         END OF ty_line.

  TYPES: BEGIN OF ty_face,
           0 TYPE ty_line,
           1 TYPE ty_line,
           2 TYPE ty_line,
         END OF ty_face.

  TYPES: BEGIN OF ty_perm,
           0 TYPE ty_face,
           1 TYPE ty_face,
           2 TYPE ty_face,
           3 TYPE ty_face,
           4 TYPE ty_face,
           5 TYPE ty_face,
         END OF ty_perm.
  DATA: converted_perm TYPE TABLE OF ty_perm.
*converted_perm

  "三维存储
  TYPES:BEGIN OF ty_cube_dict,
          x       TYPE i,
          y       TYPE i,
          z       TYPE i,
          x_color TYPE c,
          y_color TYPE c,
          z_color TYPE c,
        END OF ty_cube_dict,
        tt_cube_dict TYPE TABLE OF ty_cube_dict.
  DATA: cube_dict TYPE TABLE OF ty_cube_dict.

*---------------------------------------------------------*
*	ALG DICT
*---------------------------------------------------------*
* Used in Cube's turn_rotate method to use the correct indices of the cube when
* applying a turn or rotation.
  TYPES: BEGIN OF ty_scode,
           0 TYPE i,
           1 TYPE i,
           2 TYPE i,
           3 TYPE i,
           4 TYPE i,
           5 TYPE i,
           6 TYPE i,
           7 TYPE i,
         END OF ty_scode.
  TYPES: BEGIN OF ty_dict,
           ttype TYPE string,
           side  TYPE string,
           scode TYPE ty_scode,
         END OF ty_dict.

  DATA: param_dict TYPE TABLE OF ty_dict.

  TYPES: BEGIN OF ty_turn_dict,
           code  TYPE c,
           ttype TYPE string,
           side  TYPE c,
           bool  TYPE abap_bool,
         END OF ty_turn_dict.
  DATA: turn_dict TYPE TABLE OF ty_turn_dict.
