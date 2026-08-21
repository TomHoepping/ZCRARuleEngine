REPORT zcra_setup_log.

* Einmalige Bereitstellung der Logging-Infrastruktur der CRA Rule Engine.
* Erzeugt (idempotent):
*   - BAL-Protokollobjekt ZCRA mit Unterobjekten RUN und RULE (SLG0-Tabellen).
* BAL-Objekte sind nicht abapGit-serialisierbar, daher ist dieser Report die
* git-verwaltete, reproduzierbare Quelle ihrer Erzeugung. Gefahrlos wiederholbar.
*
* Die Nachrichtenklasse ZCRA_ENGINE wird separat über die abapGit-Serialisierung
* zcra_engine.msag.xml bereitgestellt (Deserialisierung beim gCTS-Pull). Sie wird
* hier NICHT erzeugt: RPY_MESSAGE_ID_INSERT liefert auf diesem System
* name_not_allowed.

CONSTANTS bal_object TYPE balobj-object VALUE 'ZCRA'.

START-OF-SELECTION.

* ---------------------------------------------------------------------
* BAL-Protokollobjekt ZCRA + Unterobjekte RUN, RULE
* ---------------------------------------------------------------------
  DATA log_object      TYPE balobj.
  DATA log_object_text TYPE balobjt.
  log_object-object = bal_object.
  MODIFY balobj FROM log_object.
  log_object_text-spras  = sy-langu.
  log_object_text-object = bal_object.
  log_object_text-objtxt = 'CRA Rule Engine'.
  MODIFY balobjt FROM log_object_text.

  DATA subobject      TYPE balsub.
  DATA subobject_text TYPE balsubt.

  subobject-object    = bal_object.
  subobject-subobject = 'RUN'.
  INSERT balsub FROM subobject. "#EC dup key ok
  subobject_text-spras     = sy-langu.
  subobject_text-object    = bal_object.
  subobject_text-subobject = 'RUN'.
  subobject_text-subobjtxt = 'Engine-Lauf'.
  MODIFY balsubt FROM subobject_text.

  CLEAR subobject.
  CLEAR subobject_text.
  subobject-object    = bal_object.
  subobject-subobject = 'RULE'.
  INSERT balsub FROM subobject. "#EC dup key ok
  subobject_text-spras     = sy-langu.
  subobject_text-object    = bal_object.
  subobject_text-subobject = 'RULE'.
  subobject_text-subobjtxt = 'Regelausführung'.
  MODIFY balsubt FROM subobject_text.

  COMMIT WORK AND WAIT.
  WRITE: / 'BAL-Objekt', bal_object, '+ Unterobjekte RUN, RULE bereitgestellt'.
