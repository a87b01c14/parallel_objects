class ZCL_PRC_FUTURE_TASK definition
  public
  final
  create private

  global friends ZCL_PRC_FUTURE_EXECUTOR .

public section.

  methods CONSTRUCTOR
    importing
      !IR_CALLABLE type ref to ZIF_PRC_CALLABLE .
  methods GET_RESULT
    importing
      !IV_TIMEOUT type I default 86400
    exporting
      value(RESULT) type ANY
    raising
      ZCX_PRC_WAIT_TIMOUT_EXCEPTION
      ZCX_PRC_PROCESS_FAILED .
protected section.
private section.

  data MR_CALLABLE type ref to ZIF_PRC_CALLABLE .
  data MV_DELAY type STRING .

  methods _GET
    returning
      value(RV_RESULT) type ZPRCE_DATA .
  methods _IS_COMPLETE
    importing
      !IV_PID type CHAR8
      !IV_GUID type SYSUUID_X16
    returning
      value(RV_COMPLETE) type ABAP_BOOL
    raising
      ZCX_PRC_PROCESS_FAILED .
  methods _GARBAGE_COLLECT
    importing
      !IV_BYPASS_LONGCHK type ABAP_BOOL default ABAP_FALSE .
ENDCLASS.



CLASS ZCL_PRC_FUTURE_TASK IMPLEMENTATION.


method CONSTRUCTOR.
  mr_callable = ir_callable.
endmethod.


method get_result.
  data: lv_time type t,
        lv_data type zprce_data,
        lr_data type ref to data.
  field-symbols: <fs_any> type any.

  "... Even if this times out there is no guarantee the processes
  "... executing wont just finish what they are doing
  get time field lv_time.

  try.
      while _is_complete( iv_pid = mr_callable->mv_cpid iv_guid = mr_callable->mv_guid ) eq abap_false.
        get time.
        if ( ( sy-uzeit - lv_time ) mod 86400 ) gt iv_timeout.
          raise exception type zcx_prc_wait_timout_exception.
        endif.
      endwhile.
    catch zcx_prc_process_failed.
      raise exception type zcx_prc_process_failed.
  endtry.

  "... Task is complete since we made it here, get the result
  lv_data = _get( ).

  "... Check for initial, this should be impossible
  check lv_data is not initial.

  create data lr_data like result.
  assign lr_data->* to <fs_any>.

  "... Deserialize the result
  zcl_prc_serialization_util=>deserialize_result( exporting iv_data = lv_data
                                                  importing er_result = <fs_any> ).

  result = <fs_any>.
endmethod.


method _GARBAGE_COLLECT.
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


method _GET.
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

  rv_result = lr_executor->get_result( mr_callable->mv_guid ).
  lr_area->detach_commit( ).
endmethod.


method _IS_COMPLETE.
  data: lr_area type ref to zcl_prc_executor_area,
        lr_executor type ref to zcl_prc_executor_access,
          lr_exc type ref to cx_shm_attach_error,
          lv_time type t.

  "... Clean up broken processes
  _garbage_collect( abap_true ).

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
  try.
    rv_complete = lr_executor->is_complete( iv_pid = iv_pid iv_guid = iv_guid ).
    catch zcx_prc_process_failed.
      lr_area->detach( ).
      raise exception type zcx_prc_process_failed.
  endtry.
  lr_area->detach( ).
endmethod.
ENDCLASS.
