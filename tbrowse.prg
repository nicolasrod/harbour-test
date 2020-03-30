#INCLUDE "common.ch"
#INCLUDE "box.ch"
#INCLUDE "inkey.ch"
#INCLUDE "hbclass.ch"

CLASS TDbBrowse
    VAR oBrw
    VAR aOrders
    VAR cCaja
    VAR xClave
    VAR oDBF
    VAR nDeleted AS NUMERIC INIT 0
    VAR bWhen AS CODEBLOCK INIT {|| .T. }
    VAR bValid AS CODEBLOCK INIT {|| .T. }
    VAR bColor AS CODEBLOCK INIT {|| IF( DELETED(), { 3, 4 }, { 1, 2 } ) }
    VAR hKeys AS HASH INIT { ;
        K_DOWN => {| o | o:oBrw:DOWN() }, ;
        K_PGDN => {| o | o:oBrw:PAGEDOWN() }, ;
        K_CTRL_PGDN => {| o | o:oBrw:GOBOTTOM() }, ;
        K_UP => {| o | o:oBrw:UP() }, ;
        K_PGUP => {| o | o:oBrw:PAGEUP() }, ;
        K_CTRL_PGUP => {| o | o:oBrw:GOTOP() }, ;
        K_RIGHT => {| o | o:oBrw:RIGHT() }, ;
        K_LEFT => {| o | o:oBrw:LEFT() }, ;
        K_HOME => {| o | o:oBrw:HOME() }, ;
        K_END => {| o | o:oBrw:END() }, ;
        K_CTRL_LEFT => {| o | o:oBrw:PANLEFT() }, ;
        K_CTRL_RIGHT => {| o | o:oBrw:PANRIGHT() }, ;
        K_CTRL_HOME => {| o | o:oBrw:PANHOME() }, ;
        K_CTRL_END => {| o | o:oBrw:PANEND() }, ;
        K_F7 => {| o | o:SEARCH() }, ;
        K_F8 => {| o | o:CHANGEORDER() }, ;
        K_ENTER => {| o | o:EDITREC() }, ;
        K_F2 => {|| DBAPPEND() }, ;
        K_F3 => {| o | o:DELETEREC() }, ;
        K_ESC => {|| - 1 } }

    METHOD NEW( nTop, nLeft, nBottom, nRight )
    METHOD READONLY()
    METHOD STABLE()
    METHOD DELETEREC()
    METHOD BORDER( cTitle, cFooter, cBox )
    METHOD ADDDB()
    METHOD ADDRECNO()
    METHOD ADDKEY( nKey, bCode )
    METHOD DELETEKEY( nKey )
    METHOD EXEC( oDBF )
    METHOD EVALKEY( nKey )
    METHOD EDITREC()
    METHOD SEARCH()
    METHOD CHANGEORDER()
    METHOD MAKECOL( cHeader, xField )
    METHOD REFRESH()
    METHOD ADDCOL( cHeader, xField )
    METHOD ADDARRAY( aField )
    METHOD PACKDB()
END CLASS

METHOD NEW( nTop, nLeft, nBottom, nRight )
    LOCAL brw := TBROWSEDB( HB_DEFAULTVALUE( nTop, 2 ), ;
        HB_DEFAULTVALUE( nLeft, 1 ), HB_DEFAULTVALUE( nBottom, MAXROW() - 2 ), ;
        HB_DEFAULTVALUE( nRight, MAXCOL() - 1 ) )

    brw:COLORSPEC := "W+/B, W+/G, R+/B, BG, W"
    brw:HEADSEP := "-"
    brw:COLSEP := "|"
    ::oBrw = brw
RETURN Self

METHOD READONLY()
    ::DELETEKEY( K_ENTER )
    ::DELETEKEY( K_F2 )
    ::DELETEKEY( K_F3 )
    ::DELETEKEY( K_F7 )
    ::DELETEKEY( K_F8 )
RETURN Self

METHOD STABLE()
    ::oBrw:REFRESHCURRENT()

    WHILE NEXTKEY() == 0 .AND. ! ::oBrw:STABLE
        ::oBrw:STABILIZE()
    END
RETURN Self

METHOD DELETEREC()
    LOCAL lDelete := ALERT( "Delete Record?", { "Yes", "No" } ) == 1

    IF ! lDelete
        RETURN Self
    END

    IF DELETED()
        ::oDBF:RECALL()
        ::nDeleted--
    ELSE
        ::oDBF:DELETE()
        ::nDeleted++
    END
RETURN Self

METHOD BORDER( cTitle, cFooter, cBox )
    LOCAL nTop := ::oBrw:nTop
    LOCAL nLeft := ::oBrw:nLeft
    LOCAL nBottom := ::oBrw:nBottom
    LOCAL nRight := ::oBrw:nRight
    LOCAL cColor := ::oBrw:COLORSPEC

    DISPBEGIN()
    DISPBOX( nTop - 1, nLeft - 1, nBottom + 1, nRight + 1, ;
        HB_DEFAULTVALUE( cBox, B_DOUBLE + " " ), cColor )

    IF cTitle != NIL
        @ nTop - 1, nLeft SAY cTitle COLOR cColor
    END

    IF cFooter != NIL
        @ nBottom - 1, nLeft SAY cFooter COLOR cColor
    END
    DISPEND()
RETURN Self

