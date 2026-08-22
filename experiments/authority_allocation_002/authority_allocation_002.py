#!/usr/bin/env python3
"""
AUTHORITY-ALLOCATION-002

Finite-horizon authority dose/response assay derived from AA-001.

Primary arm:
    A_i^(lambda) = (1-lambda) * 1[i = argmin_j L_j] + lambda / K

Secondary control:
    same cumulative pre-shift B authority quota as the matched informed arm,
    but quota placement across B-exposed mixed steps is randomized independently
    of comparative loss. Post-shift, both arms use the same informed lambda rule.

This file does not modify XM's shared training kernel and imports no OpenCore code.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import statistics
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

SPEC = {
    "experiment_id": "AUTHORITY-ALLOCATION-002",
    "k": 8,
    "pre_shift_steps": 128,
    "post_shift_steps": 32,
    "learning_rate": 0.05,
    "proposal_p_B": 0.5,
    "theta_A_init": 1.0,
    "theta_B_init": 0.0,
    "recovery_abs_error_threshold": 0.1,
    "lambdas": [0.0, 1e-3, 3e-3, 1e-2, 3e-2, 1e-1, 0.3, 1.0],
    "deadlines": [1, 4, 8, 16, 32],
    "primary_deadline": 16,
    "primary_recovery_probability": 0.95,
    "confirmatory_seed_start": 20000,
    "confirmatory_num_seeds": 256,
    "quota_match_tolerance": 1e-10,
}

ARMS = ("informed", "quota_random")


@dataclass
class RunRecord:
    seed: int
    lambda_index: int
    lambda_value: float
    arm: str
    B_candidate_slot_rate_pre: float
    B_exposure_step_rate_pre: float
    B_authority_sum_pre: float
    B_authority_mean_pre: float
    B_update_sum_pre: float
    B_update_mean_pre: float
    theta_A_pre: float
    theta_B_pre: float
    B_pre_error: float
    recovery_latency: Optional[int]
    theta_A_final: float
    theta_B_final: float
    B_final_error: float


def _world_stream(seed: int) -> Tuple[List[float], List[List[str]]]:
    """Paired world/proposal streams inherited from AA-001."""
    k = int(SPEC["k"])
    total = int(SPEC["pre_shift_steps"]) + int(SPEC["post_shift_steps"])
    p_B = float(SPEC["proposal_p_B"])

    label_rng = random.Random(1_000_003 + seed)
    proposal_rng = random.Random(2_000_003 + seed)

    ys: List[float] = []
    proposals: List[List[str]] = []
    for _ in range(total):
        ys.append(1.0 if label_rng.random() < 0.5 else -1.0)
        proposals.append([
            "B" if proposal_rng.random() < p_B else "A"
            for _ in range(k)
        ])
    return ys, proposals


def _candidate_quantities(
    theta_A: float,
    theta_B: float,
    y: float,
    shifted: bool,
    regions: List[str],
) -> Tuple[List[float], List[float], List[float]]:
    stable = y
    shortcut = -y if shifted else y

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

    return losses, grad_A, grad_B


def _informed_weights(losses: List[float], lam: float) -> List[float]:
    k = len(losses)
    winner = min(range(k), key=losses.__getitem__)
    weights = [lam / k] * k
    weights[winner] += 1.0 - lam
    if abs(sum(weights) - 1.0) > 1e-12:
        raise RuntimeError("authority weights do not sum to one")
    if any(w < -1e-12 or w > 1.0 + 1e-12 for w in weights):
        raise RuntimeError("authority left [0,1]")
    return weights


def _recovery_latency_after_update(
    theta_B: float,
    t: int,
    recovery_latency: Optional[int],
) -> Optional[int]:
    pre = int(SPEC["pre_shift_steps"])
    threshold = float(SPEC["recovery_abs_error_threshold"])
    if t >= pre and recovery_latency is None and abs(theta_B - 1.0) <= threshold:
        return (t - pre) + 1
    return recovery_latency


def run_informed(seed: int, lambda_index: int, lam: float) -> RunRecord:
    ys, proposals = _world_stream(seed)

    pre = int(SPEC["pre_shift_steps"])
    lr = float(SPEC["learning_rate"])
    k = int(SPEC["k"])

    theta_A = float(SPEC["theta_A_init"])
    theta_B = float(SPEC["theta_B_init"])

    B_slots_pre = 0
    B_exposure_steps_pre = 0
    B_authority_sum_pre = 0.0
    B_update_sum_pre = 0.0
    theta_A_pre = theta_A
    theta_B_pre = theta_B
    recovery_latency: Optional[int] = None

    for t, (y, regions) in enumerate(zip(ys, proposals)):
        shifted = t >= pre
        losses, grad_A, grad_B = _candidate_quantities(
            theta_A, theta_B, y, shifted, regions
        )
        weights = _informed_weights(losses, lam)

        authority_B = sum(
            w for w, region in zip(weights, regions) if region == "B"
        )
        gA = sum(w * g for w, g in zip(weights, grad_A))
        gB = sum(w * g for w, g in zip(weights, grad_B))

        if t < pre:
            B_slots_pre += sum(region == "B" for region in regions)
            B_exposure_steps_pre += int(any(region == "B" for region in regions))
            B_authority_sum_pre += authority_B
            B_update_sum_pre += abs(lr * gB)

        theta_A -= lr * gA
        theta_B -= lr * gB

        if t == pre - 1:
            theta_A_pre = theta_A
            theta_B_pre = theta_B

        recovery_latency = _recovery_latency_after_update(
            theta_B, t, recovery_latency
        )

    return RunRecord(
        seed=seed,
        lambda_index=lambda_index,
        lambda_value=lam,
        arm="informed",
        B_candidate_slot_rate_pre=B_slots_pre / (pre * k),
        B_exposure_step_rate_pre=B_exposure_steps_pre / pre,
        B_authority_sum_pre=B_authority_sum_pre,
        B_authority_mean_pre=B_authority_sum_pre / pre,
        B_update_sum_pre=B_update_sum_pre,
        B_update_mean_pre=B_update_sum_pre / pre,
        theta_A_pre=theta_A_pre,
        theta_B_pre=theta_B_pre,
        B_pre_error=(theta_B_pre - 1.0) ** 2,
        recovery_latency=recovery_latency,
        theta_A_final=theta_A,
        theta_B_final=theta_B,
        B_final_error=(theta_B - 1.0) ** 2,
    )


def _quota_random_schedule(
    seed: int,
    lambda_index: int,
    quota_B: float,
    proposals: List[List[str]],
) -> List[float]:
    """
    Allocate the exact informed pre-shift B authority quota independently of loss.

    all-B steps force B authority=1; all-A steps force B authority=0. Remaining
    authority is placed on randomly shuffled mixed A/B steps as unit pulses plus
    at most one fractional pulse.
    """
    pre = int(SPEC["pre_shift_steps"])
    k = int(SPEC["k"])
    tol = float(SPEC["quota_match_tolerance"])

    schedule: List[Optional[float]] = [None] * pre
    mixed_steps: List[int] = []
    forced_B = 0.0

    for t, regions in enumerate(proposals[:pre]):
        n_B = sum(region == "B" for region in regions)
        if n_B == k:
            schedule[t] = 1.0
            forced_B += 1.0
        elif n_B == 0:
            schedule[t] = 0.0
        else:
            mixed_steps.append(t)

    remaining = quota_B - forced_B
    if remaining < -tol or remaining > len(mixed_steps) + tol:
        raise RuntimeError(
            f"quota infeasible: quota={quota_B}, forced_B={forced_B}, mixed={len(mixed_steps)}"
        )
    remaining = min(max(remaining, 0.0), float(len(mixed_steps)))

    placement_rng = random.Random(3_000_003 + seed * 101 + lambda_index)
    placement_rng.shuffle(mixed_steps)

    full = int(math.floor(remaining + 1e-12))
    frac = remaining - full

    for j, t in enumerate(mixed_steps):
        if j < full:
            schedule[t] = 1.0
        elif j == full and frac > 1e-12:
            schedule[t] = frac
        else:
            schedule[t] = 0.0

    out = [float(x) for x in schedule]
    if any(a < -tol or a > 1.0 + tol for a in out):
        raise RuntimeError("random-placement authority left [0,1]")
    if abs(sum(out) - quota_B) > tol:
        raise RuntimeError(
            f"quota mismatch in schedule: got={sum(out)}, expected={quota_B}"
        )
    return out


def run_quota_random(
    seed: int,
    lambda_index: int,
    lam: float,
    quota_B: float,
) -> RunRecord:
    ys, proposals = _world_stream(seed)
    pre = int(SPEC["pre_shift_steps"])
    lr = float(SPEC["learning_rate"])
    k = int(SPEC["k"])

    schedule_B = _quota_random_schedule(
        seed, lambda_index, quota_B, proposals
    )

    theta_A = float(SPEC["theta_A_init"])
    theta_B = float(SPEC["theta_B_init"])

    B_slots_pre = 0
    B_exposure_steps_pre = 0
    B_authority_sum_pre = 0.0
    B_update_sum_pre = 0.0
    theta_A_pre = theta_A
    theta_B_pre = theta_B
    recovery_latency: Optional[int] = None

    for t, (y, regions) in enumerate(zip(ys, proposals)):
        shifted = t >= pre

        if t < pre:
            # Region-level authority-placement control. Placement is fixed by
            # candidate support + independent RNG, not by comparative loss.
            stable = y
            shortcut = y
            err_A = theta_A * shortcut - y
            err_B = theta_B * stable - y
            grad_A_region = 2.0 * err_A * shortcut
            grad_B_region = 2.0 * err_B * stable

            authority_B = schedule_B[t]
            authority_A = 1.0 - authority_B
            if abs((authority_A + authority_B) - 1.0) > 1e-12:
                raise RuntimeError("region authority does not sum to one")

            gA = authority_A * grad_A_region
            gB = authority_B * grad_B_region

            B_slots_pre += sum(region == "B" for region in regions)
            B_exposure_steps_pre += int(any(region == "B" for region in regions))
            B_authority_sum_pre += authority_B
            B_update_sum_pre += abs(lr * gB)
        else:
            # Common post-shift recovery procedure: use the same informed
            # lambda allocation as the matched primary arm.
            losses, grad_A, grad_B = _candidate_quantities(
                theta_A, theta_B, y, True, regions
            )
            weights = _informed_weights(losses, lam)
            authority_B = sum(
                w for w, region in zip(weights, regions) if region == "B"
            )
            gA = sum(w * g for w, g in zip(weights, grad_A))
            gB = sum(w * g for w, g in zip(weights, grad_B))

        theta_A -= lr * gA
        theta_B -= lr * gB

        if t == pre - 1:
            theta_A_pre = theta_A
            theta_B_pre = theta_B

        recovery_latency = _recovery_latency_after_update(
            theta_B, t, recovery_latency
        )

    if abs(B_authority_sum_pre - quota_B) > float(SPEC["quota_match_tolerance"]):
        raise RuntimeError(
            f"executed quota mismatch: got={B_authority_sum_pre}, expected={quota_B}"
        )

    return RunRecord(
        seed=seed,
        lambda_index=lambda_index,
        lambda_value=lam,
        arm="quota_random",
        B_candidate_slot_rate_pre=B_slots_pre / (pre * k),
        B_exposure_step_rate_pre=B_exposure_steps_pre / pre,
        B_authority_sum_pre=B_authority_sum_pre,
        B_authority_mean_pre=B_authority_sum_pre / pre,
        B_update_sum_pre=B_update_sum_pre,
        B_update_mean_pre=B_update_sum_pre / pre,
        theta_A_pre=theta_A_pre,
        theta_B_pre=theta_B_pre,
        B_pre_error=(theta_B_pre - 1.0) ** 2,
        recovery_latency=recovery_latency,
        theta_A_final=theta_A,
        theta_B_final=theta_B,
        B_final_error=(theta_B - 1.0) ** 2,
    )


def _mean(xs: Iterable[float]) -> float:
    xs = list(xs)
    return statistics.fmean(xs) if xs else float("nan")


def _censored_latency(record: RunRecord) -> int:
    return (
        record.recovery_latency
        if record.recovery_latency is not None
        else int(SPEC["post_shift_steps"]) + 1
    )


def _lambda_key(lam: float) -> str:
    return format(lam, ".12g")


def summarize(records: List[RunRecord]) -> Dict[str, object]:
    deadlines = [int(x) for x in SPEC["deadlines"]]
    lambdas = [float(x) for x in SPEC["lambdas"]]
    summary: Dict[str, object] = {"surface": {}, "paired_placement": {}}

    lookup = {(r.seed, r.lambda_index, r.arm): r for r in records}
    seeds = sorted({r.seed for r in records})

    max_quota_error = 0.0

    for li, lam in enumerate(lambdas):
        lk = _lambda_key(lam)
        summary["surface"][lk] = {}
        for arm in ARMS:
            rs = [r for r in records if r.lambda_index == li and r.arm == arm]
            censored = [_censored_latency(r) for r in rs]
            summary["surface"][lk][arm] = {
                "n": len(rs),
                "B_candidate_slot_rate_pre_mean": _mean(
                    r.B_candidate_slot_rate_pre for r in rs
                ),
                "B_exposure_step_rate_pre_mean": _mean(
                    r.B_exposure_step_rate_pre for r in rs
                ),
                "B_authority_sum_pre_mean": _mean(
                    r.B_authority_sum_pre for r in rs
                ),
                "B_authority_mean_pre_mean": _mean(
                    r.B_authority_mean_pre for r in rs
                ),
                "B_update_sum_pre_mean": _mean(
                    r.B_update_sum_pre for r in rs
                ),
                "B_update_mean_pre_mean": _mean(
                    r.B_update_mean_pre for r in rs
                ),
                "B_pre_error_mean": _mean(r.B_pre_error for r in rs),
                "recovery_latency_censored_mean": _mean(censored),
                "recovery_latency_censored_median": statistics.median(censored),
                "recovered_by_end_count": sum(
                    r.recovery_latency is not None for r in rs
                ),
                "recovered_by_deadline": {
                    str(d): sum(
                        r.recovery_latency is not None
                        and r.recovery_latency <= d
                        for r in rs
                    )
                    for d in deadlines
                },
                "B_final_error_mean": _mean(r.B_final_error for r in rs),
            }

        placement_deltas = []
        update_deltas = []
        pre_error_deltas = []
        for seed in seeds:
            inf = lookup[(seed, li, "informed")]
            rnd = lookup[(seed, li, "quota_random")]
            quota_error = abs(
                inf.B_authority_sum_pre - rnd.B_authority_sum_pre
            )
            max_quota_error = max(max_quota_error, quota_error)
            placement_deltas.append(_censored_latency(rnd) - _censored_latency(inf))
            update_deltas.append(rnd.B_update_sum_pre - inf.B_update_sum_pre)
            pre_error_deltas.append(rnd.B_pre_error - inf.B_pre_error)

        summary["paired_placement"][lk] = {
            "random_minus_informed_recovery_latency_mean": _mean(
                placement_deltas
            ),
            "random_slower_count": sum(d > 0 for d in placement_deltas),
            "tie_count": sum(d == 0 for d in placement_deltas),
            "random_faster_count": sum(d < 0 for d in placement_deltas),
            "random_minus_informed_B_update_sum_pre_mean": _mean(
                update_deltas
            ),
            "random_minus_informed_B_pre_error_mean": _mean(
                pre_error_deltas
            ),
        }

    primary_deadline = int(SPEC["primary_deadline"])
    min_successes = math.ceil(
        float(SPEC["primary_recovery_probability"])
        * int(SPEC["confirmatory_num_seeds"])
    )
    lambda_star: Optional[float] = None
    for li, lam in enumerate(lambdas):
        lk = _lambda_key(lam)
        successes = summary["surface"][lk]["informed"][
            "recovered_by_deadline"
        ][str(primary_deadline)]
        if successes >= min_successes:
            lambda_star = lam
            break

    summary["primary"] = {
        "deadline": primary_deadline,
        "required_recovery_probability": SPEC[
            "primary_recovery_probability"
        ],
        "required_success_count_for_256": min_successes,
        "lambda_star_T128_grid": (
            lambda_star if lambda_star is not None else "NONE_ON_GRID"
        ),
    }
    summary["apparatus"] = {
        "max_abs_informed_random_B_authority_quota_error": max_quota_error,
        "quota_match_tolerance": SPEC["quota_match_tolerance"],
    }
    return summary


def apparatus_ok(summary: Dict[str, object]) -> bool:
    return (
        summary["apparatus"][
            "max_abs_informed_random_B_authority_quota_error"
        ]
        <= float(SPEC["quota_match_tolerance"])
    )


def run_block(seed_start: int, num_seeds: int) -> List[RunRecord]:
    lambdas = [float(x) for x in SPEC["lambdas"]]
    records: List[RunRecord] = []

    for seed in range(seed_start, seed_start + num_seeds):
        for li, lam in enumerate(lambdas):
            informed = run_informed(seed, li, lam)
            random_control = run_quota_random(
                seed,
                li,
                lam,
                informed.B_authority_sum_pre,
            )
            records.extend([informed, random_control])
    return records


def self_test() -> None:
    # Structural checks only; these do not inspect the confirmatory block.
    for seed in (0, 1, 2):
        for li, lam in enumerate(float(x) for x in SPEC["lambdas"]):
            informed = run_informed(seed, li, lam)
            random_control = run_quota_random(
                seed, li, lam, informed.B_authority_sum_pre
            )
            assert abs(
                informed.B_authority_sum_pre
                - random_control.B_authority_sum_pre
            ) <= float(SPEC["quota_match_tolerance"])
            assert (
                informed.B_candidate_slot_rate_pre
                == random_control.B_candidate_slot_rate_pre
            )
            assert (
                informed.B_exposure_step_rate_pre
                == random_control.B_exposure_step_rate_pre
            )

    # Endpoint semantics of the informed allocation.
    losses = [0.0, 1.0, 2.0]
    hard = _informed_weights(losses, 0.0)
    balanced = _informed_weights(losses, 1.0)
    assert hard == [1.0, 0.0, 0.0]
    assert all(abs(w - 1.0 / 3.0) <= 1e-12 for w in balanced)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--mode",
        choices=("development", "confirmatory"),
        default="development",
    )
    parser.add_argument("--seed-start", type=int, default=0)
    parser.add_argument("--num-seeds", type=int, default=256)
    parser.add_argument("--out", type=Path, default=None)
    parser.add_argument("--self-test-only", action="store_true")
    args = parser.parse_args()

    self_test()
    if args.self_test_only:
        print("AA-002 self-test: PASS")
        return

    confirm_start = int(SPEC["confirmatory_seed_start"])
    confirm_n = int(SPEC["confirmatory_num_seeds"])

    if args.mode == "confirmatory":
        if args.seed_start != confirm_start or args.num_seeds != confirm_n:
            raise SystemExit(
                "confirmatory mode requires exactly the prospectively frozen "
                f"seed block {confirm_start}..{confirm_start + confirm_n - 1}"
            )
    else:
        # Development must remain disjoint from all confirmatory blocks.
        if args.seed_start < 0 or args.seed_start + args.num_seeds > 10000:
            raise SystemExit(
                "development mode is restricted to seeds 0..9999"
            )

    records = run_block(args.seed_start, args.num_seeds)
    summary = summarize(records)

    if not apparatus_ok(summary):
        status = "APPARATUS_FAILURE"
    elif args.mode == "confirmatory":
        status = "FINITE_HORIZON_AUTHORITY_SURFACE_RECORDED"
    else:
        status = "DEVELOPMENT_ONLY"

    result = {
        "experiment_id": SPEC["experiment_id"],
        "status": status,
        "mode": args.mode,
        "seed_start": args.seed_start,
        "num_seeds": args.num_seeds,
        "spec": SPEC,
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
