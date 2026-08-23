#!/usr/bin/env bash
set -Eeuo pipefail

# XM-CRCB-001 L2-only calibration orchestrator.
# Thin infrastructure over the already-frozen calibration apparatus.
# Adds no repair, metric, threshold, optimizer, evaluator, or science logic.
#
# Legal transition:
#   custody-valid B606 + B707 + immutable failed L1 predecessor
#     -> frozen run-language --language L2 only.
#
# Claim ceiling:
#   L2 calibration adequacy != H_CRCB evidence != factorization result.

APPARATUS_FREEZE_SHA="b8caf8ffcc0a3bbd4fabfbc610b0767293e11aff"
SOURCE_SCIENTIFIC_SHA="be7cefd60cf199e9fbabd6110be1254a1756590e"
CC_PROTOCOL_COMMIT="4d0e87613ef1b894d6ebac2400e358a9fd82e5ae"
BASE_INFRA_COMMIT="78aeb98a58339a2f86d43bb4b852333c745c930c"
L1_ORCHESTRATOR_COMMIT="f40d06d38bb75ae1f2b6ae1d14e2dca9fad4da8b"
REPO_URL="https://github.com/bjoern-janson/xm-oc.git"

ENTRYPOINT_BLOB="7c8c6feeadeed3aff0ad9eb071914037eaea2fb8"
CORE_BLOB="e82965c7ef33256cd26c08debc32d3cf1ee767d9"
REAL_RUNNER_BLOB="5198d56b57f108c6791159c28df84ce4569747b3"
L1_FREEZE_BLOB="32c519438c798e903dd37c8718b2be278afeb080"

ARCHIVE_606_SHA="e40ffb5b9e6874f539e5581d115ffdbc6f79f65f03c59899cd7a1b5223199a6a"
ARCHIVE_707_SHA="f8968bfbc8d87d37fbb3bd284f523b87caa6a0b9ddad045b245151613ba5d462"
MANIFEST_606_SHA="ed52af08ea165dd488e019b81da2fd67dd2361e8aff8348323599180795d5045"
MANIFEST_707_SHA="14690fe63cab93b77b211282d91b0e9a1d2f7fb20e88b9ab73ac836b207c4481"
CHECKPOINT_606_SHA="e0f8f4ae377255f3592aa2c0046e9bbefd91cdf4798d8b05ef9e223dd81a59b2"
CHECKPOINT_707_SHA="a47641d076ac9ccec6e69041c03126ddc81c81e8264b0231840b3dbbc921504b"
VAL_CACHE_SHA="f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99"
TRAIN_CACHE_SHA="624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f"

# Immutable L1 predecessor. L2 may consume these bytes; it may not recompute or reinterpret them.
L1_RESULT_SHA="b111d63df0aa14e4fa6495b4fd9b4f285a295d554f9e43a6c9ec54c41a251bf7"
L1_CUSTODY_SHA="2cdc66502079012ea8fd6d5c81c5dbb0032e12284f240fd938391adc82f952f7"
L1_RESULT_ARCHIVE_SHA="e5ff8f9cd7d6ffa7d3f6b906e7ea83ce06e3d0bf8f0b7182b808557ae0710fb2"

ARCHIVE606="${1:-}"
ARCHIVE707="${2:-}"
L1ARCHIVE="${3:-}"

if [[ -z "$ARCHIVE606" || -z "$ARCHIVE707" || -z "$L1ARCHIVE" ]]; then
  echo "usage: $0 <base606.tar.gz> <base707.tar.gz> <L1-result.tar.gz>" >&2
  exit 2
fi
for p in "$ARCHIVE606" "$ARCHIVE707" "$L1ARCHIVE"; do
  [[ -f "$p" ]] || { echo "FATAL: missing required input: $p" >&2; exit 3; }
done

ROOT="/kaggle/working/xm_crcb_001_l2_calibration"
APP_REPO="$ROOT/xm-oc"
EXTRACT606="$ROOT/base606"
EXTRACT707="$ROOT/base707"
PRED="$ROOT/L1_predecessor"
OUT="$ROOT/output"
RESULT_DIR="$OUT/L2"
BUNDLE="/kaggle/working/xm_crcb_001_L2_calibration_result.tar.gz"

