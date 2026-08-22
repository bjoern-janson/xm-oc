import json
import os
import random
from pathlib import Path

import torch


class AuthorityTopologyObserver:
    """Passive measurement side-channel for real-XM latent authority allocation.

    The observer never writes to model tensors, never samples from the global torch
    RNG, and never participates in candidate loss, selection, replay, or optimizer
    logic. Region assignment is a fixed sign hash over four preselected latent
    coordinates.
    """

    def __init__(
        self,
        *,
        region_bits=4,
        region_seed=314159,
        holdout_seed=271828,
        log_dir="logs/xm_authority_obs",
        holdout_examples=2,
        holdout_every_n_val_steps=1,
    ):
        self.region_bits = int(region_bits)
        self.num_regions = 1 << self.region_bits
        self.region_seed = int(region_seed)
        self.holdout_seed = int(holdout_seed)
        self.holdout_examples = int(holdout_examples)
        self.holdout_every_n_val_steps = int(holdout_every_n_val_steps)

        rank = int(os.environ.get("RANK", os.environ.get("LOCAL_RANK", "0")))
        self.rank = rank
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.log_path = self.log_dir / f"authority_rank{rank}.jsonl"

        self._flat_dim = None
        self._coord_indices = None
        self._batch = None
        self._last_holdout_step = None

    @classmethod
    def from_env(cls):
        if os.environ.get("XM_AUTHORITY_OBS", "0") != "1":
            return None
        return cls(
            region_bits=int(os.environ.get("XM_AUTHORITY_REGION_BITS", "4")),
            region_seed=int(os.environ.get("XM_AUTHORITY_REGION_SEED", "314159")),
            holdout_seed=int(os.environ.get("XM_AUTHORITY_HOLDOUT_SEED", "271828")),
            log_dir=os.environ.get("XM_AUTHORITY_OBS_DIR", "logs/xm_authority_obs"),
            holdout_examples=int(os.environ.get("XM_AUTHORITY_HOLDOUT_EXAMPLES", "2")),
            holdout_every_n_val_steps=int(os.environ.get("XM_AUTHORITY_HOLDOUT_EVERY_N_VAL_STEPS", "1")),
        )

    def _append(self, record):
        with self.log_path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(record, sort_keys=True) + "\n")

    def _ensure_partition(self, z):
        flat_dim = int(z[0].numel())
        if self._flat_dim is None:
            if flat_dim < self.region_bits:
                raise ValueError("latent dimensionality is smaller than region_bits")
            rng = random.Random(self.region_seed)
            self._coord_indices = sorted(rng.sample(range(flat_dim), self.region_bits))
            self._flat_dim = flat_dim
            self._append(
                {
                    "kind": "partition",
                    "rank": self.rank,
                    "region_bits": self.region_bits,
                    "num_regions": self.num_regions,
                    "region_seed": self.region_seed,
                    "flat_dim": self._flat_dim,
                    "coord_indices": self._coord_indices,
                }
            )
        elif flat_dim != self._flat_dim:
            raise ValueError(
                f"latent dimensionality changed from {self._flat_dim} to {flat_dim}"
            )

    def region_ids(self, z):
        self._ensure_partition(z)
        flat = z.detach().reshape(z.shape[0], -1)
        coords = flat[:, self._coord_indices]
        bits = (coords >= 0).to(torch.long)
        weights = 1 << torch.arange(self.region_bits, device=z.device, dtype=torch.long)
        return (bits * weights.unsqueeze(0)).sum(dim=1)

    def begin_xm_batch(self, *, batch_size, best_of_k, step):
        if self._batch is not None:
            raise RuntimeError("observer batch already active")
        self._batch = {
            "batch_size": int(batch_size),
            "best_of_k": int(best_of_k),
            "step": int(step),
            "candidate_mult_seen": 0,
            "slot_counts": torch.zeros(self.num_regions, dtype=torch.long),
            "set_seen": torch.zeros((int(batch_size), self.num_regions), dtype=torch.bool),
            "best_losses": None,
            "best_regions": None,
            "replay_checked": False,
        }

    def observe_xm_call(self, *, rand_inputs, losses):
        """Observe helper calls without influencing them.

        The first K candidate multiplicities are the exploration calls. If
        save_mem_mode=True, the later B-sized call is the winning replay and is
        used only as an audit check.
        """
        if self._batch is None:
            return
        b = self._batch["batch_size"]
        k = self._batch["best_of_k"]
        if rand_inputs.shape[0] % b != 0:
            raise AssertionError("XM observation call is not divisible by regular batch")
        mult = rand_inputs.shape[0] // b
        region_ids = self.region_ids(rand_inputs).reshape(mult, b)

        if self._batch["candidate_mult_seen"] >= k:
            if rand_inputs.shape[0] == b and self._batch["best_regions"] is not None:
                replay_regions = region_ids.reshape(-1).detach().cpu()
                if not torch.equal(replay_regions, self._batch["best_regions"]):
                    raise AssertionError("observed XM replay regions do not match reconstructed winners")
                self._batch["replay_checked"] = True
            return

        if self._batch["candidate_mult_seen"] + mult > k:
            raise AssertionError("observer saw more exploration candidates than frozen K")

        ids_cpu = region_ids.detach().cpu()
        self._batch["slot_counts"] += torch.bincount(
            ids_cpu.reshape(-1), minlength=self.num_regions
        )
        for candidate_row in ids_cpu:
            self._batch["set_seen"][
                torch.arange(b, dtype=torch.long), candidate_row
            ] = True

        detached_losses = losses.detach().reshape(mult, b)
        chunk_min_losses, chunk_min_indices = detached_losses.min(dim=0)
        winner_regions = region_ids[
            chunk_min_indices, torch.arange(b, device=region_ids.device)
        ].detach().cpu()

        if self._batch["best_losses"] is None:
            self._batch["best_losses"] = chunk_min_losses.detach()
            self._batch["best_regions"] = winner_regions
        else:
            replacement = chunk_min_losses < self._batch["best_losses"]
            if replacement.any():
                replacement_cpu = replacement.detach().cpu()
                self._batch["best_regions"][replacement_cpu] = winner_regions[replacement_cpu]
                self._batch["best_losses"][replacement] = chunk_min_losses[replacement].detach()

        self._batch["candidate_mult_seen"] += mult

    def finish_xm_batch(self):
        if self._batch is None:
            return
        if self._batch["candidate_mult_seen"] != self._batch["best_of_k"]:
            raise AssertionError("observer did not see exactly K exploration candidates per sample")

        b = self._batch["batch_size"]
        winner_counts = torch.bincount(
            self._batch["best_regions"], minlength=self.num_regions
        )
        set_hits = self._batch["set_seen"].sum(dim=0).to(torch.long)

        self._append(
            {
                "kind": "train_authority",
                "rank": self.rank,
                "step": self._batch["step"],
                "k": self._batch["best_of_k"],
                "batch_size": b,
                "candidate_slot_counts": self._batch["slot_counts"].tolist(),
                "candidate_set_hits": set_hits.tolist(),
                "winner_counts": winner_counts.tolist(),
                "replay_checked": bool(self._batch["replay_checked"]),
            }
        )
        self._batch = None

    def observe_k1_noise(self, *, noise, step):
        ids = self.region_ids(noise).detach().cpu()
        counts = torch.bincount(ids, minlength=self.num_regions)
        self._append(
            {
                "kind": "train_authority",
                "rank": self.rank,
                "step": int(step),
                "k": 1,
                "batch_size": int(noise.shape[0]),
                "candidate_slot_counts": counts.tolist(),
                "candidate_set_hits": counts.tolist(),
                "winner_counts": counts.tolist(),
                "replay_checked": True,
            }
        )

    def should_measure_holdout(self, step):
        step = int(step)
        if self._last_holdout_step == step:
            return False
        if self.holdout_every_n_val_steps <= 0:
            return False
        if step % self.holdout_every_n_val_steps != 0:
            return False
        self._last_holdout_step = step
        return True

    def conditioned_noise(self, *, reference, region, count):
        """Fixed Gaussian bank conditioned on the region's coordinate signs."""
        self._ensure_partition(reference)
        g = torch.Generator(device="cpu")
        g.manual_seed(self.holdout_seed + int(region))
        shape = (int(count), *reference.shape[1:])
        z = torch.randn(shape, generator=g, dtype=torch.float32, device="cpu")
        flat = z.reshape(count, -1)
        for bit, coord in enumerate(self._coord_indices):
            sign_positive = ((int(region) >> bit) & 1) == 1
            mag = flat[:, coord].abs()
            flat[:, coord] = mag if sign_positive else -mag
        return z.to(device=reference.device, dtype=reference.dtype)

    def holdout_times(self, *, count, device):
        g = torch.Generator(device="cpu")
        g.manual_seed(self.holdout_seed + 1_000_000)
        return torch.rand((int(count),), generator=g, dtype=torch.float32).to(device=device)

    def record_q_hold(self, *, step, region_losses):
        self._append(
            {
                "kind": "q_hold",
                "rank": self.rank,
                "step": int(step),
                "loss_by_region": [float(x) for x in region_losses],
                "holdout_seed": self.holdout_seed,
                "holdout_examples": self.holdout_examples,
            }
        )
