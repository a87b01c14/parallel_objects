*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
class lcl_iterator definition .
  public section.
    interfaces zif_iterator .
    methods constructor
      importing
        ir_collection type ref to zif_collection.
  protected section.

  private section.
    data: mr_collection type ref to zif_collection,
          mv_index type i value 0.

endclass.                    "lcl_iterator DEFINITION
"lcl_iterator DEFINITION

*----------------------------------------------------------------------*
*       CLASS lcl_iterator IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class lcl_iterator implementation.
  method constructor.
    mr_collection = ir_collection.
  endmethod.                    "constructor
  method zif_iterator~get_index.
    rv_index = mv_index.
  endmethod.                    "zif_iterator~GET_INDEX

  method zif_iterator~has_next.
    if mv_index lt mr_collection->size( ).
      rv_hasnext = abap_true.
    else.
      rv_hasnext = abap_false.
    endif.
  endmethod.                    "zif_iterator~HAS_NEXT
  method zif_iterator~next.
    mv_index = mv_index + 1.
    rr_object = mr_collection->get_item( mv_index ).
  endmethod.                    "zif_iterator~NEXT

  method zif_iterator~current.
    rr_object = mr_collection->get_item( mv_index ).
  endmethod.                    "zif_iterator~current
  method zif_iterator~first.
    mv_index = 1.
    rr_object = mr_collection->get_item( mv_index ).
  endmethod.                    "zif_iterator~first

  method zif_iterator~last.
    mv_index = mr_collection->size( ).
    rr_object = mr_collection->get_item( mv_index ).
  endmethod.                    "zif_iterator~last

endclass.                    "lcl_iterator IMPLEMENTATION
