# XM-CRCB-001 L3 provenance bridge audit

Status: **STATIC BRIDGE AUDIT PASS / L3 EXECUTION UNRUN**

Base result freeze: `9ded68ec10f7dab8b0de8aeba2ffce1a9bceb7d6`

Frozen calibration apparatus: `b8caf8ffcc0a3bbd4fabfbc610b0767293e11aff`

## Scope

Relative to the frozen L2 result, this bridge adds only:

- `infra/kaggle_xm_crcb_001_l3_calibration_frozen.sh`
- `infra/kaggle_xm_crcb_001_l3_calibration_bridge.sh`

No organism, calibration-core, real-runner, evaluator, optimizer, observer, dataset, protocol, parity, factorization, or science file is modified.

## Immutable predecessor chain

The bridge hard-binds:

- L1 result SHA-256: `b111d63df0aa14e4fa6495b4fd9b4f285a295d554f9e43a6c9ec54c41a251bf7`
- L1 result archive SHA-256: `e5ff8f9cd7d6ffa7d3f6b906e7ea83ce06e3d0bf8f0b7182b808557ae0710fb2`
- L2 result SHA-256: `73579a4a5fad030b4f893b64e52fc0ab74a75cca959b133febd218835d43a16f`
- L2 result archive SHA-256: `70f65a9a377a767768cac11934b09b7e18eecdae634e75e8369f3248650f402a`
- L1 classification: `LANGUAGE_FAIL`
- L2 classification: `LANGUAGE_FAIL`

The frozen core requires L3 priors exactly in the order `[L1, L2]` and defines L3 as `final transformer block + full final_layer`.

## Scientific invocation

The launcher exposes no language selector. Its sole scientific call is `run-language --language L3` with the exact frozen L1 and L2 results as the two `--prior-result` inputs. Construction budget, optimizer, thresholds, seeds, construction/evaluation partitions, null audit, and success predicate remain those of the frozen apparatus.

## Terminal endpoints

- genuine `LANGUAGE_PASS` with null/custody pass -> `L3_CALIBRATION_PASS`, `L_A_star=L3`, calibration closed; factorization protocol preparation becomes eligible, but factorization execution and science remain unauthorized.
- genuine `LANGUAGE_FAIL` with null/custody pass -> `REPAIR_LANGUAGE_INSUFFICIENT`, calibration closed; factorization and science remain unauthorized.
- apparatus/custody/infrastructure failure -> no scientific update.

No language beyond L3 is introduced.

Claim ceiling: `L3 calibration adequacy != H_CRCB evidence != factorization result.`

This audit freezes the bridge only. **It does not report an L3 result.**
