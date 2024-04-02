*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_ZPRCC_WP_CONFIG
*   generation date: 2023-02-16 at 09:10:12
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_ZPRCC_WP_CONFIG    .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
