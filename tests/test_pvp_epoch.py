import runpy
from pathlib import Path
ns=runpy.run_path('tests/test_kos.py')
r=ns['client']('Member')
r.execute('''
function UnitGUID(unit)if unit=="player" then return "Player-1-Self" end end
function GetServerTime()return 1800001000 end
ForeverKoSDB.pvpKills={['Player-1-Self']={['Player-2-Enemy']={count=30,losses=20}},['Player-1-Alt']={['Player-2-Enemy']={count=15}}}
ForeverKoSDB.guilds.Guild.pvpLeaderboard={member={wins=100}}
ForeverKoSDB.guilds.Guild.requests={example={name='Keep request'}}
ForeverKoSDB.ui={angle=123}
''')
source=Path('Kills.lua').read_text(encoding='utf-8')
r.execute(source)
r.execute('testFrame.OnEvent(testFrame,"PLAYER_LOGIN")')
api=r.globals().ForeverKoS
assert api.GetPlayerPvPRecord('Player-2-Enemy')==(0,0)
assert r.globals().ForeverKoSDB.pvpKills['Player-1-Alt'] is None
assert len(r.globals().ForeverKoSDB.guilds.Guild.pvpLeaderboard)==0
assert r.globals().ForeverKoSDB.guilds.Guild.requests.example.name=='Keep request'
assert r.globals().ForeverKoSDB.ui.angle==123
r.execute('testFrame.OnEvent(testFrame,"PARTY_KILL","Player-1-Self","Player-2-Enemy")')
assert api.GetPlayerKillCount('Player-2-Enemy')==1
r.execute(source)
r.execute('testFrame.OnEvent(testFrame,"PLAYER_LOGIN")')
assert api.GetPlayerKillCount('Player-2-Enemy')==1
r.execute(Path('PvPStats.lua').read_text(encoding='utf-8'))
api.ReceivePvPStats('L\t1800001000\t999\t0\t999\t0\tEnemy\t999','Alice')
assert len(r.globals().ForeverKoSDB.guilds.Guild.pvpLeaderboard)==0
print('PASS: 0.6.0 resets PvP counts/cache once for all characters; preserves requests/settings; keeps new counts over reload and rejects pre-reset summaries.')
