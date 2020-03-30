#INCLUDE "hbclass.ch"
#INCLUDE "common.ch"
#INCLUDE "inkey.ch"

CLASS TDBF
    VAR nArea
    VAR aState

    METHOD OPEN( cName, cPath, cIndex, cOrder )
    METHOD CLOSE()
    METHOD GETREC( lBlank )
    METHOD SAVEREC( aRec, lAppend )
    METHOD LOOKUP( xExp, bAction, cnOrder, lExact )
    METHOD SETINDEX( cIdx )
    METHOD DELETE( bExp )
    METHOD RECNO( n )
    METHOD IDXDESTROY( cName )
    METHOD PUSHSTATE()
    METHOD POPSTATE( aOldState )
    METHOD NEXTID( cField, cOrder )
    METHOD GETIDXS( nMax )
    METHOD ORDCREATE( cIdx, cOrder, cExp, bExp, lUniq )
    METHOD ORDDESTROY( cOrder, cIdx )
    METHOD APPEND()
    METHOD GOBOTTOM()
    METHOD GOTOP()
    METHOD ISDELETED()
    METHOD RECALL()
    METHOD EOF()
    METHOD BOF()
    METHOD LASTREC()
    METHOD PACK()
    METHOD ISOPEN( cName )
    METHOD SEEK( cExp, lSoft )
    METHOD SKIP( nRecs )
    METHOD SELECT()
    METHOD SETORDER( cnOrd )
    METHOD ORDKEY( cnOrd )
    METHOD FIELDGET( cKey )
    METHOD FIELDPUT( cKey, xValue )
    METHOD GETTABLE( bLine, bGet, cCaption, bInit, bSearch, bEnd, lSendKey )
    METHOD HASRECS()

    ERROR HANDLER ONERROR( xParam )
ENDCLASS

METHOD GETTABLE( bLine, bGet, cCaption, bInit, bSearch, bEnd, lSendKey )
    LOCAL nLen := LEN( EVAL( bLine ) )
    LOCAL nLeft := 78 - nLen
    LOCAL cMsg := '[ESC] Exit [ENTER] Select Item'
    LOCAL brw := TDBBROWSE():NEW( 4, nLeft, 20, 77 )
    LOCAL w := TWINDOW():NEW()
    LOCAL s := ::PUSHSTATE()
    LOCAL xRet

    HB_DEFAULT( @lSendKey, .T. )
    HB_DEFAULT( @cCaption, " Select Item " )

    IF HB_ISBLOCK( bInit )
        EVAL( bInit )
    END

    brw:oBrw:COLSEP := ''
    brw:oBrw:HEADSEP := ''
    brw:oBrw:COLORSPEC := 'I, W/N'

    brw:ADDCOL( '', bLine )
    brw:READONLY()

    IF HB_ISBLOCK( bSearch )
        cMsg += ' [F7] Search'
        brw:ADDKEY( K_F7, bSearch )
    END

    w:STATUS( cMsg )
    brw:ADDKEY( K_ENTER, {|| xRet := HB_VALTOSTR( EVAL( bGet ) ), ;
        IF( lSendKey, __KEYBOARD( xRet + CHR(13 ) ), NIL ), - 1 } )
    brw:BORDER( cCaption )
    brw:EXEC()

    IF bEnd != nil
        EVAL( bEnd )
    END

    ::POPSTATE( s )
    w:CLOSE()
RETURN NIL

METHOD HASRECS()
RETURN ( ::nArea )->( LASTREC() ) > 0

METHOD ORDCREATE( cIdx, cOrder, cExp, bExp, lUniq )
    ( ::nArea )->( ORDCREATE( cIdx, cOrder, cExp, bExp, lUniq ) )
RETURN NIL

METHOD ORDDESTROY( cOrder, cIdx )
    ( ::nArea )->( ORDDESTROY( cOrder, cIdx ) )
RETURN NIL

METHOD APPEND()
    ( ::nArea )->( DBAPPEND() )
RETURN NIL

