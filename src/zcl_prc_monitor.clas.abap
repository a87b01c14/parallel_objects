class ZCL_PRC_MONITOR definition
  public
  final
  create private .

public section.

  class-methods REGISTER_PID
    returning
      value(RV_PID) type CHAR8
    raising
      ZCX_PRC_NO_PROCESSES_AVAIL .
  class-methods DEREGISTER_PID
    importing
      !IV_PID type CHAR8 .
  class-methods ATTACH_WP
    importing
      !IV_PID type CHAR8 .
  class-methods PID_EXISTS
    importing
      !IV_PID type CHAR8
    returning
      value(RV_EXISTS) type ABAP_BOOL .
  class-methods HAS_PROCESSES
    returning
      value(RV_RESULT) type ABAP_BOOL .
  class-methods MAX_WORK_PROCESSES
    importing
      !IV_NUM type I .
  class-methods GET_WP_AVAIL
    returning
      value(RV_WP_AVAIL) type I .
protected section.
private section.

  class-methods GARBAGE_COLLECT
    importing
      !IV_BYPASS_LONGCHK type ABAP_BOOL default ABAP_FALSE .
ENDCLASS.



CLASS ZCL_PRC_MONITOR IMPLEMENTATION.


method attach_wp.
    data: lr_area type ref to zcl_prc_monitor_area,
          lr_monitor type ref to zcl_prc_monitor_access,
          lr_exc type ref to cx_shm_attach_error,
          lv_time type t.

    get time field lv_time.
    do.
      try.
          lr_area = zcl_prc_monitor_area=>attach_for_update( 'ZCL_PRC_MONITOR_AREA' ).
          exit. "... Exit Do
        catch cx_shm_exclusive_lock_active
              cx_shm_version_limit_exceeded
              cx_shm_change_lock_active
              cx_shm_read_lock_active
              cx_shm_no_active_version into lr_exc.
          get time.
          "... 1hr Retry(pretty extreme)
          if ( ( sy-uzeit - lv_time ) mod 86400 ) gt 3600.
            raise exception type zcx_prc_wait_timout_exception.
          endif.
      endtry.
    enddo.

    "... Check for previous success
    check lr_area is not initial and lr_area->root is not initial.
    lr_monitor = lr_area->root.

    lr_monitor->attach_wp( iv_pid ).
    lr_area->detach_commit( ).
  endmethod.


method deregister_pid.
    data: lr_area type ref to zcl_prc_monitor_area,
          lr_monitor type ref to zcl_prc_monitor_access,
          lr_exc type ref to cx_shm_attach_error,
          lv_time type t.

    get time field lv_time.
    do.
      try.
          lr_area = zcl_prc_monitor_area=>attach_for_update( 'ZCL_PRC_MONITOR_AREA' ).
          exit. "... Exit Do
      catch cx_shm_exclusive_lock_active
            cx_shm_version_limit_exceeded
            cx_shm_change_lock_active
            cx_shm_read_lock_active
            cx_shm_no_active_version into lr_exc.
          get time.
          "... 1hr Retry(pretty extreme)
          if ( ( sy-uzeit - lv_time ) mod 86400 ) gt 3600.
            raise exception type zcx_prc_wait_timout_exception.
          endif.
      endtry.
    enddo.

    "... Check for previous success
    check lr_area is not initial and lr_area->root is not initial.
    lr_monitor = lr_area->root.

    lr_monitor->deregister_pid( iv_pid ).
    lr_area->detach_commit( ).
  endmethod.                    "DEREGISTER_PID


method garbage_collect.
    data: lr_area type ref to zcl_prc_monitor_area,
          lr_monitor type ref to zcl_prc_monitor_access,
          lr_exc type ref to cx_shm_attach_error,
          lv_time type t.

    get time field lv_time.
    do.
      try.
          lr_area = zcl_prc_monitor_area=>attach_for_update( 'ZCL_PRC_MONITOR_AREA' ).
          exit. "... Exit Do
        catch cx_shm_exclusive_lock_active
              cx_shm_version_limit_exceeded
              cx_shm_change_lock_active
              cx_shm_read_lock_active
              cx_shm_no_active_version into lr_exc.
          get time.
          "... 1hr Retry(pretty extreme)
          if ( ( sy-uzeit - lv_time ) mod 86400 ) gt 3600.
            raise exception type zcx_prc_wait_timout_exception.
          endif.
      endtry.
    enddo.

    "... Check for previous success
    check lr_area is not initial and lr_area->root is not initial.
    lr_monitor = lr_area->root.

    lr_monitor->garbage_collect( iv_bypass_longchk ).
    lr_area->detach_commit( ).
  endmethod.


method get_wp_avail.
  data: lr_area type ref to zcl_prc_monitor_area,
        lr_monitor type ref to zcl_prc_monitor_access,
        lr_exc type ref to cx_shm_attach_error,
        rv_cleaned type abap_bool,
        lv_time type t.

  "... Do any GC first
  garbage_collect( ).

  get time field lv_time.
  do.
    try.
        lr_area = zcl_prc_monitor_area=>attach_for_read( 'ZCL_PRC_MONITOR_AREA' ).
        exit. "... Exit Do
      catch cx_shm_exclusive_lock_active
            cx_shm_version_limit_exceeded
            cx_shm_change_lock_active
            cx_shm_read_lock_active
            cx_shm_no_active_version into lr_exc.
        get time.
        "... 1hr Retry(pretty extreme)
        if ( ( sy-uzeit - lv_time ) mod 86400 ) gt 3600.
          raise exception type zcx_prc_wait_timout_exception.
        endif.
    endtry.
  enddo.

  "... Check for previous success
  check lr_area is not initial and lr_area->root is not initial.
  lr_monitor = lr_area->root.

  rv_wp_avail = lr_monitor->get_wp_avail( ).
  lr_area->detach( ).

  case rv_wp_avail.
    when -1. "... Not initialised
      "... Initialise the work processes to default, can return that value here
      rv_wp_avail = zcl_prc_wp_manager=>get_max_work_processes( ).
      max_work_processes( rv_wp_avail ).
    when 0.
      garbage_collect( ).
  endcase.
