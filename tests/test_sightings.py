import runpy
from pathlib import Path
ns=runpy.run_path('tests/test_kos.py')
def client(name):
    r=ns['client'](name)
    r.execute('''
stamp=1800000000
function GetServerTime() return stamp end
C_Map={GetBestMapForUnit=function() return 1944 end,
GetPlayerMapPosition=function() return {GetXY=function() return 0.25,0.75 end} end,
GetMapInfo=function(map) if map==1944 then return {name="Hellfire Peninsula"} end end}
TomTom={AddWaypoint=function(_,map,x,y,options) pin={map=map,x=x,y=y} end}
''')
    for file in ('Locations.lua','Sightings.lua'):
        r.execute(Path(file).read_text(encoding='utf-8'))
    ns['sent'](r)
    return r
a,m,n=client('Alice'),client('Member'),client('Listener')
ns['command'](a,'add target Test sighting')
msgs=ns['sent'](a)
for r in (m,n):
    for p,msg,c,t in msgs: ns['packet'](r,msg,'Alice-Realm',c)
m.execute('testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert m.globals().ForeverKoS.GetSighting('Enemy-Realm').spotter=='Member-Realm'
msgs=ns['sent'](m)
assert len(msgs)==1 and msgs[0][1].startswith('S\t')
for r in (a,n):
    for p,msg,c,t in msgs: ns['packet'](r,msg,'Member-Realm',c)
s=n.globals().ForeverKoS.GetSighting('Enemy-Realm')
assert s.spotter=='Member-Realm' and s.map==1944 and s.x==0.25
assert n.globals().ForeverKoS.SightingZone(s)=='Hellfire Peninsula'
assert n.globals().ForeverKoS.SightingAge(s)=='Just now'
n.execute('ForeverKoS.PinSighting("Enemy-Realm");assert(pin.map==1944 and pin.x==0.25 and pin.y==0.75)')
# Regular member has not acquired edit rights by reporting.
ns['command'](m,'remove Enemy-Realm')
assert not ns['records'](m)['enemy-realm'].deleted
new='S\t1800000060\tEnemy-Realm\t1944\t50000\t60000\tListener-Realm'
for r in (a,m,n): r.execute('stamp=1800000060')
ns['packet'](m,new,'Listener-Realm')
assert m.globals().ForeverKoS.GetSighting('Enemy-Realm').spotter=='Listener-Realm'
ns['packet'](m,msgs[0][1],'Member-Realm') # older packet also self rejected
assert m.globals().ForeverKoS.GetSighting('Enemy-Realm').stamp==1800000060
# A non-officer cannot claim somebody else's observation; strangers cannot report.
ns['packet'](n,new,'Member-Realm')
assert n.globals().ForeverKoS.GetSighting('Enemy-Realm').spotter=='Member-Realm'
ns['packet'](n,new,'Stranger-Realm')
assert n.globals().ForeverKoS.GetSighting('Enemy-Realm').spotter=='Member-Realm'
ns['packet'](n,'S\t1800009999\tEnemy-Realm\t1944\t1\t1\tListener-Realm','Listener-Realm')
assert n.globals().ForeverKoS.GetSighting('Enemy-Realm').stamp==1800000000
# Officer synchronization includes cached locations attributed to original spotter.
ns['packet'](a,'Q','Listener-Realm')
snapshot=ns['sent'](a)
assert any(msg.startswith('H\t') for _,msg,_,_ in snapshot)
for p,msg,c,t in snapshot: ns['packet'](n,msg,'Alice-Realm',c)
assert n.globals().ForeverKoS.GetSighting('Enemy-Realm').spotter=='Member-Realm'
# Muted alerts still collect sighting information.
m.execute('stamp=1800000121;now=221')
ns['command'](m,'alerts off')
m.execute('testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert m.globals().sounds==1
assert m.globals().ForeverKoS.GetSighting('Enemy-Realm').stamp==1800000121
assert any(msg.startswith('S\t') for _,msg,_,_ in ns['sent'](m))
# Removing an entry blocks further incoming sightings; guild separation isolates it.
ns['command'](a,'remove Enemy-Realm'); ns['deliver'](a,n,'Alice-Realm')
ns['packet'](n,new,'Listener-Realm')
assert ns['records'](n)['enemy-realm'].deleted
n.execute('guildName="Other Guild";testFrame.OnEvent(testFrame,"PLAYER_GUILD_UPDATE")')
assert n.globals().ForeverKoS.GetSighting('Enemy-Realm') is None
print('PASS: ordinary-member reporting with release edit restrictions; shared last-seen coordinates/spotter/time; frozen pin; newest wins; spoof/outsider/future rejection; officer history sync; muted collection; removal and guild isolation.')
