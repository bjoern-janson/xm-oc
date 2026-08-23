# REAL-XM-AUTHORITY-001 — replication v3 segmented execution recovery

Status: **FRESH 15-MEMBER RERUN REQUIRED / V3 SEGMENTED EXECUTION FROZEN / UNRUN**.

Scientific protocol and endpoint remain those frozen in `REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION.md`.

Frozen scientific/apparatus SHA:

`be7cefd60cf199e9fbabd6110be1254a1756590e`

Frozen recovered scientific execution bundle used inside every member:

`30cacad1aa73b5b860f5057b5e1bb8b75b4b000f`

## Why v3 exists

Replication v2 completed and audited 14/15 members, but the Kaggle execution terminated without an internal diagnostic during seed 505 / K=12. A later custody-only check found `/kaggle/working` empty in the new session, so none of the 14 measurement-bearing artifacts survived.

Therefore the minimal 14+1 recovery is inadmissible and the clean fallback is a complete fresh 15-member rerun.

The interruption cause remains unknown. V3 does not assert a cause. It only removes dependence on one long-lived Kaggle runtime by executing and preserving one complete training-seed block per invocation.

## Scientific invariants

Unchanged:

- independent replication seeds `{101,202,303,404,505}`;
- matched `K={2,8,12}` within every seed block;
- same frozen model/XM/observer code;
- same matched ImageNet specimen and exact custody hashes;
- same optimizer, schedule, CFG, region map, holdout bank, precision, and 2049-step horizon;
- same checkpoint-free infrastructure recovery (`save_top_k=0`, external `save_last=False`, Q_gen out of scope);
- same primary endpoint and contrast;
- same finite-count marginal calibration and secondary stable-region diagnostic.

No seed, K, endpoint, region, or mechanism is changed.

## Execution segmentation

Frozen v3 script commit:

`411528744cc1b91cb4d252e7ddafacb87b648038`

Seed-block launcher:

`infra/kaggle_real_xm_authority_001_high_k_replication_v3_seed_block.sh`

Run exactly once for each preregistered seed. Each invocation runs all three K values, audits all three members, and emits one archive:

`real_xm_authority_001_seed<SEED>_block.tar.gz`

The archive contains the three observer JSONLs, train logs, member audits/custody ledgers, environment audit, exact data manifest, and execution-bundle identity. It does not contain checkpoints or cached latents.

Each archive must be preserved outside the ephemeral Kaggle session before that session ends.

The seed-block launcher explicitly does **not** run the five-seed summarizer or expose the primary endpoint.

## Endpoint opening

After all five seed-block archives exist, use the separately frozen assembly script from the same commit:

`infra/kaggle_real_xm_authority_001_high_k_replication_v3_assemble.sh`

The assembly script:

1. requires exactly one archive for each seed;
2. verifies frozen SHA, execution-bundle identity, exact ImageNet specimen hashes, and `primary_endpoint_opened=false` metadata;
3. re-audits all 15 observer artifacts structurally;
4. verifies zero checkpoints;
5. retrieves the already-frozen summarizer and checks its exact SHA-256;
6. only after all 15 pass, invokes that summarizer once and opens the preregistered five-seed endpoint.

## Claim state

Until assembly succeeds:

`REPLICATION_V2_INCOMPLETE -> CUSTODY_FAIL -> FULL_15_MEMBER_RERUN_REQUIRED`.

No four-seed or partial result is replication evidence.
