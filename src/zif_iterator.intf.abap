interface ZIF_ITERATOR
  public .


  methods GET_INDEX
    returning
      value(RV_INDEX) type I .
  methods HAS_NEXT
    returning
      value(RV_HASNEXT) type ABAP_BOOL .
  methods NEXT
    returning
      value(RR_OBJECT) type ref to OBJECT .
  methods FIRST
    returning
      value(RR_OBJECT) type ref to OBJECT .
  methods LAST
    returning
      value(RR_OBJECT) type ref to OBJECT .
  methods CURRENT
    returning
      value(RR_OBJECT) type ref to OBJECT .
endinterface.
