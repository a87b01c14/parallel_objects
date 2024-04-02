*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
class lcl_processor definition.
  public section.
    methods:
      constructor
        importing ir_process type ref to zcl_prc_background_job,
      dispatch
        importing iv_uname type sy-uname default sy-uname
        raising zcx_prc_process_exception zcx_prc_wait_timout_exception.
  protected section.
  private section.
    data: mr_process type ref to zcl_prc_background_job.
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
    data: ls_bg type zprcd_background,
          lv_count type btcjobcnt,
          lv_job type btcjob value 'Z_PRC_BACKGROUND_JOB',
          lv_released type btcchar1,
          lv_group type bpsrvgrp,
          lv_priority type btcjobclas value 'B',
          lv_time type t.

    get time field lv_time.

    "... Set the guid
    mr_process->mv_guid = cl_system_uuid=>create_uuid_x16_static( ).
    lv_group = mr_process->mv_group.

    "... Get the serialized data
    ls_bg-data = serialize( ).
    ls_bg-guid = mr_process->mv_guid.
    get time stamp field ls_bg-time.

    if mr_process->mr_schedule is not initial.
      lv_job = mr_process->mr_schedule->jobname( ).
      lv_priority = mr_process->mr_schedule->priority( ).
    endif.

    call function 'JOB_OPEN'
      exporting
        jobname          = lv_job
        jobclass         = lv_priority
      importing
        jobcount         = lv_count
      exceptions
        cant_create_job  = 1
        invalid_job_data = 2
        jobname_missing  = 3
        others           = 4.
    if sy-subrc <> 0.
      raise exception type zcx_prc_process_failed.
    endif.

    "... The program will use this table entry
    modify zprcd_background from ls_bg.

    "... Submit the job
    submit z_prc_background_job with guid = mr_process->mv_guid
                    with delay = mr_process->mv_delay
                    user sy-uname
                    via job lv_job number lv_count and return.
    if sy-subrc ne 0.
      delete zprcd_background from ls_bg.
      commit work. "... This must happen
      raise exception type zcx_prc_process_failed.
    endif.
    if mr_process->mr_schedule is initial.
      "... No schedule, start immediately
      call function 'JOB_CLOSE'
        exporting
          jobcount             = lv_count
          jobname              = lv_job
          strtimmed            = 'X'
          targetgroup          = lv_group
        importing
          job_was_released     = lv_released
        exceptions
          cant_start_immediate = 1
          invalid_startdate    = 2
          jobname_missing      = 3
          job_close_failed     = 4
          job_nosteps          = 5
          job_notex            = 6
          lock_failed          = 7
          invalid_target       = 8
          others               = 9.
      if sy-subrc ne 0.
        delete zprcd_background from ls_bg.
        commit work. "... This must happen
        raise exception type zcx_prc_process_failed.
      endif.
    else.
      "... Use the schedule
      call function 'JOB_CLOSE'
        exporting
          jobcount             = lv_count
          jobname              = lv_job
          sdlstrtdt            = mr_process->mr_schedule->date( )
          sdlstrttm            = mr_process->mr_schedule->time( )
          targetgroup          = lv_group
        importing
          job_was_released     = lv_released
        exceptions
          cant_start_immediate = 1
          invalid_startdate    = 2
          jobname_missing      = 3
          job_close_failed     = 4
          job_nosteps          = 5
          job_notex            = 6
          lock_failed          = 7
          invalid_target       = 8
          others               = 9.
      if sy-subrc ne 0.
        delete zprcd_background from ls_bg.
        commit work. "... This must happen
        raise exception type zcx_prc_process_failed.
      endif.
    endif.

    "... Commit
    commit work.
  endmethod.                   "dispatch
endclass.                    "lcl_processor IMPLEMENTATION
