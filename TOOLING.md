# Tooling baseline — ZCRA Rule Engine

Merge gate + formatter for the ZCRA Rule Engine (D-43, DEVELOPMENT_GUIDELINES.md §9).
Everything here is versioned alongside the code so the whole team shares one baseline.

## System & packages
- System / client: **S01 / 300** (S/4, gCTS-managed).
- Structure package `ZCRA_RULE_ENGINE` → sub-packages `ZCRA_RULE_ENGINE_CORE`
  (generic engine, interfaces, base classes, result, logger, factory, canonical
  context container) and `ZCRA_RULE_ENGINE_PAYLOAD` (concrete `ZCRA_CL_VAL_*` /
  `ZCRA_CL_TRN_*` rules, per-process `ZCRA_CL_DET_*`).
- Dependency direction is **strictly one-way `PAYLOAD → CORE`** (G-PKG-1, D-35).
  CORE must never reference PAYLOAD.

## abapGit link
- `.abapgit.xml`: `STARTING_FOLDER=/src/`, `FOLDER_LOGIC=PREFIX`, `MASTER_LANGUAGE=E`
  (matches the objects, which are all created with master language `E`).
- Code is versioned in this repo. Deployment to S01 is **git-first via gCTS**; abapGit
  serialization is kept consistent so the repo can also be linked/pulled through abapGit.

## ATC merge gate (G-TOOL-1)
Run through the VS-Punk MCP bridge:

```
# bundles ATC + package-boundary + staleness for a package
SAP(action="analyze", params={"type": "health", "package": "ZCRA_RULE_ENGINE_CORE"})

# raw ATC worklist for an object or package
SAP(action="test", params={"type": "atc", "object_url": "/sap/bc/adt/packages/zcra_rule_engine_core"})

# directional PAYLOAD -> CORE boundary check (G-PKG-1)
SAP(action="analyze", params={"type": "check_boundaries", "package": "ZCRA_RULE_ENGINE_PAYLOAD",
                              "whitelist": "ZCRA_RULE_ENGINE_CORE"})
```

**Intended check-variant composition** (SAP standard building blocks):
- SAP **clean-code** variant.
- S/4 **custom-code / clean-core** checks (released-API usage, no forbidden statements).
- The **package-dependency / use-access** check enforcing G-PKG-1.

**Gate rule:** **zero new priority-1 or priority-2 findings** to merge.

### Accepted residual findings (priority-3 info only)
The gate ignores priority-3 infos. Current CORE baseline (`health` = WARN, but
**0 errors / 0 warnings**, boundaries **CLEAN**):
- ~23× *"Inconsistency in the SAP configuration for the time zones … TTZCU … Note 481835"*
  — **system infrastructure** (SLIN cache), not our code; cannot be fixed from the package.
- A few *"Strings without text elements are not translated"* in `ZCRA_SETUP_LOG` (setup
  report WRITE output) and `ZCRA_CL_LOG_BAL` (technical BAL log texts). Priority-3, acceptable
  for a technical logger / one-off setup report.

## Formatter (G-TOOL-2, D-43)
- **Pretty Printer** (committed system setting on S01): indentation **on**, keyword case
  **upper** (`keywordUpper`). The Swisscom ABAP linter requires **UPPERCASE keywords**.
  > History: an earlier baseline used `keywordLower` (commit `977b4ad`); this was **reversed**
  > to `keywordUpper` to satisfy the linter. The whole codebase is re-formatted accordingly.
  ```
  SAP(action="analyze", params={"type": "set_pretty_printer_settings",
                                "indentation": true, "style": "upperCase"})
  ```
- **ABAP cleaner** (Eclipse plugin) shared profile — enable at least:
  - Align: ABAP Doc, declarations, assignments, method calls, logical expressions.
  - Clean up: remove needless `RETURNING`/`EXPORTING` keywords where inferable, use
    inline `DATA(...)`, `VALUE #( )` / `NEW #( )` constructor operators, `xsdbool`,
    string templates over `&&`/`CONCATENATE`.
  - Keep: **UPPERCASE keywords**, ABAP Doc `"! …` on every public interface method.
  Apply cleaner **before commit**; the Pretty Printer settings above are the fallback.

## Naming & comments (G-NAME-1, G-TOOL-4)
- **No Hungarian notation** on locals / parameters / members (`iv_/io_/mo_/lo_/ls_/rv_` … are
  removed). Only repository object prefixes stay (`ZCRA_CL_`, `ZCRA_IF_`, `ZCRA_S_`, …). Names
  state intent/role; members are addressed via `me->`. Returning params are usually `result`.
  Watch reserved words: use `rule_type` (not `type`), `severity` (message type), etc.
- **Code comments and ABAP Doc are written in German**; **identifiers stay English** (SAP norm).
- **ABAP Doc** `"! …` on every **public** method (params + intent). Each rule documents the
  graph sections it reads/writes and its `rule_id` / purpose (D-33).

## Accepted residual ATC findings (baseline)
Priority-3 infos only; both packages **0 errors / 0 warnings**, boundaries **CLEAN**:
- CORE `health` = WARN with **29 P3 infos**; PAYLOAD **18 P3 infos**.
- Dominated by system-infra *TTZCU / time-zone (Note 481835)* SLIN notes (not our code) and a
  few *"Strings without text elements"* in `ZCRA_SETUP_LOG` / `ZCRA_CL_LOG_BAL`. Acceptable.