rm -rf "$ROOT"
rm -f "$BUNDLE"
mkdir -p "$EXTRACT606" "$EXTRACT707" "$PRED" "$OUT"

exec > >(tee "$OUT/orchestration.log") 2>&1

echo "=== XM-CRCB-001 L2-ONLY CALIBRATION ==="
echo "apparatus_freeze=$APPARATUS_FREEZE_SHA"
echo "source_scientific_sha=$SOURCE_SCIENTIFIC_SHA"
echo "cc_protocol=$CC_PROTOCOL_COMMIT"
echo "language=L2"
echo "required_predecessor_L1_sha=$L1_RESULT_SHA"
echo "CLAIM CEILING: L2 calibration adequacy != H_CRCB evidence != factorization result"
echo "L3 forbidden unless this frozen L2 invocation returns a genuine language failure."
echo "No factorization / parity / held-out science object may be constructed."

sha_file() { sha256sum "$1" | awk '{print $1}'; }
check_sha() {
  local path="$1" expected="$2" label="$3" got
  got="$(sha_file "$path")"
  [[ "$got" == "$expected" ]] || {
    echo "FATAL: $label SHA mismatch" >&2
    echo "expected=$expected" >&2
    echo "actual=$got" >&2
    exit 10
  }
  echo "SHA_PASS $label $got"
}

# Bind all external bytes before extraction or execution.
check_sha "$ARCHIVE606" "$ARCHIVE_606_SHA" "base606_archive"
check_sha "$ARCHIVE707" "$ARCHIVE_707_SHA" "base707_archive"
check_sha "$L1ARCHIVE" "$L1_RESULT_ARCHIVE_SHA" "L1_result_archive"

# Reject path traversal, links/devices, and unexpected archive roots; compute required unpacked bytes.
UNPACKED_BYTES="$(python - "$ARCHIVE606" 606 "$ARCHIVE707" 707 "$L1ARCHIVE" <<'PY'
import pathlib, sys, tarfile
base_total=0
for archive,seed_s in ((sys.argv[1],sys.argv[2]),(sys.argv[3],sys.argv[4])):
    seed=int(seed_s); expected=f'base_seed{seed}'
    with tarfile.open(archive,'r:gz') as tf:
        members=tf.getmembers()
        if not members: raise SystemExit(f'FATAL: empty archive seed={seed}')
        for m in members:
            p=pathlib.PurePosixPath(m.name); parts=[x for x in p.parts if x not in ('','.')]
            if p.is_absolute() or '..' in parts: raise SystemExit(f'FATAL: unsafe archive path seed={seed}: {m.name}')
            if m.issym() or m.islnk() or m.isdev(): raise SystemExit(f'FATAL: non-regular archive member seed={seed}: {m.name}')
            if parts and parts[0] != expected: raise SystemExit(f'FATAL: unexpected archive root seed={seed}: {m.name}')
            if m.isfile(): base_total += m.size

allowed_roots={'L1','endpoint.json','L1-run-exit-code.txt','L1-orchestration-custody.sha256','apparatus-preflight.txt','orchestration.log','apparatus-freeze-sha.txt','base606-archive-sha256.txt','base707-archive-sha256.txt'}
with tarfile.open(sys.argv[5],'r:gz') as tf:
    members=tf.getmembers()
    if not members: raise SystemExit('FATAL: empty L1 predecessor archive')
    for m in members:
        p=pathlib.PurePosixPath(m.name); parts=[x for x in p.parts if x not in ('','.')]
        if p.is_absolute() or '..' in parts: raise SystemExit(f'FATAL: unsafe L1 archive path: {m.name}')
        if m.issym() or m.islnk() or m.isdev(): raise SystemExit(f'FATAL: non-regular L1 archive member: {m.name}')
        if parts and parts[0] not in allowed_roots: raise SystemExit(f'FATAL: unexpected L1 archive root: {m.name}')
print(base_total)
PY
)"
echo "ARCHIVE_STRUCTURE_PASS"

