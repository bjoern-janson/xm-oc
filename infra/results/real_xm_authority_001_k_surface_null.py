#!/usr/bin/env python3
"""Post-hoc finite-count null calibration for REAL-XM-AUTHORITY-001 K surface.

This is a diagnostic analysis only. It is not part of the frozen observer,
training process, region definition, or preregistered surface readout.
"""

import math
import numpy as np

SEED = 20260822
REPS = 200_000
N = 2049 * 8
P = 1.0 / 16.0
NUM_REGIONS = 16
OBSERVED = {
    2: {"rho_std": 0.023113, "max_abs": 0.045898},
    5: {"rho_std": 0.025724, "max_abs": 0.064284},
    8: {"rho_std": 0.028545, "max_abs": 0.074699},
    12: {"rho_std": 0.023251, "max_abs": 0.041539},
}


def approx_sd(k: int, n: int) -> float:
    return math.sqrt((1.0 - P) * (1.0 - 1.0 / k) / (n * P))


def simulate(k: int, rng: np.random.Generator):
    # Exchangeable-winner null: choose one winner-region per example, then the
    # K-1 nonwinner candidate regions independently from the same symmetric prior.
    # Candidate slots are winner slots + nonwinner slots, preserving the structural
    # correlation between A and C_slot under the null.
    probs = np.full(NUM_REGIONS, P)
    chunk = 5_000
    stds = []
    maxabs = []
    for _ in range(REPS // chunk):
        winners = rng.multinomial(N, probs, size=chunk)
        nonwinners = rng.multinomial(N * (k - 1), probs, size=chunk)
        slots = winners + nonwinners
        rho = k * winners / slots
        stds.append(rho.std(axis=1))
        maxabs.append(np.max(np.abs(rho - 1.0), axis=1))
    return np.concatenate(stds), np.concatenate(maxabs)


def main():
    rng = np.random.default_rng(SEED)
    print("seed", SEED, "reps", REPS, "N", N)
    for k in [2, 5, 8, 12]:
        stds, maxabs = simulate(k, rng)
        obs = OBSERVED[k]
        print(
            "K", k,
            "approx_per_region_sd", approx_sd(k, N),
            "window512_approx_per_region_sd", approx_sd(k, 512 * 8),
            "null_mean_cross_region_std", float(stds.mean()),
            "observed_cross_region_std", obs["rho_std"],
            "p_std_ge_observed", float(np.mean(stds >= obs["rho_std"])),
            "null_mean_max_abs", float(maxabs.mean()),
            "observed_max_abs", obs["max_abs"],
            "p_max_ge_observed", float(np.mean(maxabs >= obs["max_abs"])),
            "q95_std", float(np.quantile(stds, 0.95)),
            "q95_max_abs", float(np.quantile(maxabs, 0.95)),
        )


if __name__ == "__main__":
    main()
