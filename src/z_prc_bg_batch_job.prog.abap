*&---------------------------------------------------------------------*
*& Report  Z_PRC_BACKGROUND_PROCESS
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

report z_prc_bg_batch_job.

data: ls_bg type zprcd_bg_batch.

get time stamp field data(lv_now).


do.
  select single * from zprcd_bg_batch into ls_bg where start_time lt lv_now.
  if sy-subrc ne 0.
    exit.
  endif.
  delete zprcd_bg_batch from ls_bg.
  commit work and wait.


  data: lr_process type ref to zcl_prc_bg_batch_job.

  "... Deserialize the input object
  call transformation id_indent
     source xml ls_bg-data
     result obj = lr_process.

  new zcl_prc_isolated_task( ir_runnable = lr_process->mr_runnable )->start(  ).
*  try.
*    "... Exceptions appropriately explode out
*    lr_process->mr_runnable->run( ).
*  endtry.

enddo.
