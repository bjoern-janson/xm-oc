from __future__ import annotations
import json, os
from pathlib import Path
import torch
from safetensors import safe_open
from safetensors.torch import save_file
from .core import *

def load_cache(path):
    path=Path(path)
    with safe_open(str(path),framework='pt',device='cpu') as f:
        L=f.get_slice('latents'); Y=f.get_slice('labels'); sh=tuple(L.get_shape())
        if sh[0]!=256 or tuple(sh[1:])!=(4,32,32) or tuple(Y.get_shape())!=(256,): raise RuntimeError('unexpected validation cache')
        x=L[0:128].contiguous(); y=Y[0:128].contiguous().long()
    fh=sha_file(path)
    if fh!=EXPECTED_VAL_LATENT_SHA: raise RuntimeError(f'validation cache hash mismatch: {fh}')
    return x,y,{'file':path.name,'file_sha256':fh,'semantic_indices_loaded':[0,127],'science_reserved_semantic_access':False,'semantic_sha256':named_hash((('latents_0_127',x),('labels_0_127',y)))}
def load_model(ckpt):
    if os.environ.get('XM_AUTHORITY_OBS','0')=='1': raise RuntimeError('XM_AUTHORITY_OBS must be disabled for XM-CRCB-001 calibration')
    from model.model_utils import load_trained_pl_model
    m,h=load_trained_pl_model(str(ckpt),for_inference=True,return_pretrained_hparams=True)
    if next(m.parameters()).device.type!='cuda': raise RuntimeError('CUDA required')
    if h.get('diffusion_supervision_type')!='velocity' or int(h.get('xm_best_of_k'))!=2: raise RuntimeError('wrong base organism')
    m.eval(); return m,h
def losses(m,x,y,t,z,grad):
    with (torch.enable_grad() if grad else torch.no_grad()):
        return m.diffusion.training_losses(m.forward,x,t,model_kwargs={'y':y,'learning':False},noise=z,reduce_loss=False)['loss']
def eval_regions(m,x_cpu,y_cpu):
    d=next(m.parameters()).device; dt=next(m.diffusion_transformer.parameters()).dtype; out=[]
    for r in range(16):
        vals=[]; ns=seed(CAL_EVAL_SEED,'eval-noise',r); ts=seed(CAL_EVAL_SEED,'eval-time',r); zall=noise(x_cpu.shape,r,ns,d,dt); tall=times(len(x_cpu),ts,d)
        for lo in range(0,len(x_cpu),BATCH):
            x=x_cpu[lo:lo+BATCH].to(d,dtype=dt); y=y_cpu[lo:lo+BATCH].to(d); z=zall[lo:lo+BATCH]; t=tall[lo:lo+BATCH]; vals.append(losses(m,x,y,t,z,False).detach().cpu())
        out.append(float(torch.cat(vals).mean()))
    return out
def construct(m,x_cpu,y_cpu,lang,base_seed,target,repair_seed,out):
    wa=whitelist(m,lang); names=wa['names']; snap=snapshot(m,names); frozen=[n for n,_ in m.named_parameters() if n not in set(names)]; hf0=param_hash(m,frozen)
    params=[p for n,p in m.named_parameters() if n in set(names)]; opt=torch.optim.AdamW(params,lr=LR,betas=BETAS,eps=EPS,weight_decay=WD); d=next(m.parameters()).device; dt=next(m.diffusion_transformer.parameters()).dtype; tr=[]
    for cycle in range(4):
        ps=seed(repair_seed,'perm',base_seed,target,cycle); order=torch.randperm(64,generator=gen(ps)).tolist()
        for b in range(8):
            st=cycle*8+b; ii=order[b*8:(b+1)*8]; x=x_cpu[ii].to(d,dtype=dt); y=y_cpu[ii].to(d); ns=seed(repair_seed,'noise',base_seed,target,st); ts=seed(repair_seed,'time',base_seed,target,st); z=noise(x.shape,target,ns,d,x.dtype); t=times(8,ts,d)
            opt.zero_grad(set_to_none=True); loss=losses(m,x,y,t,z,True).mean(); loss.backward(); gn=float(torch.nn.utils.clip_grad_norm_(params,CLIP).cpu()); opt.step(); tr.append({'step':st,'cycle':cycle,'batch':b,'construct_indices':[int(i) for i in ii],'perm_seed':ps,'noise_seed':ns,'time_seed':ts,'loss':float(loss.detach().cpu()),'grad_norm_pre_clip':gn})
    de=delta(m,snap)
    if zero_delta(de) or param_hash(m,frozen)!=hf0: raise AssertionError('repair isolation failed')
    dp=Path(out)/f'delta_b{base_seed}_r{target:02d}_s{repair_seed}_{lang}.safetensors'; save_file({k:v.contiguous() for k,v in sorted(de.items())},str(dp)); tp=Path(out)/f'trace_b{base_seed}_r{target:02d}_s{repair_seed}_{lang}.json'; tsh=write_json(tp,tr)
    return {'base_seed':base_seed,'target_region':target,'repair_seed':repair_seed,'language':lang,'whitelist':wa,'delta_sha256':sha_file(dp),'delta_file':dp.name,'trace_sha256':tsh,'trace_file':tp.name,'frozen_parameter_sha256':hf0,'delta_exact_zero':False}
