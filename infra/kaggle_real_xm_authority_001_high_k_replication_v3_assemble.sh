#!/usr/bin/env bash
set -Eeuo pipefail

# Assemble five independently preserved v3 seed-block archives, re-audit all 15
# members, then invoke the prospectively frozen summarizer exactly once.

FROZEN_SHA="be7cefd60cf199e9fbabd6110be1254a1756590e"
EXECUTION_BUNDLE_SHA="30cacad1aa73b5b860f5057b5e1bb8b75b4b000f"
SEEDS=(101 202 303 404 505)
KS=(2 8 12)
ROOT="/kaggle/working/real_xm_authority_001_high_k_replication_assembled"
OUT="$ROOT/output"
RUNNER="$ROOT/runner"

rm -rf "$ROOT"
mkdir -p "$OUT" "$RUNNER"

echo "=== REAL-XM-AUTHORITY-001 V3 FIVE-BLOCK ASSEMBLY ==="
echo "Frozen scientific SHA: $FROZEN_SHA"
echo "Execution bundle SHA: $EXECUTION_BUNDLE_SHA"
echo "This command opens the preregistered five-seed endpoint only after all five archives pass custody/structure checks."

find_one_archive() {
  local seed="$1" name="real_xm_authority_001_seed${seed}_block.tar.gz"
  mapfile -t hits < <(find /kaggle/working /kaggle/input -type f -name "$name" 2>/dev/null | sort -u)
  [[ "${#hits[@]}" -eq 1 ]] || {
    echo "FATAL: expected exactly one $name under /kaggle/working or /kaggle/input; found ${#hits[@]}" >&2
    printf '  %s\n' "${hits[@]:-}" >&2
    exit 20
  }
  printf '%s\n' "${hits[0]}"
}

for SEED in "${SEEDS[@]}"; do
  ARCHIVE="$(find_one_archive "$SEED")"
  echo "seed=$SEED archive=$ARCHIVE"
  sha256sum "$ARCHIVE" | tee "$OUT/seed${SEED}-archive.sha256"
  TMP="$ROOT/unpack_seed${SEED}"
  mkdir -p "$TMP"
  tar -C "$TMP" -xzf "$ARCHIVE"

  python - <<PY
import json
from pathlib import Path
seed=int($SEED)
tmp=Path("$TMP")
meta=json.loads((tmp/"output"/"block-metadata.json").read_text())
assert meta["kind"]=="REAL-XM-AUTHORITY-001-high-k-replication-v3-seed-block"
assert int(meta["seed"])==seed
assert meta["k_values"]==[2,8,12]
assert meta["frozen_sha"]=="$FROZEN_SHA"
assert meta["execution_bundle_sha"]=="$EXECUTION_BUNDLE_SHA"
assert meta["dataset"]=="ILSVRC/imagenet-1k"
assert meta["dataset_revision"]=="49e2ee26f3810fb5a7536bbf732a7b07389a47b5"
assert meta["primary_endpoint_opened"] is False
m=meta["data_manifest"]
assert m["train"]["rgb_label_sha256"]=="4c66cdf359d428ba6e037ce8e9d8ae7814d02b4e1c9eb636df86f0c13ec0d3c3"
assert m["train"]["latent_part_sha256"]=="624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f"
assert m["validation"]["rgb_label_sha256"]=="ddb96596358e97db3d5c31579a8376616a3bca481a31f12d92cd97204b042fb7"
assert m["validation"]["latent_part_sha256"]=="f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99"
print("BLOCK_METADATA_CUSTODY_PASS", seed)
PY

  # Exact execution bundle identity is preserved in each block ledger.
  grep -Fq "a70b93db79cc141218514c86169a86c88833f224cb5f858f78f96b00c61ca71a" "$TMP/output/execution-bundle-files.sha256"
  grep -Fq "7ab46c728b18900e8db7dc4eaa9ca85f835bb52cc2f3eb96da73cd42c5e287d0" "$TMP/output/execution-bundle-files.sha256"
  grep -Fq "44bd21fa315aa8e52030cc5fe605d437187e0fee0d15653c11be54ee48ee8c7a" "$TMP/output/execution-bundle-files.sha256"
  grep -Fq "e57a58bcda2eb9693d65f374d6464d5c9a381a5047337f7b1a5bfc81e3c6f94b" "$TMP/output/execution-bundle-files.sha256"

  cp -a "$TMP/seed${SEED}" "$ROOT/"
  cp "$TMP/output/block-metadata.json" "$OUT/seed${SEED}-block-metadata.json"
  cp "$TMP/output/block-custody.sha256" "$OUT/seed${SEED}-block-custody.sha256"