# Fail before partial extraction if writable storage is obviously insufficient.
FREE_BYTES="$(df -PB1 /kaggle/working | awk 'NR==2 {print $4}')"
HEADROOM=$((4 * 1024 * 1024 * 1024))
REQUIRED_BYTES=$((UNPACKED_BYTES + HEADROOM))
echo "storage_free_bytes=$FREE_BYTES"
echo "base_unpacked_bytes=$UNPACKED_BYTES"
echo "storage_required_with_headroom=$REQUIRED_BYTES"
[[ "$FREE_BYTES" -ge "$REQUIRED_BYTES" ]] || {
  echo "FATAL: insufficient writable storage before extraction" >&2
  echo "CALIBRATION_INFRASTRUCTURE_STORAGE_FAILURE" >&2
  echo "NO_LANGUAGE_ESCALATION_AUTHORIZED" >&2
  exit 11
}
echo "L2_STORAGE_PREFLIGHT_PASS"

tar -xzf "$ARCHIVE606" -C "$EXTRACT606"
tar -xzf "$ARCHIVE707" -C "$EXTRACT707"
tar -xzf "$L1ARCHIVE" -C "$PRED"

B606="$EXTRACT606/base_seed606"
B707="$EXTRACT707/base_seed707"
L1RESULT="$PRED/L1/calibration_L1_result.json"
L1CUSTODY="$PRED/L1/custody_manifest.json"
L1ENDPOINT="$PRED/endpoint.json"

for d in "$B606" "$B707"; do
  [[ -d "$d" ]] || { echo "FATAL: extracted base directory missing: $d" >&2; exit 12; }
  [[ -f "$d/base-custody.sha256" ]] || { echo "FATAL: base-custody.sha256 missing: $d" >&2; exit 13; }
  (cd "$d" && sha256sum -c base-custody.sha256)
done

[[ -f "$L1RESULT" && -f "$L1CUSTODY" && -f "$L1ENDPOINT" ]] || {
  echo "FATAL: immutable L1 predecessor files missing" >&2; exit 14;
}
check_sha "$L1RESULT" "$L1_RESULT_SHA" "L1_calibration_result"
check_sha "$L1CUSTODY" "$L1_CUSTODY_SHA" "L1_custody_manifest"

M606="$B606/base_manifest_seed606.json"
M707="$B707/base_manifest_seed707.json"
C606="$B606/last.ckpt"
C707="$B707/last.ckpt"
V606="$B606/imagenet_val_256x256_vae.part_00000.safetensors"
V707="$B707/imagenet_val_256x256_vae.part_00000.safetensors"

check_sha "$M606" "$MANIFEST_606_SHA" "base606_manifest"
check_sha "$M707" "$MANIFEST_707_SHA" "base707_manifest"
check_sha "$C606" "$CHECKPOINT_606_SHA" "base606_checkpoint"
check_sha "$C707" "$CHECKPOINT_707_SHA" "base707_checkpoint"
check_sha "$V606" "$VAL_CACHE_SHA" "base606_val_cache"
check_sha "$V707" "$VAL_CACHE_SHA" "base707_val_cache"
cmp -s "$V606" "$V707" || { echo "FATAL: 606/707 validation cache bytes differ" >&2; exit 15; }

# Re-establish exact pre-calibration base state and all sealed flags.
python - "$M606" "$M707" <<'PY'
import json, sys
APP='b8caf8ffcc0a3bbd4fabfbc610b0767293e11aff'; SRC='be7cefd60cf199e9fbabd6110be1254a1756590e'; CC='4d0e87613ef1b894d6ebac2400e358a9fd82e5ae'; INF='78aeb98a58339a2f86d43bb4b852333c745c930c'
TRAIN='624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f'; VAL='f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99'
CK={606:'e0f8f4ae377255f3592aa2c0046e9bbefd91cdf4798d8b05ef9e223dd81a59b2',707:'a47641d076ac9ccec6e69041c03126ddc81c81e8264b0231840b3dbbc921504b'}
false_flags=('authority_observer_enabled','repair_language_evaluated','repair_language_adequacy_known','calibration_result_opened','factorization_constructed','parity_split_constructed','science_seed_materialized','science_context_evaluated','science_region_conditioned_contexts_constructed','science_rng_materialized','calibration_region_banks_constructed')
for seed,path in zip((606,707),sys.argv[1:]):
    x=json.load(open(path)); req={'kind':'XM-CRCB-001-calibration-base','apparatus_freeze_sha':APP,'source_scientific_sha':SRC,'cc_protocol_commit':CC,'infra_commit':INF,'base_seed':seed,'k_train':2,'optimizer_steps':2049,'batch_size':8,'train_latent_sha256':TRAIN,'val_latent_sha256':VAL,'checkpoint_sha256':CK[seed],'custody_valid':True}
    for k,v in req.items():
        if x.get(k)!=v: raise SystemExit(f'FATAL: base{seed} manifest {k} mismatch: {x.get(k)!r} != {v!r}')
    if int(x.get('checkpoint',{}).get('global_step',-1))!=2049: raise SystemExit(f'FATAL: base{seed} checkpoint global_step mismatch')
    for k in false_flags:
        if x.get(k) is not False: raise SystemExit(f'FATAL: base{seed} firewall flag not false: {k}')
