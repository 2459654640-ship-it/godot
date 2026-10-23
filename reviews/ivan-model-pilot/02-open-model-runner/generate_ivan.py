"""Three-view Hunyuan3D-2mv entry point, adapted from the official examples.
The input/preflight path was tested here; GPU inference has NOT run here.
"""
from pathlib import Path
import argparse,gc,hashlib,importlib.util,json,platform,sys,time
from PIL import Image
import numpy as np


def references(folder):
    # The official example named 'left' faces image-left. Our profile faces
    # image-right, so its semantic key is 'right', not the example's 'left'.
    mapping={'front':'front.png','right':'side.png','back':'back.png'}
    images={};records=[]
    for view,name in mapping.items():
        path=folder/name
        if not path.is_file():raise ValueError(f'Missing input: {path}')
        image=Image.open(path)
        if image.mode!='RGBA':raise ValueError(f'{path.name}: use the transparent RGBA input set')
        alpha=np.asarray(image.getchannel('A'));yy,xx=np.where(alpha>100)
        if not len(yy) or np.mean(alpha<10)<.05:raise ValueError(f'{path.name}: missing isolated foreground/transparent background')
        images[view]=image
        records.append({'view':view,'file':name,'size':list(image.size),'foreground_height':int(yy.max()-yy.min()+1),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    if len({tuple(v['size']) for v in records})!=1:raise ValueError('All reference canvases must have identical dimensions')
    heights=[v['foreground_height'] for v in records]
    if (max(heights)-min(heights))/max(heights)>.02:raise ValueError('Figure-height drift exceeds 2%; inspect references before inference')
    return images,records


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reference-dir',type=Path,default=Path(__file__).resolve().parent/'inputs')
    parser.add_argument('--output-dir',type=Path,default=Path('output'))
    parser.add_argument('--model-path',default='tencent/Hunyuan3D-2mv',help='HF model ID or a local model snapshot directory')
    parser.add_argument('--paint-model-path',default='tencent/Hunyuan3D-2')
    parser.add_argument('--seed',type=int,default=1982)
    parser.add_argument('--steps',type=int,default=50)
    parser.add_argument('--resolution',type=int,default=380)
    parser.add_argument('--paint',action='store_true',help='Additionally run the multi-image texture pipeline (requires its CUDA extensions and weights)')
    parser.add_argument('--no-offload',action='store_true',help='Keep models resident on GPU; needs more VRAM')
    parser.add_argument('--dry-run',action='store_true',help='Validate input and inspect dependencies without installing/downloading/generating')
    args=parser.parse_args()
    try:images,records=references(args.reference_dir)
    except (ValueError,OSError) as error:parser.error(str(error))
    if args.steps<1 or not 64<=args.resolution<=512:parser.error('steps must be positive; resolution must be between 64 and 512')
    report={'python':platform.python_version(),'inputs':records,'shape_model':args.model_path,'shape_subfolder':'hunyuan3d-dit-v2-mv','paint_requested':args.paint,'seed':args.seed,'num_inference_steps':args.steps,'octree_resolution':args.resolution,'gpu_inference_completed':False}
    report['torch_installed']=importlib.util.find_spec('torch') is not None
    if report['torch_installed']:
        import torch
        report['cuda_available']=torch.cuda.is_available()
        if torch.cuda.is_available():
            report['gpu']=torch.cuda.get_device_name(0);report['vram_gib']=round(torch.cuda.get_device_properties(0).total_memory/2**30,2)
    else:report['cuda_available']=False
    if args.dry_run:
        print(json.dumps(report,ensure_ascii=False,indent=2));return 0
    if not report['cuda_available']:
        print('Cannot run the selected GPU pipeline: CUDA GPU/PyTorch is unavailable. No mesh was generated. Use --dry-run to inspect the prepared inputs.',file=sys.stderr);return 2
    try:
        from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline
    except ImportError as error:
        print(f'Install the pinned official Hunyuan3D environment first: {error}',file=sys.stderr);return 2
    args.output_dir.mkdir(parents=True,exist_ok=True);start=time.time()
    pipeline=Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(args.model_path,subfolder='hunyuan3d-dit-v2-mv',variant='fp16',device='cuda',dtype=torch.float16)
    if not args.no_offload:pipeline.enable_model_cpu_offload()
    mesh=pipeline(image=images,num_inference_steps=args.steps,octree_resolution=args.resolution,num_chunks=20000,generator=torch.manual_seed(args.seed),output_type='trimesh')[0]
    mesh.export(args.output_dir/'ivan-shape-unrigged.glb')
    report['shape_completed']=True;report['vertices']=int(len(mesh.vertices));report['faces']=int(len(mesh.faces))
    # Free the shape model BEFORE loading the paint model on a limited GPU.
    del pipeline;gc.collect();torch.cuda.empty_cache()
    if args.paint:
        from hy3dgen.texgen import Hunyuan3DPaintPipeline
        paint=Hunyuan3DPaintPipeline.from_pretrained(args.paint_model_path,subfolder='hunyuan3d-paint-v2-0-turbo')
        if not args.no_offload:paint.enable_model_cpu_offload()
        textured=paint(mesh,image=list(images.values()))
        textured.export(args.output_dir/'ivan-textured-unrigged.glb');report['texture_completed']=True
    report['gpu_inference_completed']=True;report['seconds']=round(time.time()-start,2)
    report['rigged']=False;report['animations']=False;report['status']='Generated mesh candidate; topology, proportions and rigging not yet reviewed.'
    (args.output_dir/'generation-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
    print(json.dumps(report,ensure_ascii=False,indent=2));return 0

if __name__=='__main__':sys.exit(main())
