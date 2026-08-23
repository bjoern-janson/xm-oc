#!/usr/bin/env python3
"""XM-CRCB-001 calibration-base manifest builder/verifier.

Custody only:
base-manifest validity != repair-language adequacy != calibration result.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import torch

APPARATUS_FREEZE_SHA = "b8caf8ffcc0a3bbd4fabfbc610b0767293e11aff"
SOURCE_SCIENTIFIC_SHA = "be7cefd60cf199e9fbabd6110be1254a1756590e"
CC_PROTOCOL_COMMIT = "4d0e87613ef1b894d6ebac2400e358a9fd82e5ae"
DATASET = "ILSVRC/imagenet-1k"
DATASET_REVISION = "49e2ee26f3810fb5a7536bbf732a7b07389a47b5"
ALLOWED_SEEDS = (606, 707)
EXPECTED_TRAIN_RGB_SHA = "4c66cdf359d428ba6e037ce8e9d8ae7814d02b4e1c9eb636df86f0c13ec0d3c3"
EXPECTED_TRAIN_LATENT_SHA = "624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f"
EXPECTED_VAL_RGB_SHA = "ddb96596358e97db3d5c31579a8376616a3bca481a31f12d92cd97204b042fb7"
EXPECTED_VAL_LATENT_SHA = "f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99"

EXPECTED_CAL = {
    "cal_region_seed": 271829,
    "cal_flat_dim": 4096,
    "cal_coords": [651, 1449, 2382, 3402],
    "cal_targets": [0, 5, 10, 15],
    "cal_base_seeds": [606, 707],
    "cal_repair_seeds": [1101, 1102, 1103],
    "cal_eval_seed": 1201201,
    "construct_semantic_indices": [0, 63],
    "eval_semantic_indices": [64, 127],
    "science_reserved_semantic_indices": [128, 255],
}

EXPECTED_HPARAMS = {
    "model_name": "dit",
    "model_size": "vit_base",
    "modality": "IMG",
    "xm_best_of_k": 2,
    "xm_chunk_bs_mult": 1,
    "xm_save_mem_mode": True,
    "diffusion_supervision_type": "velocity",
    "ode_step_size": 0.02,
    "patch_size": 2,
    "image_task": "class_conditional",
    "num_classes": 1000,
    "cfg_dropout_prob": 0.1,
    "batch_size_per_device": 8,
    "effective_batch_size": 8,
    "peak_learning_rate": 0.0001,
    "gradient_clip_val": 1.0,
    "weight_decay": 0.01,
    "min_lr_scale": 10,
    "max_steps": 2049,
    "max_scheduling_steps": 2049,
    "warm_up_steps": 20,
    "backbone_type": "vae",
    "use_cached_img_latents": True,
    "dataset_name": "imagenet",
    "num_workers_per_device": 2,
    "image_dims": [256, 256],
    "ema_model": 0.9999,
    "set_matmul_precision": "medium",
    "float_precision": "16-mixed",
    "save_top_k_ckpts": 0,
    "is_random_seed": True,
    "use_ot_flow": False,
}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def canonical_json_sha(obj) -> str:
    b = (json.dumps(obj, sort_keys=True, separators=(",", ":")) + "\n").encode()
    return hashlib.sha256(b).hexdigest()


def tensor_collection_hash(items) -> str:
    h = hashlib.sha256()
    for name, tensor in sorted(items, key=lambda x: x[0]):
        t = tensor.detach().cpu().contiguous()
        h.update(name.encode("utf-8") + b"\0")
        h.update(str(t.dtype).encode("utf-8") + b"\0")
        h.update(json.dumps(list(t.shape), separators=(",", ":")).encode("utf-8") + b"\0")
        h.update(t.view(torch.uint8).numpy().tobytes())
    return h.hexdigest()


def normalize(v):
    if isinstance(v, tuple):
        return list(v)
    return v


def assert_equal(label, got, expected):
    if normalize(got) != normalize(expected):
        raise RuntimeError(f"{label} mismatch: got={got!r} expected={expected!r}")


def load_data_manifest(path: Path) -> dict:
    x = json.loads(path.read_text())
    assert_equal("data dataset", x.get("dataset"), DATASET)
    assert_equal("data revision", x.get("dataset_revision"), DATASET_REVISION)
    assert_equal("data frozen sha", x.get("frozen_sha"), SOURCE_SCIENTIFIC_SHA)
    tr, va = x["train"], x["validation"]
    assert_equal("train count", tr.get("count"), 4096)
    assert_equal("validation count", va.get("count"), 256)
    assert_equal("train RGB hash", tr.get("rgb_label_sha256"), EXPECTED_TRAIN_RGB_SHA)
    assert_equal("train latent hash", tr.get("latent_part_sha256"), EXPECTED_TRAIN_LATENT_SHA)
    assert_equal("val RGB hash", va.get("rgb_label_sha256"), EXPECTED_VAL_RGB_SHA)
    assert_equal("val latent hash", va.get("latent_part_sha256"), EXPECTED_VAL_LATENT_SHA)
    assert_equal("train latent shape", tr.get("latent_shape"), [4096, 4, 32, 32])
    assert_equal("val latent shape", va.get("latent_shape"), [256, 4, 32, 32])
    return x


def verify_calibration_constants() -> dict:
    # Import constants only. This does not construct calibration or science region banks.
    from experiments.xm_crcb_001 import core
    core.verify_coords()
    got = {
        "cal_region_seed": int(core.CAL_REGION_SEED),
        "cal_flat_dim": int(core.CAL_FLAT_DIM),
        "cal_coords": list(core.CAL_COORDS),
        "cal_targets": list(core.CAL_TARGETS),
        "cal_base_seeds": list(core.CAL_BASE_SEEDS),
        "cal_repair_seeds": list(core.CAL_REPAIR_SEEDS),
        "cal_eval_seed": int(core.CAL_EVAL_SEED),
        "construct_semantic_indices": [min(core.CONSTRUCT), max(core.CONSTRUCT)],
        "eval_semantic_indices": [min(core.EVAL), max(core.EVAL)],
        "science_reserved_semantic_indices": [min(core.SCIENCE_RESERVED), max(core.SCIENCE_RESERVED)],
    }
    assert_equal("calibration constants", got, EXPECTED_CAL)
    return got


def inspect_checkpoint(path: Path) -> dict:
    ck = torch.load(path, map_location="cpu", weights_only=False)
    if int(ck.get("global_step", -1)) != 2049:
        raise RuntimeError(f"checkpoint global_step mismatch: {ck.get('global_step')}")
    hp = ck.get("hyper_parameters")
    if not isinstance(hp, dict):
        raise RuntimeError("checkpoint hyper_parameters missing")
    for key, expected in EXPECTED_HPARAMS.items():
        if key not in hp:
            raise RuntimeError(f"checkpoint hparam missing: {key}")
        assert_equal(f"hparam {key}", hp[key], expected)

    state = ck.get("state_dict")
    if not isinstance(state, dict):
        raise RuntimeError("checkpoint state_dict missing")
    raw = [(k, v) for k, v in state.items()
           if torch.is_tensor(v) and (
               k.startswith("model.diffusion_transformer.")
               or k.startswith("model.label_embedder.")
           )]
    ema = [(k, v) for k, v in state.items()
           if torch.is_tensor(v) and (
               k.startswith("model.ema_diffusion_transformer.")
               or k.startswith("model.ema_label_embedder.")
           )]
    if not raw:
        raise RuntimeError("raw non-EMA model state not found")
    if not ema:
        raise RuntimeError("EMA model state not found")
    return {
        "global_step": int(ck["global_step"]),
        "epoch": int(ck.get("epoch", -1)),
        "hparams_sha256": canonical_json_sha({k: normalize(hp[k]) for k in sorted(EXPECTED_HPARAMS)}),
        "raw_non_ema_state_sha256": tensor_collection_hash(raw),
        "ema_state_sha256": tensor_collection_hash(ema),
        "raw_tensor_count": len(raw),
        "ema_tensor_count": len(ema),
    }


def inspect_train_log(path: Path, seed: int) -> dict:
    text = path.read_text(errors="replace")
    required = [
        f"CAL_BASE_SEED_INJECTION {seed}",
        f"Seed set to {seed}",
        "CAL_BASE_NATIVE_SAVE_LAST_ASSERTED",
        "CAL_BASE_AUTHORITY_OBSERVER_DISABLED",
    ]
    for marker in required:
        if marker not in text:
            raise RuntimeError(f"training log missing marker: {marker}")
    forbidden = [
        "REPLICATION_CHECKPOINT_WRITES_DISABLED",
        "Traceback (most recent call last)",
        "FATAL:",
    ]
    for marker in forbidden:
        if marker in text:
            raise RuntimeError(f"training log contains forbidden marker: {marker}")
    return {
        "file": path.name,
        "sha256": sha256_file(path),
        "bytes": path.stat().st_size,
        "required_markers": required,
        "forbidden_markers_absent": forbidden,
    }


def build_manifest(args) -> dict:
    seed = int(args.seed)
    if seed not in ALLOWED_SEEDS:
        raise RuntimeError(f"seed must be one of {ALLOWED_SEEDS}")
    ckpt = Path(args.checkpoint)
    log = Path(args.train_log)
    dm_path = Path(args.data_manifest)
    val_part = Path(args.val_cache_part)
    for p in (ckpt, log, dm_path, val_part):
        if not p.is_file():
            raise FileNotFoundError(p)

    load_data_manifest(dm_path)
    if sha256_file(val_part) != EXPECTED_VAL_LATENT_SHA:
        raise RuntimeError("validation cache part hash mismatch")
    cal = verify_calibration_constants()
    cp = inspect_checkpoint(ckpt)
    lg = inspect_train_log(log, seed)

    manifest = {
        "schema": "XM-CRCB-001-CALIBRATION-BASE-v1",
        "kind": "XM-CRCB-001-calibration-base",
        "claim_ceiling": "base-manifest validity != repair-language adequacy != calibration result",
        "apparatus_freeze_sha": APPARATUS_FREEZE_SHA,
        "source_scientific_sha": SOURCE_SCIENTIFIC_SHA,
        "cc_protocol_commit": CC_PROTOCOL_COMMIT,
        "base_seed": seed,
        "k_train": 2,
        "optimizer_steps": 2049,
        "batch_size": 8,
        "dataset": DATASET,
        "dataset_revision": DATASET_REVISION,
        "train_rgb_label_sha256": EXPECTED_TRAIN_RGB_SHA,
        "train_latent_sha256": EXPECTED_TRAIN_LATENT_SHA,
        "val_rgb_label_sha256": EXPECTED_VAL_RGB_SHA,
        "val_latent_sha256": EXPECTED_VAL_LATENT_SHA,
        "data_manifest_file": dm_path.name,
        "data_manifest_sha256": sha256_file(dm_path),
        "val_cache_part_file": val_part.name,
        "val_cache_part_sha256": sha256_file(val_part),
        "checkpoint_file": ckpt.name,
        "checkpoint_sha256": sha256_file(ckpt),
        "infra_commit": args.infra_commit,
        "launcher_file": Path(args.launcher).name if args.launcher else None,
        "launcher_sha256": sha256_file(Path(args.launcher)) if args.launcher else None,
        "verifier_file": Path(args.verifier).name if args.verifier else None,
        "verifier_sha256": sha256_file(Path(args.verifier)) if args.verifier else None,
        "checkpoint_bytes": ckpt.stat().st_size,
        "checkpoint": cp,
        "training_log": lg,
        "calibration_partition": cal,
        "rng_domains": {
            "base_training_seed": seed,
            "calibration_repair_seeds_reserved": [1101, 1102, 1103],
            "calibration_eval_seed_reserved": 1201201,
            "repair_rng_materialized": False,
            "eval_rng_materialized": False,
        },
        "authority_observer_enabled": False,
        "repair_language_evaluated": False,
        "repair_language_adequacy_known": False,
        "calibration_result_opened": False,
        "factorization_constructed": False,
        "parity_split_constructed": False,
        "science_seed_materialized": False,
        "science_context_evaluated": False,
        "science_region_conditioned_contexts_constructed": False,
        "science_rng_materialized": False,
        "calibration_region_banks_constructed": False,
        "base_training_validation_uses_full_256_cache": True,
        "custody_valid": True,
    }
    return manifest


def validate_manifest_object(x: dict, checkpoint: Path, train_log: Path,
                             data_manifest: Path, val_part: Path) -> None:
    assert_equal("schema", x.get("schema"), "XM-CRCB-001-CALIBRATION-BASE-v1")
    assert_equal("kind", x.get("kind"), "XM-CRCB-001-calibration-base")
    assert_equal("claim ceiling", x.get("claim_ceiling"),
                 "base-manifest validity != repair-language adequacy != calibration result")
    assert_equal("apparatus freeze", x.get("apparatus_freeze_sha"), APPARATUS_FREEZE_SHA)
    assert_equal("source scientific sha", x.get("source_scientific_sha"), SOURCE_SCIENTIFIC_SHA)
    assert_equal("cc protocol", x.get("cc_protocol_commit"), CC_PROTOCOL_COMMIT)
    seed = int(x.get("base_seed"))
    if seed not in ALLOWED_SEEDS:
        raise RuntimeError("invalid base seed")
    assert_equal("k_train", x.get("k_train"), 2)
    assert_equal("optimizer_steps", x.get("optimizer_steps"), 2049)
    assert_equal("batch_size", x.get("batch_size"), 8)
    assert_equal("dataset", x.get("dataset"), DATASET)
    assert_equal("dataset revision", x.get("dataset_revision"), DATASET_REVISION)
    assert_equal("train latent", x.get("train_latent_sha256"), EXPECTED_TRAIN_LATENT_SHA)
    assert_equal("val latent", x.get("val_latent_sha256"), EXPECTED_VAL_LATENT_SHA)
    assert_equal("checkpoint hash", x.get("checkpoint_sha256"), sha256_file(checkpoint))
    assert_equal("train log hash", x["training_log"]["sha256"], sha256_file(train_log))
    assert_equal("data manifest hash", x.get("data_manifest_sha256"), sha256_file(data_manifest))
    assert_equal("val part hash", x.get("val_cache_part_sha256"), sha256_file(val_part))
    assert_equal("cal constants", x.get("calibration_partition"), EXPECTED_CAL)

    for key in (
        "authority_observer_enabled",
        "repair_language_evaluated",
        "repair_language_adequacy_known",
        "calibration_result_opened",
        "factorization_constructed",
        "parity_split_constructed",
        "science_seed_materialized",
        "science_context_evaluated",
        "science_region_conditioned_contexts_constructed",
        "science_rng_materialized",
        "calibration_region_banks_constructed",
    ):
        if x.get(key) is not False:
            raise RuntimeError(f"manifest firewall flag must be false: {key}")
    if x.get("base_training_validation_uses_full_256_cache") is not True:
        raise RuntimeError("base_training_validation_uses_full_256_cache must be true")
    if x.get("custody_valid") is not True:
        raise RuntimeError("custody_valid is not true")

    # Recompute external identities rather than trusting the manifest.
    load_data_manifest(data_manifest)
    verify_calibration_constants()
    inspect_checkpoint(checkpoint)
    inspect_train_log(train_log, seed)
    if sha256_file(val_part) != EXPECTED_VAL_LATENT_SHA:
        raise RuntimeError("validation cache part hash mismatch")


def main() -> int:
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="mode", required=True)

    b = sub.add_parser("build")
    b.add_argument("--seed", type=int, required=True)
    b.add_argument("--checkpoint", required=True)
    b.add_argument("--train-log", required=True)
    b.add_argument("--data-manifest", required=True)
    b.add_argument("--val-cache-part", required=True)
    b.add_argument("--infra-commit", required=True)
    b.add_argument("--launcher", required=True)
    b.add_argument("--verifier", required=True)
    b.add_argument("--out", required=True)

    v = sub.add_parser("verify")
    v.add_argument("--manifest", required=True)
    v.add_argument("--checkpoint", required=True)
    v.add_argument("--train-log", required=True)
    v.add_argument("--data-manifest", required=True)
    v.add_argument("--val-cache-part", required=True)

    a = p.parse_args()
    if a.mode == "build":
        x = build_manifest(a)
        out = Path(a.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(x, sort_keys=True, indent=2) + "\n")
        validate_manifest_object(
            x, Path(a.checkpoint), Path(a.train_log),
            Path(a.data_manifest), Path(a.val_cache_part)
        )
        print(json.dumps({
            "classification": "CALIBRATION_BASE_MANIFEST_VALID",
            "seed": a.seed,
            "manifest": str(out),
            "manifest_sha256": sha256_file(out),
        }, sort_keys=True))
        return 0

    x = json.loads(Path(a.manifest).read_text())
    validate_manifest_object(
        x, Path(a.checkpoint), Path(a.train_log),
        Path(a.data_manifest), Path(a.val_cache_part)
    )
    print(json.dumps({
        "classification": "CALIBRATION_BASE_MANIFEST_VALID",
        "seed": int(x["base_seed"]),
        "manifest": a.manifest,
        "manifest_sha256": sha256_file(Path(a.manifest)),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
