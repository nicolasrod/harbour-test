#INCLUDE "hbclass.ch"

CLASS TCreateDBF
    VAR cName
    VAR aFields INIT {}

    METHOD NEW( cName )
    METHOD CREATE( lForce )

    METHOD CHARFIELD( cName, nLen )
    METHOD NUMBERFIELD( cName, nLen, nDec )
    METHOD DATEFIELD( cName )
    METHOD BOOLFIELD( cName )
    METHOD MEMOFIELD( cName )
    METHOD MONEYFIELD( cName )
    METHOD IDFIELD( cName )
END CLASS

METHOD NEW( cName )
    ::cName = cName
RETURN SELF

METHOD CREATE( lForce )
    IF ! FILE( ::cName ) .OR. HB_DEFAULTVALUE( lForce, .F. )
        DBCREATE( ::cName, ::aFields )
    END
RETURN NIL

METHOD CHARFIELD( cName, nLen )
    AADD( ::aFields, { cName, "C", HB_DEFAULTVALUE( nLen, 1 ), 0 } )
RETURN NIL

METHOD NUMBERFIELD( cName, nLen, nDec )
    AADD( ::aFields, {  cName, "N", nLen, HB_DEFAULTVALUE( nDec, 0 ) } )
RETURN NIL

METHOD DATEFIELD( cName )
    AADD( ::aFields, {  cName, "D", 8, 0 } )
RETURN NIL

METHOD BOOLFIELD( cName )
    AADD( ::aFields, {  cName, "L", 1, 0 } )
RETURN NIL

METHOD MEMOFIELD( cName )
    AADD( ::aFields, {  cName, "M", 10, 0 } )
RETURN NIL

METHOD MONEYFIELD( cName )
    AADD( ::aFields, {  cName, "N", 12, 2 } )
RETURN NIL

METHOD IDFIELD( cName )
    AADD( ::aFields, {  HB_DEFAULTVALUE( cName, "ID" ), "N", 10, 0 } )
RETURN NIL
