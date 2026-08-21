INTERFACE zcra_if_c_rule_type
  PUBLIC.

  "! Regel-TYPE = der Determination-Bucket, in den eine Regel gelegt wird (D-24, D-33).
  "! Verschieden von KIND (V/T, der Regel innewohnend): beide Validierungs-Buckets
  "! rufen validate( ) auf, daher ist eine Validierungsregel in PRE oder POST nutzbar.
  TYPES ty_type TYPE c LENGTH 1.

  "! Validierungs-Bucket vor der Transformation.
  CONSTANTS validation_pre  TYPE ty_type VALUE '1'.
  "! Transformations-Bucket.
  CONSTANTS transformation  TYPE ty_type VALUE '2'.
  "! Validierungs-Bucket nach der Transformation.
  CONSTANTS validation_post TYPE ty_type VALUE '3'.

ENDINTERFACE.
