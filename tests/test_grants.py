import runpy
ns=runpy.run_path('tests/test_kos.py')
client,command,packet,sent=ns['client'],ns['command'],ns['packet'],ns['sent']
a,m,n=client('Alice'),client('Member'),client('Listener')
for r in (a,m,n):sent(r)
assert not m.globals().ForeverKoS.GetState()[1]
packet(m,'G\t999\tAlice\t0\tMember','Listener')
assert not m.globals().ForeverKoS.GetState()[1]
a.globals().ForeverKoS.SetEditor('Member',True)
grant=sent(a)
assert any(msg.startswith('G\t') for _,msg,_,_ in grant)
for r in (m,n):
    for _,msg,ch,_ in grant:packet(r,msg,'Alice',ch)
assert m.globals().ForeverKoS.GetState()[1]
assert not m.globals().ForeverKoS.CanManageAccess()
command(m,'add target Granted editor')
updates=sent(m)
for _,msg,ch,_ in updates:packet(n,msg,'Member',ch)
assert ns['records'](n)['enemy'].reason=='Granted editor'
m.globals().ForeverKoS.SetEditor('Listener',True)
assert not sent(m)
assert not n.globals().ForeverKoS.GetState()[1]
a.globals().ForeverKoS.SetEditor('Member',False)
revoke=sent(a)
for _,msg,ch,_ in revoke:packet(m,msg,'Alice',ch)
assert not m.globals().ForeverKoS.GetState()[1]
for _,msg,ch,_ in grant:packet(m,msg,'Alice',ch)
assert not m.globals().ForeverKoS.GetState()[1]
command(m,'remove Enemy')
assert not ns['records'](m)['enemy'].deleted
print('PASS: officers grant/revoke named guild editors; delegated list edits sync; delegates cannot grant; forged grants rejected; old grant cannot undo revocation.')