def null_audit(m,x,y,base):
    h0=param_hash(m); l=eval_regions(m,x,y); h1=param_hash(m); rel=[abs(a-b)/max(b,1e-12) for a,b in zip(l,base)]; return {'parameter_hash_before':h0,'parameter_hash_after':h1,'max_relative_loss_difference':max(rel),'null_audit_pass':h0==h1 and max(rel)<=1e-5,'delta_exact_zero':h0==h1}
def validate_base_manifest(path,base_seed,ckpt):
    x=json.loads(Path(path).read_text())
    req={'kind':'XM-CRCB-001-calibration-base','source_scientific_sha':SOURCE_SHA,'base_seed':base_seed,'k_train':2,'optimizer_steps':2049,'batch_size':8,'train_latent_sha256':EXPECTED_TRAIN_LATENT_SHA,'val_latent_sha256':EXPECTED_VAL_LATENT_SHA}
    for k,v in req.items():
        if x.get(k)!=v: raise RuntimeError(f'base manifest {path}: {k} mismatch')
    ch=sha_file(ckpt)
    if x.get('checkpoint_sha256')!=ch: raise RuntimeError(f'base manifest {path}: checkpoint hash mismatch')
    return x

def run_language(lang,ck606,ck707,manifest606,manifest707,cache,priors,out):
    torch.use_deterministic_algorithms(True); torch.backends.cudnn.benchmark=False; torch.backends.cudnn.deterministic=True
    verify_coords(); prior=validate_priors(lang,[Path(p) for p in priors]); out=Path(out); out.mkdir(parents=True,exist_ok=False); X,Y,cm=load_cache(cache); xc,yc=X[:64],Y[:64]; xe,ye=X[64:128],Y[64:128]; checkpoints={606:Path(ck606),707:Path(ck707)}; manifests={606:validate_base_manifest(manifest606,606,Path(ck606)),707:validate_base_manifest(manifest707,707,Path(ck707))}; groups=[]; bases=[]; nullok=True; artifacts=[]
    for bs in CAL_BASE_SEEDS:
        m,hp=load_model(checkpoints[bs]); wa=whitelist(m,lang); names=wa['names']; snap=snapshot(m,names); hbase=param_hash(m); base=eval_regions(m,xe,ye); nu=null_audit(m,xe,ye,base); nullok &= nu['null_audit_pass']; bg=[]
        for r in CAL_TARGETS:
            reps=[]
            for rs in CAL_REPAIR_SEEDS:
                restore(m,snap)
                if param_hash(m)!=hbase: raise AssertionError('base restore failed')
                row=construct(m,xc,yc,lang,bs,r,rs,out); rl=eval_regions(m,xe,ye); row.update(metrics(base,rl,r)); row['repaired_losses']=rl; reps.append(row); artifacts += [out/row['delta_file'],out/row['trace_file']]
            g=repeat(reps); g.update({'base_seed':bs,'target_region':r,'language':lang,'replicates':reps}); bg.append(g); groups.append(g)
        restore(m,snap)
        if param_hash(m)!=hbase: raise AssertionError('final base restore failed')
        bases.append({'base_seed':bs,'checkpoint_file':checkpoints[bs].name,'checkpoint_sha256':sha_file(checkpoints[bs]),'base_manifest_file':Path(manifest606 if bs==606 else manifest707).name,'base_manifest_sha256':sha_file(manifest606 if bs==606 else manifest707),'base_parameter_sha256':hbase,'whitelist':wa,'base_losses':base,'null_audit':nu,'groups':bg})
        del m; torch.cuda.empty_cache()
    custody=all(p.exists() and p.stat().st_size for p in artifacts); dec=decision(groups,nullok,custody); result={'schema':SCHEMA,'kind':'real_calibration_language_result','source_scientific_sha':SOURCE_SHA,'cc_protocol_commit':CC_PROTOCOL,'language':lang,'prior_results':[{'file':Path(p).name,'sha256':sha_file(p),'classification':x['decision']['classification']} for p,x in zip(priors,prior)],'cache':cm,'base_results':bases,'decision':dec,'science_reserved_semantic_access':False,'factorization_constructed':False,'authority_metrics_read':False,'calibration_only':True}; rp=out/f'calibration_{lang}_result.json'; rsh=write_json(rp,result); mp=out/'custody_manifest.json'; write_json(mp,{'result':{'file':rp.name,'sha256':rsh},'artifacts':[{'file':p.name,'sha256':sha_file(p),'bytes':p.stat().st_size} for p in sorted(artifacts)]}); print(json.dumps({'classification':dec['classification'],'language':lang,'result':str(rp),'sha256':rsh},sort_keys=True)); return 0
