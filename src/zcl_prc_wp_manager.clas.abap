class ZCL_PRC_WP_MANAGER definition
  public
  final
  create public .

public section.

  constants CO_DEFAULT_MAX type I value 10 ##NO_TEXT.

  class-methods CLASS_CONSTRUCTOR .
  class-methods GET_MAX_WORK_PROCESSES
    importing
      !USER type SYST_UNAME default SY-UNAME
    returning
      value(MAX_WP) type I .
protected section.
private section.

  class-data:
    mt_users type hashed table of zprcc_wp_config with unique key user_name .
ENDCLASS.



CLASS ZCL_PRC_WP_MANAGER IMPLEMENTATION.


method class_constructor.
    select * from zprcc_wp_config into table mt_users.
  endmethod.


method get_max_work_processes.
    read table mt_users into data(ls_user) with key user_name = user.

    if ls_user is not initial.
      max_wp = ls_user-max_wp.
    else.
      max_wp = co_default_max.
    endif.
  endmethod.
ENDCLASS.
