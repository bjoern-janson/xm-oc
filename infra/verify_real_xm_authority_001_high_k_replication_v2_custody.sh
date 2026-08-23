#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/kaggle/working/real_xm_authority_001_high_k_replication"
REPO_DIR="$ROOT/xm-oc"
RUNNER_DIR="$ROOT/runner"
CACHE_DIR="$ROOT/cached_latents/imagenet"
OUT_DIR="$ROOT/output"
FROZEN_SHA="be7cefd60cf199e9fbabd6110be1254a1756590e"
EXECUTION_BUNDLE_SHA="30cacad1aa73b5b860f5057b5e1bb8b75b4b000f"

PASS_MARKER="CUSTODY_14_PASS_MISSING_505_K12_RECOVERABLE"
FAIL_MARKER="CUSTODY_FAIL_FULL_15_MEMBER_RERUN_REQUIRED"
REPORT="${OUT_DIR}/replication-v2-custody-verification.txt"

fail() {
  local msg="$1"
  echo "FAIL: $msg" >&2
  echo "$FAIL_MARKER" >&2
  exit 42
}

sha_expect() {
  local expected="$1" path="$2" label="$3"
  [[ -f "$path" ]] || fail "missing $label: $path"
  local actual
  actual="$(sha256sum "$path" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || fail "sha256 mismatch $label expected=$expected actual=$actual path=$path"
}

mkdir -p "$OUT_DIR" 2>/dev/null || true
exec > >(tee "$REPORT") 2>&1

echo "=== REAL-XM-AUTHORITY-001 REPLICATION V2 CUSTODY VERIFICATION ==="
echo "This command performs custody verification only. It does not train or summarize."
echo "Frozen scientific SHA: $FROZEN_SHA"
echo "Execution bundle SHA: $EXECUTION_BUNDLE_SHA"

date -u '+utc_now %Y-%m-%dT%H:%M:%SZ' || true
df -h /kaggle/working || true

[[ -d "$ROOT" ]] || fail "replication root absent; prior /kaggle/working artifacts did not survive"
[[ -d "$REPO_DIR/.git" ]] || fail "frozen checkout absent"
[[ -d "$RUNNER_DIR" ]] || fail "runner directory absent"
[[ -d "$CACHE_DIR" ]] || fail "matched cache directory absent"

actual_sha="$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || true)"
[[ "$actual_sha" == "$FROZEN_SHA" ]] || fail "frozen checkout SHA mismatch expected=$FROZEN_SHA actual=$actual_sha"
git -C "$REPO_DIR" diff --quiet || fail "frozen checkout has worktree changes"
git -C "$REPO_DIR" diff --cached --quiet || fail "frozen checkout has staged changes"
echo "FROZEN_CHECKOUT_CUSTODY_PASS"

# Exact recovered execution-bundle files recorded at v2 launch.
sha_expect "a70b93db79cc141218514c86169a86c88833f224cb5f858f78f96b00c61ca71a" "$RUNNER_DIR/build_cache.py" "build_cache.py"
sha_expect "7ab46c728b18900e8db7dc4eaa9ca85f835bb52cc2f3eb96da73cd42c5e287d0" "$RUNNER_DIR/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION.md" "frozen replication protocol"
sha_expect "44bd21fa315aa8e52030cc5fe605d437187e0fee0d15653c11be54ee48ee8c7a" "$RUNNER_DIR/run_seeded.py" "run_seeded.py"
sha_expect "e57a58bcda2eb9693d65f374d6464d5c9a381a5047337f7b1a5bfc81e3c6f94b" "$RUNNER_DIR/summarize_replication.py" "summarize_replication.py"
echo "EXECUTION_BUNDLE_CUSTODY_PASS"

# Exact matched ImageNet latent cache anchors from the original pilot/surface lineage.
sha_expect "624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f" "$CACHE_DIR/imagenet_train_256x256_vae.safetensors.parts/part_00000.safetensors" "train latent cache part"
sha_expect "f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99" "$CACHE_DIR/imagenet_val_256x256_vae.safetensors.parts/part_00000.safetensors" "validation latent cache part"
echo "MATCHED_CACHE_CUSTODY_PASS"

# Any checkpoint would violate the v2 recovered checkpoint-free execution boundary.
if find "$ROOT" -name '*.ckpt' -type f -print -quit | grep -q .; then
  fail "unexpected checkpoint file exists under v2 replication root"
fi

