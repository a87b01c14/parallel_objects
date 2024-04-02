*&---------------------------------------------------------------------*
*& Report  Z_PRC_BACKGROUND_PROCESS
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

report z_prc_background_job.

parameters: guid type sysuuid_x16, delay type string.

data: ls_bg type zprcd_background.

select single * from zprcd_background into ls_bg where guid = guid.

if sy-subrc ne 0.
  "... Jobs can NOT be re-run. They are ran once only
  "... re-runnable scheduled jobs should be created as normal
  "... that is not the purpose of this code
  raise exception type zcx_prc_process_failed.
else.
  "... We have our item to process now, its on!
  delete zprcd_background from ls_bg.
  commit work.
endif.

data: lr_process type ref to zcl_prc_background_job.

"... Deserialize the input object
call transformation id_indent
   source xml ls_bg-data
   result obj = lr_process.

if delay is not initial.
  wait up to delay seconds.
endif.

"... Exceptions appropriately explode out
lr_process->mr_runnable->run( ).
