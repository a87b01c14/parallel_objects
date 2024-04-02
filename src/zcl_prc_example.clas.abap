class ZCL_PRC_EXAMPLE definition
  public
  final
  create public .

public section.

  interfaces IF_SERIALIZABLE_OBJECT .
  interfaces ZIF_PRC_RUNNABLE .
protected section.
private section.

  data MV_COUNT type I .
ENDCLASS.



CLASS ZCL_PRC_EXAMPLE IMPLEMENTATION.


method zif_prc_runnable~run.
  "... Do something that takes a long time
  write 'inside runnable'.
endmethod.
ENDCLASS.