print('BASE_PAIR_MANIFEST_FIREWALL_PASS')
PY

# Validate the immutable L1 predecessor without recomputing or reclassifying it.
python - "$L1RESULT" "$L1CUSTODY" "$L1ENDPOINT" "$PRED/L1" <<'PY'
import hashlib, json, pathlib, sys
rp,cp,ep,rd=map(pathlib.Path,sys.argv[1:]); x=json.loads(rp.read_text()); c=json.loads(cp.read_text()); e=json.loads(ep.read_text())
EXP='b111d63df0aa14e4fa6495b4fd9b4f285a295d554f9e43a6c9ec54c41a251bf7'
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for q in iter(lambda:f.read(1<<20),b''): h.update(q)
    return h.hexdigest()
if sha(rp)!=EXP: raise SystemExit('FATAL: L1 predecessor bytes changed')
if x.get('schema')!='XM-CRCB-001-CALIBRATION-APPARATUS-v1' or x.get('kind')!='real_calibration_language_result': raise SystemExit('FATAL: L1 predecessor schema/kind mismatch')
if x.get('source_scientific_sha')!='be7cefd60cf199e9fbabd6110be1254a1756590e' or x.get('cc_protocol_commit')!='4d0e87613ef1b894d6ebac2400e358a9fd82e5ae': raise SystemExit('FATAL: L1 predecessor provenance mismatch')
if x.get('language')!='L1' or x.get('decision',{}).get('classification')!='LANGUAGE_FAIL': raise SystemExit('FATAL: L1 predecessor is not the frozen failed L1 result')
if x.get('prior_results')!=[]: raise SystemExit('FATAL: L1 predecessor unexpectedly has priors')
for k,v in {'science_reserved_semantic_access':False,'factorization_constructed':False,'authority_metrics_read':False,'calibration_only':True}.items():
    if x.get(k)!=v: raise SystemExit(f'FATAL: L1 predecessor firewall mismatch {k}')
if c.get('result',{}).get('file')!=rp.name or c.get('result',{}).get('sha256')!=EXP: raise SystemExit('FATAL: L1 predecessor custody result binding mismatch')
for a in c.get('artifacts',[]):
    p=rd/a['file']
    if not p.is_file() or p.stat().st_size!=a['bytes'] or sha(p)!=a['sha256']: raise SystemExit(f"FATAL: L1 predecessor artifact custody mismatch {a['file']}")
if e.get('endpoint')!='L1_CALIBRATION_FAIL' or e.get('frozen_language_classification')!='LANGUAGE_FAIL' or e.get('L2_authorized') is not True or e.get('L3_authorized') is not False or e.get('factorization_authorized') is not False or e.get('science_authorized') is not False: raise SystemExit('FATAL: L1 predecessor endpoint mismatch')
if e.get('result_sha256')!=EXP: raise SystemExit('FATAL: L1 endpoint/result hash mismatch')
print('IMMUTABLE_L1_PREDECESSOR_PASS')
PY

# Prepare exact detached frozen apparatus; verify the committed predecessor-freeze record by Git blob.
python -m pip install -q --upgrade pip setuptools wheel
python -m pip install -q --no-cache-dir torch==2.4.0 torchvision==0.19.0 --index-url https://download.pytorch.org/whl/cu121

