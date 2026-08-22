#!/usr/bin/env python3
"""AUTHORITY-ALLOCATION-003a.

Prospectively frozen quotient-sufficiency assay.

Default invocation validates only the frozen developmental witness and execution
contract. The post-boundary recovery future is evaluated only when --execute is
supplied explicitly.
"""

from __future__ import annotations

import argparse
import json
from fractions import Fraction
from pathlib import Path
from typing import Iterable

TARGET_PRE = Fraction(1, 1)
TARGET_FUTURE = Fraction(-1, 1)
THETA0 = Fraction(0, 1)
M0 = Fraction(0, 1)
BETA = Fraction(9, 10)
ETA = Fraction(1, 20)
RECOVERY_TOL = Fraction(1, 10)
FUTURE_STEPS = 64
FUTURE_AUTHORITY = Fraction(1, 1)
CENSORED_LATENCY = FUTURE_STEPS + 1

H1 = (Fraction(1, 2), Fraction(1, 1))
H2 = (Fraction(1, 1), Fraction(0, 1))

EXPECTED_THETA_T = Fraction(19, 100)
EXPECTED_LOSS_T = Fraction(6561, 10000)
EXPECTED_U_PRE = Fraction(19, 100)
EXPECTED_M1_T = Fraction(-14, 5)
EXPECTED_M2_T = Fraction(-9, 5)


def frac(x: Fraction) -> str:
    return f"{x.numerator}/{x.denominator}"


def developmental_run(schedule: Iterable[Fraction]) -> dict[str, object]:
    theta = THETA0
    momentum = M0
    u_pre = Fraction(0, 1)
    trace: list[dict[str, object]] = []

    for step, authority in enumerate(schedule, 1):
        grad = 2 * (theta - TARGET_PRE)
        momentum = BETA * momentum + authority * grad
        next_theta = theta - ETA * momentum
        delta = next_theta - theta
        u_pre += abs(delta)
        trace.append(
            {
                "step": step,
                "authority": frac(authority),
                "gradient": frac(grad),
                "momentum_after": frac(momentum),
                "theta_after": frac(next_theta),
                "abs_delta_theta": frac(abs(delta)),
            }
        )
        theta = next_theta

    loss = (theta - TARGET_PRE) ** 2
    return {
        "theta": theta,
        "loss": loss,
        "momentum": momentum,
        "U_pre": u_pre,
        "trace": trace,
    }


def validate_frozen_witness() -> tuple[dict[str, object], dict[str, object]]:
    h1 = developmental_run(H1)
    h2 = developmental_run(H2)

    assert h1["theta"] == EXPECTED_THETA_T
    assert h2["theta"] == EXPECTED_THETA_T
    assert h1["theta"] == h2["theta"]

    assert h1["loss"] == EXPECTED_LOSS_T
    assert h2["loss"] == EXPECTED_LOSS_T
    assert h1["loss"] == h2["loss"]

    assert h1["U_pre"] == EXPECTED_U_PRE
    assert h2["U_pre"] == EXPECTED_U_PRE
    assert h1["U_pre"] == h2["U_pre"]

    assert h1["momentum"] == EXPECTED_M1_T
    assert h2["momentum"] == EXPECTED_M2_T
    assert h1["momentum"] != h2["momentum"]

    return h1, h2


def future_contract() -> dict[str, object]:
    """Single immutable future specification used for both histories."""
    return {
        "target": TARGET_FUTURE,
        "authority": FUTURE_AUTHORITY,
        "beta": BETA,
        "eta": ETA,
        "proposal_stream": (),
        "future_steps": FUTURE_STEPS,
        "recovery_tolerance": RECOVERY_TOL,
    }


def run_frozen_future(
    *, theta_t: Fraction, momentum_t: Fraction, contract: dict[str, object]
) -> dict[str, object]:
    theta = theta_t
    momentum = momentum_t
    target = contract["target"]
    authority = contract["authority"]
    beta = contract["beta"]
    eta = contract["eta"]
    steps = contract["future_steps"]
    tol = contract["recovery_tolerance"]

    assert isinstance(target, Fraction)
    assert isinstance(authority, Fraction)
    assert isinstance(beta, Fraction)
    assert isinstance(eta, Fraction)
    assert isinstance(steps, int)
    assert isinstance(tol, Fraction)
    assert contract["proposal_stream"] == ()

    recovery_latency: int | None = None
    trace: list[dict[str, object]] = []

    for d in range(1, steps + 1):
        grad = 2 * (theta - target)
        momentum = beta * momentum + authority * grad
        theta = theta - eta * momentum
        error = abs(theta - target)
        if recovery_latency is None and error <= tol:
            recovery_latency = d
        trace.append(
            {
                "d": d,
                "gradient": frac(grad),
                "momentum": frac(momentum),
                "theta": frac(theta),
                "abs_error": frac(error),
            }
        )

    return {
        "recovery_latency": (
            recovery_latency if recovery_latency is not None else CENSORED_LATENCY
        ),
        "recovered_by_horizon": recovery_latency is not None,
        "theta_final": theta,
        "momentum_final": momentum,
        "trace": trace,
    }


def serialize_boundary(record: dict[str, object]) -> dict[str, object]:
    return {
        "theta_T": frac(record["theta"]),
        "loss_T": frac(record["loss"]),
        "U_pre": frac(record["U_pre"]),
        "momentum_T": frac(record["momentum"]),
        "trace": record["trace"],
    }


def serialize_contract(contract: dict[str, object]) -> dict[str, object]:
    return {
        "target": frac(contract["target"]),
        "authority_every_step": frac(contract["authority"]),
        "beta": frac(contract["beta"]),
        "eta": frac(contract["eta"]),
        "proposal_stream": [],
        "future_steps": contract["future_steps"],
        "recovery_tolerance": frac(contract["recovery_tolerance"]),
        "censored_latency": CENSORED_LATENCY,
    }


def serialize_future(record: dict[str, object]) -> dict[str, object]:
    return {
        "recovery_latency": record["recovery_latency"],
        "recovered_by_horizon": record["recovered_by_horizon"],
        "theta_final": frac(record["theta_final"]),
        "momentum_final": frac(record["momentum_final"]),
        "trace": record["trace"],
    }


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

    # Future identity is literal, not merely seed-matched.
    assert contract_1 == contract_2

    if not args.execute:
        print("AA-003a frozen apparatus validation: PASS; recovery future UNOPENED")
        return

    try:
        r1 = run_frozen_future(
            theta_t=h1["theta"], momentum_t=h1["momentum"], contract=contract_1
        )
        r2 = run_frozen_future(
            theta_t=h2["theta"], momentum_t=h2["momentum"], contract=contract_2
        )
    except Exception as exc:  # pragma: no cover - execution audit path
        result = {
            "experiment_id": "AUTHORITY-ALLOCATION-003a",
            "status": "APPARATUS_FAILURE",
            "error": repr(exc),
        }
    else:
        if r1["recovery_latency"] != r2["recovery_latency"]:
            status = "REPAIR_QUOTIENT_COUNTEREXAMPLE_IN_FROZEN_WITNESS"
        else:
            status = "NO_QUOTIENT_COUNTEREXAMPLE_IN_FROZEN_WITNESS"

        result = {
            "experiment_id": "AUTHORITY-ALLOCATION-003a",
            "status": status,
            "scope": "single_exact_deterministic_witness",
            "boundary": {
                "Oa_equal": True,
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
