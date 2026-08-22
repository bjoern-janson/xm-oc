#!/usr/bin/env python3
"""Checkpoint-side Q_gen evaluator for REAL-XM-AUTH-001.

Generates class-balanced image samples from fixed Gaussian latent regions and
computes per-region FID/ISC using XM's existing torch-fidelity statistics path.
This script never participates in training.
"""

import argparse
import json
import random
import shutil
from pathlib import Path

import torch
from torchvision.utils import save_image
import torch_fidelity

from inference.img.online_fid_eval_callback import _fid_stats_path
from model.model_utils import load_trained_pl_model


def region_coords(flat_dim, bits, seed):
    rng = random.Random(int(seed))
    return sorted(rng.sample(range(int(flat_dim)), int(bits)))


def conditioned_noise(shape, *, region, coords, seed, device):
    g = torch.Generator(device="cpu")
    g.manual_seed(int(seed) + int(region))
    z = torch.randn(shape, generator=g, dtype=torch.float32, device="cpu")
    flat = z.reshape(z.shape[0], -1)
    for bit, coord in enumerate(coords):
        positive = ((int(region) >> bit) & 1) == 1
        mag = flat[:, coord].abs()
        flat[:, coord] = mag if positive else -mag
    return z.to(device=device)


def balanced_labels(num_samples, num_classes, device):
    base = num_samples // num_classes
    extra = num_samples % num_classes
    labels = torch.arange(num_classes, device=device).repeat_interleave(base)
    if extra:
        labels = torch.cat([labels, torch.arange(extra, device=device)])
    return labels.long()


@torch.no_grad()
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ckpt", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--num-samples-per-region", type=int, default=5000)
    parser.add_argument("--batch-size", type=int, default=64)
    parser.add_argument("--region-bits", type=int, default=4)
    parser.add_argument("--region-seed", type=int, default=314159)
    parser.add_argument("--qgen-seed", type=int, default=161803)
    parser.add_argument("--cfg-scale", type=float, default=1.5)
    parser.add_argument("--keep-images", action="store_true")
    args = parser.parse_args()

    model, _ = load_trained_pl_model(
        args.ckpt,
        for_inference=True,
        return_pretrained_hparams=True,
    )
    device = next(model.parameters()).device
    image_size = int(model.hparams.image_dims[0])
    num_classes = int(model.hparams.num_classes)
    use_ema = model.hparams.ema_model != 1.0

    if model.hparams.backbone_type == "rae":
        latent_shape = (768, 16, 16)
    else:
        latent_shape = (4, image_size // 8, image_size // 8)

    flat_dim = latent_shape[0] * latent_shape[1] * latent_shape[2]
    coords = region_coords(flat_dim, args.region_bits, args.region_seed)
    num_regions = 1 << args.region_bits
    root = Path(args.out)
    root.mkdir(parents=True, exist_ok=True)

    results = {
        "checkpoint": args.ckpt,
        "region_bits": args.region_bits,
        "region_seed": args.region_seed,
        "coord_indices": coords,
        "qgen_seed": args.qgen_seed,
        "num_samples_per_region": args.num_samples_per_region,
        "cfg_scale": args.cfg_scale,
        "fid_by_region": {},
        "isc_by_region": {},
    }

    labels_all = balanced_labels(args.num_samples_per_region, num_classes, device)
    stats_path = _fid_stats_path(image_size)

    for region in range(num_regions):
        samples_dir = root / f"region_{region:02d}"
        if samples_dir.exists():
            shutil.rmtree(samples_dir)
        samples_dir.mkdir(parents=True)

        written = 0
        with torch.amp.autocast('cuda', enabled=False):
            while written < args.num_samples_per_region:
                b = min(args.batch_size, args.num_samples_per_region - written)
                labels = labels_all[written:written + b]
                z = conditioned_noise(
                    (b, *latent_shape),
                    region=region,
                    coords=coords,
                    seed=args.qgen_seed + written * 1_000_003,
                    device=device,
                )
                samples = model.generate_samples(
                    z,
                    labels,
                    cfg_scale=args.cfg_scale,
                    use_ema=use_ema,
                )
                if model.hparams.backbone_type == "rae":
                    imgs = model.image_encoder.decode(samples).clamp(0, 1)
                else:
                    imgs = model.image_encoder.decode(samples / 0.18215).sample
                    imgs = ((imgs + 1) / 2).clamp(0, 1)
                for i in range(b):
                    save_image(imgs[i], str(samples_dir / f"{written + i:08d}.png"))
                written += b

        metrics = torch_fidelity.calculate_metrics(
            input1=str(samples_dir),
            input2=None,
            fid_statistics_file=stats_path,
            cuda=True,
            isc=True,
            fid=True,
            kid=False,
            prc=False,
            verbose=False,
        )
        results["fid_by_region"][str(region)] = float(metrics["frechet_inception_distance"])
        results["isc_by_region"][str(region)] = float(metrics["inception_score_mean"])

        if not args.keep_images:
            shutil.rmtree(samples_dir)

        (root / "q_gen_result.json").write_text(
            json.dumps(results, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    print(json.dumps(results, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
