#INCLUDE "inkey.ch"

#DEFINE APPNAME "Project Manager"

PROC Main
    LOCAL aMenu := { ;
        { "1) Clients", {|| CLIENTSBROWSE() }, "" }, ;
        { "2) Projects", {|| PROJECTSBROWSE() }, "" } }

    LOCAL w := TWINDOW()

    TAPPSETUP()
    CHECKDATABASES()

    w:NEW( "Home", APPNAME )
    w:STATUS( "[ESC] Exit [ENTER] Select" )
    w:MENU( aMenu, 2, 3 )
    w:CLOSE()
RETURN

STATIC PROC CHECKDATABASES()
    LOCAL db

    db := TCREATEDBF():NEW( "clients.dbf" )
    db:IDFIELD()
    db:CHARFIELD( "name", 50 )
    db:CHARFIELD( "email", 120 )
    db:MEMOFIELD( "address" )
    db:CREATE()

    db := TCREATEDBF():NEW( "projects.dbf" )
    db:IDFIELD()
    db:IDFIELD( "id_client" )
    db:CHARFIELD( "name", 50 )
    db:DATEFIELD( "start_date" )
    db:DATEFIELD( "end_date" )
    db:MONEYFIELD( "rate" )
    db:MEMOFIELD( "notes" )
    db:CREATE()

    db := TDBF():OPEN( "clients" )
    db:ORDCREATE( "clients", "id", "id" )
    db:ORDCREATE( "clients", "name", "name" )
    db:CLOSE()

    db := TDBF():OPEN( "projects" )
    db:ORDCREATE( "projects", "id", "id" )
    db:ORDCREATE( "projects", "idclient", "id_client" )
    db:ORDCREATE( "projects", "startdate", "start_date" )
    db:CLOSE()
RETURN


PROC CLIENTSBROWSE()
    LOCAL w := TWINDOW()
    LOCAL brw := TDBBROWSE():NEW()
    LOCAL db := TDBF():OPEN( "clients", NIL, "clients", "name" )

    w:NEW( "Clients", APPNAME )
    w:STATUS( "[ESC] Exit [F2] Add [F3] Delete [ENTER] Edit [F7] Search [F8] Sort By" )

    db:GOTOP()
    brw:BORDER()
    brw:ADDCOL( "Id", "ID" )
    brw:ADDCOL( "Name", "NAME" )
    brw:ADDKEY( K_F2, {|| CLIENTAM( .T. ) } )
    brw:ADDKEY( K_ENTER, {|| CLIENTAM( .F. ) } )
    brw:EXEC( db )
    brw:PACKDB()

    db:CLOSE()
    w:CLOSE()
RETURN

STATIC PROC CLIENTAM( lAdd )
    LOCAL w := TWINDOW()
    LOCAL db := TDBF():OPEN( "clients" )
    LOCAL cCaption := IF( lAdd, "Add", "Edit" ) + " Client"
    LOCAL aRec := db:GETREC( lAdd )

    IF ! lAdd .AND. ! db:HASRECS()
        RETURN
    END

    IF lAdd
        aRec[ "ID" ] := db:NEXTID( "ID" )
    ELSE

    END

    w:NEW( cCaption, APPNAME, .T. )
    w:STATUS( "[ESC] Exit [F10] Edit Memo" )
    w:GET( 11, 02, "Id:", @aRec[ "ID" ], "ID",,, {|| .F. } )
    w:GET( 12, 02, "Name:", @aRec[ "NAME" ], "NAME", "@KS40" )
    w:GETMEMO( 13, 02, "Address:", @aRec[ "ADDRESS" ], "ADDRESS", "Edit Address", ;
        {|| w:SHOWMSG( 1, 14, 20, "[F10] Edit Notes" ) },  {|| w:HIDEMSG(1)} )
    w:GET( 14, 02, "Email:", @aRec[ "EMAIL" ], "EMAIL", "@KS40" )
    w:READ()

    IF LASTKEY() != K_ESC
        db:SAVEREC( aRec, lAdd )
    END

    w:CLOSE()