endmethod.


method has_processes.
  data: lr_area type ref to zcl_prc_monitor_area,
        lr_monitor type ref to zcl_prc_monitor_access,
          lr_exc type ref to cx_shm_attach_error,
          lv_time type t.

  "... Do any GC first(bypassing the time wait)
  garbage_collect( abap_true ).

  get time field lv_time.
  do.
    try.
        lr_area = zcl_prc_monitor_area=>attach_for_read( 'ZCL_PRC_MONITOR_AREA' ).
        exit. "... Exit Do
      catch cx_shm_exclusive_lock_active
            cx_shm_version_limit_exceeded
            cx_shm_change_lock_active
            cx_shm_read_lock_active
            cx_shm_no_active_version into lr_exc.
        get time.
        "... 1hr Retry(pretty extreme)
        if ( ( sy-uzeit - lv_time ) mod 86400 ) gt 3600.
          raise exception type zcx_prc_wait_timout_exception.
        endif.
    endtry.
  enddo.

  "... Check for previous success
  check lr_area is not initial and lr_area->root is not initial.
  lr_monitor = lr_area->root.

  rv_result = lr_monitor->has_processes( ).
  lr_area->detach( ).

endmethod.


method max_work_processes.
  data: lr_area type ref to zcl_prc_monitor_area,
        lr_monitor type ref to zcl_prc_monitor_access,
        lr_exc type ref to cx_shm_attach_error,
        lv_time type t.

  get time field lv_time.
  do.
    try.
        lr_area = zcl_prc_monitor_area=>attach_for_update( 'ZCL_PRC_MONITOR_AREA' ).
        exit. "... Exit Do
      catch cx_shm_exclusive_lock_active
            cx_shm_version_limit_exceeded
            cx_shm_change_lock_active
            cx_shm_read_lock_active
            cx_shm_no_active_version into lr_exc.
        get time.
        "... 1hr Retry(pretty extreme)
        if ( ( sy-uzeit - lv_time ) mod 86400 ) gt 3600.
          raise exception type zcx_prc_wait_timout_exception.
        endif.
    endtry.
  enddo.

  "... Check for previous success
  check lr_area is not initial and lr_area->root is not initial.
  lr_monitor = lr_area->root.

  lr_monitor->number_of_processes( iv_num ).
  lr_area->detach_commit( ).
endmethod.


method pid_exists.
  data: lr_area type ref to zcl_prc_monitor_area,
        lr_monitor type ref to zcl_prc_monitor_access,
        lr_exc type ref to cx_shm_attach_error,
        lv_time type t.

  get time field lv_time.
  do.
    try.
        lr_area = zcl_prc_monitor_area=>attach_for_read( 'ZCL_PRC_MONITOR_AREA' ).
        exit. "... Exit Do
      catch cx_shm_exclusive_lock_active
            cx_shm_version_limit_exceeded
            cx_shm_change_lock_active
            cx_shm_read_lock_active
            cx_shm_no_active_version into lr_exc.
        get time.
        "... 1hr Retry(pretty extreme)
        if ( ( sy-uzeit - lv_time ) mod 86400 ) gt 3600.
          raise exception type zcx_prc_wait_timout_exception.
        endif.
    endtry.
  enddo.

  "... Check for previous success
  check lr_area is not initial and lr_area->root is not initial.
  lr_monitor = lr_area->root.

  rv_exists = lr_monitor->pid_exists( iv_pid ).
  lr_area->detach( ).
endmethod.                    "PID_EXISTS


method register_pid.
  data: lr_area type ref to zcl_prc_monitor_area,
        lr_monitor type ref to zcl_prc_monitor_access,
        lr_exc type ref to cx_shm_attach_error,
        lv_time type t.

  get time field lv_time.
  do.
    try.
        lr_area = zcl_prc_monitor_area=>attach_for_update( 'ZCL_PRC_MONITOR_AREA' ).
        exit. "... Exit Do
      catch cx_shm_exclusive_lock_active
            cx_shm_version_limit_exceeded
            cx_shm_change_lock_active
            cx_shm_read_lock_active
            cx_shm_no_active_version into lr_exc.
        get time.
        "... 1hr Retry(pretty extreme)
        if ( ( sy-uzeit - lv_time ) mod 86400 ) gt 3600.
          raise exception type zcx_prc_wait_timout_exception.
        endif.
    endtry.
  enddo.

  "... Check for previous success
  check lr_area is not initial and lr_area->root is not initial.
  lr_monitor = lr_area->root.

  try.
      rv_pid = lr_monitor->register_pid( ).
    catch zcx_prc_no_processes_avail.
  endtry.
  lr_area->detach_commit( ).
endmethod.                    "REGISTER_PID
ENDCLASS.
