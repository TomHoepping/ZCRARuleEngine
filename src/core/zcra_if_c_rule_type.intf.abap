interface zcra_if_c_rule_type
  public .

  "! Rule TYPE = the determination bucket a rule is placed in (D-24, D-33).
  "! Distinct from KIND (V/T, intrinsic to the rule): both validation buckets
  "! dispatch to validate( ), so a validation rule is reusable in PRE or POST.
  types ty_type type c length 1 .

  "! Pre-transformation validation bucket.
  constants validation_pre  type ty_type value '1' .
  "! Transformation bucket.
  constants transformation  type ty_type value '2' .
  "! Post-transformation validation bucket.
  constants validation_post type ty_type value '3' .

endinterface.