git clone -q "$REPO_URL" "$APP_REPO"
git -C "$APP_REPO" checkout -q --detach "$APPARATUS_FREEZE_SHA"
[[ "$(git -C "$APP_REPO" rev-parse HEAD)" == "$APPARATUS_FREEZE_SHA" ]] || { echo "FATAL: apparatus SHA mismatch" >&2; exit 20; }
git -C "$APP_REPO" diff --quiet; git -C "$APP_REPO" diff --cached --quiet
git -C "$APP_REPO" merge-base --is-ancestor "$SOURCE_SCIENTIFIC_SHA" "$APPARATUS_FREEZE_SHA"
[[ "$(git -C "$APP_REPO" rev-parse "$APPARATUS_FREEZE_SHA:experiments/xm_crcb_001_calibration.py")" == "$ENTRYPOINT_BLOB" ]] || { echo "FATAL: frozen entrypoint blob mismatch" >&2; exit 21; }
[[ "$(git -C "$APP_REPO" rev-parse "$APPARATUS_FREEZE_SHA:experiments/xm_crcb_001/core.py")" == "$CORE_BLOB" ]] || { echo "FATAL: frozen core blob mismatch" >&2; exit 22; }
[[ "$(git -C "$APP_REPO" rev-parse "$APPARATUS_FREEZE_SHA:experiments/xm_crcb_001/real_runner.py")" == "$REAL_RUNNER_BLOB" ]] || { echo "FATAL: frozen real_runner blob mismatch" >&2; exit 23; }

cd "$APP_REPO"
python -m pip install -q --no-cache-dir -r requirements.txt
export USE_TORCH=1 USE_TF=0 TRANSFORMERS_NO_TF=1
export HF_HOME="$ROOT/hf_cache" HF_HUB_DISABLE_TELEMETRY=1
export PYTHONPATH="$APP_REPO:$APP_REPO/experiments${PYTHONPATH:+:$PYTHONPATH}"
export WANDB_MODE=offline WANDB_SILENT=true
export XM_AUTHORITY_OBS=0
unset XM_AUTHORITY_REGION_BITS XM_AUTHORITY_REGION_SEED XM_AUTHORITY_HOLDOUT_SEED XM_AUTHORITY_HOLDOUT_EXAMPLES XM_AUTHORITY_HOLDOUT_EVERY_N_VAL_STEPS XM_AUTHORITY_OBS_DIR || true
mkdir -p "$HF_HOME"

nvidia-smi | tee "$OUT/nvidia-smi.txt"
python - <<'PY' | tee "$OUT/apparatus-preflight.txt"
import torch
from experiments.xm_crcb_001 import core
assert torch.cuda.is_available(), 'CUDA required'
torch.use_deterministic_algorithms(True); torch.backends.cudnn.benchmark=False; torch.backends.cudnn.deterministic=True
core.verify_coords()
assert core.LANGUAGES == ('L1','L2','L3')
assert core.LANGUAGE_LABELS['L2']=='full_final_layer'
assert core.CAL_BASE_SEEDS == (606,707)
assert core.CAL_REPAIR_SEEDS == (1101,1102,1103)
assert core.CONSTRUCT == tuple(range(64)); assert core.EVAL == tuple(range(64,128)); assert core.SCIENCE_RESERVED == tuple(range(128,256))
assert core.J == 32 and core.BATCH == 8
assert core.LR == 1e-4 and core.BETAS == (0.9,0.95) and core.WD == 0.0 and core.CLIP == 1.0
print('L2_FROZEN_APPARATUS_PREFLIGHT_PASS'); print('cuda_device',torch.cuda.get_device_name(0))
PY

# Sole scientific invocation. No language selector is exposed to the caller.
# The exact frozen failed L1 result is passed as the one required prior-result.
set +e
cd "$APP_REPO/experiments"
python xm_crcb_001_calibration.py run-language \
  --language L2 \
  --checkpoint-606 "$C606" \
  --checkpoint-707 "$C707" \
  --base-manifest-606 "$M606" \
  --base-manifest-707 "$M707" \
  --val-cache-part "$V606" \
  --prior-result "$L1RESULT" \
  --out "$RESULT_DIR" \
  2>&1 | tee "$OUT/L2-run.log"
