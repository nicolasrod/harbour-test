#INCLUDE "hbclass.ch"
#INCLUDE "inkey.ch"
#INCLUDE "getexit.ch"

CLASS TMemoField
    VAR oGet
    VAR cTitle
    VAR lReadOnly AS LOGICAL

    METHOD NEW( nRow, nCol, xVar, cTitle, nSize, lReadOnly )

    PROTECTED:

    METHOD READER( oGet )
    METHOD APPLYKEY( oGet, nKey )
END CLASS

METHOD NEW( nRow, nCol, xVar, cTitle, nSize, lReadOnly )
    LOCAL bVar := {| x | IIF( PCOUNT() < 1, xVar, xVar := x ), LEFT( xVar, HB_DEFAULTVALUE( nSize, 20 ) - 3 ) + "..." }

    ::cTitle := HB_DEFAULTVALUE( cTitle, "" )
    ::lReadOnly := HB_DEFAULTVALUE( lReadOnly, .F. )

    ::oGet := GETNEW( nRow, nCol, bVar )
    ::oGet:cargo := {| x | IIF( PCOUNT() < 1, xVar, xVar := x ) }
    ::oGet:reader := {| o | ::READER( o ) }
RETURN Self

METHOD READER( oGet )
    IF ! GETPREVALIDATE( oGet )
        RETURN NIL
    END

    SET( _SET_INSERT, .T. )
    oGet:SETFOCUS()

    WHILE oGet:exitState == GE_NOEXIT
        IF oGet:typeOut
            oGet:exitState := GE_ENTER
        END

        WHILE oGet:exitState == GE_NOEXIT
            ::APPLYKEY( oGet, TINKEY( 0 ) )
        END

        IF ( !GETPOSTVALIDATE( oGet ) )
            oGet:exitState := GE_NOEXIT
        END
    END
    oGet:KILLFOCUS()
RETURN NIL

METHOD APPLYKEY( oGet, nKey )
    LOCAL w, bKeyBlock
    LOCAL cText

    IF ( bKeyBlock := SETKEY( nKey ) ) != NIL
        GETDOSETKEY( bKeyBlock, oGet )
        RETURN NIL
    END

    DO CASE
    CASE nKey == K_UP .OR. nKey == K_SH_TAB
        oGet:exitState := GE_UP

    CASE nKey == K_DOWN .OR. nKey == K_TAB
        oGet:exitState := GE_DOWN

    CASE nKey == K_ENTER
        oGet:exitState := GE_DOWN

    CASE nKey == K_F10
        w := TWINDOW():NEW( ::cTitle,, .T. )
        w:SETKEY( K_F10, {|| __KEYBOARD( CHR( K_CTRL_W ) ) } )
        w:STATUS( "[ESC] Exit Without Saving [F10] Save and Exit" )
        w:BOX( NIL, 1, 0, MAXROW() - 1, MAXCOL() )

        cText := STRTRAN( EVAL( oGet:cargo ), CHR( 141 ) + CHR( 10 ), " " )
        EVAL( oGet:cargo, MEMOEDIT( cText, 2, 1, MAXROW() - 3,  MAXCOL() - 1, ! ::lReadOnly ) )
        w:CLOSE()

        oGet:KILLFOCUS()
        oGet:DISPLAY()
        oGet:SETFOCUS()

        oGet:exitState := GE_NOEXIT
    CASE nKey == K_ESC
        IF SET( _SET_ESCAPE )
            oGet:UNDO()
            oGet:exitState := GE_ESCAPE
        END

    CASE nKey == K_PGUP .OR. nKey == K_PGDN .OR. nKey == K_CTRL_W
        oGet:exitState := GE_WRITE

    CASE nKey == K_CTRL_HOME
        oGet:exitState := GE_TOP

    CASE nKey == K_INS
        SET( _SET_INSERT, !SET( _SET_INSERT ) )

        oGet:KILLFOCUS()
        oGet:DISPLAY()
        oGet:SETFOCUS()
    ENDCASE
RETURN NIL
