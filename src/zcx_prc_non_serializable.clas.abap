class ZCX_PRC_NON_SERIALIZABLE definition
  public
  inheriting from ZCX_PRC_PROCESS_EXCEPTION
  final
  create public .

public section.

  methods CONSTRUCTOR .
protected section.
private section.
ENDCLASS.



CLASS ZCX_PRC_NON_SERIALIZABLE IMPLEMENTATION.


  method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
.
  endmethod.
ENDCLASS.
