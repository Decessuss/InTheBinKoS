import runpy
ns=runpy.run_path('tests/test_kos.py')
a,b=[ns['client'](name) for name in ('Member','Listener')]
for r in (a,b):
    r.execute('''
members[3][1]="Decessuss Reaper"
if playerName=="Member" then units.player.name="Decessuss Reaper" end
testFrame.OnEvent(testFrame,"GUILD_ROSTER_UPDATE")
''')
    ns['sent'](r)
api=a.globals().ForeverKoS
assert api.CanAdminGuildAccess() and api.CanEditShared()
assert api.SharedAccessLabel('Decessuss Reaper')=='Addon administrator'
assert not b.globals().ForeverKoS.CanAdminGuildAccess()
api.SetEditor('Listener',True)
ns['deliver'](a,b,'Decessuss Reaper')
assert b.globals().ForeverKoS.CanEditShared()
ns['deliver'](b,a,'Listener')
assert api.GetGrantDelivery('Listener').status=='Confirmed by recipient addon'
ns['command'](a,'add Enemy Admin edit')
ns['deliver'](a,b,'Decessuss Reaper')
assert ns['records'](b)['enemy'].reason=='Admin edit'
api.SetEditor('Listener',False)
ns['deliver'](a,b,'Decessuss Reaper')
assert not b.globals().ForeverKoS.CanEditShared()
# Similar names have no exception; guild membership remains required.
assert api.SharedAccessLabel('Decessuss Other')=='Member'
b.execute('members[3]=nil;members[4]=nil;testFrame.OnEvent(testFrame,"GUILD_ROSTER_UPDATE")')
ns['packet'](b,'G\t999\tDecessuss Reaper\t0\tListener','Decessuss Reaper')
assert not b.globals().ForeverKoS.CanEditShared()
a.execute('guildName=nil;testFrame.OnEvent(testFrame,"PLAYER_GUILD_UPDATE")')
assert not api.CanAdminGuildAccess()
print('PASS: named administrator controls, peer edit/grant/revoke acceptance and ACK; unrelated names and non-guild senders rejected.')
