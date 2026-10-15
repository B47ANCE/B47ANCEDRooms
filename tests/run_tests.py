"""Offline source tests only. Does not launch, package, deploy or publish."""
from pathlib import Path
import sys, json, re
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.test-deps'))
from lupa.lua51 import LuaRuntime
SOURCE=ROOT/'src/B47ANCEDRooms'
def runtime():
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.globals().TEST_ROOT=(ROOT/'tests').as_posix()
    lua.globals().package.path=';'.join((SOURCE/f'42/media/lua/{side}/?.lua').as_posix() for side in ['shared','client'])+';'+lua.globals().package.path
    return lua
for p in SOURCE.rglob('*.lua'):
    code=p.read_text(encoding='utf-8')
    runtime().execute('assert(loadstring(...))',code)
    assert not re.search(r"require\s*['\"]B47ANCEDQuartermaster",code),p
    if '/shared/' in p.as_posix():assert not re.search(r':(?:AddItem|addItem|Remove|removeItemWithID)\s*\(',code),p
for name in ['test_registry.lua','test_detection.lua','test_permissions.lua','test_migration.lua','test_native_rooms.lua','test_editor.lua','test_network.lua']:
    path=ROOT/'tests'/name
    runtime().execute(path.read_text(encoding='utf-8'))
english=json.loads((SOURCE/'42/media/lua/shared/Translate/EN/UI.json').read_text(encoding='utf-8'))
for p in SOURCE.rglob('*.lua'):
    for key in re.findall(r"tr\('([^']+)'(?:,|\))",p.read_text(encoding='utf-8')):
        assert 'UI_B47Rooms_'+key in english,(p,key)
for p in (SOURCE/'42/media/lua/shared/Translate').glob('*/UI.json'):
    assert json.loads(p.read_text(encoding='utf-8'))==english,p
actual={p.relative_to(SOURCE).as_posix() for p in SOURCE.rglob('*') if p.is_file()}
assert len(actual)==len({n.casefold() for n in actual})
assert not any(Path(n).suffix.lower() in {'.java','.jar','.class','.dll'} for n in actual)
for p in SOURCE.rglob('*.lua'):
    for name in re.findall(r"\brequire\s*(?:\(\s*)?['\"]([^'\"]+)",p.read_text(encoding='utf-8')):
        if name.startswith(('B47ANCEDRooms/','B47RoomsUI/')):
            assert any(f'42/media/lua/{side}/{name}.lua' in actual for side in ('shared','client','server')),(p,name)
declared=set(json.loads((ROOT/'scripts/production-files.json').read_text()))
assert declared==actual,('Source manifest',declared-actual,actual-declared)
print('PASS OFFLINE Rooms syntax, standalone namespace, no inventory mutation, source inventory, localization and case checks; native/dedicated NOT TESTED')
