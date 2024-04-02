class ZCL_PRC_FUTURE_EXECUTOR definition
  public
  final
  create public .

public section.
  class ZCL_PRC_EXECUTOR_ACCESS definition load .

  methods CONSTRUCTOR
    importing
      !IV_MAXPROCESSES type I optional
      !IV_TIMEOUT type I default 43200 .
  methods SUBMIT
    importing
      !IR_CALLABLE type ref to ZIF_PRC_CALLABLE
      !IV_DELAY type STRING optional
    returning
      value(RR_PROCESS) type ref to ZCL_PRC_FUTURE_TASK .
  class-methods SET_RESULT
    importing
      !IV_PID type CHAR8
      !IV_GUID type SYSUUID_X16
      !IR_RESULT type ANY
      !IV_WPID type CHAR8
    raising
      ZCX_PRC_NON_SERIALIZABLE .
  class-methods DEREGISTER_PID
    importing
      !IV_PID type CHAR8 .
  class-methods ATTACH_WP
    importing
      !IV_PID type CHAR8 .
protected section.
private section.

  data MV_TIMEOUT type I value 299 ##NO_TEXT.

  class-methods MAX_WORK_PROCESSES
    importing
      !IV_NUM type I .
  class-methods REGISTER_PID
    returning
      value(RV_PID) type CHAR8
    raising
      ZCX_PRC_NO_PROCESSES_AVAIL .
  class-methods PID_EXISTS
    importing
      !IV_PID type CHAR8
    returning
      value(RV_EXISTS) type ABAP_BOOL .
  class-methods HAS_PROCESSES
    returning
      value(RV_RESULT) type ABAP_BOOL .
  class-methods GET_WP_AVAIL
    returning
      value(RV_WP_AVAIL) type I .
  class-methods GARBAGE_COLLECT
    importing
      !IV_BYPASS_LONGCHK type ABAP_BOOL default ABAP_FALSE .
ENDCLASS.



CLASS ZCL_PRC_FUTURE_EXECUTOR IMPLEMENTATION.


method ATTACH_WP.
    data: lr_area type ref to zcl_prc_executor_area,
          lr_executor type ref to zcl_prc_executor_access,
          lr_exc type ref to cx_shm_attach_error,
          lv_time type t.

    get time field lv_time.
    do.
      try.
          lr_area = zcl_prc_executor_area=>attach_for_update( 'ZCL_PRC_EXECUTOR_AREA' ).
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
    lr_executor = lr_area->root.

    lr_executor->attach_wp( iv_pid ).
    lr_area->detach_commit( ).
  endmethod.


method constructor.
    mv_timeout = iv_timeout.

    if iv_maxprocesses is not initial.
      max_work_processes( iv_maxprocesses ).
    else.
      max_work_processes( zcl_prc_wp_manager=>get_max_work_processes( ) ).
    endif.
  endmethod.                    "CONSTRUCTOR


method DEREGISTER_PID.
    data: lr_area type ref to zcl_prc_executor_area,
          lr_executor type ref to zcl_prc_executor_access,
          lr_exc type ref to cx_shm_attach_error,
          lv_time type t.

    get time field lv_time.
    do.
      try.
          lr_area = zcl_prc_executor_area=>attach_for_update( 'ZCL_PRC_EXECUTOR_AREA' ).
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
    lr_executor = lr_area->root.

    lr_executor->deregister_pid( iv_pid ).
    lr_area->detach_commit( ).
  endmethod.                    "DEREGISTER_PID


method GARBAGE_COLLECT.
    data: lr_area type ref to zcl_prc_executor_area,
          lr_executor type ref to zcl_prc_executor_access,
          lr_exc type ref to cx_shm_attach_error,
          lv_time type t.

    get time field lv_time.
    do.
      try.
          lr_area = zcl_prc_executor_area=>attach_for_update( 'ZCL_PRC_EXECUTOR_AREA' ).
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
    lr_executor = lr_area->root.

    lr_executor->garbage_collect( iv_bypass_longchk ).
    lr_area->detach_commit( ).
  endmethod.


method GET_WP_AVAIL.
    data: lr_area type ref to zcl_prc_executor_area,
          lr_executor type ref to zcl_prc_executor_access,
          lr_exc type ref to cx_shm_attach_error,
          rv_cleaned type abap_bool,
          lv_time type t.

    "... Do any GC first
    garbage_collect( ).

    get time field lv_time.
    do.
      try.
          lr_area = zcl_prc_executor_area=>attach_for_read( 'ZCL_PRC_EXECUTOR_AREA' ).
          exit. "... Exit Do
        catch cx_shm_inconsistent. "... When inconsistent all we need to do is reset this
          zcl_prc_executor_area=>free_area( ). "... If this fails we have a real problem
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
    lr_executor = lr_area->root.

    rv_wp_avail = lr_executor->get_wp_avail( ).
    lr_area->detach( ).

    case rv_wp_avail.
      when -1. "... Not initialised
        "... Initialise the work processes to default, can return that value here
        rv_wp_avail = zcl_prc_wp_manager=>get_max_work_processes( ).
        max_work_processes( rv_wp_avail ).
    endcase.
  endmethod.                    "GET_WP_AVAIL


