# REAL-XM-AUTHORITY-001 — high-K replication v2 incomplete execution

Status: **RECORDED EXECUTION INTERRUPTION / SCIENTIFICALLY UNRESOLVED**.

Frozen scientific/apparatus SHA: `be7cefd60cf199e9fbabd6110be1254a1756590e`.

Recovered execution bundle: `30cacad1aa73b5b860f5057b5e1bb8b75b4b000f`.

Frozen v2 launcher: `1059bd8e3d307b7718e8f82b9b3057c851e14947`.

## Classification

`REPLICATION_V2_INCOMPLETE`

The v2 campaign completed and audited 14 of the 15 preregistered `(seed,K)` members. The only missing member is `(seed=505,K=12)`.

The console log ended abruptly during epoch-0 validation of `(505,12)`, after the member had started with the correct injected seed and checkpoint writes disabled. No Python traceback, shell `FATAL:` marker, model/observer assertion, or scientific completion marker was present. Therefore the interruption cause is explicitly **unknown at the available evidence level**.

This is not a model failure and not a scientific negative. No confirmatory endpoint is opened from the four complete seed blocks.

## Completed member custody hashes

The following SHA-256 values were printed by the frozen v2 launcher after each successful member audit and are the prospective custody anchors for recovery.

| seed | K | observer JSONL | train log | member audit |
|---:|---:|---|---|---|
| 101 | 2 | `28d54b0f7c05fba735e9f4822565db0acd7854accba3af398b5fe9766fc42c95` | `b2303eb7b323049f5aaa64eb38fc823329ab0239f8dfec35c75aabe237ca471e` | `f1b33d8e574cfd7130aa735acc72f649543b6359727ea27489c1bb4e6b1e6334` |
| 101 | 8 | `2af98d00df72f3396fd337755a8aaba1d24fbdca0dcaf19cfee6c1191444b1af` | `98c0a59f6e4964ac25ba8729db8580efc4f29caaebdab56457a387fba68a05aa` | `85eba7114bf8d6b1c1afb73e919fa390f83236880a119dab01cabd465be87b6a` |
| 101 | 12 | `6305f1be7757a0f2663c01ffa60b3576c476e7fd8cf66f6f01cbc841870803cb` | `99771007fc5d05ef1d1febb8b53ca9b7e20c1c5fa05ceab91d28344a152b9055` | `5cadb0435a51fe8e99ee012ef51254002378b8c945fbfc1f12628114e34abfc8` |
| 202 | 2 | `acf4eac1438005a8a5a9e2224d42042368114da6bf8b80df8c6b2c713fa0ab23` | `f77095f8ed3fdfd7374199d89818445990e057b3cd021b656242735e73ee1a9d` | `4c7131f3ee8604e20eaa0d6a59083a29ff26279e8af897e5ae5f50fb2dba42a7` |
| 202 | 8 | `e5f08a6acca2dca549e1e3a81e731015f27b1231dbb00b47a2b3bd9b35695f7f` | `e81f9fc9586e66e7bf6b6acf9def85c7c8e3e4ed12228072a02294daea5a27eb` | `7a5660723968737c621979951ad332633b844766daf96f5c20370c4e621c5cf7` |
| 202 | 12 | `75822a7d58edff75627a3b9d599bd273e7e03c52ba3c2b71620be4b8f2e2e4b7` | `10787fc3d9190b040533abdcbdedbf758947ab4c91d68627629143709d0aea59` | `836b89d80d2b3bcba1420fe5697f78890bdc651ea3df7b91f56e59407f667b0f` |
| 303 | 2 | `30abb32cc300eb3ded56cd9d746ca3af44d001e75b3e5e376e97465f3595c9ee` | `4331ddd8d1f22f4598882610c959ccfcdde824d9b8968883f2201328f1d21831` | `e33a1531408a3db315385f467e5d8a3403cbbbaaded0531a1f3e9abdbd575e90` |
| 303 | 8 | `5a609cc92791093b39061abe48a2f5c1fbae01b35a6f062ce4adbf9e825454e5` | `ece1ca3c110ddb515233d7ebf817447201d2ec6573b0896805b245d77b3fefaf` | `65d46c087e768ec3a485b1742d21982e5bc855ab38226c84252cd2b1c2ee3034` |
| 303 | 12 | `9c13c933a2daeed6dcc9b1bf5a705a9522fb01e7f2b0dd235941fda4314d1872` | `5f347fef03f1ebc7fa692f21aa5a134b108027e985e9e4a95d8aecf4522002ed` | `fe37993f8d3508c0bba386833246f37dd086bc27fd7c4b6e2032b74f72d62eda` |
| 404 | 2 | `f35ad2796775255cb6499e09b845a9691486ae4cf5f80aa148e0056818f5e97c` | `5a571cdb96e3c570db804bda12977173d64f7febd3f7afde503775949f1fbfa3` | `378d3f0e5647292b22946eba9cea2fb791804cdd8468d708792e9e623d03e1f2` |
| 404 | 8 | `5c702595c378d955982ca07e2ea6c9a04f6c0c71e3e4a6a1dbeef52c9b92e0f3` | `57d24b931c3067ef5c41c6c96952b9b205e967bd4efe092b27505632b89a390f` | `df4004ba25944543d742c0bbb75c58405890ff5518f3e63ac89cbd713695817a` |
| 404 | 12 | `b84b1d0baed51d03f1a41a605b2f73a85ecce9d0b771e339c165c40d176ae0a7` | `4d3f6559794d1f035741acca7781a2e737059eb626ad9524c0a6c092b66a36d0` | `31fd3cc104f0f9c2d444bf4cfa24cd0577a7e30d52d053b870666bd0f10798bd` |
| 505 | 2 | `4c0e25eb596363d703e55c91404ce890071eb25679edc2011621d11e5f579504` | `65bb11a794899e6707e938e6e0ba34d1d954b035929263b31c12828584fe70f5` | `fe7694ed16300730182826309cf68efc8a65da2c6f0ac1baa73af68bba9a4312` |
| 505 | 8 | `0e78eba72e98557f846247fa7ee14f031732012f3b9ce2b5f9e5ff3bcf54923e` | `43db484ef7de892b62c17f3ffc5004313fb3a477a3e68f4bba183ccdc9a29555` | `4031c47a682b985de4bffd7e22987807ca96c599a01ac72a7f765ece557bda64` |

## Recovery rule

The only admissible minimal recovery is:

1. verify all 14 completed members byte-for-byte against the hashes above and rerun their structural audits;
2. verify the frozen checkout, execution-bundle files, and matched latent-cache hashes;
3. preserve a hash/count record of the incomplete `(505,12)` attempt if it exists, then remove only that incomplete member directory;
4. execute only `(505,12)` from scratch under the unchanged v2 protocol;
5. audit member 15;
6. invoke the already-frozen summarizer exactly once over all five seed blocks.

If any of the 14 completed member artifacts is missing or hash-mismatched, minimal recovery is forbidden and the clean fallback is a complete fresh 15-member campaign using the frozen v2 launcher.

Until all five seed blocks are complete, the confirmatory quantity remains unopened:

`Delta_s^(12-2) = Z_late(12,s) - Z_late(2,s)` for `s in {101,202,303,404,505}`.

Claim ceiling remains association replication only; no causal direction and no Q_gen claim.
