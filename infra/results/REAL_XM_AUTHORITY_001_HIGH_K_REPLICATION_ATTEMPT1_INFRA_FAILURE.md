# REAL-XM-AUTHORITY-001 high-K replication — attempt 1 infrastructure failure

Classification: `CHECKPOINT_IO_DISK_EXHAUSTION_BEFORE_REPLICATION_MEMBER_COMPLETION`.

Scientific status: **replication remains unrun / no confirmatory result opened**.

The first fresh-seed campaign invocation used:

- frozen scientific/apparatus SHA `be7cefd60cf199e9fbabd6110be1254a1756590e`;
- execution bundle SHA `4aa246b5ee80c565d1a8da7d41b4eae083361a2b`;
- seeds `{101,202,303,404,505}`;
- `K={2,8,12}`;
- matched ImageNet specimen and previously frozen cache hashes.

The environment, dataset revision, frozen cache, and numeric seed injection all passed. The run then started seed 101 / K=2 and completed the first 512-step training epoch plus validation. At epoch end, frozen `train_model.py` invoked its hard-coded `ModelCheckpoint(... save_last=True ...)` path. Writing the first `last.ckpt` failed with `OSError: [Errno 28] No space left on device` before the member could continue to steps 1024/1536/2048 or satisfy the preregistered member audit.

Therefore:

- no seed block was completed;
- the primary late endpoint was not observed for any seed;
- the primary `Delta_s^(12-2)` contrast was not observed;
- no result from this attempt is eligible as replication evidence.

The prior launcher attempted to hash and delete each checkpoint only **after** training. That safeguard was too late because Lightning writes `last.ckpt` at every epoch end. This is an execution/storage failure, not a scientific negative.

Prospective recovery boundary: disable checkpoint writes in the external replication harness while preserving the frozen model/XM/observer/training code and every scientific endpoint. Q_gen is out of scope for this replication, so checkpoints are not measurement-bearing artifacts. The same preregistered seeds, K values, data, observer, schedule, and primary endpoint remain unchanged.
