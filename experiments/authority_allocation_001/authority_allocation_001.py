#!/usr/bin/env python3
"""
AUTHORITY-ALLOCATION-001

Standalone synthetic assay for proposal exposure vs update authority under
XM-like candidate selection. This file intentionally does not import or modify
OpenCore and does not modify XM's shared training kernel.

The assay has two coupling regions:
  A: shortcut-coupled predictor, initially competent.
  B: stable-coupled predictor, initially weak but valid across a later shift.

Before the shift, shortcut == target. After the shift, shortcut == -target,
while stable == target throughout.

Four update-allocation regimes:
  k1       : one proposed region, it receives all update authority.
  hard_xm  : K proposals, lowest-loss candidate receives all authority.
  balanced : K proposals, equal authority over candidate slots.
  soft_xm  : K proposals, authority proportional to exp(-loss / tau).

All regimes share target streams. K>1 regimes share the exact same proposal
streams; k1 uses the first slot of that same K-candidate stream.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import statistics
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional

SPEC = {
    "experiment_id": "AUTHORITY-ALLOCATION-001",
    "k": 8,
    "pre_shift_steps": 128,
    "post_shift_steps": 32,
    "learning_rate": 0.05,
    "soft_temperature": 0.5,
    "proposal_p_B": 0.5,
    "theta_A_init": 1.0,
    "theta_B_init": 0.0,
    "recovery_abs_error_threshold": 0.1,
    "confirmatory_seed_start": 10000,
    "confirmatory_num_seeds": 256,
    "deadlines": [1, 4, 8, 16, 32],
}

REGIMES = ("k1", "hard_xm", "balanced", "soft_xm")


@dataclass
class RunRecord:
    seed: int
    regime: str
    theta_A_pre: float
    theta_B_pre: float
    theta_A_final: float
    theta_B_final: float
    B_candidate_slot_rate_pre: float
    B_exposure_step_rate_pre: float
    B_authority_mass_pre: float
    B_update_magnitude_pre: float
    B_pre_error: float
    recovery_latency: Optional[int]
    B_final_error: float


def _candidate_weights(regime: str, losses: List[float], tau: float) -> List[float]:
    n = len(losses)
    if regime in ("k1", "hard_xm"):
        winner = min(range(n), key=losses.__getitem__)
        out = [0.0] * n
        out[winner] = 1.0
        return out
    if regime == "balanced":
        return [1.0 / n] * n
    if regime == "soft_xm":
        # Stable softmax over negative losses.
        logits = [-loss / tau for loss in losses]
        m = max(logits)
        exps = [math.exp(v - m) for v in logits]
        z = sum(exps)
        return [v / z for v in exps]
    raise ValueError(f"unknown regime: {regime}")


def run_one(seed: int, regime: str, spec: Dict[str, object] = SPEC) -> RunRecord:
    k = int(spec["k"])
    pre = int(spec["pre_shift_steps"])
    post = int(spec["post_shift_steps"])
    lr = float(spec["learning_rate"])
    tau = float(spec["soft_temperature"])
    p_B = float(spec["proposal_p_B"])
    threshold = float(spec["recovery_abs_error_threshold"])

    theta_A = float(spec["theta_A_init"])
    theta_B = float(spec["theta_B_init"])

    # Independent streams keep target/world randomness identical across regimes
    # and make k1 use the first proposal slot from the same K-wide stream.
    label_rng = random.Random(1_000_003 + seed)
    proposal_rng = random.Random(2_000_003 + seed)

    B_slots_pre = 0
    B_exposure_steps_pre = 0
    B_authority_pre = 0.0
    B_update_magnitude_pre = 0.0
    recovery_latency: Optional[int] = None

    theta_A_pre = theta_A
    theta_B_pre = theta_B

    for t in range(pre + post):
        shifted = t >= pre

        y = 1.0 if label_rng.random() < 0.5 else -1.0
        stable = y
        shortcut = -y if shifted else y

        # Always draw K proposal slots so all four regimes are paired on the
        # same underlying proposal stream. k1 only consumes slot 0.
        proposal_slots = [
            "B" if proposal_rng.random() < p_B else "A"
            for _ in range(k)
        ]
        regions = proposal_slots[:1] if regime == "k1" else proposal_slots

        if t < pre:
            B_slots_pre += sum(r == "B" for r in regions)
            if any(r == "B" for r in regions):
                B_exposure_steps_pre += 1

        losses: List[float] = []
        grad_A: List[float] = []
        grad_B: List[float] = []

        for region in regions:
            if region == "A":
                pred = theta_A * shortcut
                err = pred - y
                losses.append(err * err)
                grad_A.append(2.0 * err * shortcut)
                grad_B.append(0.0)
            else:
                pred = theta_B * stable
                err = pred - y
                losses.append(err * err)
                grad_A.append(0.0)
                grad_B.append(2.0 * err * stable)

        weights = _candidate_weights(regime, losses, tau)
        gA = sum(w * g for w, g in zip(weights, grad_A))
        gB = sum(w * g for w, g in zip(weights, grad_B))
        authority_B = sum(w for w, region in zip(weights, regions) if region == "B")

        if t < pre:
            B_authority_pre += authority_B
            B_update_magnitude_pre += abs(lr * gB)

        theta_A -= lr * gA
        theta_B -= lr * gB

        if t == pre - 1:
            theta_A_pre = theta_A
            theta_B_pre = theta_B

        if shifted and recovery_latency is None and abs(theta_B - 1.0) <= threshold:
            recovery_latency = (t - pre) + 1

    candidate_denominator = pre * (1 if regime == "k1" else k)

    return RunRecord(
        seed=seed,
        regime=regime,
        theta_A_pre=theta_A_pre,
        theta_B_pre=theta_B_pre,
        theta_A_final=theta_A,
        theta_B_final=theta_B,
        B_candidate_slot_rate_pre=B_slots_pre / candidate_denominator,
        B_exposure_step_rate_pre=B_exposure_steps_pre / pre,
        B_authority_mass_pre=B_authority_pre / pre,
        B_update_magnitude_pre=B_update_magnitude_pre,
        B_pre_error=(theta_B_pre - 1.0) ** 2,
        recovery_latency=recovery_latency,
        B_final_error=(theta_B - 1.0) ** 2,
    )


def _mean(xs: Iterable[float]) -> float:
    xs = list(xs)
    return statistics.fmean(xs) if xs else float("nan")


def summarize(records: List[RunRecord], deadlines: List[int]) -> Dict[str, object]:
    by_regime: Dict[str, List[RunRecord]] = {
        regime: [r for r in records if r.regime == regime]
        for regime in REGIMES
    }

    summary: Dict[str, object] = {}
    for regime, rs in by_regime.items():
        latencies_censored = [
            r.recovery_latency if r.recovery_latency is not None else SPEC["post_shift_steps"] + 1
            for r in rs
        ]
        summary[regime] = {
            "n": len(rs),
            "B_candidate_slot_rate_pre_mean": _mean(r.B_candidate_slot_rate_pre for r in rs),
            "B_exposure_step_rate_pre_mean": _mean(r.B_exposure_step_rate_pre for r in rs),
            "B_authority_mass_pre_mean": _mean(r.B_authority_mass_pre for r in rs),
            "B_update_magnitude_pre_mean": _mean(r.B_update_magnitude_pre for r in rs),
            "B_pre_error_mean": _mean(r.B_pre_error for r in rs),
            "recovered_by_end_count": sum(r.recovery_latency is not None for r in rs),
            "recovery_latency_censored_mean": _mean(latencies_censored),
            "recovery_latency_censored_median": statistics.median(latencies_censored),
            "B_final_error_mean": _mean(r.B_final_error for r in rs),
            "recovered_by_deadline": {
                str(d): sum(
                    r.recovery_latency is not None and r.recovery_latency <= d
                    for r in rs
                )
                for d in deadlines
            },
        }

    # Paired effects are defined only over the common confirmatory seeds.
    paired: Dict[str, object] = {}
    lookup = {(r.seed, r.regime): r for r in records}
    seeds = sorted({r.seed for r in records})
    for comparator in ("k1", "balanced", "soft_xm"):
        deltas = []
        hard_slower = 0
        ties = 0
        for seed in seeds:
            hard = lookup[(seed, "hard_xm")]
            other = lookup[(seed, comparator)]
            hard_lat = hard.recovery_latency if hard.recovery_latency is not None else SPEC["post_shift_steps"] + 1
            other_lat = other.recovery_latency if other.recovery_latency is not None else SPEC["post_shift_steps"] + 1
            d = hard_lat - other_lat
            deltas.append(d)
            hard_slower += d > 0
            ties += d == 0
        paired[f"hard_minus_{comparator}_recovery_latency"] = {
            "mean": _mean(deltas),
            "hard_slower_count": hard_slower,
            "tie_count": ties,
            "hard_faster_count": len(deltas) - hard_slower - ties,
        }
    summary["paired"] = paired
    return summary


def classify(summary: Dict[str, object]) -> str:
    hard = summary["hard_xm"]
    paired = summary["paired"]["hard_minus_balanced_recovery_latency"]

    gates = [
        hard["B_exposure_step_rate_pre_mean"] >= 0.95,
        hard["B_authority_mass_pre_mean"] <= 0.02,
        paired["hard_slower_count"] >= math.ceil(0.95 * SPEC["confirmatory_num_seeds"]),
        paired["mean"] >= 8.0,
    ]
    return (
        "AUTHORITY_STARVATION_SUPPORTED_IN_FROZEN_TOY"
        if all(gates)
        else "AUTHORITY_STARVATION_NOT_SUPPORTED"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed-start", type=int, default=SPEC["confirmatory_seed_start"])
    parser.add_argument("--num-seeds", type=int, default=SPEC["confirmatory_num_seeds"])
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()

    seeds = range(args.seed_start, args.seed_start + args.num_seeds)
    records = [
        run_one(seed, regime)
        for seed in seeds
        for regime in REGIMES
    ]

    summary = summarize(records, list(SPEC["deadlines"]))
    result = {
        "experiment_id": SPEC["experiment_id"],
        "classification": classify(summary),
        "spec": SPEC,
        "seed_start": args.seed_start,
        "num_seeds": args.num_seeds,
        "summary": summary,
        "records": [asdict(r) for r in records],
    }

    text = json.dumps(result, indent=2, sort_keys=True)
    if args.out is None:
        print(text)
    else:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
