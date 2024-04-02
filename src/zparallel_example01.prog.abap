*&---------------------------------------------------------------------*
*& Report ZCONCURRENCY_API_EXAMPLE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zparallel_example01.

CLASS lcl_my_callable DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES: zif_prc_callable.
    METHODS:
      constructor
        IMPORTING
          iv_number TYPE i.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA v_number TYPE i.
ENDCLASS.


CLASS lcl_my_callable IMPLEMENTATION.

  METHOD constructor.
    v_number = iv_number.
  ENDMETHOD.
  METHOD zif_prc_callable~call.
    CREATE DATA rv_result TYPE i.
    ASSIGN rv_result->* TO FIELD-SYMBOL(<fs_result>).
    <fs_result> = v_number * 10.
  ENDMETHOD.


ENDCLASS.

END-OF-SELECTION.
  DATA: lv_result TYPE i.
  DATA(lr_list) = NEW zcl_prc_collection( ).
*  DATA(lr_callable) = NEW lcl_my_callable( 10 ).
  DATA(lr_executor) = NEW zcl_prc_future_executor( iv_maxprocesses = 4 ).
*  DATA(lr_future) = lr_executor->submit( lr_callable ).
*  lr_future->get_result( IMPORTING result = lv_result ).
*  WRITE lv_result.
  DO 10 TIMES.
    DATA(lr_future) = lr_executor->submit( NEW lcl_my_callable( sy-index ) ).
    lr_list->add( lr_future ).
  ENDDO.
*  WAIT UP TO '2' SECONDS.

  DATA(lr_iterator) = lr_list->zif_collection~get_iterator( ).
  WHILE lr_iterator->has_next( ) = abap_true.
    lr_future = CAST zcl_prc_future_task( lr_iterator->next( ) ).
    lr_future->get_result( IMPORTING result = lv_result ).
    WRITE: / lv_result.
  ENDWHILE.
