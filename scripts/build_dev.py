"""Build an offline development ZIP only; never deploy or upload."""
from pathlib import Path, PurePosixPath
import hashlib
import json
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'src/B47ANCEDRooms'

def run():
    for command in (['tests/run_tests.py'], ['scripts/check_versions.py']):
        subprocess.run([sys.executable, *command], cwd=ROOT, check=True)
    version = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
    target = ROOT / 'dist/current' / ('B47ANCEDRooms-' + version + '.zip')
    if target.exists():
        raise SystemExit('Preserve existing artifact; refusing overwrite: ' + str(target))
    files = {p.relative_to(SOURCE).as_posix(): p for p in SOURCE.rglob('*') if p.is_file()}
    declared = json.loads((ROOT / 'scripts/production-files.json').read_text(encoding='utf-8'))
    assert set(files) == set(declared)
    expected = {}
    for name, path in sorted(files.items()):
        assert not path.is_symlink() and not PurePosixPath(name).is_absolute() and '..' not in PurePosixPath(name).parts
        assert path.suffix.lower() not in {'.jar', '.java', '.class', '.dll', '.exe', '.py'}
        expected['B47ANCEDRooms/' + name] = path.read_bytes()
    assert len(expected) == len({n.casefold() for n in expected})
    target.parent.mkdir(parents=True, exist_ok=True)
    directories = ('common/', 'common/media/AnimSets/', 'common/media/actiongroups/', '42/media/AnimSets/', '42/media/actiongroups/')
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name in directories:
            archive.writestr(zipfile.ZipInfo('B47ANCEDRooms/' + name), b'')
        for name, content in expected.items():
            info = zipfile.ZipInfo(name); info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, content)
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None
        assert len(archive.namelist()) == len(set(archive.namelist()))
        assert {n for n in archive.namelist() if not n.endswith('/')} == set(expected)
        assert all(archive.read(name) == data for name, data in expected.items())
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    target.with_suffix('.zip.sha256').write_text(digest + '  ' + target.name + '\n', encoding='utf-8')
    subprocess.run([sys.executable, 'scripts/check_versions.py', '--release'], cwd=ROOT, check=True)
    print(f'PASS development ZIP: {len(expected)} files; SHA-256 {digest}; native/dedicated NOT TESTED')
    return target

if __name__ == '__main__':
    run()
