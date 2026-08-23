# REAL-XM-AUTHORITY-001 — V3 all-block custody verification

Classification: `ASSEMBLED_15_MEMBER_CUSTODY_PASS`

This record is custody/apparatus only. The preregistered five-seed scientific endpoint was **not opened** during this verification.

## Frozen identities

- Scientific/apparatus SHA: `be7cefd60cf199e9fbabd6110be1254a1756590e`
- Execution bundle SHA: `30cacad1aa73b5b860f5057b5e1bb8b75b4b000f`
- V3 assembly script commit: `411528744cc1b91cb4d252e7ddafacb87b648038`
- Seeds: `{101,202,303,404,505}`
- K values: `{2,8,12}`

## Uploaded archive identities

| Seed | SHA-256 |
|---:|---|
| 101 | `71ed01d83bcab39207e1069a03e9cc9eb32ae7d0195df5b842d87709ee327f8f` |
| 202 | `d59e56f98a1391daca34fcb92807eb6d43267673fecf67c8b403bef5ca0282d0` |
| 303 | `d00fc9a9137cd8d58bc3ba02c96d5aa5512a410ca34dc2acaf1fc1b2f0ab6aea` |
| 404 | `96a6dfb4d627a19169c50793db8ab0afd51f0cb3118340b29ff98cdecdcd0587` |
| 505 | `c951846db6191c162542cd873c6e14500ed4ef70f82c96f9a2a7e6b9433f2273` |

All five archives passed gzip and tar integrity checks.

## Frozen pre-endpoint assembly checks reproduced

For every seed block:

- block kind, seed, K list, frozen SHA, execution-bundle SHA, dataset and dataset revision matched;
- `primary_endpoint_opened == false`;
- train/validation RGB-label and latent hashes matched the frozen specimen;
- execution-bundle ledger contained the frozen build-cache, protocol, seeded-runner and summarizer hashes.

For all 15 `(seed,K)` members:

- observer JSONL existed;
- exactly one partition record with coordinates `[808,1575,2250,2349]` and region seed `314159`;
- exactly 2049 `train_authority` records with steps `0..2048`;
- exactly four `q_hold` records at steps `512,1024,1536,2048`;
- recorded K and batch size 8 matched;
- all train records had `replay_checked=true`;
- candidate-slot totals equaled `2049*8*K`;
- winner totals equaled `2049*8`;
- train exit code was `0`;
- member audit contained `REPLICATION_MEMBER_AUDIT_PASS`;
- no `.ckpt` files were present;
- each member custody ledger re-hashed successfully against the extracted files.

Terminal custody marker reproduced locally:

`ASSEMBLED_15_MEMBER_CUSTODY_PASS`

## Claim ceiling

This establishes that the five preserved V3 archives jointly satisfy the frozen assembler's custody/structure checks through the point immediately before scientific summarization. It does **not** report `Z_late`, `Delta`, null results, stable-region diagnostics, or any five-seed scientific conclusion.

Next authorized operation: execute the frozen V3 assembly/summarizer exactly once, with all five custody-valid archives present together.
