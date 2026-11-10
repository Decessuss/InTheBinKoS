import runpy
from pathlib import Path
ns=runpy.run_path('tests/test_kos.py')
def client(name):
    r=ns['client'](name)
    r.execute('''
coreFrame=testFrame
function UnitGUID(unit)if unit=="player" then return "Player-1-" .. playerName end end
function GetServerTime()return 1800001000 end
''')
    r.execute(Path('Kills.lua').read_text(encoding='utf-8'))
    r.globals().ForeverKoS.EnsurePvPRecordEpoch()
    r.execute(Path('PvPStats.lua').read_text(encoding='utf-8'))
    r.execute('testFrame=coreFrame')
    return r
a,m=client('Alice'),client('Member')
a.execute('''
ForeverKoSDB.pvpKills={['Player-1-Alice']={}}
for i=1,12 do
 ForeverKoSDB.pvpKills['Player-1-Alice']['Player-2-' .. i]={name='Enemy ' .. i,count=i,losses=13-i,killingBlows=i-1,assists=1,lastKill=1800000000+i,lastLoss=1800000100+i,lastKillType='killingBlow'}
end
''')
api=a.globals().ForeverKoS
assert len(api.GetPvPStatsRows('kills'))==10
assert api.GetPvPStatsRows('kills')[1].name=='Enemy 12'
assert api.GetPvPStatsRows('deaths')[1].name=='Enemy 1'
assert api.GetPvPStatsRows('recent')[1].name=='Enemy 12'
assert api.GetPvPStatsRows('guild')[1].wins==78
m.execute('''
ForeverKoSDB.pvpKills={['Player-1-Member']={['Player-2-Opponent']={name='Example Opponent',count=7,losses=2,killingBlows=3,assists=4,lastKill=1800000000}}}
''')
m.globals().ForeverKoS.RequestPvPLeaderboard()
ns['deliver'](m,a,'Member')
ns['deliver'](a,m,'Alice')
board=api.GetPvPStatsRows('guild')
member=next(row for row in board.values() if row.name=='Member')
assert member.wins==7 and member.topName=='Example Opponent' and member.topCount==7
assert m.globals().ForeverKoS.GetPvPStatsRows('guild')[1].name=='Alice'
# Data is bound to the verified sender; outsider and malformed/replayed summaries fail.
ns['packet'](a,'L\t0.6.0\t1800001000\t999\t0\t999\t0\tEnemy\t999','Stranger')
assert len(api.GetPvPStatsRows('guild'))==2
ns['packet'](a,'L\t0.6.0\t1800001001\t1\t0\t2\t0\tEnemy\t1','Member')
ns['packet'](a,'L\t0.6.0\t1\t1\t0\t1\t0\tEnemy\t1','Member')
assert next(row for row in api.GetPvPStatsRows('guild').values() if row.name=='Member').wins==7
a.execute('guildName="Other Guild";testFrame.OnEvent(testFrame,"PLAYER_GUILD_UPDATE")')
assert len(api.GetPvPStatsRows('guild'))==1
assert api.GetPvPStatsRows('kills')[1].wins==12
print('PASS: personal top-10 wins/deaths/recent, member summary sync, top opponent, sender validation, malformed/stale rejection and guild isolation.')

# Test actual page navigation in the main window using the existing UI mock.
ui=runpy.run_path('tests/test_guild_targets.py')['a']
ui.execute('''
function UnitGUID(unit)if unit=="player" then return "Player-1-UI" end end
ForeverKoSDB.pvpKills={['Player-1-UI']={['Player-2-UI']={name='Test Enemy',count=3,losses=2,killingBlows=1,assists=2,lastKill=1800000000,lastLoss=1800000001}}}
''')
ui.execute(Path('Kills.lua').read_text(encoding='utf-8'))
ui.execute('ForeverKoSDB.pvpRecordEpoch="0.6.0"')
ui.execute(Path('PvPStats.lua').read_text(encoding='utf-8'))
ui.execute(Path('PvPUI.lua').read_text(encoding='utf-8'))
ui.execute('''
ForeverKoSWindow.pvp.scripts.OnClick()
assert(InTheBinKoSPvP:IsShown() and not ForeverKoSWindow.search:IsShown())
InTheBinKoSPvP.tabs.deaths.scripts.OnClick()
InTheBinKoSPvP.tabs.recent.scripts.OnClick()
InTheBinKoSPvP.tabs.guild.scripts.OnClick()
ForeverKoSWindow.guildTab.scripts.OnClick()
assert(not InTheBinKoSPvP:IsShown())
''')
print('PASS: embedded PvP tab and personal/deaths/recent/guild subpages.')
