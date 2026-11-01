#!/usr/bin/env python3
"""Split an official Godot export into <100 MiB downloadable packs without source files.
The native template automatically mounts Metro1982.pck; Bootstrap mounts asset packs.
Usage: python3 tools/package_native.py ALL.pck OUTPUT --templates TEMPLATE_DIR
"""
from pathlib import Path
import argparse,struct,hashlib,json,subprocess,shutil,tempfile,os

def extract(source, destination):
    entries=[]
    with source.open('rb') as f:
        header=f.read(112)
        if struct.unpack_from('<II',header)!=(0x43504447,3):raise ValueError('Expected Godot PCK v3')
        base,directory=struct.unpack_from('<QQ',header,24);f.seek(directory)
        count=struct.unpack('<I',f.read(4))[0]
        for _ in range(count):
            n=struct.unpack('<I',f.read(4))[0];name=f.read(n).rstrip(b'\0').decode()
            offset,size=struct.unpack('<QQ',f.read(16));md5=f.read(16);flags=struct.unpack('<I',f.read(4))[0]
            if flags or Path(name).is_absolute() or '..' in Path(name).parts:raise ValueError('Unsupported entry '+name)
            entries.append((name,base+offset,size,md5))
        out=[]
        for name,offset,size,md5 in entries:
            f.seek(offset);data=f.read(size)
            if hashlib.md5(data).digest()!=md5:raise ValueError('Export checksum failed: '+name)
            path=destination/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            out.append({'path':name,'file':str(path),'bytes':size})
        return out

def main():
    ap=argparse.ArgumentParser();ap.add_argument('pack',type=Path);ap.add_argument('output',type=Path);ap.add_argument('--templates',type=Path,required=True);ap.add_argument('--godot',default='godot');args=ap.parse_args()
    repo=Path(__file__).resolve().parents[1];dest=args.output.resolve();dest.mkdir(parents=True,exist_ok=True);(dest/'content').mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='metro-packs-',dir=dest.parent) as tmp:
        tmp=Path(tmp);entries=extract(args.pack,tmp/'files');core=[];groups=[];current=[];size=0
        for e in entries:
            if not e['path'].startswith(('assets/','.godot/imported/')):core.append(e);continue
            if current and size+e['bytes']>78*1024**2:groups.append(current);current=[];size=0
            current.append(e);size+=e['bytes']
        if current:groups.append(current)
        mode=tmp/'content_mode.json';mode.write_text('{"chunked":true}\n');core.append({'path':'content_mode.json','file':str(mode)})
        jobs=[{'output':str(dest/'Metro1982.pck'),'entries':core}]
        jobs.extend({'output':str(dest/'content'/('world%02d.pck'%(i+1))),'entries':g} for i,g in enumerate(groups))
        spec=tmp/'spec.json';spec.write_text(json.dumps({'jobs':jobs}))
        env=os.environ.copy()
        for key,folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
            if key not in env:
                directory=tmp/folder;directory.mkdir();env[key]=str(directory)
        subprocess.run([args.godot,'--headless','--path',str(repo),'--script',str(repo/'tools/build_packs.gd'),'--',str(spec)],env=env,check=True)
    manifest={'version':1,'engine':'4.6.3','packs':[]}
    for path in sorted((dest/'content').glob('world*.pck')):
        manifest['packs'].append({'file':path.name,'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    (dest/'content'/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    for source,name in [('windows_release_x86_64.exe','Metro1982.exe'),('linux_release.x86_64','Metro1982.x86_64')]:
        shutil.copyfile(args.templates/source,dest/name);(dest/name).chmod(0o755)
    for path in dest.rglob('*'):
        if path.is_file() and path.stat().st_size>=100*1024**2:raise ValueError('GitHub file limit exceeded: '+str(path))
    print('NATIVE_PACKAGE_READY',dest)
if __name__=='__main__':main()
