import sys
from pathlib import Path

from lupa.lua51 import LuaRuntime

source = Path('Core.lua').read_text(encoding='utf-8')
mock = '''
now=100; playerName=...; guildName="Guild"; sounds=0; notices={}; outgoing={}; scans={}
members={{"Alice",0},{"Bob",1},{"Member",2},{"Listener",3}}
units={player={name=playerName,faction="Alliance"},target={name="Enemy",faction="Horde"}}
function CreateFrame() local f={}; function f:SetScript(k,v) self[k]=v end; function f:RegisterEvent() end; testFrame=f; return f end
function print(s) notices[#notices+1]=s end
function GetNormalizedRealmName() return "Realm" end
function GetRealmName() return "Realm" end
function UnitFullName(u) local v=units[u]; if not v then return end; return v.name,"IgnoredRealm" end
function GetGuildInfo() return guildName end
function GetNumGuildMembers() return #members end
function GetGuildRosterInfo(i) return members[i][1],"Rank",members[i][2] end
function GetTime() return now end
function UnitExists(u) return units[u]~=nil end
function UnitIsPlayer(u) return units[u]~=nil end
function UnitFactionGroup(u) return units[u] and units[u].faction end
function PlaySound() sounds=sounds+1 end
function GetZoneText() return "Test Zone" end
C_GuildInfo={GuildRoster=function() end, GuildControlGetRankFlags=function(rank) return {[3]=rank==4,[4]=rank==2} end}
C_ChatInfo={RegisterAddonMessagePrefix=function() end,SendAddonMessage=function(p,m,c,t) outgoing[#outgoing+1]={p,m,c,t} end}
ForeverAuras={ScanEvents=function(...) scans[#scans+1]={...} end}
SlashCmdList={}
'''

def client(name):
    r=LuaRuntime(unpack_returned_tuples=True)
    r.execute(mock,name+'')
    r.execute(source)
    r.execute('testFrame.OnEvent(testFrame,"ADDON_LOADED","ForeverKoS"); testFrame.OnEvent(testFrame,"PLAYER_LOGIN")')
    return r

def command(r,s): r.globals().SlashCmdList.FOREVERKOS(s)
def records(r): return r.globals().ForeverKoSDB.guilds['Guild'].records
def tick(r): r.execute('testFrame.OnUpdate(testFrame,0.21)')
def packet(r,msg,sender='Alice',channel='GUILD'):
    r.globals().testFrame.OnEvent(r.globals().testFrame,'CHAT_MSG_ADDON','ForeverKoS1',msg,channel,sender)
def sent(r):
    result=[]
    for _ in range(100): tick(r)
    for _,v in r.globals().outgoing.items(): result.append(tuple(v[i] for i in range(1,5)))
    r.execute('outgoing={}')
    return result
def deliver(a,b,sender):
    for p,m,c,t in sent(a): packet(b,m,sender,c)

a,b,m,l=[client(n) for n in ('Alice','Bob','Member','Listener')]
for r in (a,b,m,l): sent(r)
command(a,'add target Camping')
assert records(a)['enemy'].reason=='Camping'
deliver(a,m,'Alice')
assert records(m)['enemy'].reason=='Camping'
command(m,'remove Enemy'); command(l,'add Other')
assert not records(m)['enemy'].deleted
assert records(l)['other'] is None
packet(m,'R\t999\tMember\t1\tEnemy\t','Member')
assert not records(m)['enemy'].deleted
packet(m,'R\t999\tListener\t1\tEnemy\t','Listener')
assert not records(m)['enemy'].deleted
command(a,'remove Enemy'); deliver(a,m,'Alice')
assert records(m)['enemy'].deleted
packet(m,'R\t1\tAlice\t0\tEnemy\tOld')
assert records(m)['enemy'].deleted
command(a,'add Enemy Readded'); deliver(a,m,'Alice')
assert not records(m)['enemy'].deleted
for _ in range(2): m.execute('testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert m.globals().sounds==1 and len(m.globals().scans)==1
m.execute('now=161;testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT");testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert m.globals().sounds==2
m.execute('units.target.faction="Alliance";now=230;testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert m.globals().sounds==2
command(m,'alerts off')
m.execute('units.target.faction="Horde";testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert m.globals().sounds==2
command(m,'test'); assert m.globals().sounds==3
# Concurrent revision, deterministic editor tie-break, in both delivery orders.
command(b,'remove Rival'); command(a,'add Rival Added')
pa=[x[1] for x in sent(a) if x[1].startswith('R\t')][-1]
pb=[x[1] for x in sent(b) if x[1].startswith('R\t')][-1]
# Equalize revisions explicitly to exercise exact tie.
pa='R\t10\tAlice\t0\tRival\tAdded'
pb='R\t10\tBob\t1\tRival\t'
packet(m,pa);packet(m,pb,'Bob');packet(l,pb,'Bob');packet(l,pa)
assert records(m)['rival'].deleted and records(l)['rival'].deleted
assert records(m)['rival'].editor=='Bob'
# Request/response sends a snapshot only from an authorized officer.
packet(b,'Q','Member'); snapshot=sent(b)
assert any(v[1].startswith('C\t') and v[2]=='WHISPER' and v[3]=='Member' for v in snapshot)
packet(m,'Q','Bob'); assert all(v[1].startswith('C\t') for v in sent(m))
# Permission change takes effect without trusting sender's claim.
m.execute('members[2][2]=2;testFrame.OnEvent(testFrame,"GUILD_ROSTER_UPDATE")')
packet(m,'R\t20\tBob\t0\tDemoted\t','Bob')
assert records(m)['demoted'] is None
# Unsupported permission API fails closed for non-GM.
b.execute('C_GuildInfo.GuildControlGetRankFlags=nil')
command(b,'add Unsupported'); assert records(b)['unsupported'] is None
# Guild scope changes stop former guild alerts and isolate edits.
m.execute('guildName=nil;testFrame.OnEvent(testFrame,"PLAYER_GUILD_UPDATE");now=400;testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert m.globals().sounds==3
packet(l,'R\t999\tAlice\t0\tBroken\tbad%09text')
assert records(l)['broken'] is None
command(a,'add Long '+('x'*500)); assert len(records(a)['long'].reason)==60
# Syntax-check the documented aura functions with Lua 5.1.
text=Path('docs/ForeverKoS-SETUP.md').read_text(encoding='utf-8')
for snippet in text.split('```lua\n')[1:]:
    a.execute('return '+snippet.split('```')[0])
print('PASS: Lua 5.1 load; officer/GM/member/listener permissions; spoof rejection; add/remove/re-add; tombstones; conflict convergence; sync authorization; sighting cooldown/faction/settings; demotion; unsupported API; guild separation; malformed record; reason bounds; aura syntax.')
