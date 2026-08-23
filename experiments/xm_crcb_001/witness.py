from __future__ import annotations
import copy, json
from pathlib import Path
import torch
from torch import nn
from .core import *

class Final(nn.Module):
    def __init__(self,h=16,d=4096): super().__init__(); self.adaLN_modulation=nn.Sequential(nn.SiLU(),nn.Linear(h,2*h)); self.linear=nn.Linear(h,d)
    def forward(self,x,c): s,a=self.adaLN_modulation(c).chunk(2,-1); return self.linear(x*(1+.05*a)+.05*s)
class Transformer(nn.Module):
    def __init__(self): super().__init__(); self.input_proj=nn.Linear(4096,16); self.blocks=nn.ModuleList([nn.Linear(16,16),nn.Linear(16,16)]); self.final_layer=Final()
    def forward(self,x,t,y):
        h=torch.tanh(self.input_proj(x.flatten(1))); c=y+t[:,None]*.01
        for b in self.blocks: h=torch.tanh(b(h))
        return self.final_layer(h,c).reshape_as(x)
class Flow:
    def training_losses(self,f,x,t,model_kwargs=None,noise=None,reduce_loss=True):
        if noise is None: raise AssertionError('implicit RNG forbidden')
        xt=(1-t[:,None,None,None])*noise+t[:,None,None,None]*x; u=x-noise; y=model_kwargs['y']; per=(f(xt,t,y=y,learning=False)-u).flatten(1).pow(2).mean(1); return {'loss':per.mean() if reduce_loss else per}
class Model(nn.Module):
    def __init__(self):
        super().__init__()
        with torch.random.fork_rng(devices=[]): torch.manual_seed(4242001); self.diffusion_transformer=Transformer(); self.label_embedder=nn.Embedding(8,16)
        self.diffusion=Flow()
    def forward(self,x,t,y=None,learning=False,**kw): return self.diffusion_transformer(x,t,self.label_embedder(y))
class Data:
    def __init__(self): g=gen(999001); self.x=torch.randn((256,1,64,64),generator=g); self.y=torch.arange(256)%8; self.access=[]
    def take(self,ii): self.access += list(map(int,ii)); j=torch.tensor(ii); return self.x[j].clone(),self.y[j].clone()
def fl(m,x,y,t,z,grad):
    with (torch.enable_grad() if grad else torch.no_grad()): return m.diffusion.training_losses(m.forward,x,t,model_kwargs={'y':y,'learning':False},noise=z,reduce_loss=False)['loss']
def stop_fixture():
    f={'L1':'LANGUAGE_FAIL','L2':'LANGUAGE_PASS','L3':'MUST_NOT_RUN'}; attempted=[]; selected=None
    for l in LANGUAGES:
        if selected: break
        attempted.append(l)
        if f[l]=='LANGUAGE_PASS': selected=l
        elif f[l]!='LANGUAGE_FAIL': raise AssertionError('bad stop')
    if attempted!=['L1','L2'] or selected!='L2': raise AssertionError('stop-rule witness')
    return {'fixture':f,'attempted':attempted,'selected':selected,'pass':True}
