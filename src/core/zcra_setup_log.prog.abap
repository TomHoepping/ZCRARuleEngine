REPORT zcra_setup_log.

* One-time provisioning for the CRA Rule Engine logging infrastructure.
* Creates (idempotently):
*   - BAL log object ZCRA with subobjects RUN and RULE (SLG0 tables).
* BAL objects are not abapGit-serializable, so this report is the git-tracked,
* reproducible source of truth for their creation. Re-runnable safely.
*
* The message class ZCRA_ENGINE is provisioned separately via the abapGit
* serialization zcra_engine.msag.xml (deserialized on gCTS pull). It is NOT
* created here: RPY_MESSAGE_ID_INSERT returns name_not_allowed on this system.

CONSTANTS: gc_balobj  TYPE balobj-object VALUE 'ZCRA'.

START-OF-SELECTION.

* ---------------------------------------------------------------------
* BAL log object ZCRA + subobjects RUN, RULE
* ---------------------------------------------------------------------
  DATA ls_obj  TYPE balobj.
  DATA ls_objt TYPE balobjt.
  ls_obj-object = gc_balobj.
  MODIFY balobj FROM ls_obj.
  ls_objt-spras  = sy-langu.
  ls_objt-object = gc_balobj.
  ls_objt-objtxt = 'CRA Rule Engine'.
  MODIFY balobjt FROM ls_objt.

  DATA ls_sub  TYPE balsub.
  DATA ls_subt TYPE balsubt.

  ls_sub-object = gc_balobj.
  ls_sub-subobject = 'RUN'.
  INSERT balsub FROM ls_sub. "#EC dup key ok
  ls_subt-spras = sy-langu.
  ls_subt-object = gc_balobj.
  ls_subt-subobject = 'RUN'.
  ls_subt-subobjtxt = 'Engine run'.
  MODIFY balsubt FROM ls_subt.

  CLEAR ls_sub.
  CLEAR ls_subt.
  ls_sub-object = gc_balobj.
  ls_sub-subobject = 'RULE'.
  INSERT balsub FROM ls_sub. "#EC dup key ok
  ls_subt-spras = sy-langu.
  ls_subt-object = gc_balobj.
  ls_subt-subobject = 'RULE'.
  ls_subt-subobjtxt = 'Rule execution'.
  MODIFY balsubt FROM ls_subt.

  COMMIT WORK AND WAIT.
  WRITE: / 'BAL object', gc_balobj, '+ subobjects RUN, RULE provisioned'.
