import runpy
from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
runtime=LuaRuntime(unpack_returned_tuples=True)
for path in root.glob('*.lua'):
    result=runtime.eval('loadstring')(path.read_text(encoding='utf-8'))
    assert not isinstance(result,tuple),f'Lua syntax failure: {path.name}: {result}'
for name in ['test_kos','test_sightings','test_guild_alerts','test_grants','test_personal','test_peer_sync','test_mouseover','test_full_names','test_guild_targets','test_release_upload','test_officer_access','test_sighting_sound','test_presence','test_access_management','test_realm_free','test_guild_throttle','test_named_admin','test_update_notice','test_grant_confirmation_throttle','test_enemy_level','test_nameplate_skulls','test_requests','test_nearby','test_request_retention','test_kills','test_pvp_losses','test_pvp_assists','test_pvp_stats','test_pvp_instances','test_pvp_epoch']:
    runpy.run_path(str(root/'tests'/f'{name}.py'))
print('All standalone release tests passed.')
