"""Validate and stage an explicit Workshop submission. Never uploads or deploys."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[1]
MOD='B47ANCEDRooms'

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def git(*args): return subprocess.check_output(['git','-C',str(ROOT),*args],stderr=subprocess.DEVNULL)
def escape(value): return value.replace('\\','\\\\').replace('"','\\"').replace('\r\n','\n').replace('\r','\n')

def prepare(output, create_private=False):
    subprocess.run([sys.executable,str(ROOT/'scripts/check_versions.py'),'--root',str(ROOT),'--release'],check=True)
    version=(ROOT/'VERSION').read_text(encoding='utf-8').strip()
    identity=ROOT/'WORKSHOP_ID.txt'
    if create_private:
        if identity.exists(): raise ValueError('Workshop identity already exists; never create another item')
        published_id='0'
    else:
        published_id=identity.read_text(encoding='utf-8').strip()
        if not re.fullmatch(r'[1-9][0-9]{6,19}',published_id): raise ValueError('Invalid assigned Workshop ID')
    output=output.resolve()
    output.relative_to((ROOT/'dist').resolve())
    if output.exists(): raise ValueError('Use a fresh output directory; preserve prior submissions')
    source=ROOT/'src'/MOD
    source_files={p.relative_to(source).as_posix():sha(p) for p in source.rglob('*') if p.is_file()}
    declared=json.loads((ROOT/'scripts/production-files.json').read_text(encoding='utf-8'))
    assert set(source_files)==set(declared) and len(source_files)==len({p.casefold() for p in source_files})
    for name in source_files:
        p=source/name
        assert not p.is_symlink() and p.suffix.lower() not in {'.java','.jar','.class','.dll','.exe','.py'}
        committed=git('show','HEAD:'+p.relative_to(ROOT).as_posix())
        assert p.read_bytes()==committed or p.read_bytes().replace(b'\r\n',b'\n')==committed,name
    archive=ROOT/'dist/current'/f'{MOD}-{version}.zip'
    with zipfile.ZipFile(archive) as z:
        names=z.namelist()
        assert z.testzip() is None and len(names)==len(set(names))==len({n.casefold() for n in names})
        for name in names:
            path=PurePosixPath(name);assert not path.is_absolute() and '..' not in path.parts and '\\' not in name
        actual={n.removeprefix(MOD+'/'):hashlib.sha256(z.read(n)).hexdigest() for n in names if not n.endswith('/')}
        assert actual==source_files,'Current package is not current source'
    output.mkdir(parents=True)
    generated=ROOT/'workshop'
    generated.mkdir(exist_ok=True)
    renderer=Path.home()/'.codex/b47anced-team/tools/Build-WorkshopDescription.py'
    subprocess.run([sys.executable,str(renderer),'--repo',str(ROOT),'--input',str(ROOT/'docs/WORKSHOP_DESCRIPTION.md'),
                    '--output',str(generated/'description.bbcode')],check=True)
    description=(generated/'description.bbcode').read_text(encoding='utf-8').strip()
    note=(ROOT/'docs/WORKSHOP_CHANGELOG.md').read_text(encoding='utf-8').strip()
    assert note.startswith('# Version '+version)
    note=note.replace('# Version '+version,'[b]Version '+version+'[/b]',1)
    (generated/'changenote.txt').write_bytes((note+'\n').encode('utf-8'))
    for value in [description,note]:
        assert 'MP testing build - dedicated multiplayer NOT TESTED' in value
        assert '\\n' not in value and '\n\n' in value
        assert not re.search(r'\b(?:TODO|TBD|PLACEHOLDER)\b',value)
    assert len(description.encode('utf-8'))<8000
    stage=output/'stage'
    shutil.copytree(source,stage/'Contents/mods'/MOD)
    for name in ('common/media/AnimSets','common/media/actiongroups','42/media/AnimSets','42/media/actiongroups'):
        (stage/'Contents/mods'/MOD/name).mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/'artwork/thumbnail.png',stage/'preview.png')
    assert sha(stage/'preview.png')==sha(ROOT/'artwork/thumbnail.png')
    assert 0<(stage/'preview.png').stat().st_size<1048576
    staged={p.relative_to(stage/'Contents/mods'/MOD).as_posix():sha(p) for p in (stage/'Contents/mods'/MOD).rglob('*') if p.is_file()}
    assert staged==source_files
    fields={'appid':'108600','publishedfileid':published_id,'contentfolder':str(stage/'Contents'),
            'previewfile':str(stage/'preview.png'),'visibility':'2' if create_private else '0',
            'title':"B47ANCE'd Rooms",'description':description,'changenote':note,
            'tags':'Build 42;Interface;QoL'}
    vdf='"workshopitem"\n{\n'+''.join('    "'+k+'" "'+escape(v)+'"\n' for k,v in fields.items())+'}\n'
    (output/'submission.vdf').write_bytes(vdf.encode('utf-8'))
    manifest={'version':version,'modId':MOD,'workshopId':None if create_private else published_id,'appId':108600,
              'kind':'MP testing build - dedicated multiplayer NOT TESTED','creationReservation':create_private,
              'visibility':'private identity allocation' if create_private else 'public',
              'commit':git('rev-parse','HEAD').decode().strip(),'sourceFiles':source_files,'packageSha256':sha(archive),
              'descriptionSha256':sha(generated/'description.bbcode'),'changenoteSha256':sha(generated/'changenote.txt'),
              'previewSha256':sha(stage/'preview.png'),'vdfSha256':sha(output/'submission.vdf'),
              'gameBuild':'42.21.0','offline':'PASS','G7':'BLOCKED / NOT TESTED','stableG8':'BLOCKED',
              'localDeployment':False,'serverChanges':False,'published':False,'canonicalInputs':['docs/WORKSHOP_DESCRIPTION.md','docs/WORKSHOP_CHANGELOG.md'],
              'stage':str(stage),'vdf':str(output/'submission.vdf'),'package':str(archive)}
    (output/'release-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    print(f'PASS {len(staged)} committed Lua-only source/package/stage files; ZIP CRC/paths/case/parity; canonical rendered prose; immutable VDF/manifest: {output}')
    return manifest

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--create-private',action='store_true',help='Explicit initial private identity allocation; only when no identity exists')
    args=parser.parse_args()
    prepare(args.output,args.create_private)
