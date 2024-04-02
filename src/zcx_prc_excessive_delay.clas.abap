class ZCX_PRC_EXCESSIVE_DELAY definition
  public
  inheriting from ZCX_PRC_PROCESS_EXCEPTION
  final
  create public .

public section.

  methods CONSTRUCTOR .
protected section.
private section.
ENDCLASS.



CLASS ZCX_PRC_EXCESSIVE_DELAY IMPLEMENTATION.


  method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
.
  endmethod.
ENDCLASS.
