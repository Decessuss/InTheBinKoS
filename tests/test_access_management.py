import runpy
ns=runpy.run_path('tests/test_presence.py')
client,base=ns['client'],ns['base']
a,m=client('Alice'),client('Member')
for r in (a,m):base['sent'](r)
a.globals().ForeverKoS.SetEditor('Member',True)
assert a.globals().ForeverKoS.GetGrantDelivery('Member').status=='Waiting for recipient addon'
base['deliver'](a,m,'Alice');base['deliver'](m,a,'Member')
assert m.globals().ForeverKoS.GetState()[1]
assert a.globals().ForeverKoS.GetGrantDelivery('Member').status=='Confirmed by recipient addon'
a.globals().ForeverKoS.ToggleAccessFilter()
editors=a.globals().ForeverKoS.GetAddonUsers()
member=next(row for row in editors.values() if row.name=='Member')
assert member.access=='Granted editor' and not member.detected and 'YES' in member.reason
# The explicit editors view includes offline grantees, unlike Addon Users.
a.execute('''
local old=GetGuildRosterInfo
GetGuildRosterInfo=function(i)local n,r,k=old(i);return n,r,k,nil,nil,nil,nil,nil,n~="Member" end
''')
assert any(row.name=='Member' for row in a.globals().ForeverKoS.GetAddonUsers().values())
a.globals().ForeverKoS.SetEditor('Member',False)
base['deliver'](a,m,'Alice');base['deliver'](m,a,'Member')
assert not m.globals().ForeverKoS.GetState()[1]
assert not any(row.name=='Member' for row in a.globals().ForeverKoS.GetAddonUsers().values())
# A locally recognized officer whose rank flags are missing on the peer is explicitly rejected.
officer,peer=client('Bob'),client('Member')
for r in (officer,peer):base['sent'](r)
officer.execute('C_GuildInfo.IsGuildOfficer=function()return true end')
peer.execute('C_GuildInfo.GuildControlGetRankFlags=function()return {} end')
officer.globals().ForeverKoS.SetEditor('Member',True)
base['deliver'](officer,peer,'Bob');base['deliver'](peer,officer,'Member')
assert not peer.globals().ForeverKoS.GetState()[1]
assert 'Rejected:' in officer.globals().ForeverKoS.GetGrantDelivery('Member').status
# Officer navigation must remain visible while viewing the Personal List.
u=ns['u']
u.execute('''
ForeverKoS.SetUsersMode(false);ForeverKoS.SetPersonalMode(true)
ForeverKoSWindow.scripts.OnShow()
local tab
for _,f in ipairs(frames) do if rawget(f,"text")=="Users & Access" then tab=f end end
assert(tab and tab.shown)
tab.scripts.OnClick()
assert(ForeverKoS.IsUsersMode() and not ForeverKoS.IsPersonalMode())
''')
print('PASS: confirmed grants/revocations, visible YES/NO access, offline editor list, explicit peer rejection and Personal-mode navigation.')
