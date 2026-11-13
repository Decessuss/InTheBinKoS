import runpy
ns=runpy.run_path('tests/test_sightings.py');base=ns['ns']
a,b=ns['client']('Alice'),ns['client']('Member')
for r in (a,b):r.execute('RAID_CLASS_COLORS={MAGE={r=0.25,g=0.78,b=0.92}}')
base['command'](a,'add target Class test');base['deliver'](a,b,'Alice')
a.execute('function UnitClass()return "Mage","MAGE" end;testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
assert '|cff40c7ebEnemy|r' in a.globals().notices[len(a.globals().notices)]
base['deliver'](a,b,'Alice')
assert b.globals().ForeverKoS.GetSighting('Enemy').classToken=='MAGE'
assert '|cff40c7ebEnemy|r' in b.globals().notices[len(b.globals().notices)]
# Aura names remain plain, and legacy sighting packets remain unchanged.
assert b.globals().scans[1][2]=='Enemy'
assert a.globals().ForeverKoS.ClassColoredName('Enemy',None)=='Enemy'
assert a.globals().ForeverKoS.ClassColoredName('Priest Name','PRIEST')=='|cffbfbfbfPriest Name|r'
base['packet'](b,'I\t1800000000\tEnemy\tINVENTED','Alice')
assert b.globals().ForeverKoS.GetSighting('Enemy').classToken=='MAGE'
base['packet'](b,'I\t1800000000\tEnemy\tMAGE','Stranger')
print('PASS: local/shared class-colored chat, sender-bound metadata, invalid class rejection, plain aura payload and no-class fallback.')
