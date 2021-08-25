*&---------------------------------------------------------------------*
*& 包含               Z_CFOP_OPERATE
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form FRM_SCRAMBLE
*&---------------------------------------------------------------------*
*& 打乱
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_SCRAMBLE .
  DATA: STRING_CUBE TYPE C LENGTH 54.
  DATA: LT_SIX_CUBE TYPE TABLE OF TY_CUBE.
  DATA: LS_CONVERTED_PERM TYPE TY_PERM.
  DATA: LT_CUBE_DICT TYPE TT_CUBE_DICT.
  DATA: SCRAMBLE TYPE C LENGTH 20.

  SCRAMBLE = '@Q!^BL%FRDQK^A#$FUK$'.

  CONCATENATE  'YYYYYYYYY'
               'OOOOOOOOO'
               'BBBBBBBBB'
               'RRRRRRRRR'
               'GGGGGGGGG'
               'WWWWWWWWW'
          INTO STRING_CUBE .

  PERFORM FRM_STRING_TO_SIX_CUBE CHANGING STRING_CUBE LT_SIX_CUBE.

  PERFORM FRM_SIX_CUBE_TO_PERM CHANGING LT_SIX_CUBE LS_CONVERTED_PERM.

  PERFORM FRM_SIX_PERM_TO_DICT CHANGING LS_CONVERTED_PERM LT_CUBE_DICT.

  PERFORM FRM_APPLY_ALG USING SCRAMBLE CHANGING LT_CUBE_DICT.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_STRING_TO_TT_CUBE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_CUBE
*&      --> LT_CUBE
*&---------------------------------------------------------------------*
FORM FRM_STRING_TO_SIX_CUBE  CHANGING STRING_CUBE
                                      PT_SIX_CUBE LIKE SIX_FACE.
  DATA: LS_SIX_LAYER TYPE TY_CUBE.
  DATA: OFF TYPE I VALUE 0,
        LEN TYPE I VALUE 9.
  DATA: LV_STRING_CUBE TYPE STRING.

  LV_STRING_CUBE = STRING_CUBE.

  DO 6 TIMES.
    DATA(LV_FACE) = LV_STRING_CUBE+OFF(LEN).
    LS_SIX_LAYER-FACE = LV_FACE+4(1).
    LS_SIX_LAYER-COLOR = LV_FACE.
    APPEND LS_SIX_LAYER TO PT_SIX_CUBE.
    OFF = OFF + 9.
  ENDDO.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_SIX_CUBE_TO_PERM
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LT_SIX_CUBE
*&      <-- CONVERTED_PERM
*&---------------------------------------------------------------------*
FORM FRM_SIX_CUBE_TO_PERM  CHANGING SIX_CUBE LIKE SIX_FACE
                                    PS_CONVERTED_PERM TYPE TY_PERM.

*  CONSTANTS SORTING TYPE C LENGTH 6 VALUE 'YOBRGW'.
  CONSTANTS SORTING TYPE C LENGTH 6 VALUE 'WOGRBY'.
  DATA: LV_INDEX TYPE I VALUE 0.
  DATA: LS_LINE TYPE TY_LINE,
        LT_LINE TYPE TABLE OF TY_LINE.

  DATA: LS_FACE TYPE TY_FACE,
        LT_FACE TYPE TABLE OF TY_FACE.
  DATA I  TYPE I.

  DO 6 TIMES.
    I = SY-INDEX.
    LV_INDEX = SY-INDEX - 1.
    DATA(LV_COLOR) = SORTING+LV_INDEX(1).
    READ TABLE SIX_CUBE ASSIGNING FIELD-SYMBOL(<FS_SIX>) WITH KEY FACE = LV_COLOR.
    IF SY-SUBRC = '0'.
      DO  3 TIMES.
        CASE SY-INDEX.
          WHEN 1.
            LS_LINE = <FS_SIX>-COLOR+0(3).
            LS_FACE-0 = LS_LINE.
          WHEN 2.
            LS_LINE = <FS_SIX>-COLOR+3(3).
            LS_FACE-1 = LS_LINE.
          WHEN 3.
            LS_LINE = <FS_SIX>-COLOR+6(3).
            LS_FACE-2 = LS_LINE.
        ENDCASE.
      ENDDO.
      ASSIGN COMPONENT I OF STRUCTURE PS_CONVERTED_PERM TO FIELD-SYMBOL(<FS_FACE>).
      IF SY-SUBRC = '0'.
        <FS_FACE> = LS_FACE.
      ENDIF.
    ENDIF.
  ENDDO.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_SIX_PERM_TO_DICT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LS_CONVERTED_PERM
