#!/usr/bin/env python3
"""Run frozen train_model.py through its existing --is_random_seed path with a fixed seed.

This helper does not edit the scientific checkout. It substitutes exactly one
random.randint result, restores the original function immediately, then lets
frozen train_model.main call Lightning seed_everything(seed, workers=True).
"""

from __future__ import annotations

import argparse
import sys


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

    original_randint = train_model.random.randint
    calls = {"n": 0}

    def one_shot_randint(a: int, b: int) -> int:
        calls["n"] += 1
        # Restore globally before seed_everything or any downstream code executes.
        train_model.random.randint = original_randint
        if calls["n"] != 1:
            raise RuntimeError("seed injection path called more than once")
        if not a <= seed <= b:
            raise RuntimeError(f"seed {seed} outside requested randint range [{a}, {b}]")
        print(f"REPLICATION_SEED_INJECTION {seed}", flush=True)
        return seed

    train_model.random.randint = one_shot_randint
    try:
        train_model.main(args)
    finally:
        train_model.random.randint = original_randint

    if calls["n"] != 1:
        raise RuntimeError(f"expected exactly one seed injection call, observed {calls['n']}")


if __name__ == "__main__":
    main()
