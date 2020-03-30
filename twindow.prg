#INCLUDE "hbclass.ch"
#INCLUDE "box.ch"
#INCLUDE "inkey.ch"

CLASS TWINDOW
    VAR aState AS ARRAY
    VAR hMsgs AS HASH INIT { => }
    VAR GetList AS ARRAY INIT {}

    METHOD NEW( cTitle, cAppName, lBorder )
    METHOD STATUS( cMsg )
    METHOD CLOSE()
    METHOD BOX( cCaption, nTop, nLeft, nBottom, nRight, lShadow )
    METHOD INFO( cText, nRow, cBox, lShadow )
    METHOD SAY( nRow, nCol, cText, cPict, cColor )
    METHOD GET( nRow, nCol, cText, xVar, cVar, cPict, cColor, bWhen, bValid )
    METHOD GETMEMO( nRow, nCol, cText, xVar, cVar, cTitle, bWhen, bValid, lReadOnly, nSize )
    METHOD GETREDISPLAY()
    METHOD READ()
    METHOD MENU( aItems, nTop, nLeft )
    METHOD SETKEY( nKey, bAction )
    METHOD SETKEYFOR( nKey, cGetName, bAction )
    METHOD SHOWMSG(nItem, nRow, nCol, acMsg, cColor )
    METHOD HIDEMSG(nItem )
END CLASS

METHOD SHOWMSG( nItem, nRow, nCol, acMsg, cColor )
    LOCAL aLineas := HB_ATOKENS( acMsg, ';' )
    LOCAL nLen := LEN( aLineas )
    LOCAL nRow2 := nRow + nLen + 1
    LOCAL nCol2 := 0
    LOCAL nPos := HB_HPOS(::hMsgs, nItem )

    HB_DEFAULT(@cColor, "W+/G" )

    IF nPos == 0
        AEVAL( aLineas, {| x | IF( LEN(x ) > nCol2, nCol2 := LEN(x ), ) } )
        nCol2 += 2 + nCol

        ::hMsgs[ nItem ] := { nItem, nRow, nCol, nRow2, nCol2, SAVESCREEN( nRow, nCol, nRow2, nCol2 ) }

        HB_DISPBOX( nRow, nCol, nRow2, nCol2, B_DOUBLE + ' ', cColor )
        nCol++
        AEVAL( aLineas, {| x | HB_DISPOUTAT( ++nRow, nCol, x, cColor ) } )
    END
RETURN .T.

METHOD HIDEMSG( nItem )
    LOCAL xItem := HB_HGETDEF(::hMsgs, nItem, NIL )

    IF xItem != NIL
        RESTSCREEN( xItem[ 2 ], xItem[ 3 ], xItem[ 4 ], xItem[ 5 ], xItem[ 6 ] )
        HB_HDEL(::hMsgs, nItem )
    END
RETURN .T.

METHOD GETREDISPLAY()
    AEVAL( ::GetList, {| o | o:DISPLAY() } )
RETURN NIL

METHOD SAY( nRow, nCol, cText, cPict, cColor ) CLASS TWINDOW
    DEVPOS( nRow, nCol )
    DEVOUTPICT( cText, cPict, cColor )
RETURN NIL

METHOD GET( nRow, nCol, cText, xVar, cVar, cPict, cColor, bWhen, bValid ) CLASS TWINDOW
    DEVPOS( nrow, nCol )

    IF HB_ISSTRING( cText )
        ::SAY( nRow, nCol, cText )
        SETPOS( ROW(), COL() + 1 )
    END

    AADD( ::GetList, _GET_( xVar, cVar, cPict, bValid, bWhen ) )

    IF HB_ISSTRING( cColor )
        ATAIL( ::GetList ):COLORDISP( cColor )
    END

    ATAIL( ::GetList ):DISPLAY()
RETURN NIL

METHOD GETMEMO( nRow, nCol, cText, xVar, cVar, cTitle, bWhen, ;
        bValid, lReadOnly, nSize ) CLASS TWINDOW
    IF HB_ISSTRING( cText )
        ::SAY( nRow, nCol, cText )
        SETPOS( ROW(), COL() + 1 )
    ELSE
        SETPOS( nRow, nCol )
    END

    AADD( ::GetList, TMEMOFIELD():NEW( ROW(), COL(), @xVar, cTitle, cVar, ;
        HB_DEFAULTVALUE(nSize,15 ), lReadOnly ):oGet )
    ATAIL( ::GetList ):preblock := HB_DEFAULTVALUE( bWhen, {|| .T. } )
    ATAIL( ::GetList ):postblock := HB_DEFAULTVALUE( bValid, {|| .T. } )
    ATAIL( ::GetList ):DISPLAY()
RETURN NIL

METHOD READ() CLASS TWINDOW
    LOCAL lUpdated := READMODAL( ::GetList, NIL,,,,, )
    ::GetList := {}
RETURN lUpdated

