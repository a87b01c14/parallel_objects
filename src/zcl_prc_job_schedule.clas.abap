class ZCL_PRC_JOB_SCHEDULE definition
  public
  final
  create public .

public section.

  interfaces IF_SERIALIZABLE_OBJECT .

  constants HIGH_PRIORITY type CHAR1 value 'A' ##NO_TEXT.
  constants MEDIUM_PRIORITY type CHAR1 value 'B' ##NO_TEXT.
  constants LOW_PRIORITY type CHAR1 value 'C' ##NO_TEXT.

  methods CONSTRUCTOR
    importing
      value(DATE) type DATS default SY-DATUM
      value(TIME) type TIMS default SY-UZEIT
      value(JOBNAME) type STRING default 'Z_PRC_BACKGROUND_JOB'
      value(PRIORITY) type CHAR1 default MEDIUM_PRIORITY .
  methods TIME
    returning
      value(TIME) type TIMS .
  methods DATE
    returning
      value(DATE) type DATS .
  methods JOBNAME
    returning
      value(JOBNAME) type STRING .
  methods PRIORITY
    returning
      value(PRIORITY) type CHAR1 .
protected section.
private section.

  data _TIME type TIMS .
  data _DATE type DATS .
  data _JOBNAME type STRING .
  data _PRIORITY type CHAR1 .
ENDCLASS.



CLASS ZCL_PRC_JOB_SCHEDULE IMPLEMENTATION.


method constructor.

    _date = date.
    _time = time.
    _jobname = jobname.
    _priority = priority.

    if sy-uzeit gt _time and sy-datum eq _date.
      _date = _date + 1. "... Increment this
    endif.
  endmethod.


method DATE.
    date = _date.
  endmethod.


method JOBNAME.
    jobname = _jobname.
  endmethod.


method PRIORITY.
    priority = _priority.
  endmethod.


method TIME.
    time = _time.
  endmethod.
ENDCLASS.
