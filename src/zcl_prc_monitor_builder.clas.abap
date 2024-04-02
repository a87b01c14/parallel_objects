class ZCL_PRC_MONITOR_BUILDER definition
  public
  final
  create public .

public section.

  interfaces IF_SHM_BUILD_INSTANCE .
protected section.
private section.
ENDCLASS.



CLASS ZCL_PRC_MONITOR_BUILDER IMPLEMENTATION.


method if_shm_build_instance~build.
  data:
  lr_area type ref to zcl_prc_monitor_area,
  lr_root type ref to zcl_prc_monitor_access,
  lr_exc type ref to cx_root.

  try.
      lr_area = zcl_prc_monitor_area=>attach_for_write( 'ZCL_PRC_MONITOR_AREA' ).
    catch cx_shm_error into lr_exc.
      raise exception type cx_shm_build_failed
        exporting
          previous = lr_exc.
  endtry.

  create object lr_root area handle lr_area.
  lr_area->set_root( lr_root ).

  try.
      lr_area->detach_commit( ).
    catch cx_root into lr_exc.
*      raise exception type cx_shm_build_failed
*        exporting
*          previous = lr_exc.
  endtry.

  if invocation_mode = cl_shm_area=>invocation_mode_auto_build.
    call function 'DB_COMMIT'.
  endif.
endmethod.
ENDCLASS.
