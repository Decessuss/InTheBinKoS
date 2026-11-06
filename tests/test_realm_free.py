import runpy
ns=runpy.run_path('tests/test_kos.py')
clients=[ns['client']('Bob'),ns['client']('Member')]
for r,name in zip(clients,['Oven Baked','Decessuss Reaper']):
    r.globals().testCharacter=name
    r.execute('''
guildName="in the bin"
units.player.name=testCharacter
function UnitFullName(unit)
 local v=units[unit];if not v then return end
 return v.name:match("^(%S+) (.+)$")
end
members={{"Oven Baked-CAMWOWAU1Realm2PvP",1},{"Decessuss Reaper-Another Realm",4}}
testFrame.OnEvent(testFrame,"GUILD_ROSTER_UPDATE")
''')
    ns['sent'](r)
a,b=clients
assert a.globals().ForeverKoS.CanManageAccess()
assert not b.globals().ForeverKoS.GetState()[1]
a.globals().ForeverKoS.SetEditor('Decessuss Reaper',True)
ns['deliver'](a,b,'Oven Baked-DifferentRealm')
assert b.globals().ForeverKoS.GetState()[1]
ns['deliver'](b,a,'Decessuss Reaper-YetAnotherRealm')
assert a.globals().ForeverKoS.GetGrantDelivery('Decessuss Reaper').status=='Confirmed by recipient addon'
a.globals().ForeverKoS.SetEditor('Decessuss Reaper-OldRealm',False)
ns['deliver'](a,b,'Oven Baked')
assert not b.globals().ForeverKoS.GetState()[1]
ns['packet'](b,'G\t999\tStranger\t0\tDecessuss Reaper','Stranger-Realm')
assert not b.globals().ForeverKoS.GetState()[1]
assert b.globals().ForeverKoS.NormalizeName('  Decessuss   Reaper-CAMWOWAU1Realm2PvP')=='Decessuss Reaper'
print('PASS: exact officer/member names with mixed realm formats; grant, automatic acknowledgement, revocation and outsider rejection.')

# Upgrade a saved guild list without losing records or revocations.
from lupa.lua51 import LuaRuntime
r=LuaRuntime(unpack_returned_tuples=True)
r.execute(ns['mock'],'Member')
r.execute('''
ForeverKoSDB={guilds={['Guild@OldRealm']={clock=12,records={
 ['enemy-oldrealm']={name='Enemy-OldRealm',editor='Bob-OldRealm',rev=10,reason='Keep me'}},
 grants={['member-oldrealm']={name='Member-OldRealm',editor='Bob-OldRealm',rev=12,deleted=true}},
 sightings={['enemy-oldrealm']={name='Enemy-OldRealm',spotter='Bob-OldRealm',stamp=123}}}}}
''')
r.execute(ns['source'])
r.execute('testFrame.OnEvent(testFrame,"ADDON_LOADED","ForeverKoS");testFrame.OnEvent(testFrame,"PLAYER_LOGIN")')
saved=r.globals().ForeverKoSDB.guilds
assert saved['Guild'].records['enemy'].reason=='Keep me'
assert saved['Guild'].records['enemy'].editor=='Bob'
assert saved['Guild'].grants['member'].deleted
assert saved['Guild'].sightings['enemy'].spotter=='Bob'
assert saved['Guild'].clock==12
assert saved['Guild@OldRealm'].records['enemy-oldrealm'].name=='Enemy-OldRealm'
assert not r.globals().ForeverKoS.GetState()[1]
print('PASS: saved guild record, revocation and sighting migration; legacy snapshot retained.')
