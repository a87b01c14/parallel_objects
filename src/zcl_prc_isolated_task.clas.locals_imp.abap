*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
class lcl_processor definition.
  public section.
    methods:
      constructor importing ir_process type ref to zcl_prc_isolated_task,
      dispatch raising zcx_prc_process_exception zcx_prc_wait_timout_exception.
  protected section.
  private section.
    data: mr_process type ref to zcl_prc_isolated_task.
    methods:
      serialize returning value(rv_process) type zprce_data.
endclass.                    "lcl_processor DEFINITION

*----------------------------------------------------------------------*
*       CLASS lcl_processor IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class lcl_processor implementation.
  method constructor.
    mr_process = ir_process.
  endmethod.                    "constructor

  method serialize.
    call transformation id_indent
     source obj = mr_process
     result xml rv_process.
  endmethod.                    "serialize
  method dispatch.
    data: lv_data type zprce_data,
          lv_time type t.

    get time field lv_time.
    do.

      "... Get the serialized data
      lv_data = serialize( ).

      call function 'Z_PRC_RUN_ISOLATED_TASK' starting new task '' destination in group default
        exporting
          iv_process = lv_data
          iv_delay   = mr_process->mv_delay
        exceptions
          system_failure = 1
          communication_failure = 2
          resource_failure = 3.

        case sy-subrc.
          when 0.
            exit. "... Exit the do loop to complete the method
          when 3.
            "... Do nothing because we are waiting
          when others.
            "... Explode in other cases
            raise exception type zcx_prc_system_failure.
        endcase.

      get time. "... Init the system time to be sure
      if ( ( sy-uzeit - lv_time ) mod 86400 ) gt mr_process->mv_timeout.
        "... Wait time is over
        raise exception type zcx_prc_wait_timout_exception.
      endif.
    enddo.
  endmethod.                   "dispatch
endclass.                    "lcl_processor IMPLEMENTATION
