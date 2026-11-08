import runpy
ns=runpy.run_path('tests/test_presence.py')
base=ns['base']
def messages(r):
    return [str(s) for s in r.globals().notices.values() if 'Update available:' in str(s)]
r=ns['client']('Member')
r.execute('C_AddOns={GetAddOnMetadata=function()return "0.5.9" end}')
for value in ('0.5.9','0.5.8','0.5.10-beta.1','garbage'):
    base['packet'](r,'V\t'+value,'Alice')
assert not messages(r)
base['packet'](r,'V\t0.5.10','Outsider')
assert not messages(r)
base['packet'](r,'V\t0.5.10','Alice')
assert len(messages(r))==1 and 'you have 0.5.9' in messages(r)[0]
base['packet'](r,'V\t0.5.10','Bob')
base['packet'](r,'V\t0.5.12','Alice')
assert len(messages(r))==1
assert not r.globals().ForeverKoS.CanAdminGuildAccess()
for installed,remote in [('0.5.12','0.6.0'),('0.9.99','1.0.0'),('0.5.12-beta.1','0.5.12')]:
    r=ns['client']('Member')
    r.globals().installedTestVersion=installed
    r.execute('C_AddOns={GetAddOnMetadata=function()return installedTestVersion end}')
    base['packet'](r,'V\t'+remote,'Alice')
    assert len(messages(r))==1
print('PASS: member update notice, numeric versions, prerelease handling, outsider rejection and once-per-session throttling.')

old,new=ns['client']('Member'),ns['client']('Alice')
old.execute('C_AddOns={GetAddOnMetadata=function()return "0.5.12" end}')
new.execute('C_AddOns={GetAddOnMetadata=function()return "0.5.13" end}')
login=base['sent'](old)
assert sum(msg=='P' for _,msg,_,_ in login)==1
# A newly logged-in peer replies even if it just announced its own version.
base['sent'](new)
for _,msg,ch,_ in login:base['packet'](new,msg,'Member',ch)
base['deliver'](new,old,'Alice')
assert len(messages(old))==1 and '0.5.13' in messages(old)[0]
old.execute('testFrame.OnEvent(testFrame,"GUILD_ROSTER_UPDATE")')
assert not any(msg=='P' for _,msg,_,_ in base['sent'](old))
print('PASS: automatic member login query, immediate peer reply and no repeated roster queries.')
