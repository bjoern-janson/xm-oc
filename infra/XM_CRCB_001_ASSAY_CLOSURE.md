# XM-CRCB-001 assay closure

Status: **TERMINAL CALIBRATION NEGATIVE / ASSAY CLOSED**

Terminal result freeze commit: `1dda3fff714320d3329f6ca5ca4a4ca50c9f7b45`

Frozen calibration apparatus: `b8caf8ffcc0a3bbd4fabfbc610b0767293e11aff`

## Earned result

Under the frozen XM-CRCB-001 calibration regime, none of the three preregistered parameter-local repair languages met the preregistered adequacy predicate:

1. `L1 = final_layer.linear` -> `LANGUAGE_FAIL`
2. `L2 = full final_layer` -> `LANGUAGE_FAIL`
3. `L3 = blocks[-1] + full final_layer` -> `LANGUAGE_FAIL`

Therefore the terminal calibration endpoint is:

`REPAIR_LANGUAGE_INSUFFICIENT`

This endpoint is local to the preregistered family `L1 subset L2 subset L3` under the frozen calibration protocol.

## Scientific statement

Under the frozen XM-CRCB-001 calibration regime, none of the three predeclared parameter-local repair languages produced sufficiently repeatable, target-specific improvement while satisfying the frozen collateral-damage constraints.

## What remains unresolved

The calibration protocol does not identify which of the following generated the failure:

1. **Representation failure** — `L1:L3` cannot express the required correction.
2. **Optimization / credit-assignment failure** — the language may be expressive enough, but the frozen `J=32` construction procedure does not find an adequate correction.
3. **Structural failure** — the chosen regional competence differences may not be locally repairable in this form.

No post-hoc experiment inside XM-CRCB-001 may be used to choose among these explanations.

## Non-implications

`REPAIR_LANGUAGE_INSUFFICIENT` does **not** establish:

- repair impossibility in general;
- `H_CRCB` falsehood;
- factorization failure;
- factorization impossibility;
- inadequacy of every possible repair substrate;
- inadequacy of every optimizer, repair horizon, or construction procedure.

## Gating consequences

Because the direct-repair adequacy gate failed for every preregistered language:

- calibration is closed;
- no `L4` is authorized;
- factorization protocol preparation is unauthorized;
- factorization execution is unauthorized;
- parity construction remains sealed;
- the held-out science endpoint remains sealed.

## Program-level status

`H_CRCB` remains **OPEN / UNTESTED BY XM-CRCB-001** because XM-CRCB-001 never established the necessary primitive repair-substrate viability condition required to reach the factorization test.

The terminal negative therefore preserves the distinction:

`repair usefulness != repairability in a chosen substrate != repair factorization != CC-specific mechanism`.

## Reopening rule

XM-CRCB-001 is closed as an assay, not paused.

Any future work that introduces a newly justified repair substrate, larger parameter scope, different optimizer, different construction horizon, altered thresholds, altered evaluator, altered target geometry, or other substantive calibration redesign must be prospectively specified as a **new assay with a new identity**. It must not be described as a continuation, rescue, extension, or additional rung of XM-CRCB-001.

No future positive result may retroactively alter this terminal negative.
