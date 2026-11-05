import runpy
from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
runtime=LuaRuntime(unpack_returned_tuples=True)
for path in root.glob('*.lua'):
    result=runtime.eval('loadstring')(path.read_text(encoding='utf-8'))
    assert not isinstance(result,tuple),f'Lua syntax failure: {path.name}: {result}'
for name in ['test_kos','test_sightings','test_guild_alerts','test_grants','test_personal','test_peer_sync','test_mouseover','test_full_names','test_guild_targets']:
    runpy.run_path(str(root/'tests'/f'{name}.py'))
print('All standalone release tests passed.')
