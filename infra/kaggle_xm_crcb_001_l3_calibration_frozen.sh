#!/usr/bin/env bash
set -Eeuo pipefail
# XM-CRCB-001 final calibration rung. Infrastructure only; frozen science remains b8caf8ff...
APP=b8caf8ffcc0a3bbd4fabfbc610b0767293e11aff
SRC=be7cefd60cf199e9fbabd6110be1254a1756590e
CC=4d0e87613ef1b894d6ebac2400e358a9fd82e5ae
ENTRY=7c8c6feeadeed3aff0ad9eb071914037eaea2fb8
CORE=e82965c7ef33256cd26c08debc32d3cf1ee767d9
RUNNER=5198d56b57f108c6791159c28df84ce4569747b3
A606_SHA=e40ffb5b9e6874f539e5581d115ffdbc6f79f65f03c59899cd7a1b5223199a6a
A707_SHA=f8968bfbc8d87d37fbb3bd284f523b87caa6a0b9ddad045b245151613ba5d462
M606_SHA=ed52af08ea165dd488e019b81da2fd67dd2361e8aff8348323599180795d5045
M707_SHA=14690fe63cab93b77b211282d91b0e9a1d2f7fb20e88b9ab73ac836b207c4481
C606_SHA=e0f8f4ae377255f3592aa2c0046e9bbefd91cdf4798d8b05ef9e223dd81a59b2
C707_SHA=a47641d076ac9ccec6e69041c03126ddc81c81e8264b0231840b3dbbc921504b
VAL_SHA=f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99
L1_SHA=b111d63df0aa14e4fa6495b4fd9b4f285a295d554f9e43a6c9ec54c41a251bf7
L1C_SHA=2cdc66502079012ea8fd6d5c81c5dbb0032e12284f240fd938391adc82f952f7
L1A_SHA=e5ff8f9cd7d6ffa7d3f6b906e7ea83ce06e3d0bf8f0b7182b808557ae0710fb2
L2_SHA=73579a4a5fad030b4f893b64e52fc0ab74a75cca959b133febd218835d43a16f
L2C_SHA=8c8d2086ed9a2762d573650042ff8ba6e229cd2a02c54588fd61c76509f6b1f4
L2A_SHA=70f65a9a377a767768cac11934b09b7e18eecdae634e75e8369f3248650f402a
A606=${1:-}; A707=${2:-}; L1A=${3:-}; L2A=${4:-}
[[ -n "$A606" && -n "$A707" && -n "$L1A" && -n "$L2A" ]] || { echo "usage: $0 <606.tar.gz> <707.tar.gz> <L1.tar.gz> <L2.tar.gz>" >&2; exit 2; }
for p in "$A606" "$A707" "$L1A" "$L2A"; do [[ -f "$p" ]] || { echo "FATAL missing $p" >&2; exit 3; }; done
ROOT=/kaggle/working/xm_crcb_001_l3_calibration; OUT=$ROOT/output; REPO=$ROOT/xm-oc; BUNDLE=/kaggle/working/xm_crcb_001_L3_calibration_result.tar.gz
rm -rf "$ROOT"; rm -f "$BUNDLE"; mkdir -p "$ROOT"/{b606,b707,p1,p2,output}; exec > >(tee "$OUT/orchestration.log") 2>&1
sha(){ sha256sum "$1"|awk '{print $1}'; }; ck(){ [[ "$(sha "$1")" == "$2" ]] || { echo "FATAL SHA $3" >&2; exit 10; }; echo "SHA_PASS $3 $2"; }
echo '=== XM-CRCB-001 L3-ONLY CALIBRATION ==='; echo "apparatus_freeze=$APP"; echo "language=L3"; echo "L1=$L1_SHA"; echo "L2=$L2_SHA"; echo 'No factorization/parity/science object may be constructed.'
ck "$A606" "$A606_SHA" base606_archive; ck "$A707" "$A707_SHA" base707_archive; ck "$L1A" "$L1A_SHA" L1_result_archive; ck "$L2A" "$L2A_SHA" L2_result_archive
python - "$A606" "$A707" "$L1A" "$L2A" <<'PY'
import os,pathlib,sys,tarfile
items=[(sys.argv[1],'base_seed606'),(sys.argv[2],'base_seed707'),(sys.argv[3],'L1'),(sys.argv[4],'L2')]; total=0
for f,root in items:
 with tarfile.open(f,'r:gz') as t:
  ms=t.getmembers(); assert ms
  for m in ms:
   p=pathlib.PurePosixPath(m.name); q=[x for x in p.parts if x not in ('','.')]
   if p.is_absolute() or '..' in q or m.issym() or m.islnk() or m.isdev(): raise SystemExit('FATAL unsafe archive member '+m.name)
   if root.startswith('base_') and q and q[0]!=root: raise SystemExit('FATAL bad base root '+m.name)
   if m.isfile() and root.startswith('base_'): total+=m.size
