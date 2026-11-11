import runpy
ns=runpy.run_path('tests/test_pvp_stats.py')
a,m=ns['client']('Alice'),ns['client']('Member')
base=ns['ns'];api=a.globals().ForeverKoS
base['command'](a,'add "Yozah Hunt" Test entry')
for runtime in (a,m):
 runtime.execute('WeakAuras={ScanEvents=function(...)lastSlainAura={...};auraCount=(auraCount or 0)+1 end};ForeverAuras=WeakAuras')
api.RecordKoSSlain('Yozah Hunt',None)
rows=api.GetPvPStatsRows('slain')
assert len(rows)==1 and rows[1].count==1 and rows[1].name=='Alice'
base['deliver'](a,m,'Alice')
remote=m.globals().ForeverKoS.GetPvPStatsRows('slain')
assert len(remote)==1 and remote[1].count==1
assert m.globals().lastSlainAura[1]=='FOREVER_KOS_SLAIN'
assert m.globals().lastSlainAura[2]=='Yozah Hunt'
# Duplicate live packets and historical snapshots cannot replay announcements.
packet='K\t0.6.0\t1800001000\t1\tYozah Hunt\t1'
base['packet'](m,packet,'Alice')
assert m.globals().auraCount==1
api.RecordKoSSlain('Yozah Hunt',None)
base['deliver'](a,m,'Alice')
assert m.globals().ForeverKoS.GetPvPStatsRows('slain')[1].count==2
assert m.globals().lastSlainAura[4]==2
base['packet'](m,'K\t0.6.0\t1800001000\t9\tOther Enemy\t0','Alice')
assert m.globals().auraCount==2
# Outsiders and malformed/future counts are rejected by the normal guild receiver.
base['packet'](m,'K\t0.6.0\t1800001000\t99\tYozah Hunt\t1','Stranger')
base['packet'](m,'K\t0.6.0\t1900001000\t99\tYozah Hunt\t1','Alice')
base['packet'](m,'K\t0.6.0\t1800001000\t0\tYozah Hunt\t1','Alice')
assert m.globals().auraCount==2
api.RecordKoSSlain('Not Listed',None)
assert len(api.GetPvPStatsRows('slain'))==1
# Exercise the actual killing-blow hook and duplicate suppression.
from pathlib import Path
a.execute(Path('Kills.lua').read_text(encoding='utf-8'))
a.execute("""
function GetPlayerInfoByGUID()return "Mage","MAGE","Human","Human",2,"Yozah","Hunt" end
now=1000
testFrame.OnEvent(testFrame,"PARTY_KILL","Player-1-Alice","Player-2-Yozah")
testFrame.OnEvent(testFrame,"PARTY_KILL","Player-1-Alice","Player-2-Yozah")
""")
assert api.GetPvPStatsRows('slain')[1].count==3
# An assist is not a slain-by credit; a later killing blow upgrades it once.
a.execute('now=1010;COMBATLOG_HONORGAIN="%s dies (Honorable Kill). You gain %d Honor.";testFrame.OnEvent(testFrame,"CHAT_MSG_COMBAT_HONOR_GAIN","Yozah Hunt dies (Honorable Kill). You gain 4 Honor.")')
assert api.GetPvPStatsRows('slain')[1].count==3
a.execute('testFrame.OnEvent(testFrame,"PARTY_KILL","Player-1-Alice","Player-2-Yozah")')
assert api.GetPvPStatsRows('slain')[1].count==4
print('PASS: KoS slain kill hook, counts, guild packets, aura payload, duplicate handling, silent snapshots and invalid/outsider rejection.')

