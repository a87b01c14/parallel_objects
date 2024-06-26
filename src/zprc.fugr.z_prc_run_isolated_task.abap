FUNCTION Z_PRC_RUN_ISOLATED_TASK.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_PROCESS) TYPE  ZPRCE_DATA
*"     VALUE(IV_DELAY) TYPE  STRING OPTIONAL
*"  EXCEPTIONS
*"      PRC_PROCESS_FAILED
*"--------------------------------------------------------------------
*======================================================================*
* These objects were created by me: Hugo Armstrong, 2012               *
* Don't try to claim credit for my work. Modifying the objects may     *
* cause the entire package to break so that is not exactly recommended *
*                                                                      *
* hugo.armstrong@gmail.com                                             *
*======================================================================*
  data: lr_process type ref to zcl_prc_isolated_task.

  "... Deserialize the input object
  call transformation id_indent
     source xml iv_process
     result obj = lr_process.

  if iv_delay is not initial.
    wait up to iv_delay seconds.
  endif.

  "... Exceptions appropriately explode out
  lr_process->mr_runnable->run( ).





ENDFUNCTION.
