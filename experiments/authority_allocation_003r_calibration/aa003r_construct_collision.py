#!/usr/bin/env python3
"""AA-003r independent collision construction calibration only.

This script searches for two developmental histories in a redundantly
parameterized scalar model theta = a*b. It uses stateless gradient descent;
there is no momentum or optimizer memory.

Success requires exact equality of (theta, loss, U_pre) with distinct internal
parameter states (a,b) that are not merely coordinate swaps.

There is intentionally no post-boundary future and no recovery computation in
this file.
"""

from __future__ import annotations

import argparse
import json
from fractions import Fraction
from itertools import product
from pathlib import Path

TARGET = Fraction(0, 1)
ETA = Fraction(1, 20)
A0 = Fraction(1, 1)
B0 = Fraction(1, 1)
MAX_STEPS = 6

A_ONLY = (Fraction(1, 1), Fraction(0, 1))
B_ONLY = (Fraction(0, 1), Fraction(1, 1))
BOTH = (Fraction(1, 1), Fraction(1, 1))
ACTIONS = (
    ("A_ONLY", A_ONLY),
    ("B_ONLY", B_ONLY),
    ("BOTH", BOTH),
)


def frac(x: Fraction) -> str:
    return f"{x.numerator}/{x.denominator}"


def run(schedule: tuple[tuple[str, tuple[Fraction, Fraction]], ...]) -> dict[str, object]:
    a = A0
    b = B0
    u_pre = Fraction(0, 1)
    trace: list[dict[str, object]] = []

    for step, (name, (mask_a, mask_b)) in enumerate(schedule, 1):
        theta = a * b
        error = theta - TARGET
        grad_a = 2 * error * b
        grad_b = 2 * error * a

        next_a = a - ETA * mask_a * grad_a
        next_b = b - ETA * mask_b * grad_b
        next_theta = next_a * next_b
        delta_theta = next_theta - theta
        u_pre += abs(delta_theta)

        trace.append(
            {
                "step": step,
                "action": name,
                "a_before": frac(a),
                "b_before": frac(b),
                "theta_before": frac(theta),
                "grad_a": frac(grad_a),
                "grad_b": frac(grad_b),
                "a_after": frac(next_a),
                "b_after": frac(next_b),
                "theta_after": frac(next_theta),
                "abs_delta_theta": frac(abs(delta_theta)),
            }
        )
        a, b = next_a, next_b

    theta = a * b
    loss = (theta - TARGET) ** 2
    return {
        "schedule": [name for name, _ in schedule],
        "a": a,
        "b": b,
        "theta": theta,
        "loss": loss,
        "U_pre": u_pre,
        "trace": trace,
    }


def same_hidden_state(x: dict[str, object], y: dict[str, object]) -> bool:
    return x["a"] == y["a"] and x["b"] == y["b"]


def coordinate_swap(x: dict[str, object], y: dict[str, object]) -> bool:
    return x["a"] == y["b"] and x["b"] == y["a"]


def find_collision() -> tuple[int, dict[str, object], dict[str, object]]:
    """Return first exact non-swap collision under deterministic enumeration."""
    for steps in range(1, MAX_STEPS + 1):
        by_quotient: dict[
            tuple[Fraction, Fraction, Fraction], list[dict[str, object]]
        ] = {}

        for schedule in product(ACTIONS, repeat=steps):
            record = run(schedule)
            key = (record["theta"], record["loss"], record["U_pre"])
            assert all(isinstance(v, Fraction) for v in key)

            for prior in by_quotient.get(key, []):
                if not same_hidden_state(prior, record) and not coordinate_swap(
                    prior, record
                ):
                    return steps, prior, record

            by_quotient.setdefault(key, []).append(record)

    raise RuntimeError("No exact independent collision found in calibration space")


def serialize(record: dict[str, object]) -> dict[str, object]:
    return {
        "schedule": record["schedule"],
        "a_exact": frac(record["a"]),
        "b_exact": frac(record["b"]),
        "theta_exact": frac(record["theta"]),
        "loss_exact": frac(record["loss"]),
        "U_pre_exact": frac(record["U_pre"]),
        "trace": record["trace"],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()

    steps, h1, h2 = find_collision()

    assert h1["theta"] == h2["theta"]
    assert h1["loss"] == h2["loss"]
    assert h1["U_pre"] == h2["U_pre"]
    assert not same_hidden_state(h1, h2)
    assert not coordinate_swap(h1, h2)

    result = {
        "artifact": "AA-003r independent collision calibration",
        "status": "INDEPENDENT_CONSTRUCTION_COLLISION_FOUND",
        "scope": "construction_only_no_future_recovery_executed",
        "mechanism": "redundant_parameterization_theta_equals_a_times_b",
        "optimizer": "stateless_gradient_descent_no_momentum",
        "dynamics": {
            "target": frac(TARGET),
            "eta": frac(ETA),
            "a0": frac(A0),
            "b0": frac(B0),
            "action_alphabet": [name for name, _ in ACTIONS],
            "max_steps": MAX_STEPS,
        },
        "first_collision_steps": steps,
        "H1": serialize(h1),
        "H2": serialize(h2),
        "checks": {
            "theta_exact_equal": True,
            "loss_exact_equal": True,
            "U_pre_exact_equal": True,
            "hidden_parameter_state_distinct": True,
            "not_coordinate_swap": True,
        },
        "terminal_differences": {
            "theta": frac(h2["theta"] - h1["theta"]),
            "loss": frac(h2["loss"] - h1["loss"]),
            "U_pre": frac(h2["U_pre"] - h1["U_pre"]),
            "a": frac(h2["a"] - h1["a"]),
            "b": frac(h2["b"] - h1["b"]),
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
