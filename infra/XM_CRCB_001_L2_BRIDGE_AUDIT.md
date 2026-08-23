# XM-CRCB-001 L2 provenance bridge audit

Status: **STATIC BRIDGE AUDIT PASS / L2 EXECUTION UNRUN**

Audited bridge-content head: `706e806ee5f5e6ef6a2d7a9c1da635081dc2e541`

Frozen predecessor orchestration commit: `f40d06d38bb75ae1f2b6ae1d14e2dca9fad4da8b`

Frozen calibration apparatus: `b8caf8ffcc0a3bbd4fabfbc610b0767293e11aff`

## Scope audit

Comparison against the frozen L1 orchestrator adds only:

- `infra/xm_crcb_001_l1_result_freeze.json`
- `infra/kaggle_xm_crcb_001_l2_calibration.sh`
- `infra/kaggle_xm_crcb_001_l2_calibration_frozen.sh`

No organism, calibration-core, real-runner, evaluator, observer, optimizer, dataset, protocol, parity, factorization, or science file is modified.

## Immutable predecessor binding

The bridge hard-binds:

- `calibration_L1_result.json` SHA-256: `b111d63df0aa14e4fa6495b4fd9b4f285a295d554f9e43a6c9ec54c41a251bf7`
- L1 custody manifest SHA-256: `2cdc66502079012ea8fd6d5c81c5dbb0032e12284f240fd938391adc82f952f7`
- L1 result archive SHA-256: `e5ff8f9cd7d6ffa7d3f6b906e7ea83ce06e3d0bf8f0b7182b808557ae0710fb2`
- frozen L1 classification: `LANGUAGE_FAIL`
- frozen orchestration endpoint: `L1_CALIBRATION_FAIL`

The predecessor is verified as an immutable prior. It is not recomputed and its classification is not reinterpreted.

## Frozen language semantics

The frozen calibration core defines:

- L2 label: `full_final_layer`
- L2 parameter family: `diffusion_transformer.final_layer.*`
- L2 prior requirement: exactly one prior, language `L1`, classification `LANGUAGE_FAIL`
- calibration bases: `606, 707`
- repair seeds: `1101, 1102, 1103`
- construction indices: `0..63`
- evaluation indices: `64..127`
- science-reserved indices: `128..255`
- construction steps: `J=32`

The L2 launcher exposes no caller-controlled language selector. Its sole scientific invocation is hard-coded to `--language L2` and passes the exact frozen L1 result as the sole `--prior-result`.

## Endpoint audit

Only the following orchestration transitions are admitted:

- genuine `LANGUAGE_PASS` with null/custody pass -> `L2_CALIBRATION_PASS`, `L_A_star=L2`, L3 forbidden
- genuine `LANGUAGE_FAIL` with null/custody pass -> `L2_CALIBRATION_FAIL`, L3 authorized
- null/custody/apparatus failure -> `CALIBRATION_APPARATUS_FAILURE`, no language escalation

In all cases:

- factorization remains unauthorized
- parity remains unopened
- held-out science remains unauthorized

## Storage/custody hardening

The bridge verifies the full 606/707 archive hashes and the full L1 predecessor-result archive hash before extraction. It rejects unsafe archive members and performs a writable-storage preflight before unpacking the large base organisms, so an insufficient-disk condition fails before a partial scientific setup.

## Claim ceiling

`L2 calibration adequacy != H_CRCB evidence != factorization result.`

This audit authorizes freezing the bridge implementation only. **It does not authorize or report an L2 calibration result.**
