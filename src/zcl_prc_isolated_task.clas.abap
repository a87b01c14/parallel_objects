class ZCL_PRC_ISOLATED_TASK definition
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
    raising
      ZCX_PRC_PROCESS_EXCEPTION
      ZCX_PRC_WAIT_TIMOUT_EXCEPTION .
protected section.
private section.

  data MV_TIMEOUT type I value 299 ##NO_TEXT.
  data MV_DELAY type STRING .
ENDCLASS.



CLASS ZCL_PRC_ISOLATED_TASK IMPLEMENTATION.


method constructor.
  data: lv_p type p decimals 2.
  lv_p = iv_delay.
  if lv_p gt 45.
    raise exception type zcx_prc_excessive_delay.
  endif.
  mr_runnable = ir_runnable.
  mv_delay = iv_delay.
endmethod.                    "CONSTRUCTOR


method START.
    data: lr_processor type ref to lcl_processor.

    create object lr_processor
      exporting
        ir_process = me.

    lr_processor->dispatch( ).
  endmethod.                    "START
ENDCLASS.
