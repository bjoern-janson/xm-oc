#!/usr/bin/env python3
"""Build and custody-audit the exact real-ImageNet specimen used by REAL-XM-AUTHORITY-001.

Run from the frozen scientific checkout. This is infrastructure/data preparation only.
It writes the native CachedLatentsDataset sharded-safetensors format expected by the
frozen trainer and fails closed unless the selected RGB specimen and encoded latents
match the already-recorded K=2 pilot hashes exactly.
"""

import argparse
import hashlib
import json
import os
from collections import Counter
from itertools import islice
from pathlib import Path

import torch
from datasets import load_dataset
from safetensors.torch import save_file
from torchvision import transforms

from model.model_utils import center_crop_arr, get_encoded_images, load_image_encoder

DATASET = "ILSVRC/imagenet-1k"
REVISION = "49e2ee26f3810fb5a7536bbf732a7b07389a47b5"
TRAIN_N = 4096
VAL_N = 256
TRAIN_SEED = 424242
VAL_SEED = 424243
SHUFFLE_BUFFER = 10000

EXPECTED = {
    "train": {
        "rgb": "4c66cdf359d428ba6e037ce8e9d8ae7814d02b4e1c9eb636df86f0c13ec0d3c3",
        "latent": "624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f",
    },
    "validation": {
        "rgb": "ddb96596358e97db3d5c31579a8376616a3bca481a31f12d92cd97204b042fb7",
        "latent": "f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99",
    },
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def build_split(*, split: str, count: int, seed: int, stem: str, cache_dir: Path, token: str, vae, transform):
    print(f"BUILDING {split}: count={count} seed={seed} buffer={SHUFFLE_BUFFER}")
    stream = load_dataset(
        DATASET,
        split=split,
        streaming=True,
        revision=REVISION,
        token=token,
        trust_remote_code=True,
    )
    stream = stream.shuffle(seed=seed, buffer_size=SHUFFLE_BUFFER)

    latents = []
    labels = []
    pixel_digest = hashlib.sha256()
    label_hist = Counter()
    batch_images = []
    batch_labels = []
    seen = 0

    def flush():
        nonlocal batch_images, batch_labels
        if not batch_images:
            return
        x = torch.stack([transform(im) for im in batch_images], dim=0).to("cuda")
        with torch.no_grad():
            z = get_encoded_images(x, "vae", vae, sdxl_vae_standardization=True).cpu().contiguous()
        latents.append(z)
        labels.extend(batch_labels)
        batch_images = []
        batch_labels = []

    for sample in islice(iter(stream), count):
        image = sample["image"].convert("RGB")
        label = int(sample["label"])
        w, h = image.size
        pixel_digest.update(label.to_bytes(4, "little", signed=True))
        pixel_digest.update(w.to_bytes(4, "little", signed=False))
        pixel_digest.update(h.to_bytes(4, "little", signed=False))
        pixel_digest.update(image.tobytes())
        label_hist[label] += 1
        batch_images.append(image)
        batch_labels.append(label)
        seen += 1
        if len(batch_images) == 16:
            flush()
        if seen % 256 == 0:
            print(f"{split}: selected+encoded {seen}/{count}")
    flush()

    if seen != count:
        raise RuntimeError(f"{split}: expected {count} samples, got {seen}")

    z = torch.cat(latents, dim=0)
    y = torch.tensor(labels, dtype=torch.long)
    if z.shape[0] != count or y.shape[0] != count:
        raise AssertionError((z.shape, y.shape, count))
    if tuple(z.shape[1:]) != (4, 32, 32):
        raise AssertionError(f"unexpected latent shape {tuple(z.shape)}")

    cache_file = cache_dir / f"{stem}.safetensors"
    parts_dir = cache_file.with_suffix(cache_file.suffix + ".parts")
    parts_dir.mkdir(parents=True, exist_ok=True)
    part = parts_dir / "part_00000.safetensors"
    save_file({"latents": z, "labels": y}, str(part))
    (parts_dir / "manifest.json").write_text(
        json.dumps(
            {
                "parts_dir": parts_dir.name,
                "parts": [{"file": part.name, "size": count}],
            },
            sort_keys=True,
            indent=2,
        )
    )
    cache_file.write_text("sharded")

    rgb_sha = pixel_digest.hexdigest()
    latent_sha = sha256(part)
    exp = EXPECTED[split]
    print(f"{split}_rgb_sha256", rgb_sha)
    print(f"{split}_latent_sha256", latent_sha)
    if rgb_sha != exp["rgb"]:
        raise AssertionError(f"{split}: RGB specimen hash mismatch: {rgb_sha} != {exp['rgb']}")
    if latent_sha != exp["latent"]:
        raise AssertionError(f"{split}: latent cache hash mismatch: {latent_sha} != {exp['latent']}")

    return {
        "split": split,
        "count": count,
        "selection_seed": seed,
        "shuffle_buffer": SHUFFLE_BUFFER,
        "rgb_label_sha256": rgb_sha,
        "latent_part_sha256": latent_sha,
        "latent_shape": list(z.shape),
        "num_classes_present": len(label_hist),
        "label_histogram": {str(k): int(v) for k, v in sorted(label_hist.items())},
        "cache_file": str(cache_file),
        "part_file": str(part),
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--cache-dir", required=True)
    p.add_argument("--manifest", required=True)
    p.add_argument("--frozen-sha", required=True)
    args = p.parse_args()

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA is required")
    token = os.environ.get("HF_TOKEN")
    if not token:
        raise RuntimeError("HF_TOKEN is required")

    cache_dir = Path(args.cache_dir)
    cache_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = Path(args.manifest)
    manifest_path.parent.mkdir(parents=True, exist_ok=True)

    transform = transforms.Compose(
        [
            transforms.Lambda(lambda pil_image: center_crop_arr(pil_image, 256)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5], inplace=True),
        ]
    )

    vae = load_image_encoder("vae", "base", device="cuda", use_ema=True)
    vae.eval()
    for param in vae.parameters():
        param.requires_grad = False

    train = build_split(
        split="train",
        count=TRAIN_N,
        seed=TRAIN_SEED,
        stem="imagenet_train_256x256_vae",
        cache_dir=cache_dir,
        token=token,
        vae=vae,
        transform=transform,
    )
    val = build_split(
        split="validation",
        count=VAL_N,
        seed=VAL_SEED,
        stem="imagenet_val_256x256_vae",
        cache_dir=cache_dir,
        token=token,
        vae=vae,
        transform=transform,
    )

    manifest = {
        "kind": "REAL-XM-AUTHORITY-001-matched-surface-cache",
        "frozen_sha": args.frozen_sha,
        "dataset": DATASET,
        "dataset_revision": REVISION,
        "selection_method": "HF streaming deterministic shuffle then first N",
        "encoder": "stabilityai/sd-vae-ft-ema via frozen load_image_encoder(use_ema=True)",
        "encoding": "frozen get_encoded_images with 0.18215 scaling",
        "transform": "center_crop_arr(256)->ToTensor->Normalize(0.5,0.5)",
        "pilot_hash_match_required": True,
        "train": train,
        "validation": val,
    }
    manifest_path.write_text(json.dumps(manifest, sort_keys=True, indent=2))
    print(json.dumps(manifest, sort_keys=True, indent=2))
    print("MATCHED_REAL_IMAGENET_CACHE_AUDIT_PASS")


if __name__ == "__main__":
    main()