method HAS_PROCESSES.
    data: lr_area type ref to zcl_prc_executor_area,
          lr_executor type ref to zcl_prc_executor_access,
            lr_exc type ref to cx_shm_attach_error,
            lv_time type t.

    "... Do any GC first(probably not used for completion?)
    garbage_collect( abap_true ).

    get time field lv_time.
    do.
      try.
          lr_area = zcl_prc_executor_area=>attach_for_read( 'ZCL_PRC_EXECUTOR_AREA' ).
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
    lr_executor = lr_area->root.

    rv_result = lr_executor->has_processes( ).
    lr_area->detach( ).

  endmethod.                    "HAS_PROCESSES


method MAX_WORK_PROCESSES.
    data: lr_area type ref to zcl_prc_executor_area,
          lr_executor type ref to zcl_prc_executor_access,
          lr_exc type ref to cx_shm_attach_error,
          lv_time type t.

    get time field lv_time.
    do.
      try.
          lr_area = zcl_prc_executor_area=>attach_for_update( 'ZCL_PRC_EXECUTOR_AREA' ).
          exit. "... Exit Do
        catch cx_shm_inconsistent. "... When inconsistent all we need to do is reset this
          zcl_prc_executor_area=>free_area( ). "... If this fails we have a real problem
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
    lr_executor = lr_area->root.

    lr_executor->number_of_processes( iv_num ).
    lr_area->detach_commit( ).
  endmethod.                    "MAX_WORK_PROCESSES


method PID_EXISTS.
    data: lr_area type ref to zcl_prc_executor_area,
          lr_executor type ref to zcl_prc_executor_access,
          lr_exc type ref to cx_shm_attach_error,
          lv_time type t.

    get time field lv_time.
    do.
      try.
          lr_area = zcl_prc_executor_area=>attach_for_read( 'ZCL_PRC_EXECUTOR_AREA' ).
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
    lr_executor = lr_area->root.

    rv_exists = lr_executor->pid_exists( iv_pid ).
    lr_area->detach( ).
  endmethod.                    "PID_EXISTS


method REGISTER_PID.
    data: lr_area type ref to zcl_prc_executor_area,
          lr_executor type ref to zcl_prc_executor_access,
          lr_exc type ref to cx_shm_attach_error,
          lv_time type t.

    get time field lv_time.
    do.
      try.
          lr_area = zcl_prc_executor_area=>attach_for_update( 'ZCL_PRC_EXECUTOR_AREA' ).
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
    lr_executor = lr_area->root.

    rv_pid = lr_executor->register_pid( ).
    lr_area->detach_commit( ).
  endmethod.                    "REGISTER_PID


method SET_RESULT.
    data: lr_area type ref to zcl_prc_executor_area,
      lr_executor type ref to zcl_prc_executor_access,
      lr_exc type ref to cx_shm_attach_error,
      lv_data type zprce_data,
      lv_time type t.

    "... First thing to do is try to serialize the input
    try.
        lv_data = zcl_prc_serialization_util=>serialize_result( ir_result ).
      catch zcx_prc_non_serializable.
        raise exception type zcx_prc_non_serializable.
    endtry.

    get time field lv_time.
    do.
      try.
          lr_area = zcl_prc_executor_area=>attach_for_update( 'ZCL_PRC_EXECUTOR_AREA' ).
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
    lr_executor = lr_area->root.

    lr_executor->set_result( iv_pid    = iv_pid
                             iv_guid   = iv_guid
                             iv_wpid   = iv_wpid
                             iv_result = lv_data ).
    lr_area->detach_commit( ).
  endmethod.                    "SET_RESULT


method submit.
    data: lr_processor type ref to lcl_processor,
          lv_pid type char8.
    data: lv_p type p decimals 2.
    lv_p = iv_delay.
    if lv_p gt 45.
      raise exception type zcx_prc_excessive_delay.
    endif.

    create object lr_processor
      exporting
        ir_callable = ir_callable
        iv_delay    = iv_delay
        iv_timeout  = mv_timeout.

    lr_processor->dispatch( ).

    create object rr_process
      exporting
        ir_callable = ir_callable.
  endmethod.                    "submit
ENDCLASS.