# seed K observer_sha train_sha audit_sha
while read -r seed k obs_sha train_sha audit_sha; do
  [[ -n "${seed:-}" ]] || continue
  member="$ROOT/seed${seed}/k${k}"
  obs="$member/observer/authority_rank0.jsonl"
  train_log="$member/train.log"
  audit="$member/member-audit.txt"
  exit_code="$member/train-exit-code.txt"
  custody="$member/custody.sha256"

  sha_expect "$obs_sha" "$obs" "seed=$seed K=$k observer"
  sha_expect "$train_sha" "$train_log" "seed=$seed K=$k train log"
  sha_expect "$audit_sha" "$audit" "seed=$seed K=$k member audit"
  [[ -f "$exit_code" ]] || fail "missing seed=$seed K=$k train exit code"
  [[ "$(tr -d '[:space:]' < "$exit_code")" == "0" ]] || fail "nonzero recorded train exit code seed=$seed K=$k"
  [[ -f "$custody" ]] || fail "missing seed=$seed K=$k custody.sha256"

  grep -Fq "REPLICATION_MEMBER_AUDIT_PASS $seed $k" "$audit" || fail "member audit marker missing seed=$seed K=$k"
  grep -Fq "REPLICATION_SEED_INJECTION $seed" "$train_log" || fail "seed injection marker missing seed=$seed K=$k"
  grep -Fq "Seed set to $seed" "$train_log" || fail "Lightning/frozen seed marker missing seed=$seed K=$k"
  grep -Fq "REPLICATION_CHECKPOINT_WRITES_DISABLED" "$train_log" || fail "checkpoint-disable marker missing seed=$seed K=$k"

  python - "$obs" "$k" <<'PY'
import json, sys
from pathlib import Path
obs=Path(sys.argv[1]); K=int(sys.argv[2])
records=[json.loads(x) for x in obs.read_text().splitlines() if x.strip()]
parts=[r for r in records if r.get('kind')=='partition']
train=[r for r in records if r.get('kind')=='train_authority']
q=[r for r in records if r.get('kind')=='q_hold']
assert len(parts)==1
assert parts[0]['coord_indices']==[808,1575,2250,2349]
assert int(parts[0]['region_seed'])==314159
assert len(train)==2049
assert sorted(int(r['step']) for r in train)==list(range(2049))
assert len(q)==4
assert [int(r['step']) for r in q]==[512,1024,1536,2048]
assert all(int(r['k'])==K and int(r['batch_size'])==8 and bool(r.get('replay_checked',False)) for r in train)
assert sum(sum(r['candidate_slot_counts']) for r in train)==2049*8*K
assert sum(sum(r['winner_counts']) for r in train)==2049*8
PY

  echo "CUSTODY_MEMBER_PASS $seed $k"
