import runpy
ns=runpy.run_path('tests/test_sightings.py');base=ns['ns']
a,b=ns['client']('Alice'),ns['client']('Member')
base['command'](a,'add target Sound mode');base['deliver'](a,b,'Alice')
b.execute('ForeverKoS.Settings().sightingSoundSameZoneOnly=true;C_Map.GetBestMapForUnit=function()return 999 end')
a.execute('testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
base['deliver'](a,b,'Alice')
assert a.globals().sounds==1 and b.globals().sounds==0
assert len(b.globals().scans)==1
# Remote chat/aura cooldown must not silence our first local detection.
b.execute('testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert b.globals().sounds==1
b.execute('testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert b.globals().sounds==1
# Master sound checkbox and per-target mute still override the local mode.
base['command'](b,'sound off')
b.execute('now=161;stamp=1800000061;testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert b.globals().sounds==1
base['command'](b,'sound on')
b.execute('now=222;stamp=1800000122;ForeverKoS.SetSightingMute("Enemy",1);testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert b.globals().sounds==1
base['command'](b,'test');assert b.globals().sounds==2
# A different player reported in our zone is audible; other zones remain silent.
b.execute("\nnow=300;stamp=1800000200\nlocal db=ForeverKoS.SightingContext()\ndb.records['second enemy']={name='Second Enemy',reason='Test',editor='Alice',rev=2,deleted=false}\nC_Map.GetBestMapForUnit=function()return 1944 end\n")
base['packet'](b,'S\t1800000200\tSecond Enemy\t1944\t25000\t75000\tAlice','Alice')
assert b.globals().sounds==3
# Zone-name fallback covers differing map IDs for the same named zone.
b.execute('C_Map.GetBestMapForUnit=function()return 999 end;function GetRealZoneText()return "Hellfire Peninsula" end')
assert b.globals().ForeverKoS.SightingInMyZone(b.globals().ForeverKoS.GetSighting('Second Enemy'))
assert not b.globals().ForeverKoS.SightingInMyZone(b.table_from({'map':0}))

print('PASS: local-only sound with shared visual alerts, remote-first/local-second ordering, repeat cooldown, master sound/mute and test preview.')
# Settings control saves both choices.
u=runpy.run_path('tests/test_nearby.py')['r']
u.execute('\nInTheBinKoSSettings.localSound.GetChecked=function()return true end\nInTheBinKoSSettings.localSound.scripts.OnClick(InTheBinKoSSettings.localSound)\nassert(ForeverKoS.Settings().sightingSoundSameZoneOnly==true)\nInTheBinKoSSettings.localSound.GetChecked=function()return false end\nInTheBinKoSSettings.localSound.scripts.OnClick(InTheBinKoSSettings.localSound)\nassert(ForeverKoS.Settings().sightingSoundSameZoneOnly==false)\n')