RUN_RC=${PIPESTATUS[0]}
set -e
printf '%s\n' "$RUN_RC" > "$OUT/L2-run-exit-code.txt"
[[ "$RUN_RC" -eq 0 ]] || { echo "FATAL: frozen L2 runner failed rc=$RUN_RC" >&2; exit "$RUN_RC"; }

RESULT="$RESULT_DIR/calibration_L2_result.json"
CUSTODY="$RESULT_DIR/custody_manifest.json"
[[ -f "$RESULT" && -f "$CUSTODY" ]] || { echo "FATAL: frozen L2 result/custody output missing" >&2; exit 30; }

# Post-audit only: map frozen language decision onto the authorized next gate.
python - "$RESULT" "$CUSTODY" "$RESULT_DIR" "$OUT/endpoint.json" <<'PY'
import hashlib, json, pathlib, sys
rp,cp,rd,op=map(pathlib.Path,sys.argv[1:]); x=json.loads(rp.read_text()); c=json.loads(cp.read_text())
L1='b111d63df0aa14e4fa6495b4fd9b4f285a295d554f9e43a6c9ec54c41a251bf7'
if x.get('schema')!='XM-CRCB-001-CALIBRATION-APPARATUS-v1' or x.get('kind')!='real_calibration_language_result': raise SystemExit('FATAL: result schema/kind mismatch')
if x.get('source_scientific_sha')!='be7cefd60cf199e9fbabd6110be1254a1756590e' or x.get('cc_protocol_commit')!='4d0e87613ef1b894d6ebac2400e358a9fd82e5ae': raise SystemExit('FATAL: result provenance mismatch')
if x.get('language')!='L2': raise SystemExit('FATAL: non-L2 result')
pri=x.get('prior_results',[])
if len(pri)!=1 or pri[0].get('file')!='calibration_L1_result.json' or pri[0].get('sha256')!=L1 or pri[0].get('classification')!='LANGUAGE_FAIL': raise SystemExit('FATAL: L2 predecessor binding mismatch')
for k,v in {'science_reserved_semantic_access':False,'factorization_constructed':False,'authority_metrics_read':False,'calibration_only':True}.items():
    if x.get(k)!=v: raise SystemExit(f'FATAL: result firewall mismatch {k}')
bases=x.get('base_results',[])
if [b.get('base_seed') for b in bases] != [606,707]: raise SystemExit('FATAL: base result identity/order mismatch')
for b in bases:
    w=b.get('whitelist',{})
    if w.get('language')!='L2' or w.get('label')!='full_final_layer': raise SystemExit('FATAL: whitelist language mismatch')
    names=w.get('names',[])
    if not names or any(not n.startswith('diffusion_transformer.final_layer.') for n in names): raise SystemExit('FATAL: parameter outside full final_layer whitelist')
    if not any('.adaLN_modulation.' in n for n in names): raise SystemExit('FATAL: L2 whitelist collapsed to L1-like subset')
    if not b.get('null_audit',{}).get('delta_exact_zero',False): raise SystemExit('FATAL: null delta not exact zero')
rows=[]
for b in bases:
    groups=b.get('groups',[])
    if sorted(g.get('target_region') for g in groups)!=[0,5,10,15]: raise SystemExit('FATAL: calibration targets mismatch')
    for g in groups:
        reps=g.get('replicates',[])
        if sorted(r.get('repair_seed') for r in reps)!=[1101,1102,1103]: raise SystemExit('FATAL: repair seeds mismatch')
        if any(r.get('language')!='L2' for r in reps): raise SystemExit('FATAL: non-L2 replicate')
        rows.extend(reps)
