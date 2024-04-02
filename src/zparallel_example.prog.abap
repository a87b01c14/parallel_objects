*&---------------------------------------------------------------------*
*& Report ZCONCURRENCY_API_EXAMPLE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zparallel_example.

CLASS lcl_my_runnable DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES:
        tty_numbers TYPE STANDARD TABLE OF i
        WITH NON-UNIQUE DEFAULT KEY.
    INTERFACES: zif_prc_runnable.
    METHODS:
      constructor
        IMPORTING
          it_numbers TYPE tty_numbers,
      get_sum
        RETURNING VALUE(rv_result) TYPE i.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA t_numbers TYPE lcl_my_runnable=>tty_numbers.
    DATA v_result TYPE i.
ENDCLASS.


CLASS lcl_my_runnable IMPLEMENTATION.

  METHOD constructor.
    t_numbers = it_numbers.
  ENDMETHOD.
  METHOD zif_prc_runnable~run.
    v_result = REDUCE #(
        INIT result TYPE i
        FOR number IN t_numbers
        NEXT result = result + number
    ).
    MESSAGE 'done' TYPE 'S'.
  ENDMETHOD.

  METHOD get_sum.
    rv_result = v_result.
  ENDMETHOD.

ENDCLASS.

END-OF-SELECTION.
  DATA(lr_runnable) = NEW lcl_my_runnable( VALUE #( ( 10 ) ( 20 ) ( 30 ) ) ).
  zcl_prc_monitor=>max_work_processes( 4 ).
*  DATA(lr_task) = NEW zcl_prc_isolated_task( lr_runnable ).
  DO 10 TIMES.
    DATA(lr_task) = NEW zcl_prc_managed_task( lr_runnable ).
    lr_task->start( ).
  ENDDO.
  zcl_prc_barrier=>wait( ).
