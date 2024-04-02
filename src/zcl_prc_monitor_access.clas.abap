class ZCL_PRC_MONITOR_ACCESS definition
  public
  final
  create private
  shared memory enabled

  global friends ZCL_PRC_MONITOR
                 ZCL_PRC_MONITOR_BUILDER .

public section.

  interfaces IF_SERIALIZABLE_OBJECT .

  methods CONSTRUCTOR .
protected section.
private section.

  types:
    begin of registration,
          pid type char8,
          uname like sy-uname,
          wp_id type char8,
          mod_time type timestampl,
        end of registration .
  types:
    begin of count_entry,
          uname like sy-uname,
          wp_max type i,
          wp_counter type i,
        end of count_entry .

  data MV_PROCESS_COUNT type I .
  data:
    mt_register type sorted table of registration with unique key pid .
  data:
    mt_avail_pids type standard table of i .
  data:
    mt_wp_count type hashed table of count_entry with unique key uname .

  methods REGISTER_PID
    returning
      value(RV_PID) type CHAR8
    raising
      ZCX_PRC_NO_PROCESSES_AVAIL .
  methods ATTACH_WP
    importing
      !IV_PID type CHAR8 .
  methods DEREGISTER_PID
    importing
      !IV_PID type CHAR8 .
  methods PID_EXISTS
    importing
      !IV_PID type CHAR8
    returning
      value(RV_EXISTS) type ABAP_BOOL .
  methods HAS_PROCESSES
    returning
      value(RV_RESULT) type ABAP_BOOL .
  methods NUMBER_OF_PROCESSES
    importing
      !IV_NUM type I .
  methods GET_WP_AVAIL
    returning
      value(RV_WP_AVAIL) type I .
  methods GET_WP_MAX
    returning
      value(RV_WP_MAX) type I .
  methods SET_WP_AVAIL
    importing
      !IV_WP_AVAIL type I .
  methods POP_PID
    returning
      value(RV_PID) type CHAR8 .
  methods PUSH_PID
    importing
      !IV_PID type CHAR8 .
  methods INCREASE_PID_BUFFER
    importing
      !IV_THRESHHOLD type I .
  methods GARBAGE_COLLECT
    importing
      !IV_BYPASS_LONGCHK type ABAP_BOOL default ABAP_FALSE .
  methods GET_WP_ID
    returning
      value(RV_PID) type CHAR8 .
  methods HAS_LONG_PROCESS
    returning
      value(RV_RESULT) type ABAP_BOOL .
ENDCLASS.



CLASS ZCL_PRC_MONITOR_ACCESS IMPLEMENTATION.


method attach_wp.
    field-symbols: <fs_register> like line of mt_register.

    read table mt_register with table key pid = iv_pid assigning <fs_register>.
    <fs_register>-wp_id = get_wp_id( ).
  endmethod.


method constructor.
    data: lv_count type i value 1,
          lv_pid type num8.

    "... Setup a buffer of PIDS
    do 10000 times.
      lv_pid = lv_count.
      append lv_pid to mt_avail_pids.

      lv_count = lv_count + 1.
    enddo.

    mv_process_count = mv_process_count + 1000.
  endmethod.                    "CONSTRUCTOR


method deregister_pid.
    delete table mt_register with table key pid = iv_pid.
*    delete table mt_register with table key pid = iv_pid wp_id = get_wp_id( ).
    set_wp_avail( get_wp_avail( ) + 1 ).

    "... Push the PID back as an available id
    push_pid( iv_pid ).

  endmethod.                    "DEREGISTER_PID


method garbage_collect.
    data: lt_wpinfo type standard table of wpinfo,
          ls_wpinfo type wpinfo,
          ls_register like line of mt_register,
          lt_pids type standard table of char8,
          lv_check type abap_bool,
          lv_pid type char8.

    if get_wp_avail( ) eq 0 or iv_bypass_longchk eq abap_true.
      lv_check = abap_true.
    elseif has_long_process( ) eq abap_true.
      lv_check = abap_true.
    endif.

    if lv_check eq abap_true.
      call function 'TH_WPINFO'
        tables
          wplist     = lt_wpinfo
        exceptions
          send_error = 1
          others     = 2.

      loop at mt_register into ls_register where uname eq sy-uname.
        if ls_register-wp_id is initial.
          continue.
        endif.
        read table lt_wpinfo with key wp_bname = sy-uname wp_pid = ls_register-wp_id into ls_wpinfo.
        if sy-subrc ne 0.
          append ls_register-pid to lt_pids.
        endif.
      endloop.
      loop at lt_pids into lv_pid.
        deregister_pid( lv_pid ).
      endloop.
    endif.
  endmethod.