done

echo "=== RE-AUDIT ALL 15 MEMBERS ==="
python - <<'PY'
import json
from pathlib import Path
root=Path("/kaggle/working/real_xm_authority_001_high_k_replication_assembled")
for seed in [101,202,303,404,505]:
    for k in [2,8,12]:
        member=root/f"seed{seed}"/f"k{k}"
        obs=member/"observer"/"authority_rank0.jsonl"
        assert obs.exists(), obs
        records=[json.loads(x) for x in obs.read_text().splitlines() if x.strip()]
        parts=[r for r in records if r.get("kind")=="partition"]
        train=[r for r in records if r.get("kind")=="train_authority"]
        q=[r for r in records if r.get("kind")=="q_hold"]
        assert len(parts)==1
        assert parts[0]["coord_indices"]==[808,1575,2250,2349]
        assert int(parts[0]["region_seed"])==314159
        assert len(train)==2049
        assert sorted(int(r["step"]) for r in train)==list(range(2049))
        assert len(q)==4
        assert [int(r["step"]) for r in q]==[512,1024,1536,2048]
        assert all(int(r["k"])==k and int(r["batch_size"])==8 and bool(r.get("replay_checked",False)) for r in train)
        assert sum(sum(r["candidate_slot_counts"]) for r in train)==2049*8*k
        assert sum(sum(r["winner_counts"]) for r in train)==2049*8
        assert (member/"train-exit-code.txt").read_text().strip()=="0"
        assert "REPLICATION_MEMBER_AUDIT_PASS" in (member/"member-audit.txt").read_text()
        assert not list(member.rglob("*.ckpt"))
        print("ASSEMBLED_MEMBER_AUDIT_PASS",seed,k)
print("ASSEMBLED_15_MEMBER_CUSTODY_PASS")
PY

# Only now retrieve and execute the previously frozen summarizer.
BASE_RAW="https://raw.githubusercontent.com/bjoern-janson/xm-oc/$EXECUTION_BUNDLE_SHA/infra"
curl -fsSL "$BASE_RAW/summarize_real_xm_authority_001_high_k_replication.py" -o "$RUNNER/summarize_replication.py"
SUM_SHA="$(sha256sum "$RUNNER/summarize_replication.py" | awk '{print $1}')"
[[ "$SUM_SHA" == "e57a58bcda2eb9693d65f374d6464d5c9a381a5047337f7b1a5bfc81e3c6f94b" ]] || { echo "FATAL: frozen summarizer hash mismatch" >&2; exit 30; }

echo "=== OPENING FROZEN FIVE-SEED ENDPOINT ==="
python "$RUNNER/summarize_replication.py" \
  --root "$ROOT" \
  --output "$OUT/replication-summary.json" \
  --frozen-sha "$FROZEN_SHA" \
  --execution-bundle-sha "$EXECUTION_BUNDLE_SHA" \
  2>&1 | tee "$OUT/replication-summary.txt"

sha256sum "$OUT/replication-summary.json" "$OUT/replication-summary.txt" | tee "$OUT/replication-summary.sha256"

echo "=== REAL_DATA_HIGH_K_COUPLING_REPLICATION_RECORDED ==="
echo "SUMMARY_JSON $OUT/replication-summary.json"
echo "SUMMARY_TEXT $OUT/replication-summary.txt"
