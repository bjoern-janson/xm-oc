#!/usr/bin/env python3
"""Descriptive frozen readout for REAL-XM-AUTHORITY-001 matched K surface."""

import argparse
import hashlib
import json
import math
import statistics
from pathlib import Path

KS = [1, 2, 5, 8, 12]
EXPECTED_QHOLD_STEPS = [512, 1024, 1536, 2048]
EXPECTED_TRAIN_RECORDS = 2049
BATCH = 8
NUM_REGIONS = 16


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def pearson(x, y):
    if len(x) != len(y) or len(x) < 2:
        return None
    mx = sum(x) / len(x)
    my = sum(y) / len(y)
    dx = [v - mx for v in x]
    dy = [v - my for v in y]
    den = math.sqrt(sum(v * v for v in dx) * sum(v * v for v in dy))
    if den == 0:
        return None
    return sum(a * b for a, b in zip(dx, dy)) / den


def load_records(obs_dir: Path):
    files = sorted(obs_dir.glob("authority_rank*.jsonl"))
    if len(files) != 1:
        raise AssertionError(f"expected exactly one rank JSONL in {obs_dir}, got {files}")
    records = []
    for line in files[0].read_text().splitlines():
        if line.strip():
            records.append(json.loads(line))
    return files[0], records


def aggregate(train_records, k):
    slots = [0] * NUM_REGIONS
    sets = [0] * NUM_REGIONS
    winners = [0] * NUM_REGIONS
    sample_den = 0
    slot_den = 0
    for rec in train_records:
        if int(rec["k"]) != k:
            raise AssertionError((rec["k"], k))
        b = int(rec["batch_size"])
        sample_den += b
        slot_den += b * k
        for r in range(NUM_REGIONS):
            slots[r] += int(rec["candidate_slot_counts"][r])
            sets[r] += int(rec["candidate_set_hits"][r])
            winners[r] += int(rec["winner_counts"][r])
    if slot_den != sum(slots):
        raise AssertionError((slot_den, sum(slots)))
    if sample_den != sum(winners):
        raise AssertionError((sample_den, sum(winners)))
    c_slot = [v / slot_den for v in slots]
    c_set = [v / sample_den for v in sets]
    authority = [v / sample_den for v in winners]
    rho = [authority[r] / c_slot[r] if c_slot[r] > 0 else None for r in range(NUM_REGIONS)]
    return {
        "candidate_slot_counts": slots,
        "candidate_set_hits": sets,
        "winner_counts": winners,
        "candidate_slot_denominator": slot_den,
        "sample_denominator": sample_den,
        "num_train_records": len(train_records),
        "C_slot": c_slot,
        "C_set": c_set,
        "A": authority,
        "rho": rho,
    }