done <<'EOF'
101 2 28d54b0f7c05fba735e9f4822565db0acd7854accba3af398b5fe9766fc42c95 b2303eb7b323049f5aaa64eb38fc823329ab0239f8dfec35c75aabe237ca471e f1b33d8e574cfd7130aa735acc72f649543b6359727ea27489c1bb4e6b1e6334
101 8 2af98d00df72f3396fd337755a8aaba1d24fbdca0dcaf19cfee6c1191444b1af 98c0a59f6e4964ac25ba8729db8580efc4f29caaebdab56457a387fba68a05aa 85eba7114bf8d6b1c1afb73e919fa390f83236880a119dab01cabd465be87b6a
101 12 6305f1be7757a0f2663c01ffa60b3576c476e7fd8cf66f6f01cbc841870803cb 99771007fc5d05ef1d1febb8b53ca9b7e20c1c5fa05ceab91d28344a152b9055 5cadb0435a51fe8e99ee012ef51254002378b8c945fbfc1f12628114e34abfc8
202 2 acf4eac1438005a8a5a9e2224d42042368114da6bf8b80df8c6b2c713fa0ab23 f77095f8ed3fdfd7374199d89818445990e057b3cd021b656242735e73ee1a9d 4c7131f3ee8604e20eaa0d6a59083a29ff26279e8af897e5ae5f50fb2dba42a7
202 8 e5f08a6acca2dca549e1e3a81e731015f27b1231dbb00b47a2b3bd9b35695f7f e81f9fc9586e66e7bf6b6acf9def85c7c8e3e4ed12228072a02294daea5a27eb 7a5660723968737c621979951ad332633b844766daf96f5c20370c4e621c5cf7
202 12 75822a7d58edff75627a3b9d599bd273e7e03c52ba3c2b71620be4b8f2e2e4b7 10787fc3d9190b040533abdcbdedbf758947ab4c91d68627629143709d0aea59 836b89d80d2b3bcba1420fe5697f78890bdc651ea3df7b91f56e59407f667b0f
303 2 30abb32cc300eb3ded56cd9d746ca3af44d001e75b3e5e376e97465f3595c9ee 4331ddd8d1f22f4598882610c959ccfcdde824d9b8968883f2201328f1d21831 e33a1531408a3db315385f467e5d8a3403cbbbaaded0531a1f3e9abdbd575e90
303 8 5a609cc92791093b39061abe48a2f5c1fbae01b35a6f062ce4adbf9e825454e5 ece1ca3c110ddb515233d7ebf817447201d2ec6573b0896805b245d77b3fefaf 65d46c087e768ec3a485b1742d21982e5bc855ab38226c84252cd2b1c2ee3034
303 12 9c13c933a2daeed6dcc9b1bf5a705a9522fb01e7f2b0dd235941fda4314d1872 5f347fef03f1ebc7fa692f21aa5a134b108027e985e9e4a95d8aecf4522002ed fe37993f8d3508c0bba386833246f37dd086bc27fd7c4b6e2032b74f72d62eda
404 2 f35ad2796775255cb6499e09b845a9691486ae4cf5f80aa148e0056818f5e97c 5a571cdb96e3c570db804bda12977173d64f7febd3f7afde503775949f1fbfa3 378d3f0e5647292b22946eba9cea2fb791804cdd8468d708792e9e623d03e1f2
404 8 5c702595c378d955982ca07e2ea6c9a04f6c0c71e3e4a6a1dbeef52c9b92e0f3 57d24b931c3067ef5c41c6c96952b9b205e967bd4efe092b27505632b89a390f df4004ba25944543d742c0bbb75c58405890ff5518f3e63ac89cbd713695817a
404 12 b84b1d0baed51d03f1a41a605b2f73a85ecce9d0b771e339c165c40d176ae0a7 4d3f6559794d1f035741acca7781a2e737059eb626ad9524c0a6c092b66a36d0 31fd3cc104f0f9c2d444bf4cfa24cd0577a7e30d52d053b870666bd0f10798bd
505 2 4c0e25eb596363d703e55c91404ce890071eb25679edc2011621d11e5f579504 65bb11a794899e6707e938e6e0ba34d1d954b035929263b31c12828584fe70f5 fe7694ed16300730182826309cf68efc8a65da2c6f0ac1baa73af68bba9a4312
505 8 0e78eba72e98557f846247fa7ee14f031732012f3b9ce2b5f9e5ff3bcf54923e 43db484ef7de892b62c17f3ffc5004313fb3a477a3e68f4bba183ccdc9a29555 4031c47a682b985de4bffd7e22987807ca96c599a01ac72a7f765ece557bda64
EOF

echo "COMPLETED_MEMBER_COUNT 14"

# The missing member must not be silently accepted as complete. We only record its present partial state.
MISSING="$ROOT/seed505/k12"
if [[ -d "$MISSING" ]]; then
  echo "=== PARTIAL 505 K12 PRESENT: RECORDING NON-SCIENTIFIC CUSTODY ==="
  find "$MISSING" -type f -print0 | sort -z | xargs -0 -r sha256sum || true
  if [[ -f "$MISSING/observer/authority_rank0.jsonl" ]]; then
    python - "$MISSING/observer/authority_rank0.jsonl" <<'PY'
import json, sys
from pathlib import Path
p=Path(sys.argv[1])
records=[json.loads(x) for x in p.read_text().splitlines() if x.strip()]
print('PARTIAL_505_K12_TOTAL_RECORDS', len(records))
print('PARTIAL_505_K12_PARTITION_RECORDS', sum(r.get('kind')=='partition' for r in records))
train=[r for r in records if r.get('kind')=='train_authority']
q=[r for r in records if r.get('kind')=='q_hold']
print('PARTIAL_505_K12_TRAIN_AUTHORITY_RECORDS', len(train))
print('PARTIAL_505_K12_Q_HOLD_STEPS', [int(r['step']) for r in q])
PY
  fi
else
  echo "PARTIAL_505_K12_DIRECTORY_ABSENT"
fi

# A complete campaign summary must not already exist; opening it before member 15 would violate the freeze.
if [[ -f "$OUT_DIR/replication-summary.json" ]]; then
  fail "replication-summary.json already exists despite incomplete member set"
fi

echo "$PASS_MARKER"
echo "NEXT_AUTHORIZED_ACTION: rerun only seed=505 K=12 from scratch, audit it, then invoke the frozen summarizer once."
echo "NO_CONFIRMATORY_RESULT_OPENED"