METHOD GOBOTTOM()
    ( ::nArea )->( DBGOBOTTOM() )
RETURN NIL

METHOD GOTOP()
    ( ::nArea )->( DBGOTOP() )
RETURN NIL

METHOD ISDELETED()
    ( ::nArea )->( DELETED() )
RETURN NIL

METHOD RECALL()
    ( ::nArea )->( DBRECALL() )
RETURN NIL

METHOD EOF()
RETURN ( ::nArea )->( EOF() )

METHOD BOF()
RETURN ( ::nArea )->( BOF() )

METHOD LASTREC()
RETURN ( ::nArea )->( LASTREC() )

METHOD PACK()
    ( ::nArea )->( __DBPACK() )
RETURN NIL

METHOD ISOPEN( cName )
RETURN SELECT( cName ) != 0

METHOD SEEK( cExp, lSoft )
RETURN ( ::nArea )->( DBSEEK( cExp, lSoft ) )

METHOD SKIP( nRecs )
RETURN ( ::nArea )->( DBSKIP( HB_DEFAULTVALUE( nRecs, 1 ) ) )

METHOD SELECT()
    DBSELECTAREA( ::nArea )
RETURN NIL

METHOD SETORDER( cnOrd )
    ( ::nArea )->( ORDSETFOCUS( cnOrd ) )
RETURN NIL

METHOD ORDKEY( cnOrd )
RETURN ( ::nArea )->( ORDKEY( HB_DEFAULTVALUE( cnOrd, 0 ) ) )

METHOD FIELDGET( cKey )
RETURN ( ::nArea )->( FIELDGET( ( ::nArea )->( FIELDPOS( cKey ) ) ) )

METHOD FIELDPUT( cKey, xValue )
    ( ::nArea )->( FIELDPUT( ( ::nArea )->( FIELDPOS( cKey ) ), xValue ) )
RETURN NIL

METHOD GETIDXS( nMax )
    LOCAL aOrders := {}
    LOCAL i
    LOCAL cOrder

    FOR i := 1 TO HB_DEFAULTVALUE( nMax, 200 )
        cOrder := ORDNAME( i )

        IF cOrder == ""
            EXIT
        END

        AADD( aOrders, cOrder )
    NEXT
RETURN aOrders

METHOD NEXTID( cField, cOrder )
    LOCAL nLast := 0

    HB_SYMBOL_UNUSED( nLast )

    ::PUSHSTATE()

    IF cOrder != nil
        ORDSETFOCUS( cOrder )
    END

    ( ::nArea )->( DBGOBOTTOM() )
    nLast := ( ::nArea )->( FIELDGET( ( ::nArea )->( FIELDPOS( cField ) ) ) )

    IF ! HB_ISNUMERIC( nLast )
        nLast := 0
    END

    ::POPSTATE()
RETURN nLast + 1

METHOD PUSHSTATE()
    LOCAL aOldState := ::aState

    IF ( ::nArea )->( USED() )
        ::aState := { ( ::nArea )->( SELECT() ), ( ::nArea )->( RECNO() ), ;
            ( ::nArea )->( INDEXORD() ), SET( _SET_SOFTSEEK ), SET( _SET_DELETED ) }
    END
RETURN aOldState

METHOD POPSTATE( aOldState )
    LOCAL aState := IF( HB_ISARRAY(aOldState ), aOldState, @::aState )

    IF HB_ISARRAY( aState )
        SET( _SET_SOFTSEEK, aState[ 4 ] )
        SET( _SET_DELETED, aState[ 5 ] )
        ( ::nArea )->( SELECT( aState[ 1 ] ) )
        ( ::nArea )->( DBGOTO( aState[ 2 ] ) )
        ( ::nArea )->( ORDSETFOCUS( aState[ 3 ] ) )
        aState := NIL
    END
RETURN NIL

METHOD IDXDESTROY( cName )
    LOCAL cIdx := cName + ORDBAGEXT()

    IF FILE( cIdx )
        FERASE( cIdx )
    END
RETURN NIL

