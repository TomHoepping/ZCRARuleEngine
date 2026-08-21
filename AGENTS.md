# AGENTS.md — ZCRA Rule Engine

Operational context for AI agents working on this repo. Coding conventions live in
`.github/instructions/abap.instructions.md` (auto-scoped to `**/*.abap`); the full
rationale is in `../DEVELOPMENT_GUIDELINES.md` and `../REQUIREMENTS_v2.1-working.md`.

## What this is
Custom SAP ABAP rule engine (validation + transformation) for OIZ citizen processes.
Two packages, strict one-way dependency:

```
ZCRA_RULE_ENGINE                structure package (no code)
├── ZCRA_RULE_ENGINE_CORE       engine, interfaces (ZCRA_IF_*), base classes, result,
│                               loggers, factory, canonical container ZCRA_S_GRAPH
└── ZCRA_RULE_ENGINE_PAYLOAD    concrete rules (ZCRA_CL_VAL_* / ZCRA_CL_TRN_*),
                                per-process determination (ZCRA_CL_DET_*), registry
```
**CORE must never reference PAYLOAD** (G-PKG-1 / D-35). Enforced via boundary check.

## Environment
- **System / client:** S01 / 300 (S/4 on-prem, gCTS-managed). ABAP 7.50 classic OO.
- **Transport:** `S01K901334`.
- **Access:** the **VS-Punk (Vibing Steampunk) ADT↔MCP bridge** (`vsp` / `SAP(...)` tool).
  Credentials live in the MCP config — **never hard-code or commit them**. The MCP
  connects as user **TAAHOTO2**. Docs: https://github.com/oisee/vibing-steampunk
- **Repo ↔ system:** git-first. Edit files here → deploy into S01 → run AUnit/ATC →
  commit/push → the developer gCTS-pulls into ADT. Do **not** hand-edit on the backend
  and in the repo in the same change (divergence risk).

## MCP operational playbook (hard-won — read before deploying)
1. **Deploy sequentially, never in parallel.** Parallel `deploy_from_file` calls each
   lock their object and cross-fail activation ("User TAAHOTO2 is currently editing X").
   One deploy per message.
2. **New/changed class = deploy the main *and* the test include.** `deploy_from_file`
   syntax-gates the main source together with the currently-active `.clas.testclasses`.
   If a rename breaks the old test include, deploy a **blank testclasses** (a single
   comment — always passes) first, then the main, then the real testclasses. Each step
   auto-activates.
3. **Standalone testclasses deploy is more lenient than the combined check.** After
   deploying a testclasses include, **re-deploy the main class** to force a combined
   re-activation — this both surfaces latent syntax errors and rebuilds the ADT
   test-relation index (otherwise `test` returns `{"classes":[]}`).
4. **Stale locks** (from your own failed-activation deploys, gname `SEOCLSENQ`, garg
   starts with the class name) are cleared with `ENQUE_DELETE` (function group SENQ) via
   `execute_abap` — **only after confirming no human has unsaved ADT edits**.
5. **`execute_abap` cannot `WRITE`.** It wraps code in a unit-test method; surface output
   via `cl_abap_unit_assert=>fail( msg = ... )` (appears under "Raw Alerts"). Keep every
   line **≤ 255 chars** or the ADT source update rejects it (split long string templates).
6. **ABAP-Doc rejects `<...>` (parsed as HTML).** Don't write `ZCRA_CL_DET_<PROCESS>` in a
   `"!` comment; use `ZCRA_CL_DET_...`.

### Common calls
```
SAP(action="system",  params={type:"deploy_from_file", file_path, package_name, transport:"S01K901334"})
SAP(action="test",    params={object_url:"/sap/bc/adt/oo/classes/<name>"})            # AUnit — no alerts = pass
SAP(action="test",    params={type:"atc", object_url:"/sap/bc/adt/oo/classes/<name>"})
SAP(action="analyze", params={type:"check_boundaries", package:"ZCRA_RULE_ENGINE_PAYLOAD", whitelist:"ZCRA_RULE_ENGINE_CORE"})
SAP(action="analyze", params={type:"execute_abap", code:"..."})                       # quick end-to-end probe
```

## Merge gate (run before every commit)
- **AUnit:** all suites green.
- **ATC:** **zero new priority-1/2** findings. P3 infos are baseline-accepted (see
  `TOOLING.md`): system SLIN/TTZCU time-zone notes + "strings without text elements" in
  console/logger code.
- **Boundaries:** `check_boundaries` **CLEAN** both packages.
- Then commit + push and tell the developer to **gCTS-pull** (this also brings program
  text pools, which `deploy_from_file` does not transfer).

## Key entry points
- `ZCRA_CL_ENGINE_RUNNER` (CORE) — facade: `run( input_graph, process )`, log mode
  none/console/slg1; `get_trace_lines()` (console only), `get_result_graph()`.
- `ZCRA_CL_DET_REGISTRY` (PAYLOAD) — static `build()` = compile-time process→determination map.
- `ZCRA_CL_DEMO_RUN` (ADT console, F9) and `ZCRA_TEST_ENGINE` (classic SE38 report) — debug shells.

## Commit convention
Include the trailer: `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`
