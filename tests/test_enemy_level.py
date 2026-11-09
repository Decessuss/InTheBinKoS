import runpy
ns=runpy.run_path('tests/test_sightings.py')
base=ns['ns']
a,b=ns['client']('Alice'),ns['client']('Member')
base['command'](a,'add target Level test')
base['deliver'](a,b,'Alice')
a.execute('function UnitLevel()return 60 end;testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert 'Level 60' in str(a.globals().notices[len(a.globals().notices)])
assert a.globals().scans[1][6]==60 and 'Level 60' in a.globals().scans[1][3]
base['deliver'](a,b,'Alice')
assert b.globals().ForeverKoS.GetSighting('Enemy').level==60
assert 'Level 60' in str(b.globals().notices[len(b.globals().notices)])
assert b.globals().scans[1][6]==60
a.execute('now=161;stamp=1800000061;function UnitLevel()return -1 end;testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
base['deliver'](a,b,'Alice')
assert 'Level ??' in str(a.globals().notices[len(a.globals().notices)])
assert b.globals().ForeverKoS.GetSighting('Enemy').level==-1
# Historical/legacy packets still work and invalid levels cannot overwrite data.
base['packet'](b,'S\t1800000062\tEnemy\t1944\t10000\t20000\tAlice\tL:1001','Alice')
assert b.globals().ForeverKoS.GetSighting('Enemy').level==-1
base['packet'](b,'S\t1800000063\tEnemy\t1944\t10000\t20000\tAlice','Alice')
assert b.globals().ForeverKoS.GetSighting('Enemy').level is None
print('PASS: local/shared enemy level, existing aura reason display, unknown level, legacy packets and invalid level rejection.')
