class ZCL_PRC_LOCK definition
  public
  final
  create public .

public section.

  class-methods ENQUEUE
    importing
      !KEY type STRING
      !WAIT type ABAP_BOOL default ABAP_FALSE
    raising
      ZCX_PRC_LOCKED
      ZCX_PRC_SYSTEM_FAILURE .
  class-methods DEQUEUE
    importing
      !KEY type STRING .
protected section.
private section.
ENDCLASS.



CLASS ZCL_PRC_LOCK IMPLEMENTATION.


method dequeue.
    data: lv_key type zprcd_lock_tab-lock_key.
    lv_key = key.
    call function 'DEQUEUE_EZPRC_LOCK'
      exporting
        lock_key = lv_key.
  endmethod.


method enqueue.
    data: lv_key type zprcd_lock_tab-lock_key.
    lv_key = key.
    call function 'ENQUEUE_EZPRC_LOCK'
      exporting
        lock_key       = lv_key
        _wait          = wait
        _scope         = '1'
      exceptions
        foreign_lock   = 1
        system_failure = 2
        others         = 3.

    case sy-subrc.
      when 1.
        raise exception type zcx_prc_locked.
      when 2 or 3.
        raise exception type zcx_prc_system_failure.
    endcase.
endmethod.
ENDCLASS.
