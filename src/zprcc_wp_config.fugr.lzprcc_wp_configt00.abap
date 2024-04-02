*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZPRCC_WP_CONFIG.................................*
DATA:  BEGIN OF STATUS_ZPRCC_WP_CONFIG               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZPRCC_WP_CONFIG               .
CONTROLS: TCTRL_ZPRCC_WP_CONFIG
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *ZPRCC_WP_CONFIG               .
TABLES: ZPRCC_WP_CONFIG                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
