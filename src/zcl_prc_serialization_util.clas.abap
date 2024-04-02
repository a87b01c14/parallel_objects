class ZCL_PRC_SERIALIZATION_UTIL definition
  public
  final
  create public .

public section.

  class-methods SERIALIZE_RESULT
    importing
      !IR_RESULT type ANY
    returning
      value(RV_DATA) type ZPRCE_DATA
    raising
      ZCX_PRC_NON_SERIALIZABLE .
  class-methods DESERIALIZE_RESULT
    importing
      !IV_DATA type ZPRCE_DATA
    exporting
      value(ER_RESULT) type ANY
    raising
      ZCX_PRC_RETURN_TYPE_MISMATCH .
protected section.
private section.
ENDCLASS.



CLASS ZCL_PRC_SERIALIZATION_UTIL IMPLEMENTATION.


method deserialize_result.
  try.
      call transformation id_indent
      source xml iv_data
      result obj = er_result.
    catch cx_xslt_format_error.
      raise exception type zcx_prc_return_type_mismatch.
  endtry.
endmethod.


method serialize_result.
  try.
      call transformation id_indent
      source obj = ir_result
      result xml rv_data.
    catch cx_root.
      raise exception type zcx_prc_non_serializable.
  endtry.
endmethod.
ENDCLASS.