def summarize_k(k: int, run_dir: Path):
    obs_file, records = load_records(run_dir / "observer")
    partitions = [r for r in records if r.get("kind") == "partition"]
    train = [r for r in records if r.get("kind") == "train_authority"]
    qhold = [r for r in records if r.get("kind") == "q_hold"]

    if len(partitions) != 1:
        raise AssertionError(f"K={k}: partition count {len(partitions)}")
    if len(train) != EXPECTED_TRAIN_RECORDS:
        raise AssertionError(f"K={k}: train record count {len(train)}")
    if len(qhold) != 4:
        raise AssertionError(f"K={k}: q_hold count {len(qhold)}")
    qsteps = [int(r["step"]) for r in qhold]
    if qsteps != EXPECTED_QHOLD_STEPS:
        raise AssertionError(f"K={k}: q_hold steps {qsteps}")
    if any(not bool(r.get("replay_checked", False)) for r in train):
        raise AssertionError(f"K={k}: replay/direct audit failure")

    overall = aggregate(train, k)
    expected_slot_den = EXPECTED_TRAIN_RECORDS * BATCH * k
    expected_sample_den = EXPECTED_TRAIN_RECORDS * BATCH
    if overall["candidate_slot_denominator"] != expected_slot_den:
        raise AssertionError((k, overall["candidate_slot_denominator"], expected_slot_den))
    if overall["sample_denominator"] != expected_sample_den:
        raise AssertionError((k, overall["sample_denominator"], expected_sample_den))

    windows = []
    for start in [0, 512, 1024, 1536, 2048]:
        end = min(start + 512, EXPECTED_TRAIN_RECORDS)
        sub = [r for r in train if start <= int(r["step"]) < end]
        if not sub:
            continue
        item = aggregate(sub, k)
        item.update(
            {
                "start_step": start,
                "end_step_exclusive": end,
                "complete_512_step_window": len(sub) == 512,
            }
        )
        windows.append(item)

    cumulative_corrs = []
    for q in qhold:
        step = int(q["step"])
        sub = [r for r in train if int(r["step"]) < step]
        agg = aggregate(sub, k)
        rho = agg["rho"]
        losses = [float(x) for x in q["loss_by_region"]]
        usable = [(a, b) for a, b in zip(rho, losses) if a is not None]
        cumulative_corrs.append(
            {
                "q_hold_step": step,
                "pearson_rho_vs_loss": pearson([a for a, _ in usable], [b for _, b in usable]),
            }
        )

    rho_vals = [x for x in overall["rho"] if x is not None]
    expected_cset = 1.0 - (15.0 / 16.0) ** k
    metrics = {
        "rho_min": min(rho_vals),
        "rho_max": max(rho_vals),
        "rho_range": max(rho_vals) - min(rho_vals),
        "rho_std_population": statistics.pstdev(rho_vals),
        "max_abs_rho_minus_1": max(abs(x - 1.0) for x in rho_vals),
        "mean_C_slot": sum(overall["C_slot"]) / NUM_REGIONS,
        "mean_C_set": sum(overall["C_set"]) / NUM_REGIONS,
        "expected_symmetric_C_set": expected_cset,
        "mean_C_set_minus_expected": sum(overall["C_set"]) / NUM_REGIONS - expected_cset,
    }

    ckpts = sorted((run_dir / "checkpoints").rglob("last.ckpt"))
    if len(ckpts) != 1:
        raise AssertionError(f"K={k}: expected one last.ckpt, got {ckpts}")

    return {
        "k": k,
        "observer_jsonl": str(obs_file),
        "observer_jsonl_sha256": sha256(obs_file),
        "checkpoint": str(ckpts[0]),
        "checkpoint_sha256": sha256(ckpts[0]),
        "partition": partitions[0],
        "record_count": len(records),
        "partition_records": len(partitions),
        "train_authority_records": len(train),
        "q_hold_records": len(qhold),
        "overall": overall,
        "metrics": metrics,
        "windows": windows,
        "q_hold": qhold,
        "cumulative_rho_vs_qhold_pearson": cumulative_corrs,
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--root", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--frozen-sha", required=True)
    p.add_argument("--execution-bundle-sha", required=True)
    args = p.parse_args()

    root = Path(args.root)
    members = [summarize_k(k, root / f"k{k}") for k in KS]

    partition_coords = [m["partition"]["coord_indices"] for m in members]
    if any(coords != partition_coords[0] for coords in partition_coords[1:]):
        raise AssertionError(f"partition mismatch across K: {partition_coords}")

    surface = {
        "classification": "REAL_DATA_MATCHED_K_SURFACE_RECORDED",
        "claim_ceiling": "single-seed small real-ImageNet-subset matched K surface; descriptive, not universal XM claim",
        "frozen_scientific_apparatus_sha": args.frozen_sha,
        "execution_bundle_sha": args.execution_bundle_sha,
        "k_surface": KS,
        "q_hold_steps": EXPECTED_QHOLD_STEPS,
        "partition_coord_indices": partition_coords[0],
        "members": members,
        "surface_metrics": [
            {
                "k": m["k"],
                **m["metrics"],
            }
            for m in members
        ],
    }

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(surface, sort_keys=True, indent=2))

    print("=== REAL-XM-AUTHORITY-001 MATCHED K SURFACE ===")
    for m in members:
        x = m["metrics"]
        print(
            "K",
            m["k"],
            "rho_min", f"{x['rho_min']:.6f}",
            "rho_max", f"{x['rho_max']:.6f}",
            "rho_std", f"{x['rho_std_population']:.6f}",
            "max_abs_rho_minus_1", f"{x['max_abs_rho_minus_1']:.6f}",
            "mean_C_set", f"{x['mean_C_set']:.6f}",
            "expected_C_set", f"{x['expected_symmetric_C_set']:.6f}",
        )
        print("  cumulative_rho_vs_qhold", m["cumulative_rho_vs_qhold_pearson"])
        for w in m["windows"]:
            if w["complete_512_step_window"]:
                vals = [v for v in w["rho"] if v is not None]
                print(
                    "  window",
                    f"[{w['start_step']},{w['end_step_exclusive']})",
                    "rho_min", f"{min(vals):.6f}",
                    "rho_max", f"{max(vals):.6f}",
                    "rho_std", f"{statistics.pstdev(vals):.6f}",
                )
    print("surface_json", out)
    print("surface_json_sha256", sha256(out))
    print("REAL_DATA_MATCHED_K_SURFACE_OBSERVATION_FROZEN")


if __name__ == "__main__":
    main()
