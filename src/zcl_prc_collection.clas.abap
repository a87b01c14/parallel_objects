class ZCL_PRC_COLLECTION definition
  public
  create public .

public section.

  interfaces ZIF_COLLECTION .
  interfaces IF_SERIALIZABLE_OBJECT .

  methods ADD
    importing
      !IR_OBJECT type ref to OBJECT .
  methods REMOVE_INDEX
    importing
      !IV_INDEX type I .
  methods REMOVE
    importing
      !IR_ITEM type ref to OBJECT .
  methods CLEAR .
protected section.

  data:
    MT_COLLECTION type standard table of ref to object .
private section.
ENDCLASS.



CLASS ZCL_PRC_COLLECTION IMPLEMENTATION.


method ADD.
  append ir_object to mt_collection.
endmethod.


method CLEAR.
  clear mt_collection.
endmethod.


method REMOVE.
  delete table mt_collection from ir_item.
endmethod.


method REMOVE_INDEX.
  delete mt_collection index iv_index.
endmethod.


method ZIF_COLLECTION~GET_ITEM.
  read table mt_collection into rr_object index iv_index.
endmethod.


method ZIF_COLLECTION~GET_ITERATOR.
  create object rif_iterator type lcl_iterator
    exporting
      ir_collection = me.
endmethod.


method ZIF_COLLECTION~IS_EMPTY.
  if me->zif_collection~size( ) eq 0.
    rv_empty = abap_true.
  else.
    rv_empty = abap_false.
  endif.
endmethod.


method ZIF_COLLECTION~SIZE.
  rv_size = lines( mt_collection ).
endmethod.
ENDCLASS.
