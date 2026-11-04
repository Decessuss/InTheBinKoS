import runpy
from pathlib import Path
ns=runpy.run_path('tests/test_kos.py')
r=ns['client']('Member')
core=r.globals().testFrame
r.execute(Path('Personal.lua').read_text(encoding='utf-8'))
r.globals().testFrame=core
ns['sent'](r)
r.execute('''
ForeverKoS.SetPersonalMode(true)
ForeverKoS.Edit("Friend-Realm","Ninja looter",false)
local rows,canEdit=ForeverKoS.GetState();assert(canEdit and #rows==1 and rows[1].reason=="Ninja looter")
assert(not ForeverKoS.CanManageAccess())
assert(ForeverKoSDB.guilds["Guild@Realm"].records["friend-realm"]==nil)
units.mouseover={name="Friend-Realm",faction="Alliance"}
testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")
assert(sounds==1)
testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")
assert(sounds==1)
assert(notices[#notices]:find("On your personal avoid list"))
partyCount=1;units.party1={name="Friend-Realm",faction="Alliance"}
function IsInRaid() return false end
function GetNumSubgroupMembers() return partyCount end
ForeverKoS.CheckPersonalGroup();assert(sounds==2)
assert(notices[#notices]:find("IN YOUR PARTY"))
ForeverKoS.CheckPersonalGroup();assert(sounds==2)
partyCount=0;ForeverKoS.CheckPersonalGroup()
partyCount=1;ForeverKoS.CheckPersonalGroup();assert(sounds==3)
ForeverKoS.SetAlerts(false)
partyCount=0;ForeverKoS.CheckPersonalGroup();partyCount=1;ForeverKoS.CheckPersonalGroup();assert(sounds==3)
ForeverKoS.SetPersonalMode(false)
local guildRows,canEdit,_,sound,alerts=ForeverKoS.GetState()
assert(#guildRows==0 and not canEdit and sound and alerts)
ForeverKoS.SetPersonalMode(true)
ForeverKoS.SetAlerts(true)
units.player.name="Another-Realm"
assert(#ForeverKoS.GetState()==0)
units.player.name="Member-Realm"
assert(#ForeverKoS.GetState()==1)
guildName=nil;testFrame.OnEvent(testFrame,"PLAYER_GUILD_UPDATE")
assert(#ForeverKoS.GetState()==1)
ForeverKoS.Edit("Friend-Realm","",true);assert(#ForeverKoS.GetState()==0)
''')
assert not ns['sent'](r)
print('PASS: ordinary member edits private list; no guild records or messages; friendly mouseover cooldown; party-entry warning without repeated roster spam; independent settings; per-character persistence; guildless use; removal.')
