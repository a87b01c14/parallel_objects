*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
class lcl_processor definition.
  public section.
    methods:
      constructor
        importing ir_process type ref to zcl_prc_bg_batch_job,
      dispatch
        importing iv_uname type sy-uname default sy-uname
        raising zcx_prc_process_exception zcx_prc_wait_timout_exception.
  protected section.
  private section.
    data: mr_process type ref to zcl_prc_bg_batch_job.
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
    data: ls_bg type zprcd_bg_batch.

    "... Set the guid
    mr_process->mv_guid = cl_system_uuid=>create_uuid_x16_static( ).
    convert
      date mr_process->mr_schedule->date( )
      time mr_process->mr_schedule->time( )
      into time stamp data(lv_start_time) time zone sy-zonlo.

    "... Get the serialized data
    ls_bg-data = serialize( ).
    ls_bg-guid = mr_process->mv_guid.
    get time stamp field ls_bg-time.
    ls_bg-start_time = lv_start_time.

    "... The program will use this table entry
    modify zprcd_bg_batch from ls_bg.

    "... Commit
    commit work.
  endmethod.                   "dispatch
endclass.                    "lcl_processor IMPLEMENTATION
