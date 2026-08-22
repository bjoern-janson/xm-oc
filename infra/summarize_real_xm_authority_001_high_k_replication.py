#!/usr/bin/env python3
"""Summarize the prospectively frozen REAL-XM-AUTHORITY-001 fresh-seed replication.

Primary replication unit: training seed block.
Primary endpoint: late Fisher-z average of corr_R(rho, Q_hold) at steps 1536/2048.
Primary contrast: Z_late(K=12,s) - Z_late(K=2,s).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from typing import Any

import numpy as np

SEEDS = [101, 202, 303, 404, 505]
KS = [2, 8, 12]
Q_STEPS = [512, 1024, 1536, 2048]
LATE_STEPS = [1536, 2048]
NUM_REGIONS = 16
NULL_MC_SEED = 20260823
NULL_MC_SURFACES = 200_000
N_EXAMPLES = 2049 * 8


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def load_records(path: Path) -> tuple[dict[str, Any], list[dict[str, Any]], dict[int, dict[str, Any]]]:
    records = [json.loads(x) for x in path.read_text().splitlines() if x.strip()]
    parts = [r for r in records if r.get("kind") == "partition"]
    train = [r for r in records if r.get("kind") == "train_authority"]
    q = [r for r in records if r.get("kind") == "q_hold"]
    assert len(parts) == 1
    assert len(train) == 2049
    assert len(q) == 4
    train.sort(key=lambda r: int(r["step"]))
    assert [int(r["step"]) for r in train] == list(range(2049))
    qmap = {int(r["step"]): r for r in q}
    assert sorted(qmap) == Q_STEPS
    return parts[0], train, qmap


def aggregate_rho(train: list[dict[str, Any]], k: int, before_step: int | None = None) -> np.ndarray:
    chosen = train if before_step is None else [r for r in train if int(r["step"]) < before_step]
    assert chosen
    slots = np.sum(np.asarray([r["candidate_slot_counts"] for r in chosen], dtype=np.float64), axis=0)
    wins = np.sum(np.asarray([r["winner_counts"] for r in chosen], dtype=np.float64), axis=0)
    assert slots.shape == (NUM_REGIONS,)
    assert wins.shape == (NUM_REGIONS,)
    assert np.all(slots > 0)
    rho = k * wins / slots
    return rho


def pearson(x: np.ndarray, y: np.ndarray) -> float:
    x = np.asarray(x, dtype=np.float64)
    y = np.asarray(y, dtype=np.float64)
    assert x.shape == y.shape == (NUM_REGIONS,)
    xc = x - x.mean()
    yc = y - y.mean()
    denom = math.sqrt(float(np.dot(xc, xc) * np.dot(yc, yc)))
    if denom == 0.0:
        return float("nan")
    return float(np.dot(xc, yc) / denom)


def fisher_z(r: float) -> float:
    if not math.isfinite(r):
        return float("nan")
    return float(np.arctanh(np.clip(r, -0.999999999999, 0.999999999999)))


def ordinal_ranks(x: np.ndarray) -> np.ndarray:
    # Values are continuous in this assay; deterministic stable ordering handles any exact ties.
    order = np.argsort(np.asarray(x), kind="mergesort")
    ranks = np.empty(len(order), dtype=np.float64)
    ranks[order] = np.arange(len(order), dtype=np.float64)
    return ranks


def spearman(x: np.ndarray, y: np.ndarray) -> float:
    return pearson(ordinal_ranks(x), ordinal_ranks(y))


def bottom4(x: np.ndarray) -> list[int]:
    idx = np.arange(NUM_REGIONS)
    order = np.lexsort((idx, np.asarray(x, dtype=np.float64)))
    return [int(i) for i in order[:4]]


def top4(x: np.ndarray) -> list[int]:
    idx = np.arange(NUM_REGIONS)
    order = np.lexsort((idx, -np.asarray(x, dtype=np.float64)))
    return [int(i) for i in order[:4]]


def pairwise_seed_spearman(vectors: dict[int, np.ndarray]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for i, s1 in enumerate(SEEDS):
        for s2 in SEEDS[i + 1 :]:
            out.append({"seed_a": s1, "seed_b": s2, "spearman": spearman(vectors[s1], vectors[s2])})
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, required=True)
    ap.add_argument("--output", type=Path, required=True)
    ap.add_argument("--frozen-sha", required=True)
    ap.add_argument("--execution-bundle-sha", required=True)
    args = ap.parse_args()

    result: dict[str, Any] = {
        "classification": "REAL_DATA_HIGH_K_COUPLING_REPLICATION_RECORDED",
        "claim_ceiling": "five fresh seed blocks on the same small real-ImageNet subset; observational association only; no causal direction and no Q_gen claim",
        "frozen_sha": args.frozen_sha,
        "execution_bundle_sha": args.execution_bundle_sha,
        "seeds": SEEDS,
        "k_values": KS,
        "q_hold_steps": Q_STEPS,
        "primary_late_steps": LATE_STEPS,
        "null_mc_seed": NULL_MC_SEED,
        "null_mc_surfaces": NULL_MC_SURFACES,
        "seed_blocks": {},
    }

    partition_ref = None
    final_rhos: dict[int, dict[int, np.ndarray]] = {k: {} for k in KS}
    late_rhos: dict[int, dict[int, np.ndarray]] = {k: {} for k in KS}
    late_qs: dict[int, dict[int, np.ndarray]] = {k: {} for k in KS}

    for seed in SEEDS:
        block: dict[str, Any] = {"seed": seed, "K": {}}
        for k in KS:
            obs = args.root / f"seed{seed}" / f"k{k}" / "observer" / "authority_rank0.jsonl"
            assert obs.exists(), obs
            partition, train, qmap = load_records(obs)
            if partition_ref is None:
                partition_ref = partition
                assert partition_ref["coord_indices"] == [808, 1575, 2250, 2349]
                assert int(partition_ref["region_seed"]) == 314159
            else:
                assert partition["coord_indices"] == partition_ref["coord_indices"]
                assert int(partition["region_seed"]) == int(partition_ref["region_seed"])

            assert all(int(r["k"]) == k for r in train)
            assert all(int(r["batch_size"]) == 8 for r in train)
            assert all(bool(r.get("replay_checked", False)) for r in train)

            r_by_step: dict[str, float] = {}
            rho_by_step: dict[int, np.ndarray] = {}
            q_by_step: dict[int, np.ndarray] = {}
            for t in Q_STEPS:
                rho_t = aggregate_rho(train, k, before_step=t)
                q_t = np.asarray(qmap[t]["loss_by_region"], dtype=np.float64)
                assert q_t.shape == (NUM_REGIONS,)
                rho_by_step[t] = rho_t
                q_by_step[t] = q_t
                r_by_step[str(t)] = pearson(rho_t, q_t)

            z_late = float(np.mean([fisher_z(r_by_step[str(t)]) for t in LATE_STEPS]))
            rho_late = np.mean(np.stack([rho_by_step[t] for t in LATE_STEPS]), axis=0)
            q_late = np.mean(np.stack([q_by_step[t] for t in LATE_STEPS]), axis=0)
            low = bottom4(rho_late)
            high = top4(q_late)
            joint = sorted(set(low) & set(high))

            rho_final = aggregate_rho(train, k, before_step=None)
            final_rhos[k][seed] = rho_final
            late_rhos[k][seed] = rho_late
            late_qs[k][seed] = q_late

            block["K"][str(k)] = {
                "observer_sha256": sha256_file(obs),
                "r_by_step": r_by_step,
                "z_late": z_late,
                "rho_final": rho_final.tolist(),
                "rho_final_std": float(np.std(rho_final)),
                "rho_final_min": float(np.min(rho_final)),
                "rho_final_max": float(np.max(rho_final)),
                "rho_final_max_abs_minus_1": float(np.max(np.abs(rho_final - 1.0))),
                "rho_late": rho_late.tolist(),
                "q_late": q_late.tolist(),
                "low_rho_regions": low,
                "high_q_regions": high,
                "joint_low_rho_high_q_regions": joint,
            }

        z2 = float(block["K"]["2"]["z_late"])
        z8 = float(block["K"]["8"]["z_late"])
        z12 = float(block["K"]["12"]["z_late"])
        block["delta_12_minus_2"] = z12 - z2
        block["delta_8_minus_2"] = z8 - z2
        block["delta_12_minus_8"] = z12 - z8
        result["seed_blocks"][str(seed)] = block

    assert partition_ref is not None
    result["partition"] = partition_ref

    deltas = np.asarray([result["seed_blocks"][str(s)]["delta_12_minus_2"] for s in SEEDS], dtype=np.float64)
    z2s = np.asarray([result["seed_blocks"][str(s)]["K"]["2"]["z_late"] for s in SEEDS], dtype=np.float64)
    z8s = np.asarray([result["seed_blocks"][str(s)]["K"]["8"]["z_late"] for s in SEEDS], dtype=np.float64)
    z12s = np.asarray([result["seed_blocks"][str(s)]["K"]["12"]["z_late"] for s in SEEDS], dtype=np.float64)

    result["primary"] = {
        "estimand": "mean_s [Z_late(K=12,s) - Z_late(K=2,s)]",
        "delta_12_minus_2_by_seed": {str(s): float(result["seed_blocks"][str(s)]["delta_12_minus_2"]) for s in SEEDS},
        "mean_delta_12_minus_2": float(np.mean(deltas)),
        "median_delta_12_minus_2": float(np.median(deltas)),
        "negative_delta_count": int(np.sum(deltas < 0)),
        "mean_z_late_k2": float(np.mean(z2s)),
        "median_z_late_k2": float(np.median(z2s)),
        "mean_z_late_k8": float(np.mean(z8s)),
        "median_z_late_k8": float(np.median(z8s)),
        "mean_z_late_k12": float(np.mean(z12s)),
        "median_z_late_k12": float(np.median(z12s)),
        "primary_direction_mean_delta_lt_zero": bool(np.mean(deltas) < 0),
        "robustness_median_delta_lt_zero": bool(np.median(deltas) < 0),
    }

    # Prospectively fixed exchangeable-winner marginal-dispersion calibration.
    rng = np.random.default_rng(NULL_MC_SEED)
    p = np.full(NUM_REGIONS, 1.0 / NUM_REGIONS)
    marginal_null: dict[str, Any] = {}
    for k in KS:
        W = rng.multinomial(N_EXAMPLES, p, size=NULL_MC_SURFACES).astype(np.float64)
        U = rng.multinomial(N_EXAMPLES * (k - 1), p, size=NULL_MC_SURFACES).astype(np.float64)
        S = W + U
        rho_null = k * W / S
        null_sd = np.std(rho_null, axis=1)
        null_maxabs = np.max(np.abs(rho_null - 1.0), axis=1)
        per_seed: dict[str, Any] = {}
        for seed in SEEDS:
            obs = final_rhos[k][seed]
            obs_sd = float(np.std(obs))
            obs_max = float(np.max(np.abs(obs - 1.0)))
            per_seed[str(seed)] = {
                "observed_rho_std": obs_sd,
                "observed_max_abs_rho_minus_1": obs_max,
                "p_null_rho_std_ge_observed": float(np.mean(null_sd >= obs_sd)),
                "p_null_max_abs_ge_observed": float(np.mean(null_maxabs >= obs_max)),
            }
        marginal_null[str(k)] = {
            "null_mean_rho_std": float(np.mean(null_sd)),
            "null_mean_max_abs_rho_minus_1": float(np.mean(null_maxabs)),
            "by_seed": per_seed,
        }
    result["marginal_null_calibration"] = marginal_null

    # Secondary stable-region diagnostic.
    identity: dict[str, Any] = {}
    for k in KS:
        low_counts = np.zeros(NUM_REGIONS, dtype=int)
        high_counts = np.zeros(NUM_REGIONS, dtype=int)
        joint_counts = np.zeros(NUM_REGIONS, dtype=int)
        for seed in SEEDS:
            entry = result["seed_blocks"][str(seed)]["K"][str(k)]
            for r in entry["low_rho_regions"]:
                low_counts[int(r)] += 1
            for r in entry["high_q_regions"]:
                high_counts[int(r)] += 1
            for r in entry["joint_low_rho_high_q_regions"]:
                joint_counts[int(r)] += 1
        rho_pairs = pairwise_seed_spearman(late_rhos[k])
        q_pairs = pairwise_seed_spearman(late_qs[k])
        identity[str(k)] = {
            "low_rho_membership_count_by_region": low_counts.tolist(),
            "high_q_membership_count_by_region": high_counts.tolist(),
            "joint_membership_count_by_region": joint_counts.tolist(),
            "rho_late_pairwise_seed_spearman": rho_pairs,
            "q_late_pairwise_seed_spearman": q_pairs,
            "rho_late_mean_pairwise_seed_spearman": float(np.mean([x["spearman"] for x in rho_pairs])),
            "q_late_mean_pairwise_seed_spearman": float(np.mean([x["spearman"] for x in q_pairs])),
        }
    result["stable_region_diagnostic"] = identity

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")

    print("=== REAL-XM-AUTHORITY-001 HIGH-K COUPLING REPLICATION ===")
    for seed in SEEDS:
        b = result["seed_blocks"][str(seed)]
        print(
            "seed", seed,
            "Z2", f"{b['K']['2']['z_late']:.6f}",
            "Z8", f"{b['K']['8']['z_late']:.6f}",
            "Z12", f"{b['K']['12']['z_late']:.6f}",
            "Delta12-2", f"{b['delta_12_minus_2']:.6f}",
        )
    p0 = result["primary"]
    print("PRIMARY mean_delta_12_minus_2", f"{p0['mean_delta_12_minus_2']:.6f}")
    print("PRIMARY median_delta_12_minus_2", f"{p0['median_delta_12_minus_2']:.6f}")
    print("PRIMARY negative_delta_count", p0["negative_delta_count"], "/", len(SEEDS))
    print("PRIMARY mean_z_late_k2", f"{p0['mean_z_late_k2']:.6f}")
    print("PRIMARY mean_z_late_k8", f"{p0['mean_z_late_k8']:.6f}")
    print("PRIMARY mean_z_late_k12", f"{p0['mean_z_late_k12']:.6f}")
    for k in KS:
        print("MARGINAL_NULL K", k)
        for seed in SEEDS:
            x = result["marginal_null_calibration"][str(k)]["by_seed"][str(seed)]
            print(
                " seed", seed,
                "rho_std", f"{x['observed_rho_std']:.6f}",
                "p_sd", f"{x['p_null_rho_std_ge_observed']:.6f}",
                "maxabs", f"{x['observed_max_abs_rho_minus_1']:.6f}",
                "p_max", f"{x['p_null_max_abs_ge_observed']:.6f}",
            )
    print("replication_json", args.output)
    print("replication_json_sha256", sha256_file(args.output))
    print("REAL_DATA_HIGH_K_COUPLING_REPLICATION_OBSERVATION_FROZEN")


if __name__ == "__main__":
    main()
