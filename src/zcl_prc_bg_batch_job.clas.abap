class ZCL_PRC_BG_BATCH_JOB definition
  public
  create public .

public section.

  interfaces IF_SERIALIZABLE_OBJECT .

  data MR_RUNNABLE type ref to ZIF_PRC_RUNNABLE .

  methods CONSTRUCTOR
    importing
      !IR_RUNNABLE type ref to ZIF_PRC_RUNNABLE
      !IV_DELAY type STRING optional .
  methods START
    importing
      !SCHEDULE type ref to ZCL_PRC_JOB_SCHEDULE optional
    raising
      ZCX_PRC_PROCESS_EXCEPTION
      ZCX_PRC_WAIT_TIMOUT_EXCEPTION .
protected section.

  data MV_GROUP type STRING value ' ' ##NO_TEXT.
private section.

  data MV_DELAY type STRING .
  data MV_GUID type SYSUUID_X16 .
  data MR_SCHEDULE type ref to ZCL_PRC_JOB_SCHEDULE .
ENDCLASS.



CLASS ZCL_PRC_BG_BATCH_JOB IMPLEMENTATION.


method CONSTRUCTOR.
  mr_runnable = ir_runnable.
  mv_delay = iv_delay.
endmethod.                    "CONSTRUCTOR


method START.
  data: lr_processor type ref to lcl_processor.

  mr_schedule = schedule.

  create object lr_processor
    exporting
      ir_process = me.

  lr_processor->dispatch( ).
endmethod.                    "START
ENDCLASS.