*&      <-- LT_CUBE_DICT
*&---------------------------------------------------------------------*
FORM FRM_SIX_PERM_TO_DICT  CHANGING PS_CONVERTED_PERM TYPE TY_PERM
                                    PT_CUBE_DICT TYPE TT_CUBE_DICT.

  DATA: X TYPE I,
        Y TYPE I,
        Z TYPE I.
  DATA: I TYPE I,
        J TYPE I,
        K TYPE I.
  DATA: LS_CUBE_DICT TYPE TY_CUBE_DICT.

  FIELD-SYMBOLS:<FS_FACE>,
                <FS_LINE>,
                <FS_C>.

  DEFINE MACRO_TO_DICT.
    ASSIGN COMPONENT I OF STRUCTURE PS_CONVERTED_PERM TO <FS_FACE>.
    IF SY-SUBRC = '0'.
      ASSIGN COMPONENT J OF STRUCTURE <FS_FACE> TO <FS_LINE>.
      IF SY-SUBRC = '0'.
        ASSIGN COMPONENT K OF STRUCTURE <FS_LINE> TO <FS_C>.
        IF SY-SUBRC = '0'.
          &1 = <FS_C> .
        ENDIF.
      ENDIF.
    ENDIF.
  END-OF-DEFINITION.

  X = -1.
  DO 3 TIMES.
    Y = -1.
    DO 3 TIMES.
      Z = -1.
      DO 3 TIMES.
        LS_CUBE_DICT-X = X.
        LS_CUBE_DICT-Y = Y.
        LS_CUBE_DICT-Z = Z.
        CLEAR: I, J, K.
        IF LS_CUBE_DICT-X = 1.
          I = 3.
          J = ABS( LS_CUBE_DICT-Y - 1 ).
          K = ABS( LS_CUBE_DICT-Z - 1 ).
          MACRO_TO_DICT LS_CUBE_DICT-X_COLOR  .
        ELSEIF LS_CUBE_DICT-X = -1.
          I = 1.
          J = ABS( LS_CUBE_DICT-Y - 1 ).
          K = ABS( LS_CUBE_DICT-Z + 1 ).
          MACRO_TO_DICT LS_CUBE_DICT-X_COLOR.
        ENDIF.
        IF LS_CUBE_DICT-Y = 1.
          I = 0.
          J = ABS( LS_CUBE_DICT-Z + 1 ).
          K = ABS( LS_CUBE_DICT-X + 1 ).
          MACRO_TO_DICT LS_CUBE_DICT-Y_COLOR.
        ELSEIF LS_CUBE_DICT-Y = -1.
          I = 5.
          J = ABS( LS_CUBE_DICT-Z - 1 ).
          K = ABS( LS_CUBE_DICT-X + 1 ).
          MACRO_TO_DICT LS_CUBE_DICT-Y_COLOR.
        ENDIF.
        IF LS_CUBE_DICT-Z = 1.
          I = 2.
          J = ABS( LS_CUBE_DICT-Y - 1 ).
          K = ABS( LS_CUBE_DICT-X + 1 ).
          MACRO_TO_DICT LS_CUBE_DICT-Z_COLOR.
        ELSEIF LS_CUBE_DICT-Z = -1.
          I = 4.
          J = ABS( LS_CUBE_DICT-Y - 1 ).
          K = ABS( LS_CUBE_DICT-X - 1 ).
          MACRO_TO_DICT LS_CUBE_DICT-Z_COLOR.
        ENDIF.
        APPEND LS_CUBE_DICT TO PT_CUBE_DICT.
        CLEAR: LS_CUBE_DICT.
        Z = Z + 1.
      ENDDO.
      Y = Y + 1.
    ENDDO.
    X = X + 1.
  ENDDO.
  SORT PT_CUBE_DICT BY X Y Z ASCENDING.
  DELETE PT_CUBE_DICT WHERE X = 0 AND Y = 0 AND Z = 0 .
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_APPLY_ALG
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> SCRAMBLE
*&      <-- LT_CUBE_DICT
*&---------------------------------------------------------------------*
FORM FRM_APPLY_ALG  USING    PV_SCRAMBLE TYPE CHAR20
                    CHANGING PT_CUBE_DICT TYPE TT_CUBE_DICT.


ENDFORM.