if len(rows)!=24: raise SystemExit(f'FATAL: expected 24 repairs, got {len(rows)}')
for r in rows:
    tp=rd/r['trace_file']
    if not tp.is_file(): raise SystemExit(f'FATAL: missing trace {tp.name}')
    tr=json.loads(tp.read_text())
    if len(tr)!=32 or [z.get('step') for z in tr]!=list(range(32)): raise SystemExit(f'FATAL: trace step contract failed {tp.name}')
    used={int(i) for z in tr for i in z.get('construct_indices',[])}
    if not used.issubset(set(range(64))): raise SystemExit(f'FATAL: construction index outside 0:63 in {tp.name}')
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for q in iter(lambda:f.read(1<<20),b''): h.update(q)
    return h.hexdigest()
if c.get('result',{}).get('file')!=rp.name or c.get('result',{}).get('sha256')!=sha(rp): raise SystemExit('FATAL: result custody mismatch')
for a in c.get('artifacts',[]):
    p=rd/a['file']
    if not p.is_file() or p.stat().st_size!=a['bytes'] or sha(p)!=a['sha256']: raise SystemExit(f"FATAL: artifact custody mismatch {a['file']}")
d=x.get('decision',{}); null_ok=bool(d.get('null_audit_pass')) and all(bool(b.get('null_audit',{}).get('null_audit_pass')) for b in bases); custody_ok=bool(d.get('custody_pass')); classification=d.get('classification')
if not null_ok or not custody_ok:
    endpoint='CALIBRATION_APPARATUS_FAILURE'; l3=False; la=None
elif classification=='LANGUAGE_PASS':
    endpoint='L2_CALIBRATION_PASS'; l3=False; la='L2'
elif classification=='LANGUAGE_FAIL':
    endpoint='L2_CALIBRATION_FAIL'; l3=True; la=None
else: raise SystemExit(f'FATAL: unknown frozen classification {classification!r}')
out={'kind':'XM-CRCB-001-L2-orchestration-endpoint-v1','endpoint':endpoint,'frozen_language_classification':classification,'L_A_star':la,'L3_authorized':l3,'factorization_authorized':False,'science_authorized':False,'claim_ceiling':'L2 calibration adequacy != H_CRCB evidence != factorization result','L1_predecessor_sha256':L1,'result_sha256':sha(rp),'custody_manifest_sha256':sha(cp)}
op.write_text(json.dumps(out,sort_keys=True,indent=2)+'\n')
print(json.dumps(out,sort_keys=True)); print(endpoint)
if endpoint=='L2_CALIBRATION_PASS': print('L_A_STAR L2; L3_FORBIDDEN')
elif endpoint=='L2_CALIBRATION_FAIL': print('L3_AUTHORIZED')
else: print('NO_LANGUAGE_ESCALATION_AUTHORIZED')
PY

# Package only L2 outputs/provenance, never giant base checkpoints or predecessor artifacts.
sha256sum "$RESULT" "$CUSTODY" "$OUT/endpoint.json" "$OUT/L2-run.log" "$OUT/apparatus-preflight.txt" > "$OUT/L2-orchestration-custody.sha256"
STAGE="$ROOT/result_stage"; mkdir -p "$STAGE"
cp -a "$RESULT_DIR" "$STAGE/"
cp "$OUT/endpoint.json" "$STAGE/"; cp "$OUT/L2-run-exit-code.txt" "$STAGE/"; cp "$OUT/L2-orchestration-custody.sha256" "$STAGE/"; cp "$OUT/apparatus-preflight.txt" "$STAGE/"; cp "$OUT/orchestration.log" "$STAGE/"
printf '%s\n' "$APPARATUS_FREEZE_SHA" > "$STAGE/apparatus-freeze-sha.txt"
printf '%s\n' "$ARCHIVE_606_SHA" > "$STAGE/base606-archive-sha256.txt"
printf '%s\n' "$ARCHIVE_707_SHA" > "$STAGE/base707-archive-sha256.txt"
printf '%s\n' "$L1_RESULT_SHA" > "$STAGE/L1-predecessor-result-sha256.txt"
printf '%s\n' "$L1_RESULT_ARCHIVE_SHA" > "$STAGE/L1-predecessor-archive-sha256.txt"

tar -C "$STAGE" -czf "$BUNDLE" .
sha256sum "$BUNDLE" | tee "$OUT/L2-result-archive.sha256"
echo "L2_RESULT_ARCHIVE $BUNDLE"
echo "XM_CRCB_001_L2_ORCHESTRATION_COMPLETE"
