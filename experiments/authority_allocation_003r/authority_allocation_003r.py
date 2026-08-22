#!/usr/bin/env python3
"""AUTHORITY-ALLOCATION-003r.

Prospectively frozen independent-witness replication assay.

Default invocation validates only the frozen quotient collision and common-future
contract. The post-boundary recovery future is evaluated only when --execute is
supplied explicitly.
"""

from __future__ import annotations

import argparse
import json
from fractions import Fraction
from pathlib import Path

TARGET_PRE = Fraction(0, 1)
TARGET_FUTURE = Fraction(1, 1)
ETA = Fraction(1, 20)
A0 = Fraction(1, 1)
B0 = Fraction(1, 1)
RECOVERY_TOL = Fraction(1, 10)
FUTURE_STEPS = 64
CENSORED_LATENCY = FUTURE_STEPS + 1

A_ONLY = (Fraction(1, 1), Fraction(0, 1))
B_ONLY = (Fraction(0, 1), Fraction(1, 1))
BOTH = (Fraction(1, 1), Fraction(1, 1))

H1 = (("A_ONLY", A_ONLY), ("BOTH", BOTH))
H2 = (("BOTH", BOTH), ("A_ONLY", A_ONLY))

EXPECTED_H1_A = Fraction(81, 100)
EXPECTED_H1_B = Fraction(919, 1000)
EXPECTED_H2_A = Fraction(8271, 10000)
EXPECTED_H2_B = Fraction(9, 10)
EXPECTED_THETA_T = Fraction(74439, 100000)
EXPECTED_LOSS_T = Fraction(5541164721, 10000000000)
EXPECTED_U_PRE = Fraction(25561, 100000)


def int_hex(x: int) -> str:
    """Exact integer serialization using a base exempt from decimal digit limits."""
    sign = "-" if x < 0 else ""
    return f"{sign}0x{abs(x):x}"


def frac(x: Fraction) -> dict[str, str]:
    """Overflow-safe exact rational audit representation."""
    return {
        "numerator_hex": int_hex(x.numerator),
        "denominator_hex": int_hex(x.denominator),
    }


def developmental_run(
    schedule: tuple[tuple[str, tuple[Fraction, Fraction]], ...]
) -> dict[str, object]:
    a = A0
    b = B0
    u_pre = Fraction(0, 1)
    trace: list[dict[str, object]] = []

    for step, (name, (mask_a, mask_b)) in enumerate(schedule, 1):
        theta = a * b
        error = theta - TARGET_PRE
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
                "a_after": frac(next_a),
                "b_after": frac(next_b),
                "theta_after": frac(next_theta),
                "abs_delta_theta": frac(abs(delta_theta)),
            }
        )
        a, b = next_a, next_b

    theta = a * b
    loss = (theta - TARGET_PRE) ** 2
    return {
        "a": a,
        "b": b,
        "theta": theta,
        "loss": loss,
        "U_pre": u_pre,
        "trace": trace,
    }


def validate_frozen_witness() -> tuple[dict[str, object], dict[str, object]]:
    h1 = developmental_run(H1)
    h2 = developmental_run(H2)

    assert h1["a"] == EXPECTED_H1_A
    assert h1["b"] == EXPECTED_H1_B
    assert h2["a"] == EXPECTED_H2_A
    assert h2["b"] == EXPECTED_H2_B

    assert h1["theta"] == EXPECTED_THETA_T
    assert h2["theta"] == EXPECTED_THETA_T
    assert h1["theta"] == h2["theta"]

    assert h1["loss"] == EXPECTED_LOSS_T
    assert h2["loss"] == EXPECTED_LOSS_T
    assert h1["loss"] == h2["loss"]

    assert h1["U_pre"] == EXPECTED_U_PRE
    assert h2["U_pre"] == EXPECTED_U_PRE
    assert h1["U_pre"] == h2["U_pre"]

    assert (h1["a"], h1["b"]) != (h2["a"], h2["b"])
    assert (h1["a"], h1["b"]) != (h2["b"], h2["a"])

    return h1, h2


def future_contract() -> dict[str, object]:
    """Single immutable deterministic future used for both histories."""
    return {
        "target": TARGET_FUTURE,
        "eta": ETA,
        "update_mask": BOTH,
        "proposal_stream": (),
        "future_steps": FUTURE_STEPS,
        "recovery_tolerance": RECOVERY_TOL,
    }


def exact_state(*, d: int, a: Fraction, b: Fraction, target: Fraction) -> dict[str, object]:
    """Raw exact state for bounded audit; serialization occurs only after termination."""
    theta = a * b
    return {
        "d": d,
        "a": a,
        "b": b,
        "theta": theta,
        "abs_error": abs(theta - target),
    }


