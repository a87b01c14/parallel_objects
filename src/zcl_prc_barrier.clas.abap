class ZCL_PRC_BARRIER definition
  public
  final
  create private .

public section.

  class-methods WAIT
    importing
      !IV_TIMEOUT type I default 86400
    raising
      ZCX_PRC_WAIT_TIMOUT_EXCEPTION .
protected section.
private section.
ENDCLASS.



CLASS ZCL_PRC_BARRIER IMPLEMENTATION.


method wait.
  data lv_time type t.
  "... Even if this times out there is no guarantee the processes
  "... executing wont just finish what they are doing
  get time field lv_time.
  while zcl_prc_monitor=>has_processes( ) eq abap_true.
    get time.
    if ( ( sy-uzeit - lv_time ) mod 86400 ) gt iv_timeout.
      raise exception type zcx_prc_wait_timout_exception.
    endif.
  endwhile.
endmethod.
ENDCLASS.