free=os.statvfs('/kaggle/working').f_bavail*os.statvfs('/kaggle/working').f_frsize; need=total+4*(1<<30)
print('ARCHIVE_STRUCTURE_PASS'); print('storage_free_bytes',free); print('base_unpacked_bytes',total); print('storage_required_with_headroom',need)
if free<need: raise SystemExit('CALIBRATION_INFRASTRUCTURE_STORAGE_FAILURE')
PY
echo L3_STORAGE_PREFLIGHT_PASS
tar -xzf "$A606" -C "$ROOT/b606"; tar -xzf "$A707" -C "$ROOT/b707"; tar -xzf "$L1A" -C "$ROOT/p1"; tar -xzf "$L2A" -C "$ROOT/p2"
B606=$ROOT/b606/base_seed606; B707=$ROOT/b707/base_seed707; L1=$ROOT/p1/L1/calibration_L1_result.json; L1C=$ROOT/p1/L1/custody_manifest.json; E1=$ROOT/p1/endpoint.json; L2=$ROOT/p2/L2/calibration_L2_result.json; L2C=$ROOT/p2/L2/custody_manifest.json; E2=$ROOT/p2/endpoint.json
(cd "$B606" && sha256sum -c base-custody.sha256); (cd "$B707" && sha256sum -c base-custody.sha256)
M606=$B606/base_manifest_seed606.json; M707=$B707/base_manifest_seed707.json; C606=$B606/last.ckpt; C707=$B707/last.ckpt; V606=$B606/imagenet_val_256x256_vae.part_00000.safetensors; V707=$B707/imagenet_val_256x256_vae.part_00000.safetensors
ck "$M606" "$M606_SHA" base606_manifest; ck "$M707" "$M707_SHA" base707_manifest; ck "$C606" "$C606_SHA" base606_checkpoint; ck "$C707" "$C707_SHA" base707_checkpoint; ck "$V606" "$VAL_SHA" base606_val_cache; ck "$V707" "$VAL_SHA" base707_val_cache; ck "$L1" "$L1_SHA" L1_result; ck "$L1C" "$L1C_SHA" L1_custody; ck "$L2" "$L2_SHA" L2_result; ck "$L2C" "$L2C_SHA" L2_custody; cmp -s "$V606" "$V707"
python - "$M606" "$M707" "$L1" "$L1C" "$E1" "$ROOT/p1/L1" "$L2" "$L2C" "$E2" "$ROOT/p2/L2" <<'PY'
import hashlib,json,pathlib,sys
L1='b111d63df0aa14e4fa6495b4fd9b4f285a295d554f9e43a6c9ec54c41a251bf7'; L2='73579a4a5fad030b4f893b64e52fc0ab74a75cca959b133febd218835d43a16f'
def sh(p):
 h=hashlib.sha256()
 with pathlib.Path(p).open('rb') as f:
  for b in iter(lambda:f.read(1<<20),b''): h.update(b)
 return h.hexdigest()
for seed,p in zip((606,707),sys.argv[1:3]):
 x=json.load(open(p)); req={'kind':'XM-CRCB-001-calibration-base','source_scientific_sha':'be7cefd60cf199e9fbabd6110be1254a1756590e','base_seed':seed,'k_train':2,'optimizer_steps':2049,'batch_size':8,'custody_valid':True}
 for k,v in req.items():
  if x.get(k)!=v: raise SystemExit(f'FATAL base{seed} {k}')
 for k in ('repair_language_evaluated','repair_language_adequacy_known','calibration_result_opened','factorization_constructed','parity_split_constructed','science_seed_materialized','science_context_evaluated','science_rng_materialized'):
  if x.get(k) is not False: raise SystemExit(f'FATAL base firewall {seed} {k}')
def pred(r,c,e,d,lang,exp,pri,endpoint):
 r,c,e,d=map(pathlib.Path,(r,c,e,d)); x=json.loads(r.read_text()); cm=json.loads(c.read_text()); ep=json.loads(e.read_text())
 if sh(r)!=exp or x.get('language')!=lang or x.get('decision',{}).get('classification')!='LANGUAGE_FAIL': raise SystemExit('FATAL predecessor '+lang)
 got=x.get('prior_results',[])
 if [(z.get('language',z.get('file')),z.get('sha256'),z.get('classification')) for z in got] != pri: raise SystemExit('FATAL predecessor chain '+lang)
 if cm.get('result',{}).get('sha256')!=exp: raise SystemExit('FATAL predecessor custody '+lang)
 for a in cm.get('artifacts',[]):
  p=d/a['file']
  if not p.is_file() or p.stat().st_size!=a['bytes'] or sh(p)!=a['sha256']: raise SystemExit('FATAL predecessor artifact '+lang)
 if ep.get('endpoint')!=endpoint or ep.get('result_sha256')!=exp: raise SystemExit('FATAL predecessor endpoint '+lang)