def run_frozen_future(
    *, a_t: Fraction, b_t: Fraction, contract: dict[str, object]
) -> dict[str, object]:
    """Exact first-hit evaluator for the frozen recovery-latency functional."""
    a = a_t
    b = b_t
    target = contract["target"]
    eta = contract["eta"]
    mask_a, mask_b = contract["update_mask"]
    steps = contract["future_steps"]
    tol = contract["recovery_tolerance"]

    assert isinstance(target, Fraction)
    assert isinstance(eta, Fraction)
    assert isinstance(mask_a, Fraction)
    assert isinstance(mask_b, Fraction)
    assert isinstance(steps, int)
    assert isinstance(tol, Fraction)
    assert (mask_a, mask_b) == BOTH
    assert contract["proposal_stream"] == ()

    for d in range(1, steps + 1):
        pre_hit_state = exact_state(d=d - 1, a=a, b=b, target=target)
        theta = a * b
        error = theta - target
        grad_a = 2 * error * b
        grad_b = 2 * error * a

        a = a - eta * mask_a * grad_a
        b = b - eta * mask_b * grad_b
        hit_state = exact_state(d=d, a=a, b=b, target=target)

        if hit_state["abs_error"] <= tol:
            return {
                "recovery_latency": d,
                "recovered_by_horizon": True,
                "pre_hit_state": pre_hit_state,
                "hit_state": hit_state,
            }

    return {
        "recovery_latency": CENSORED_LATENCY,
        "recovered_by_horizon": False,
        "final_state": exact_state(d=steps, a=a, b=b, target=target),
    }


def serialize_boundary(record: dict[str, object]) -> dict[str, object]:
    return {
        "a_T": frac(record["a"]),
        "b_T": frac(record["b"]),
        "theta_T": frac(record["theta"]),
        "loss_T": frac(record["loss"]),
        "U_pre": frac(record["U_pre"]),
        "trace": record["trace"],
    }


def serialize_contract(contract: dict[str, object]) -> dict[str, object]:
    return {
        "target": frac(contract["target"]),
        "eta": frac(contract["eta"]),
        "update_mask": [frac(x) for x in contract["update_mask"]],
        "proposal_stream": [],
        "future_steps": contract["future_steps"],
        "recovery_tolerance": frac(contract["recovery_tolerance"]),
        "censored_latency": CENSORED_LATENCY,
    }


def serialize_state(record: dict[str, object]) -> dict[str, object]:
    return {
        "d": record["d"],
        "a": frac(record["a"]),
        "b": frac(record["b"]),
        "theta": frac(record["theta"]),
        "abs_error": frac(record["abs_error"]),
    }


def serialize_future(record: dict[str, object]) -> dict[str, object]:
    serialized: dict[str, object] = {
        "recovery_latency": record["recovery_latency"],
        "recovered_by_horizon": record["recovered_by_horizon"],
    }
    if record["recovered_by_horizon"]:
        serialized["pre_hit_state"] = serialize_state(record["pre_hit_state"])
        serialized["hit_state"] = serialize_state(record["hit_state"])
    else:
        serialized["final_state"] = serialize_state(record["final_state"])
    return serialized


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--execute",
        action="store_true",
        help="Explicitly open and evaluate the prospectively frozen future.",
    )
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()

    h1, h2 = validate_frozen_witness()
    contract_1 = future_contract()
    contract_2 = future_contract()

    # Future identity is literal, not seed-matched.
    assert contract_1 == contract_2

    if not args.execute:
        print("AA-003r frozen apparatus validation: PASS; recovery future UNOPENED")
        return

    try:
        r1 = run_frozen_future(a_t=h1["a"], b_t=h1["b"], contract=contract_1)
        r2 = run_frozen_future(a_t=h2["a"], b_t=h2["b"], contract=contract_2)
    except Exception as exc:  # pragma: no cover - execution audit path
        result = {
            "experiment_id": "AUTHORITY-ALLOCATION-003r",
            "status": "APPARATUS_FAILURE",
            "error": repr(exc),
        }
    else:
        if r1["recovery_latency"] != r2["recovery_latency"]:
            status = "REPAIR_QUOTIENT_FAILURE_REPLICATED_IN_INDEPENDENT_WITNESS"
        else:
            status = "NO_REPLICATION_IN_INDEPENDENT_WITNESS"

        result = {
            "experiment_id": "AUTHORITY-ALLOCATION-003r",
            "status": status,
            "scope": "single_exact_deterministic_independent_witness",
            "mechanism": "redundant_parameterization_theta_equals_a_times_b",
            "optimizer": "stateless_gradient_descent_no_momentum",
            "boundary": {
                "Ob_equal": True,
                "H1": serialize_boundary(h1),
                "H2": serialize_boundary(h2),
            },
            "future_contract": serialize_contract(contract_1),
            "future_identity_exact": contract_1 == contract_2,
            "H1_future": serialize_future(r1),
            "H2_future": serialize_future(r2),
            "primary": {
                "H1_recovery_latency": r1["recovery_latency"],
                "H2_recovery_latency": r2["recovery_latency"],
                "recovery_latency_equal": (
                    r1["recovery_latency"] == r2["recovery_latency"]
                ),
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
