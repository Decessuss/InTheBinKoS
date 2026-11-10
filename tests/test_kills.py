import runpy
from pathlib import Path
ns=runpy.run_path('tests/test_kos.py')
r=ns['client']('Member')
r.execute('''
guids={player="Player-1-Self",pet="Pet-1-Self",mouseover="Player-2-Enemy",target="Player-2-Enemy"}
function UnitGUID(unit)return guids[unit]end
function GetServerTime()return 1800000000 end
function GetPlayerInfoByGUID(guid)return "Mage","MAGE","Human","Human",2,"Enemy","Person" end
tooltipLines={}
GameTooltip={scripts={}}
function GameTooltip:HookScript(event,fn)self.scripts[event]=fn end
function GameTooltip:GetUnit()return "Enemy Person","mouseover" end
function GameTooltip:AddLine(text)tooltipLines[#tooltipLines+1]=text end
units.mouseover={name="Enemy Person",faction="Horde"}
''')
source=Path('Kills.lua').read_text(encoding='utf-8')
assert 'COMBAT_LOG_EVENT_UNFILTERED' not in source
assert 'CombatLogGetCurrentEventInfo' not in source
r.execute(source)
r.execute('killFrame=testFrame;killFrame.OnEvent(killFrame,"PLAYER_LOGIN")')
api=r.globals().ForeverKoS
def kill(source,victim='Player-2-Enemy'):
    r.globals().killFrame.OnEvent(r.globals().killFrame,'PARTY_KILL',source,victim)
kill('Player-1-Self')
assert api.GetPlayerKillCount('Player-2-Enemy')==1
assert not api.MatchRecord('Enemy Person')
# Repeated kill events count one death, not two.
kill('Player-1-Self')
assert api.GetPlayerKillCount('Player-2-Enemy')==1
kill('Player-3-PartyMember','Player-2-Other')
kill('Player-1-Self','Creature-1-NPC')
kill('Player-1-Self','Player-1-Self')
assert api.GetPlayerKillCount('Player-2-Other')==0
r.execute('now=104')
kill('Pet-1-Self')
assert api.GetPlayerKillCount('Player-2-Enemy')==2
r.execute('GameTooltip.scripts.OnTooltipSetUnit(GameTooltip);GameTooltip.scripts.OnTooltipSetUnit(GameTooltip)')
assert list(r.globals().tooltipLines.values())==['Your PvP record: 2 wins / 0 losses']
r.execute('GameTooltip.scripts.OnTooltipCleared(GameTooltip);guids.mouseover="Player-2-Unseen";GameTooltip.scripts.OnTooltipSetUnit(GameTooltip)')
assert r.globals().tooltipLines[2]=='Your PvP record: 0 wins / 0 losses'
# Private character storage, independent of guild membership and saved over reload.
r.execute('guids.player="Player-1-Alt"')
assert api.GetPlayerKillCount('Player-2-Enemy')==0
r.execute('guids.player="Player-1-Self";guildName=nil')
r.execute(source)
assert api.GetPlayerKillCount('Player-2-Enemy')==2
assert r.globals().ForeverKoSDB.pvpKills['Player-1-Self']['Player-2-Enemy'].name=='Enemy Person'
# Modern tooltip processing is supported too, and restricted identity is ignored.
r.execute('''
Enum={TooltipDataType={Unit=1}}
TooltipDataProcessor={AddTooltipPostCall=function(_,fn)modernCallback=fn end}
testFrame.OnEvent(testFrame,"PLAYER_LOGIN")
GameTooltip.scripts.OnTooltipCleared(GameTooltip)
guids.mouseover="Player-2-Enemy"
modernCallback(GameTooltip)
assert(tooltipLines[#tooltipLines]=="Your PvP record: 2 wins / 0 losses")
local hidden={}
function issecretvalue(v)return v==hidden end
testFrame.OnEvent(testFrame,"PARTY_KILL",hidden,hidden)
''')
assert api.GetPlayerKillCount('Player-2-Enemy')==2
print('PASS: personal/player-pet PvP kills, non-KoS tooltips, duplicate suppression, NPC/party/self exclusion, per-character persistence, guildless use and modern/legacy tooltip hooks.')
r.execute('''
GameTooltip.scripts.OnTooltipCleared(GameTooltip)
local before=#tooltipLines
function UnitIsFriend()return true end
modernCallback(GameTooltip)
assert(#tooltipLines==before)
function UnitIsFriend()return false end
modernCallback(GameTooltip)
assert(#tooltipLines==before+1)
UnitIsFriend=nil
''')
r.execute('''
ForeverKoS.Settings().showPvPRecordTooltip=false
GameTooltip.scripts.OnTooltipCleared(GameTooltip)
local before=#tooltipLines
modernCallback(GameTooltip)
assert(#tooltipLines==before)
testFrame.OnEvent(testFrame,"PARTY_KILL","Player-1-Self","Player-2-NewEnemy")
assert(ForeverKoS.GetPlayerKillCount("Player-2-NewEnemy")==1)
ForeverKoS.Settings().showPvPRecordTooltip=true
modernCallback(GameTooltip)
assert(#tooltipLines==before+1)
''')