method get_wp_avail.
  data: ls_count_entry type count_entry.

  read table mt_wp_count with table key uname = sy-uname into ls_count_entry.

  "... User has a count return it
  if sy-subrc eq 0.
    rv_wp_avail = ls_count_entry-wp_counter.
  else.
    "... If no count avail return a -1 to indicate so it can be initialised via change lock
    rv_wp_avail = -1.
  endif.
endmethod.                    "GET_WP_AVAIL


method get_wp_id.
    "... Get the PID for the current work process
    call function 'TH_GET_OWN_WP_NO'
      importing
        wp_pid   = rv_pid.
  endmethod.


method get_wp_max.
    data: ls_count_entry type count_entry.
    read table mt_wp_count with table key uname = sy-uname into ls_count_entry.

    "... User has a max set return it
    if sy-subrc eq 0.
      rv_wp_max = ls_count_entry-wp_max.
    else.
      "... no max so we will set one up()
      number_of_processes( zcl_prc_wp_manager=>get_max_work_processes( ) ).
    endif.
  endmethod.                    "GET_WP_MAX


method has_long_process.
    data: ls_register like line of mt_register,
          lv_time type timestampl,
          lv_secs type tzntstmpl.

    "... Get current time
    get time stamp field lv_time.

    loop at mt_register into ls_register where uname = sy-uname.
      lv_secs = cl_abap_tstmp=>subtract( tstmp1 = lv_time
                                         tstmp2 = ls_register-mod_time ).
      if lv_secs gt 120.
        rv_result = abap_true.
        return.
      endif.
    endloop.
  endmethod.


method has_processes.
  read table mt_register with key uname = sy-uname transporting no fields.
  case sy-subrc.
    when 0.
      rv_result = abap_true.
  endcase.
endmethod.                    "has_processes


method increase_pid_buffer.
  endmethod.                    "INCREASE_PID_BUFFER


method number_of_processes.
    data: lv_chk type i,
          ls_count_entry type count_entry.
    field-symbols: <fs_count_entry> type count_entry.
    read table mt_wp_count with table key uname = sy-uname assigning <fs_count_entry>.

    if sy-subrc eq 0.
      if iv_num ne <fs_count_entry>-wp_max.
        lv_chk = iv_num - ( <fs_count_entry>-wp_max - <fs_count_entry>-wp_counter ).

        if lv_chk ge 0.
          <fs_count_entry>-wp_counter = lv_chk.
        else.
          <fs_count_entry>-wp_counter = 0.
        endif.
      endif.
      <fs_count_entry>-wp_max = iv_num.
    else.
      ls_count_entry-uname = sy-uname.
      ls_count_entry-wp_max = iv_num.
      ls_count_entry-wp_counter = iv_num.
      insert ls_count_entry into table mt_wp_count.
    endif.

  endmethod.                    "NUMBER_OF_PROCESSES


method pid_exists.
    read table mt_register with table key pid = iv_pid transporting no fields.
*    read table mt_register with table key pid = iv_pid wp_id = get_wp_id( ) transporting no fields.

    case sy-subrc.
      when 0.
        rv_exists = abap_true.
    endcase.
  endmethod.                    "PID_EXISTS


method pop_pid.
    data: lv_num type num8.
    read table mt_avail_pids into lv_num index 1.
    delete mt_avail_pids index 1.
    rv_pid = lv_num.
  endmethod.                    "POP_PID


method push_pid.
    data: lv_pid type i.
    lv_pid = iv_pid.
    append lv_pid to mt_avail_pids.
  endmethod.                    "PUSH_PID


method register_pid.
    data: lv_num type num8,
          lv_wp_avail type i,
          ls_register type registration.

    lv_wp_avail = get_wp_avail( ).
    if lv_wp_avail eq 0.
      raise exception type zcx_prc_no_processes_avail.
    endif.

    "... Get the next available PID
    rv_pid = pop_pid( ).

    ls_register-pid = rv_pid.
    ls_register-uname = sy-uname.
    get time stamp field ls_register-mod_time.
    insert ls_register into table mt_register.
    set_wp_avail( lv_wp_avail - 1 ).
  endmethod.                    "REGISTER_PID


method set_wp_avail.
    field-symbols: <fs_count_entry> type count_entry.
    read table mt_wp_count with table key uname = sy-uname assigning <fs_count_entry>.

    "... This is a major explosion if its ne 0
    if sy-subrc ne 0.
      raise exception type zcx_prc_process_exception.
    else.
      <fs_count_entry>-wp_counter = iv_wp_avail.
    endif.
  endmethod.                    "SET_WP_AVAIL
ENDCLASS.