pred(sys.argv[3],sys.argv[4],sys.argv[5],sys.argv[6],'L1',L1,[],'L1_CALIBRATION_FAIL')
pred(sys.argv[7],sys.argv[8],sys.argv[9],sys.argv[10],'L2',L2,[('calibration_L1_result.json',L1,'LANGUAGE_FAIL')],'L2_CALIBRATION_FAIL')
print('IMMUTABLE_L1_L2_PREDECESSOR_CHAIN_PASS')
PY
python -m pip install -q --upgrade pip setuptools wheel
python -m pip install -q --no-cache-dir torch==2.4.0 torchvision==0.19.0 --index-url https://download.pytorch.org/whl/cu121
git clone -q https://github.com/bjoern-janson/xm-oc.git "$REPO"; git -C "$REPO" checkout -q --detach "$APP"; [[ "$(git -C "$REPO" rev-parse HEAD)" == "$APP" ]]
[[ "$(git -C "$REPO" rev-parse "$APP:experiments/xm_crcb_001_calibration.py")" == "$ENTRY" ]]; [[ "$(git -C "$REPO" rev-parse "$APP:experiments/xm_crcb_001/core.py")" == "$CORE" ]]; [[ "$(git -C "$REPO" rev-parse "$APP:experiments/xm_crcb_001/real_runner.py")" == "$RUNNER" ]]
cd "$REPO"; python -m pip install -q --no-cache-dir -r requirements.txt; export USE_TORCH=1 USE_TF=0 TRANSFORMERS_NO_TF=1 HF_HOME="$ROOT/hf_cache" HF_HUB_DISABLE_TELEMETRY=1 PYTHONPATH="$REPO:$REPO/experiments${PYTHONPATH:+:$PYTHONPATH}" WANDB_MODE=offline WANDB_SILENT=true XM_AUTHORITY_OBS=0
unset XM_AUTHORITY_REGION_BITS XM_AUTHORITY_REGION_SEED XM_AUTHORITY_HOLDOUT_SEED XM_AUTHORITY_HOLDOUT_EXAMPLES XM_AUTHORITY_HOLDOUT_EVERY_N_VAL_STEPS XM_AUTHORITY_OBS_DIR || true
python - <<'PY' | tee "$OUT/apparatus-preflight.txt"
import torch
from experiments.xm_crcb_001 import core
assert torch.cuda.is_available(); core.verify_coords(); assert core.LANGUAGE_LABELS['L3']=='final_transformer_block_plus_final_layer'; assert core.CAL_REPAIR_SEEDS==(1101,1102,1103); assert core.CONSTRUCT==tuple(range(64)); assert core.EVAL==tuple(range(64,128)); assert core.SCIENCE_RESERVED==tuple(range(128,256)); assert core.J==32 and core.BATCH==8 and core.LR==1e-4 and core.BETAS==(0.9,0.95) and core.WD==0.0 and core.CLIP==1.0
print('L3_FROZEN_APPARATUS_PREFLIGHT_PASS'); print('cuda_device',torch.cuda.get_device_name(0))
PY
set +e; cd "$REPO/experiments"; python xm_crcb_001_calibration.py run-language --language L3 --checkpoint-606 "$C606" --checkpoint-707 "$C707" --base-manifest-606 "$M606" --base-manifest-707 "$M707" --val-cache-part "$V606" --prior-result "$L1" --prior-result "$L2" --out "$OUT/L3" 2>&1 | tee "$OUT/L3-run.log"; RC=${PIPESTATUS[0]}; set -e; printf '%s\n' "$RC" > "$OUT/L3-run-exit-code.txt"; [[ "$RC" -eq 0 ]] || exit "$RC"
R=$OUT/L3/calibration_L3_result.json; C=$OUT/L3/custody_manifest.json; [[ -f "$R" && -f "$C" ]]
python - "$R" "$C" "$OUT/L3" "$OUT/endpoint.json" <<'PY'
import hashlib,json,pathlib,re,sys
r,c,d,o=map(pathlib.Path,sys.argv[1:]); x=json.loads(r.read_text()); cm=json.loads(c.read_text()); L1='b111d63df0aa14e4fa6495b4fd9b4f285a295d554f9e43a6c9ec54c41a251bf7'; L2='73579a4a5fad030b4f893b64e52fc0ab74a75cca959b133febd218835d43a16f'
def sh(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1<<20),b''): h.update(b)
 return h.hexdigest()
