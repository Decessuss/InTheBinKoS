import runpy
from pathlib import Path
ns=runpy.run_path('tests/test_sightings.py')
base=ns['ns']
a,m=ns['client']('Alice'),ns['client']('Member')
for r in (a,m):
    r.execute('''
members[1][1]="Alice Officer";members[3][1]="Member Tester"
units.player.name=playerName=="Alice" and "Alice Officer" or "Member Tester"
units.mouseover={name="Enemy Person",faction="Horde"}
testFrame.OnEvent(testFrame,"GUILD_ROSTER_UPDATE")
''')
api=a.globals().ForeverKoS
assert api.NormalizeName('  Enemy   Person  ')=='Enemy Person'
assert api.NameKey('ENEMY PERSON')=='enemy person'
assert api.DisplayName('Enemy Person')=='Enemy Person'
for invalid in ['Enemy\tPerson','Enemy\nPerson','Enemy|Person','']:
    assert api.NormalizeName(invalid) is None,repr(invalid)
base['command'](a,'add "Enemy Person" Camping again')
assert base['records'](a)['enemy person'].reason=='Camping again'
base['deliver'](a,m,'Alice Officer')
assert base['records'](m)['enemy person'].name=='Enemy Person'
m.execute('testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")')
assert m.globals().sounds==1
base['deliver'](m,a,'Member Tester')
assert api.GetSighting('Enemy Person').spotter=='Member Tester'
assert a.globals().sounds==1
assert 'Enemy Person' in list(a.globals().scans[1].values())
api.SetEditor('Member Tester',True)
base['deliver'](a,m,'Alice Officer')
assert m.globals().ForeverKoS.GetState()[1]
base['command'](m,'add "Another Enemy" Delegated edit')
base['deliver'](m,a,'Member Tester')
assert base['records'](a)['another enemy'].reason=='Delegated edit'
base['command'](a,'remove "Enemy Person"')
base['deliver'](a,m,'Alice Officer')
assert base['records'](m)['enemy person'].deleted
base['command'](a,'add "Unclosed Name')
assert base['records'](a)['unclosed'] is None
# Personal mode shares quoted-name parsing, and never sends guild edits.
m.execute('savedCoreFrame=testFrame')
m.execute(Path('Personal.lua').read_text(encoding='utf-8'))
m.execute('testFrame=savedCoreFrame')
base['sent'](m)
base['command'](m,'personal')
base['command'](m,'add "Friendly Person" Avoid grouping')
rows=m.globals().ForeverKoS.GetState()[0]
assert rows[1].name=='Friendly Person' and rows[1].reason=='Avoid grouping'
assert not base['sent'](m)
base['command'](m,'remove "Friendly Person"')
assert len(m.globals().ForeverKoS.GetState()[0])==0
print('PASS: full-name normalization, quoted commands, guild sync, mouseover, shared sighting/aura, named grants and private lists.')

