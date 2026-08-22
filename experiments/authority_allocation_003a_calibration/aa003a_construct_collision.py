#!/usr/bin/env python3
"""AA-003a construction calibration only.

Search deterministically for two developmental authority schedules that end with
identical present competence (theta, loss) but different persistent momentum.

This script contains no post-boundary future and no recovery assay.
"""

from __future__ import annotations

import argparse
import json
from fractions import Fraction
from itertools import product
from pathlib import Path

TARGET = Fraction(1, 1)
THETA0 = Fraction(0, 1)
M0 = Fraction(0, 1)
BETA = Fraction(9, 10)
ETA = Fraction(1, 20)
AUTHORITY_ALPHABET = (Fraction(0, 1), Fraction(1, 2), Fraction(1, 1))
MAX_STEPS = 8


def frac(x: Fraction) -> str:
    return f"{x.numerator}/{x.denominator}"


def run(schedule: tuple[Fraction, ...]) -> dict[str, object]:
    theta = THETA0
    momentum = M0
    update_mass = Fraction(0, 1)
    trace = []

    for step, authority in enumerate(schedule, 1):
        grad = 2 * (theta - TARGET)
        next_momentum = BETA * momentum + authority * grad
        next_theta = theta - ETA * next_momentum
        delta = next_theta - theta
        update_mass += abs(delta)
        trace.append(
            {
                "step": step,
                "authority": frac(authority),
                "theta_before": frac(theta),
                "gradient": frac(grad),
                "momentum_after": frac(next_momentum),
                "theta_after": frac(next_theta),
                "abs_delta_theta": frac(abs(delta)),
            }
        )
        theta = next_theta
        momentum = next_momentum

    loss = (theta - TARGET) ** 2
    return {
        "schedule": [frac(a) for a in schedule],
        "theta": theta,
        "momentum": momentum,
        "loss": loss,
        "U_pre": update_mass,
        "trace": trace,
    }


def find_collision() -> tuple[int, dict[str, object], dict[str, object]]:
    """Return the first exact theta collision with unequal terminal momentum."""
    for steps in range(1, MAX_STEPS + 1):
        by_theta: dict[Fraction, list[dict[str, object]]] = {}
        for schedule in product(AUTHORITY_ALPHABET, repeat=steps):
            record = run(schedule)
            theta = record["theta"]
            assert isinstance(theta, Fraction)
            for prior in by_theta.get(theta, []):
                if prior["momentum"] != record["momentum"]:
                    assert prior["loss"] == record["loss"]
                    return steps, prior, record
            by_theta.setdefault(theta, []).append(record)
    raise RuntimeError("No exact collision found in frozen calibration search space")


def serialize(record: dict[str, object]) -> dict[str, object]:
    return {
        "schedule": record["schedule"],
        "theta_exact": frac(record["theta"]),
        "theta_float": float(record["theta"]),
        "loss_exact": frac(record["loss"]),
        "loss_float": float(record["loss"]),
        "momentum_exact": frac(record["momentum"]),
        "momentum_float": float(record["momentum"]),
        "U_pre_exact": frac(record["U_pre"]),
        "U_pre_float": float(record["U_pre"]),
        "trace": record["trace"],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()

    steps, h1, h2 = find_collision()

    # Construction success criterion: exact present-state collision, unequal hidden state.
    assert h1["theta"] == h2["theta"]
    assert h1["loss"] == h2["loss"]
    assert h1["momentum"] != h2["momentum"]

    result = {
        "artifact": "AA-003a construction calibration",
        "status": "CONSTRUCTION_COLLISION_FOUND",
        "scope": "calibration_only_no_future_recovery_executed",
        "dynamics": {
            "target": frac(TARGET),
            "theta0": frac(THETA0),
            "momentum0": frac(M0),
            "beta": frac(BETA),
            "eta": frac(ETA),
            "authority_alphabet": [frac(a) for a in AUTHORITY_ALPHABET],
            "max_steps": MAX_STEPS,
        },
        "first_collision_steps": steps,
        "H1": serialize(h1),
        "H2": serialize(h2),
        "checks": {
            "theta_exact_equal": True,
            "loss_exact_equal": True,
            "terminal_momentum_different": True,
            "U_pre_exact_equal": h1["U_pre"] == h2["U_pre"],
        },
        "terminal_differences": {
            "theta": frac(h2["theta"] - h1["theta"]),
            "loss": frac(h2["loss"] - h1["loss"]),
            "momentum": frac(h2["momentum"] - h1["momentum"]),
            "U_pre": frac(h2["U_pre"] - h1["U_pre"]),
        },
    }

    text = json.dumps(result, indent=2, sort_keys=True)
    if args.out is None:
        print(text)
    else:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
