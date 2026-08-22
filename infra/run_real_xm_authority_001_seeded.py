#!/usr/bin/env python3
"""Run frozen train_model.py through its existing --is_random_seed path with a fixed seed.

This helper does not edit the scientific checkout. It substitutes exactly one
random.randint result, restores the original function immediately, then lets
frozen train_model.main call Lightning seed_everything(seed, workers=True).

For the high-K replication only, it also suppresses ModelCheckpoint writes.
Frozen train_model.py hard-codes save_last=True even when save_top_k=0; the first
replication attempt exhausted Kaggle working storage while writing the first
epoch checkpoint. Checkpoints are not measurement-bearing for this replication
(Q_gen is out of scope), so the external harness forces save_last=False while
requiring save_top_k=0. No model/XM/observer/training file is edited.
"""

from __future__ import annotations

import argparse


def main() -> None:
    outer = argparse.ArgumentParser(add_help=False)
    outer.add_argument("--replication-seed", type=int, required=True)
    known, remaining = outer.parse_known_args()
    seed = int(known.replication_seed)
    if not 0 <= seed <= 1_000_000:
        raise ValueError(f"replication seed outside frozen random-seed range: {seed}")

    import train_model

    parser = train_model.get_parser()
    args = parser.parse_args(remaining)
    if not bool(args.is_random_seed):
        raise RuntimeError("seed harness requires frozen trainer flag --is_random_seed")
    if int(args.save_top_k_ckpts) != 0:
        raise RuntimeError("replication checkpoint suppression requires --save_top_k_ckpts 0")

    original_randint = train_model.random.randint
    original_model_checkpoint = train_model.ModelCheckpoint
    calls = {"seed": 0, "checkpoint": 0}

    def one_shot_randint(a: int, b: int) -> int:
        calls["seed"] += 1
        # Restore globally before seed_everything or any downstream code executes.
        train_model.random.randint = original_randint
        if calls["seed"] != 1:
            raise RuntimeError("seed injection path called more than once")
        if not a <= seed <= b:
            raise RuntimeError(f"seed {seed} outside requested randint range [{a}, {b}]")
        print(f"REPLICATION_SEED_INJECTION {seed}", flush=True)
        return seed

    def no_write_model_checkpoint(*args, **kwargs):
        calls["checkpoint"] += 1
        if int(kwargs.get("save_top_k", 0)) != 0:
            raise RuntimeError("unexpected nonzero save_top_k in replication")
        # Frozen trainer currently requests save_last=True. Suppress only the
        # storage side effect; retain the native callback object and hooks.
        kwargs["save_last"] = False
        print("REPLICATION_CHECKPOINT_WRITES_DISABLED", flush=True)
        return original_model_checkpoint(*args, **kwargs)

    train_model.random.randint = one_shot_randint
    train_model.ModelCheckpoint = no_write_model_checkpoint
    try:
        train_model.main(args)
    finally:
        train_model.random.randint = original_randint
        train_model.ModelCheckpoint = original_model_checkpoint

    if calls["seed"] != 1:
        raise RuntimeError(f"expected exactly one seed injection call, observed {calls['seed']}")
    if calls["checkpoint"] != 1:
        raise RuntimeError(f"expected exactly one checkpoint callback construction, observed {calls['checkpoint']}")


if __name__ == "__main__":
    main()
