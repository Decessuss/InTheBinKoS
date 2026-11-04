import runpy
from pathlib import Path
ns=runpy.run_path('tests/test_sightings.py')
base=ns['ns']
a,m=ns['client']('Alice'),ns['client']('Member')
for r in (a,m):
    r.execute('''
members[1][1]="Alice Officer-Realm";members[3][1]="Member Tester-Realm"
units.player.name=playerName=="Alice-Realm" and "Alice Officer-Realm" or "Member Tester-Realm"
units.mouseover={name="Enemy Person-Realm",faction="Horde"}
testFrame.OnEvent(testFrame,"GUILD_ROSTER_UPDATE")
''')
api=a.globals().ForeverKoS
assert api.NormalizeName('  Enemy   Person  ')=='Enemy Person-Realm'
assert api.NameKey('ENEMY PERSON')=='enemy person-realm'
assert api.DisplayName('Enemy Person-Realm')=='Enemy Person'
for invalid in ['Enemy\tPerson','Enemy\nPerson','Enemy|Person','Enemy Person-','-Realm','Enemy -Realm','Enemy Person-Bad Realm']:
    assert api.NormalizeName(invalid) is None,repr(invalid)
base['command'](a,'add "Enemy Person" Camping again')
assert base['records'](a)['enemy person-realm'].reason=='Camping again'
base['deliver'](a,m,'Alice Officer-Realm')
assert base['records'](m)['enemy person-realm'].name=='Enemy Person-Realm'
m.execute('testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")')
assert m.globals().sounds==1
base['deliver'](m,a,'Member Tester-Realm')
assert api.GetSighting('Enemy Person').spotter=='Member Tester-Realm'
assert a.globals().sounds==1
assert 'Enemy Person-Realm' in list(a.globals().scans[1].values())
api.SetEditor('Member Tester',True)
base['deliver'](a,m,'Alice Officer-Realm')
assert m.globals().ForeverKoS.GetState()[1]
base['command'](m,'add "Another Enemy" Delegated edit')
base['deliver'](m,a,'Member Tester-Realm')
assert base['records'](a)['another enemy-realm'].reason=='Delegated edit'
base['command'](a,'remove "Enemy Person"')
base['deliver'](a,m,'Alice Officer-Realm')
assert base['records'](m)['enemy person-realm'].deleted
base['command'](a,'add "Unclosed Name')
assert base['records'](a)['unclosed-realm'] is None
# Personal mode shares quoted-name parsing, and never sends guild edits.
m.execute('savedCoreFrame=testFrame')
m.execute(Path('Personal.lua').read_text(encoding='utf-8'))
m.execute('testFrame=savedCoreFrame')
base['sent'](m)
base['command'](m,'personal')
base['command'](m,'add "Friendly Person" Avoid grouping')
rows=m.globals().ForeverKoS.GetState()[0]
assert rows[1].name=='Friendly Person-Realm' and rows[1].reason=='Avoid grouping'
assert not base['sent'](m)
base['command'](m,'remove "Friendly Person"')
assert len(m.globals().ForeverKoS.GetState()[0])==0
print('PASS: full-name normalization, quoted commands, guild sync, mouseover, shared sighting/aura, named grants and private lists.')