METHOD MENU( aItems, nTop, nLeft ) CLASS TWINDOW
    LOCAL nBottom := LEN( aItems ) + 1
    LOCAL nLong := LEN( TAFIND( aItems, {| x, y | LEN( x[ 1 ] ) > LEN( y[ 1 ] ) } )[ 1 ] )
    LOCAL w := TWINDOW():NEW()
    LOCAL nRight
    LOCAL nChoice
    LOCAL aItem

    HB_DEFAULT( @nTop, 6 )
    HB_DEFAULT( @nLeft, 5 )

    nRight := nLong + nLeft + 1
    nBottom += nTop

    SET MESSAGE TO MAXROW() - 1

    WHILE .T.
        DISPBEGIN()
        SETCOLOR( "W/B,N/W+" )
        HB_DISPBOX( nTop, nLeft, nBottom, nRight, B_DOUBLE, "W+/B" )
        HB_SHADOW( nTop, nLeft, nBottom, nRight )

        FOR EACH aItem in aItems
            __ATPROMPT( nTop + aItem:__ENUMINDEX(), nLeft + 1, PADR( aItem[ 1 ], nLong ), aItem[ 3 ] )
        NEXT
        DISPEND()
        MENU TO nChoice

        IF LASTKEY() == K_ESC
            EXIT
        END

        IF nChoice > 0
            IF HB_ISARRAY( aItems[ nChoice, 2 ] )
                ::MENU( aItems[ nChoice, 2 ], nTop + nChoice, nLeft + 6 )
            ELSE
                SETCOLOR( "W/B, N/W,,, W/N" )
                EVAL( aItems[ nChoice, 2 ] )
            END
        END
    END

    w:CLOSE()
RETURN NIL

METHOD NEW( cTitle, cAppName, lBorder ) CLASS TWINDOW
    ::aState := { SAVESCREEN(), SETCURSOR(), ROW(), COL(), SETCOLOR(), READINSERT(), HB_SETKEYSAVE() }

    IF cTitle != NIL
        DISPBEGIN()
        HB_DISPOUTAT( 0, 0, PADR( cTitle + " | " + HB_DEFAULTVALUE( cAppName, "" ), ;
            MAXCOL() - 10 ) + " | " + DTOC( DATE() ), "W+/BG" )
        ::STATUS( "" )
        HB_DISPBOX( 1, 0, MAXROW() - 1, MAXCOL(), REPLI( " ", 9 ), "B/B" )

        IF HB_DEFAULTVALUE( lBorder, .F. )
            HB_DISPBOX( 1, 0, MAXROW() - 1, MAXCOL(), B_DOUBLE, "W+/B" )
        END
        DISPEND()
    END
RETURN SELF

METHOD SETKEY( nKey, bAction ) CLASS TWINDOW
    SETKEY( nKey, bAction )
RETURN NIL

METHOD SETKEYFOR( nKey, cGetName, bAction ) CLASS TWINDOW
    ::SETKEY( nKey, {| oGet | oGet := GETACTIVE(), IF( oGet != NIL, ;
        IF( UPPER( oGet:NAME() ) == UPPER( cGetName ), ;
        EVAL( bAction, oGet ), NIL ), NIL ) } )
RETURN NIL

METHOD CLOSE() CLASS TWINDOW
    RESTSCREEN( NIL, NIL, NIL, NIL, ::aState[ 1 ] )
    SETCURSOR( ::aState[ 2 ] )
    DEVPOS( ::aState[ 3 ], ::aState[ 4 ] )
    SETCOLOR( ::aState[ 5 ] )
    READINSERT( ::aState[ 6 ] )
    HB_SETKEYSAVE( ::aState[ 7 ] )
RETURN NIL

METHOD STATUS( cMsg ) CLASS TWINDOW
    DISPBEGIN()
    HB_DISPOUTAT( MAXROW(), 0, PADR( cMsg, MAXCOL() + 1 ), "W+/R" )
    DISPEND()
RETURN NIL

METHOD BOX( cCaption, nTop, nLeft, nBottom, nRight, lShadow ) CLASS TWINDOW
    HB_DEFAULT( @nTop, 2 )
    HB_DEFAULT( @nLeft, 1 )
    HB_DEFAULT( @nBottom, MAXROW() - 2 )
    HB_DEFAULT( @nRight, MAXCOL() - 1 )
    HB_DEFAULT( @lShadow, .T. )

    DISPBEGIN()
    HB_DISPBOX( nTop, nLeft, nBottom, nRight, B_DOUBLE + " ", "W/B" )

    IF cCaption != NIL
        HB_DISPOUTAT( nTop, nLeft, SPACE( nRight - nLeft + 1 ), "W+/BG" )
        HB_DISPOUTAT( nTop, nLeft + 1, ALLTRIM( PADR( cCaption, nRight - nLeft - 5 ) ), "W+/BG" )
    END
    DISPEND()
RETURN NIL

METHOD INFO( cText, nRow, cBox, lShadow ) CLASS TWINDOW
    HB_DEFAULT( @nRow, MAXROW() / 2 )
    HB_DEFAULT( @cBox, B_DOUBLE + " " )
    HB_DEFAULT( @lShadow, .T. )

    cText := ALLTRIM( HB_DEFAULTVALUE( cText, "Please wait..." ) )

    DISPBEGIN()
    HB_DISPBOX( nRow - 1, 1, nRow + 1, MAXCOL() - 2, cBox, "W/G" )
    HB_DISPOUTAT( nRow, 3, PADR( cText, MIN( LEN( cText ), MAXCOL() - 3 ) ), "W+/G" )

    IF lShadow
        HB_SHADOW( nRow - 1, 1, nRow + 1, MAXCOL() - 1 )
    END
    DISPEND()
RETURN NIL

// =============================================================================

STATIC FUNC TAFIND( aItems, bCode )
    LOCAL xVal := aItems[ 1 ]

    AEVAL( aItems, {| xItem | xVal := IF( EVAL( bCode, xItem, xVal ), xItem, xVal ) } )
RETURN xVal