METHOD DELETE( bExp )
    IF HB_ISBLOCK( bExp )
        ( ::nArea )->( DBEVAL( {|| DBDELETE() }, bExp,,,, .F. ) )
    ELSE
        ( ::nArea )->( DBDELETE() )
    END
RETURN NIL

METHOD GETREC( lBlank )
    LOCAL h := HB_HASH()
    LOCAL i

    ::PUSHSTATE()

    IF HB_DEFAULTVALUE( lBlank, .F. )
        ::GOBOTTOM()
        ::SKIP()
    END

    FOR i := 1 TO ( ::nArea )->( FCOUNT() )
        h[ ( ::nArea )->( FIELDNAME( i ) ) ] := ( ::nArea )->( FIELDGET( i ) )
    END

    ::POPSTATE()
RETURN h

METHOD SAVEREC( aRec, lAppend )
    LOCAL aKeys := HB_HKEYS( aRec )
    LOCAL cKey

    IF HB_DEFAULTVALUE( lAppend, .F. )
        ( ::nArea )->( DBAPPEND() )
    END

    FOR EACH cKey in aKeys
        ( ::nArea )->( FIELDPUT( ( ::nArea )->( FIELDPOS( cKey ) ), aRec[ cKey ] ) )
    NEXT
RETURN NIL

METHOD LOOKUP( xExp, bAction, cnOrder, lExact )
    LOCAL lFound := .F.
    LOCAL oldIdx := ( ::nArea )->( INDEXORD() )

    IF cnOrder != NIL
        ( ::nArea )->( ORDSETFOCUS( cnOrder ) )
    END

    IF ( ::nArea )->( DBSEEK( xExp, HB_DEFAULTVALUE( lExact, .F. ) ) )
        lFound := .T.

        IF bAction != NIL
            EVAL( bAction )
        END
    END

    ( ::nArea )->( ORDSETFOCUS( oldIdx ) )
RETURN lFound

METHOD SETINDEX( cIdx )
    IF HB_ISARRAY( cIdx )
        AEVAL( cIdx, {| x | ( ::nArea )->( DBSETINDEX( x ) ) } )
    ELSE
        ( ::nArea )->( ORDLISTADD( cIdx ) )
    END
RETURN NIL

METHOD OPEN( cName, cPath, cIndex, cOrder )
    LOCAL cFile

    HB_DEFAULT( @cPath, "" )

    IF ::ISOPEN( cName )
        ::nArea = SELECT( cName )
        DBSELECTAREA( ::nArea )
    ELSE
        IF cPath != ""
            cFile := cPath - HB_PS() - cName
        ELSE
            cFile := cName
        END

        DBSELECTAREA( "0" )
        ::nArea = SELECT()
        DBUSEAREA( .T.,, cFile, cName, .F., .F. )
    END

    IF cIndex != nil
        ORDLISTADD( cIndex )
    END

    IF cOrder != nil
        ORDSETFOCUS( cOrder )
    END
RETURN SELF

METHOD CLOSE()
    IF HB_ISNUMERIC( ::nArea )
        ( ::nArea )->( DBCLOSEAREA() )
    END
    ::nArea := NIL
RETURN NIL

METHOD RECNO( n )
    IF n != NIL
        ( ::nArea )->( DBGOTO( n ) )
    END
RETURN ( ::nArea )->( RECNO() )

METHOD ONERROR( xParam )
    LOCAL cMsg := __GETMESSAGE()
    LOCAL cFieldName
    LOCAL nPos

    IF LEFT( cMsg, 1 ) == "_"
        cFieldName := SUBSTR( cMsg, 2 )
    ELSE
        cFieldName := cMsg
    END

    IF ( nPos := ( ::nArea )->( FIELDPOS( cFieldName ) ) ) == 0
        ALERT( cFieldName + " wrong field name!" )
    ELSEIF cFieldName == cMsg
        RETURN ( ::nArea )->( FIELDGET( nPos ) )
    ELSE
        ( ::nArea )->( FIELDPUT( nPos, xParam ) )
    END
RETURN NIL
