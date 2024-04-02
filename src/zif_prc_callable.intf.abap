interface ZIF_PRC_CALLABLE
  public .


  interfaces IF_SERIALIZABLE_OBJECT .

  data MV_CPID type CHAR8 .
  data MV_GUID type SYSUUID_X16 .
  data MV_WPID type CHAR8 .

  methods CALL
    returning
      value(RV_RESULT) type ref to DATA .
endinterface.
