#INCLUDE "inkey.ch"
// #INCLUDE "getexit.Ch"

REQUEST DBFNSX

PROC TAPPSETUP()
    RDDSETDEFAULT( "DBFNSX" )

    SET( 4, "dd/mm/yyyy" )
    SET( 5, 1980 )
    SET( 32, "off" )
    __SETCENTURY( "on" )
    SET( 1, "on" )
    SETCOLOR( "W / N, N / W,,, W / N" )
    SETCURSOR( 1 )
RETURN

FUNC TINKEY( nSecs, bBloque )
    LOCAL nTime := SECONDS()
    LOCAL bSetKey
    LOCAL nKey

    HB_DEFAULT( @nSecs, 0 )

    IF nSecs == 0
        WHILE ( nKey := INKEY() ) == 0
            IF HB_ISBLOCK( bBloque )
                EVAL( bBloque )
            END
        END
    ELSE
        WHILE ( nKey := INKEY() ) == 0 .AND. ( SECONDS() - nTime ) < nSecs
            IF HB_ISBLOCK( bBloque )
                EVAL( bBloque )
            END
        END
    END

    IF ( bSetKey := SETKEY( nKey ) ) != nil
        EVAL( bSetKey, PROCNAME( 0 ), PROCLINE( 0 ), READVAR() )
        nKey := 0
    END
RETURN nKey
