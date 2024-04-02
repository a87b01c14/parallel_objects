interface ZIF_COLLECTION
  public .


  methods SIZE
    returning
      value(RV_SIZE) type I .
  methods IS_EMPTY
    returning
      value(RV_EMPTY) type ABAP_BOOL .
  methods GET_ITEM
    importing
      !IV_INDEX type I
    returning
      value(RR_OBJECT) type ref to OBJECT .
  methods GET_ITERATOR
    returning
      value(RIF_ITERATOR) type ref to ZIF_ITERATOR .
endinterface.