def once():
    verify_coords(); rng0=torch.random.get_rng_state().clone(); ds=Data(); xc,yc=ds.take(CONSTRUCT); xe,ye=ds.take(EVAL)
    if max(ds.access)>=128: raise AssertionError('science-reserved access')
    base=Model(); wh={}; iso={}
    for l in LANGUAGES:
        m=copy.deepcopy(base); wa=whitelist(m,l); names=wa['names']; snap=snapshot(m,names); frozen=[n for n,_ in m.named_parameters() if n not in set(names)]; h0=param_hash(m,frozen); ps=[p for n,p in m.named_parameters() if n in set(names)]; op=torch.optim.AdamW(ps,lr=1e-4,betas=(.9,.95),eps=1e-8,weight_decay=0); x=xc[:8]; y=yc[:8]; ns=seed(1101,'witness-noise',l); ts=seed(1101,'witness-time',l); z=noise(x.shape,5,ns,torch.device('cpu'),x.dtype); t=times(8,ts,torch.device('cpu')); op.zero_grad(set_to_none=True); loss=fl(m,x,y,t,z,True).mean(); loss.backward(); torch.nn.utils.clip_grad_norm_(ps,1.); op.step(); de=delta(m,snap); changed=not zero_delta(de); h1=param_hash(m,frozen)
        if not changed or h0!=h1: raise AssertionError(f'isolation {l}')
        wh[l]=wa; iso[l]={'selected_changed':changed,'frozen_before':h0,'frozen_after':h1,'frozen_unchanged':h0==h1,'noise_seed':ns,'time_seed':ts}
    m=copy.deepcopy(base); h0=param_hash(m); x=xe[:8]; y=ye[:8]; ns=seed(CAL_EVAL_SEED,'witness-null-noise',0); ts=seed(CAL_EVAL_SEED,'witness-null-time',0); z=noise(x.shape,0,ns,torch.device('cpu'),x.dtype); t=times(8,ts,torch.device('cpu')); null_a=fl(m,x,y,t,z,False); null_b=fl(m,x,y,t,z,False); h1=param_hash(m); null_equal=torch.equal(null_a,null_b); null=h0==h1 and null_equal
    if not null: raise AssertionError('null')
    rng_a=noise((2,1,64,64),10,seed(1101,'rng-A'),torch.device('cpu'),torch.float32); rng_b=noise((2,1,64,64),10,seed(1101,'rng-A'),torch.device('cpu'),torch.float32); rng_c=noise((2,1,64,64),10,seed(1101,'rng-B'),torch.device('cpu'),torch.float32); rng_replay=torch.equal(rng_a,rng_b); rng_distinct=not torch.equal(rng_a,rng_c); rngok=rng_replay and rng_distinct; globalok=torch.equal(rng0,torch.random.get_rng_state())
    if not rngok or not globalok: raise AssertionError('RNG isolation')
    return {'schema':SCHEMA,'kind':'synthetic_noop_witness','classification':'APPARATUS_READY','claim_ceiling':'witness pass != repair-language adequacy','source_scientific_sha':SOURCE_SHA,'cc_protocol_commit':CC_PROTOCOL,'validation_partition':{'construct':[0,63],'eval':[64,127],'max_semantic_index_accessed':max(ds.access),'science_reserved_access_count':sum(i>=128 for i in ds.access),'science_region_constructor_calls':0},'parameter_whitelist':wh,'parameter_isolation':iso,'null_path':{'delta_exact_zero':h0==h1,'repeat_eval_bitwise_equal':null_equal,'pass':null},'rng_isolation':{'same_domain_replay_equal':rng_replay,'different_domain_differs':rng_distinct,'global_torch_rng_unchanged':globalok,'pass':rngok and globalok},'synthetic_stop_rule':stop_fixture(),'factorization_constructed':False,'calibration_outcome_observed':False,'real_checkpoint_loaded':False,'real_cache_loaded':False,'authority_metrics_read':False}
def run(out):
    out=Path(out); out.mkdir(parents=True,exist_ok=False); a=once(); b=once()
    if cjson(a)!=cjson(b): raise AssertionError('witness not reproducible')
    r=dict(a); r['witness_rerun_bitwise_json_equal']=True; r['witness_payload_sha256']=sha_bytes(cjson(a)); rp=out/'witness_result.json'; rh=write_json(rp,r); mp=out/'witness_custody_manifest.json'; mh=write_json(mp,{'schema':SCHEMA,'kind':'witness_custody_manifest','result_file':rp.name,'result_sha256':rh,'result_bytes':rp.stat().st_size,'classification':'APPARATUS_READY','claim_ceiling':'witness pass != repair-language adequacy'}); print(json.dumps({'classification':'APPARATUS_READY','result_sha256':rh,'manifest_sha256':mh,'witness_payload_sha256':r['witness_payload_sha256']},sort_keys=True)); return 0