if x.get('language')!='L3' or [(z.get('file'),z.get('sha256'),z.get('classification')) for z in x.get('prior_results',[])]!=[('calibration_L1_result.json',L1,'LANGUAGE_FAIL'),('calibration_L2_result.json',L2,'LANGUAGE_FAIL')]: raise SystemExit('FATAL L3 provenance')
for k,v in {'science_reserved_semantic_access':False,'factorization_constructed':False,'authority_metrics_read':False,'calibration_only':True}.items():
 if x.get(k)!=v: raise SystemExit('FATAL firewall '+k)
rows=[]
for b in x.get('base_results',[]):
 w=b.get('whitelist',{}); ns=w.get('names',[]); ids={int(m.group(1)) for n in ns for m in [re.match(r'diffusion_transformer\.blocks\.(\d+)\.',n)] if m}
 if w.get('language')!='L3' or w.get('label')!='final_transformer_block_plus_final_layer' or len(ids)!=1 or not any(n.startswith('diffusion_transformer.final_layer.') for n in ns) or any(not(n.startswith('diffusion_transformer.final_layer.') or n.startswith('diffusion_transformer.blocks.')) for n in ns): raise SystemExit('FATAL L3 whitelist')
 if not b.get('null_audit',{}).get('delta_exact_zero',False): raise SystemExit('FATAL null')
 for g in b.get('groups',[]): rows+=g.get('replicates',[])
if len(rows)!=24: raise SystemExit('FATAL replicate count')
for z in rows:
 t=json.loads((d/z['trace_file']).read_text())
 if len(t)!=32 or not {int(i) for q in t for i in q.get('construct_indices',[])}.issubset(set(range(64))): raise SystemExit('FATAL trace')
if cm.get('result',{}).get('sha256')!=sh(r): raise SystemExit('FATAL result custody')
for a in cm.get('artifacts',[]):
 p=d/a['file']
 if not p.is_file() or p.stat().st_size!=a['bytes'] or sh(p)!=a['sha256']: raise SystemExit('FATAL artifact custody')
dec=x.get('decision',{}); null=bool(dec.get('null_audit_pass')) and all(bool(b.get('null_audit',{}).get('null_audit_pass')) for b in x.get('base_results',[])); custody=bool(dec.get('custody_pass')); cl=dec.get('classification')
if not null or not custody: ep='CALIBRATION_APPARATUS_FAILURE'; la=None; closed=False; insuff=False; prep=False
elif cl=='LANGUAGE_PASS': ep='L3_CALIBRATION_PASS'; la='L3'; closed=True; insuff=False; prep=True
elif cl=='LANGUAGE_FAIL': ep='REPAIR_LANGUAGE_INSUFFICIENT'; la=None; closed=True; insuff=True; prep=False
else: raise SystemExit('FATAL classification')
out={'kind':'XM-CRCB-001-L3-orchestration-endpoint-v1','endpoint':ep,'frozen_language_classification':cl,'L_A_star':la,'calibration_closed':closed,'repair_language_insufficient':insuff,'factorization_protocol_preparation_authorized':prep,'factorization_execution_authorized':False,'science_authorized':False,'L1_predecessor_sha256':L1,'L2_predecessor_sha256':L2,'result_sha256':sh(r),'custody_manifest_sha256':sh(c)}; o.write_text(json.dumps(out,sort_keys=True,indent=2)+'\n'); print(json.dumps(out,sort_keys=True)); print(ep)
if ep=='L3_CALIBRATION_PASS': print('L_A_STAR L3; CALIBRATION_CLOSED; FACTORIZATION_PROTOCOL_PREPARATION_AUTHORIZED; FACTORIZATION_EXECUTION_FORBIDDEN')
elif ep=='REPAIR_LANGUAGE_INSUFFICIENT': print('CALIBRATION_CLOSED; FACTORIZATION_FORBIDDEN')
else: print('NO_SCIENTIFIC_UPDATE')
PY
sha256sum "$R" "$C" "$OUT/endpoint.json" "$OUT/L3-run.log" "$OUT/apparatus-preflight.txt" > "$OUT/L3-orchestration-custody.sha256"
S=$ROOT/result_stage; mkdir -p "$S"; cp -a "$OUT/L3" "$S/"; cp "$OUT"/{endpoint.json,L3-run-exit-code.txt,L3-orchestration-custody.sha256,apparatus-preflight.txt,orchestration.log} "$S/"; printf '%s\n' "$L1_SHA" > "$S/L1-predecessor-result-sha256.txt"; printf '%s\n' "$L2_SHA" > "$S/L2-predecessor-result-sha256.txt"; tar -C "$S" -czf "$BUNDLE" .; sha256sum "$BUNDLE" | tee "$OUT/L3-result-archive.sha256"; echo "L3_RESULT_ARCHIVE $BUNDLE"; echo XM_CRCB_001_L3_ORCHESTRATION_COMPLETE