METHOD ADDDB()
    LOCAL aFields := ARRAY( FCOUNT() )
    LOCAL oCol

    AEVAL( aFields, {| x, i, xField | x := x, xField := FIELD( i ), ;
        oCol := TBCOLUMNNEW( xField, FIELDWBLOCK( xField, SELECT() ) ), ;
        oCol:COLORBLOCK := ::bColor, ;
        ::oBrw:ADDCOLUMN( oCol ) } )
RETURN Self

METHOD ADDRECNO()
    LOCAL oCol := TBCOLUMNNEW( "#", {|| ::oDBF:RECNO() } )
    oCol:WIDTH := 6
    oCol:COLORBLOCK := ::bColor
    ::oBrw:ADDCOLUMN( oCol )
RETURN Self

METHOD ADDKEY( nKey, bCode )
    HB_HSET(::hKeys, nKey, bCode )
RETURN Self

METHOD DELETEKEY( nKey )
    IF nKey $ ::hKeys
        HB_HDEL( ::hKeys, nKey )
    END
RETURN Self

METHOD EXEC( oDBF )
    LOCAL w := TWINDOW():NEW()
    LOCAL xRet
    LOCAL nRow
    LOCAL nCol

    IF ! USED() .OR. ! EVAL( ::bWhen )
        RETURN -1
    END

    SET CURSOR ON
    ::oDBF := oDBF
    ::oBrw:REFRESHALL()

    WHILE .T.
        IF::oBrw:COLPOS <= ::oBrw:FREEZE
            ::oBrw:COLPOS := ::oBrw:FREEZE + 1
        END

        ::oBrw:REFRESHALL()
        ::oBrw:FORCESTABLE()

        nRow := ROW()
        nCol := COL()

        ::oBrw:COLORRECT( { ::oBrw:ROWPOS, 1, ::oBrw:ROWPOS, ::oBrw:COLCOUNT }, { 2, 2 } )
        SETPOS( nRow, nCol )

        xRet := ::EVALKEY( TINKEY() )

        IF HB_ISNUMERIC( xRet ) .AND. xRet == -1
            IF EVAL( ::bValid )
                EXIT
            END
        END
    END

    w:CLOSE()
RETURN 0

METHOD EVALKEY( nKey )
    IF nKey $ ::hKeys
        RETURN EVAL( HB_HGET(::hKeys, nKey ), Self )
    END
RETURN NIL

METHOD EDITREC()
    LOCAL w := TWINDOW():NEW()
    LOCAL bGetBlock := ::oBrw:GETCOLUMN( ::oBrw:COLPOS ):BLOCK
    LOCAL oGet := GETNEW( ROW(), COL(), bGetBlock, "" )

    IF LASTREC() > 0
        SET CURSOR ON
        READMODAL( { oGet } )
        ::REFRESH()
    END
    w:CLOSE()
RETURN Self

METHOD SEARCH()
    LOCAL w := TWINDOW():NEW()
    LOCAL cKey := ::oDBF:ORDKEY()
    LOCAL xGet

    IF EMPTY( cKey )
        RETURN Self
    END

    ::xClave := ::oDBF:FIELDGET( cKey )
    xGet := ::xClave
    cKey := IF( ::cCaja == NIL, cKey, ::cCaja )

    SET CURSOR ON
    w:BOX( PADR( cKey, 32 ), 15, 5, 17, 40 )
    w:GET( 16, 7, "Search:", xGet, "xGet", "@KS22" )
    w:READ()

    w:CLOSE()

    IF UPDATED()
        ::oDBF:GOTOP()
        ::oDBF:SEEK( xGet, .T. )
        ::REFRESH()
    END
RETURN Self

METHOD CHANGEORDER()
    LOCAL w := TWINDOW():NEW()
    LOCAL aOrders := ::oDBF:GETIDXS()
    LOCAL nIdx

    w:BOX( "Sort by", 9, 9, 21, 30, .T. )
    nIdx := ACHOICE( 10, 10, 20, 29, aOrders )
    IF nIdx == 0
        RETURN self
    END

    ORDSETFOCUS( aOrders[ nIdx ] )
    w:CLOSE()
    DBGOTOP()
RETURN Self

METHOD MAKECOL( cHeader, xField )
    LOCAL oCol

    IF xField != NIL
        DO CASE
        CASE HB_ISNUMERIC( xField )
            oCol := FIELDWBLOCK( FIELD( xField ), SELECT() )
        CASE HB_ISSTRING( xField )
            oCol := FIELDWBLOCK( xField, SELECT() )
        CASE HB_ISBLOCK( xField )
            oCol := xField
        ENDCASE

        oCol := TBCOLUMNNEW( cHeader, oCol )
        oCol:COLORBLOCK := {|| IF( DELETED(), { 3, 4 }, { 1, 2 } ) }
    END
RETURN oCol

METHOD REFRESH()
    ::oBrw:REFRESHALL()
    ::oBrw:FORCESTABLE()
RETURN Self

METHOD ADDCOL( cHeader, xField )
    ::oBrw:ADDCOLUMN( ::MAKECOL( cHeader, xField ) )
RETURN Self

METHOD ADDARRAY( aField )
    AEVAL( aField, {| x | ::ADDCOL( x[ 1 ], x[ 2 ] ) } )
RETURN Self

METHOD PACKDB()
    LOCAL w := TWINDOW():NEW()
    IF ::nDeleted > 0
        w:INFO( "Please wait, optimizing DBF file..." )
        __DBPACK()
        ::nDeleted := 0
    END
    w:CLOSE()
RETURN Self