RETURN

PROC PROJECTSBROWSE()
    LOCAL w := TWINDOW()
    LOCAL brw := TDBBROWSE():NEW()
    LOCAL dbClient := TDBF():OPEN("clients" )
    LOCAL db := TDBF():OPEN( "projects", NIL, "projects", "startdate" )

    (dbClient )

    w:NEW( "Projects", APPNAME )
    w:STATUS( "[ESC] Exit [F2] Add [F3] Delete [ENTER] Edit [F7] Search [F8] Sort By" )

    db:GOTOP()
    brw:BORDER()
    brw:ADDCOL( "Id", "ID" )
    brw:ADDCOL( "Client #", "ID_CLIENT" )
    brw:ADDCOL( "Project Name", "name" )
    brw:ADDCOL( "Start Date", "start_date" )
    brw:ADDKEY( K_F2, {|| PROJECTAM( .T. ) } )
    brw:ADDKEY( K_ENTER, {|| PROJECTAM( .F. ) } )
    brw:EXEC( db )

    db:CLOSE()
    dbClient:CLOSE()
    w:CLOSE()
RETURN

STATIC PROC PROJECTAM( lAdd )
    LOCAL w := TWINDOW()
    LOCAL dbClient := TDBF():OPEN( "clients", NIL, "clients", "id" )
    LOCAL db := TDBF():OPEN( "projects" )
    LOCAL cCaption := IF( lAdd, "Add", "Edit" ) + " Project"
    LOCAL bList := {|| dbClient:GETTABLE( {|| dbClient:name }, ;
        {|| dbClient:ID }, "[ Select Client ]", ;
        {|| dbClient:GOTOP(), dbClient:SELECT() },, {|| db:SELECT()} ) }
    LOCAL aRec := db:GETREC( lAdd )

    IF ! lAdd .AND. db:LASTREC() <= 0
        RETURN
    END

    SET CURSOR ON

    IF lAdd
        aRec[ "ID" ] := db:NEXTID( "ID" )
        aRec[ "START_DATE" ] := DATE()
        aRec[ "END_DATE" ] := DATE()
    END

    w:NEW( cCaption, APPNAME, .T. )
    w:SETKEYFOR( K_F1, "ID_CLIENT", bList )
    w:STATUS( "[ESC] Exit" )
    w:GET( 11, 02, "Id:", @aRec[ "ID" ], "ID",,, {|| .F. } )
    w:GET( 12, 02, "Client #:", @aRec[ "ID_CLIENT" ], "ID_CLIENT",,, ;
        {|| w:SHOWMSG( 1, 13, 20, "[F1] Show the Client's list" ) }, ;
        {|| w:HIDEMSG(1), dbClient:LOOKUP( aRec[ "ID_CLIENT" ],, "ID", .T. ) } )
    w:GET( 13, 02, "Project Name:", @aRec[ "NAME" ], "NAME", "@KS40" )
    w:GET( 14, 02, "Start Date:", @aRec[ "START_DATE" ], "START_DATE", "@D" )
    w:GET( 15, 02, "End Date:", @aRec[ "END_DATE" ], "END_DATE", "@D" )
    w:GETMEMO( 16, 02, "Notes:", @aRec[ "NOTES" ], "NOTES", "Edit Project Notes", ;
        {|| w:SHOWMSG( 1, 17, 20, "[F10] Edit Notes" ) },  {|| w:HIDEMSG(1)} )
    w:GET( 17, 02, "Rate (USD/hr):", @aRec[ "RATE" ], "RATE", "@KS40" )
    w:READ()

    IF LASTKEY() != K_ESC
        db:SAVEREC( aRec, lAdd )
    END

    w:CLOSE()
RETURN
