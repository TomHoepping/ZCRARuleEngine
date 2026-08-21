---
applyTo: "**/*.abap"
---

# ABAP coding conventions — ZCRA Rule Engine

Distilled, always-on rules for ABAP source. Full rationale (decision anchors D-xx,
guardrails G-xx) is in `../../DEVELOPMENT_GUIDELINES.md` and `../../TOOLING.md` — read
those when a rule's *why* matters.

## Language & style
- **ABAP 7.50 classic OO.** Use modern constructs: inline `DATA(...)` / `FINAL(...)`,
  `NEW #( )`, `VALUE #( )`, `CORRESPONDING #( )`, `REF #( )`, `COND`/`SWITCH`, table
  expressions `tab[ key = ... ]` + `line_exists( )`, `REDUCE`/`FILTER`, string templates,
  `RAISE EXCEPTION TYPE ... MESSAGE ...`.
- **Forbidden:** `HEADER LINES`/`OCCURS`/`WITH HEADER LINE`/`RANGES`, `MOVE(-CORRESPONDING)`,
  `CALL METHOD`, `CHECK`/`EXIT` inside methods (use guard clauses + `RETURN`), classic
  parameter exceptions, `WRITE`/list-processing for business logic, static
  `CREATE OBJECT` of collaborators (use constructor injection).
- **Keywords UPPERCASE** (Swisscom linter requirement; Pretty Printer `keywordUpper`).

## Naming — NO Hungarian notation (G-NAME-1)
- **Keep** repository object prefixes only: `ZCRA_CL_`, `ZCRA_IF_`, `ZCRA_S_`, `ZCRA_T_`,
  `ZCRA_CX_`, `ZCRA_D_`, `ZCRA_IF_C_` (constants pools).
- **Drop all** `iv_/is_/it_/io_/ev_/cv_/rv_/ro_/mv_/mo_/lt_/ls_/lo_/gv_` prefixes on locals,
  parameters and members. Names state **intent/role**, not type/scope. Members via `me->`.
  Returning parameter is usually `result`; loop work areas named by role (`rule`, `address`).
- Methods verb-first; boolean queries `is_`/`has_`/`can_` returning `abap_bool`.
- Watch reserved words when de-Hungarianising: `rule_type` (not `type`), `severity`, etc.
- No `ENUM` in 7.50 → model type/kind as constants interfaces (`ZCRA_IF_C_RULE_TYPE`,
  `ZCRA_IF_C_RULE_KIND`), typed via a data element; never magic literals.

## Comments & docs (G-TOOL-4)
- **Code comments and ABAP-Doc in German; identifiers stay English.**
- `"! ...` ABAP-Doc on every **public** method (params + intent). Each rule documents the
  graph sections it reads/writes and its `rule_id`/purpose.
- ABAP-Doc must not contain `<...>` (parsed as HTML → syntax error) — write `..._...` instead.

## Architecture rules
- **One-way dependency `PAYLOAD → CORE`** (G-PKG-1 / D-35). CORE never references PAYLOAD.
  Callers depend on `ZCRA_IF_*`, never on a concrete rule class.
- **Rules are pure & stateless** (D-21/D-31/D-32): no run-scoped state, **no I/O**
  (`SELECT`/RFC/BAPI/`COMMIT`/`AUTHORITY-CHECK`) inside a rule — the caller pre-loads all
  facts into the context. `validate( )` gets a read context; `transform( )` gets the
  mutable context and mutates **`new` only**.
- **Dependency injection** via constructor (logger, determination, factory) into
  `ZCRA_CL_ENGINE`. Direct `NEW` via compile-time class refs; **no dynamic
  `CREATE OBJECT (name)`** (D-39).

## Error handling — two separate channels (never mix)
- **Business findings → `BAPIRET2`** on `ZCRA_CL_RESULT` (collect messages; blocking = 
  `request_stop( )`). **Never raise an exception for a business error.**
- **Technical faults → class-based `ZCRA_CX_*`** (chain `PREVIOUS`, `TEXTID`s). Never put
  technical faults into the BAPIRET2 business result.

## Testing (G-TEST)
- One ABAP-Unit class per rule, `FOR TESTING DURATION SHORT RISK LEVEL HARMLESS`, **no DB /
  no system dependency**. Engine tests use a mock determination + stub rules (injected).
- Include an idempotency test (run twice, identical result). Build fixtures via graph builders.

## DDIC container (ZCRA_S_GRAPH)
- **Append-only** (append structures / CI includes); never rename/repurpose/remove
  components. Enhancement category "Can be enhanced (deep)". Never persist the raw deep
  structure — serialize (JSON via `/ui2/cl_json`) for the log snapshot.
