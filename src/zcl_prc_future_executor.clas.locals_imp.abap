*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
class lcl_processor definition.
  public section.
    methods:
      constructor
        importing
          ir_callable type ref to zif_prc_callable
          iv_delay type string optional
          iv_timeout type i optional,
      dispatch
        raising zcx_prc_process_exception zcx_prc_wait_timout_exception.
  protected section.
  private section.
    data: mr_callable type ref to zif_prc_callable,
          mv_delay type string,
          mv_timeout type i.
    methods:
      serialize returning value(rv_callable) type zprce_data.
    methods:
      initialize_group returning value(rv_group) type rzlli_apcl.
    methods:
      get_wp_id returning value(rv_wpid) type char8.
endclass.                    "lcl_processor DEFINITION

*----------------------------------------------------------------------*
*       CLASS lcl_processor IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class lcl_processor implementation.
  method constructor.
    mr_callable = ir_callable.
    mv_delay = iv_delay.
    mv_timeout = iv_timeout.
  endmethod.                    "constructor

  method serialize.
    call transformation id_indent
     source obj = mr_callable
     result xml rv_callable.
  endmethod.                    "serialize
  method dispatch.
    data: lv_group type rzlli_apcl value ' ',
          lv_data type zprce_data,
          lv_time type t.

    get time field lv_time.
    do. "... Timeout checked at end

      try.
          if zcl_prc_future_executor=>get_wp_avail( ) ne 0.

            "... Set the process ID
            mr_callable->mv_cpid = zcl_prc_future_executor=>register_pid( ).
            mr_callable->mv_guid = cl_system_uuid=>create_uuid_x16_static( ).
            mr_callable->mv_wpid = get_wp_id( ).

            "... Get the serialized data
            lv_data = serialize( ).

            call function 'Z_PRC_RUN_FUTURE_TASK' starting new task mr_callable->mv_cpid
              destination 'NONE'
              exporting
                iv_callable           = lv_data
                iv_delay              = mv_delay
              exceptions
                system_failure        = 1
                communication_failure = 2
                resource_failure      = 3.

            case sy-subrc.
              when 0.
                exit. "... Exit the do loop to complete the method
              when 3.
                "... Do nothing because we are waiting
              when others.
                "... Explode in other cases
                raise exception type zcx_prc_system_failure.
            endcase.
          endif.
        catch zcx_prc_no_processes_avail.
          "... No process available, occurs under very high load
          "... Let the retry occur
      endtry.
      get time. "... Init the system time to be sure
      if ( ( sy-uzeit - lv_time ) mod 86400 ) gt mv_timeout.
        "... Wait time is over
        raise exception type zcx_prc_wait_timout_exception.
      endif.
    enddo.
  endmethod.                    "dispatch
  method initialize_group.
    data: lv_available type i,
          lv_time type t,
          lv_initial type abap_bool value abap_true,
          lv_max type i.
    get time field lv_time.
    do. "... Timeout checked at end
      "... IF unsure do intialisation
      if lv_initial eq abap_true.
        "... Prepare for launch, we need the number of available processes
        call function 'SPBT_INITIALIZE'
          exporting
            group_name                     = rv_group "... name of group
          importing
            max_pbt_wps                    = lv_max "... number of dialog processes avail
            free_pbt_wps                   = lv_available "... number available
          exceptions
            invalid_group_name             = 1 "... Incorrect group name; RFC group not defined.
*                                              "... See transaction RZ12
            internal_error                 = 2 "... Server error
            pbt_env_already_initialized    = 3 "... Apparently this FM can only be called once
            currently_no_resources_avail   = 4 "... No processes available / workload too high
            no_pbt_resources_found         = 5 "... No servers in workgrp with 2 or more processes defined
            cant_init_different_pbt_groups = 6 "... Another grp is already initialised
            others                         = 7. "... Who knows?
      else.
        "... We are certain initialisation is done lets check resources
        call function 'SPBT_GET_CURR_RESOURCE_INFO'
          importing
            max_pbt_wps                 = lv_max
            free_pbt_wps                = lv_available
          exceptions
            internal_error              = 1
            pbt_env_not_initialized_yet = 2
            others                      = 3. "... Thanks SAP for making 3 other! thats really not
*                                                 very helpful for my case statement
      endif.
      case sy-subrc.
        when 3. "... Either initial failed or getting resources failed
          if lv_initial eq abap_true.
            lv_initial = abap_false.
            mv_timeout = mv_timeout + 1. "... A second was wasted so add it back on
            continue.
          else.
            "... Resource grab failed
            raise exception type zcx_prc_process_exception.
          endif.
        when 4 or 0.
          "... Not enough available processes
          if lv_available eq 0 or zcl_prc_future_executor=>get_wp_avail( ) eq 0.
            "... Do nothing we will continue the loop
          else.
            "... Theres at least 1 process free so lets exit the do loop and move on
            exit.
          endif.
        when others.
          raise exception type zcx_prc_process_exception.
      endcase.

      get time. "... Init the system time to be sure
      if ( ( sy-uzeit - lv_time ) mod 86400 ) gt mv_timeout.
        "... Wait time is over
        raise exception type zcx_prc_wait_timout_exception.
      endif.
    enddo.
  endmethod.
  method get_wp_id.

    "...get the originating work process ID
    call function 'TH_GET_OWN_WP_NO'
     importing
       wp_pid = rv_wpid.

  endmethod.                  "get work process id
endclass.                    "lcl_processor IMPLEMENTATION
