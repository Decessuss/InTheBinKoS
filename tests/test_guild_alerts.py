import runpy
ns=runpy.run_path('tests/test_sightings.py')
client=ns['client'];base=ns['ns']
a,b=client('Alice'),client('Member')
base['command'](a,'add target Guild alert')
base['deliver'](a,b,'Alice')
a.execute('testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
msgs=base['sent'](a)
for _,msg,ch,_ in msgs:base['packet'](b,msg,'Alice',ch)
assert b.globals().sounds==1 and len(b.globals().scans)==1
assert b.globals().scans[1][1]=='FOREVER_KOS_SPOTTED'
assert b.globals().scans[1][4]=='Hellfire Peninsula'
assert b.globals().scans[1][5]=='Alice'
assert 'spotted by Alice' in b.globals().notices[len(b.globals().notices)]
assert '1944:25000:75000' in b.globals().notices[len(b.globals().notices)]
for _,msg,ch,_ in msgs:base['packet'](b,msg,'Alice',ch)
assert b.globals().sounds==1
b.execute('now=161;stamp=1800000061')
base['packet'](b,'H\t1800000061\tEnemy\t1944\t10000\t20000\tAlice','Alice','WHISPER')
assert b.globals().sounds==1
base['packet'](b,'S\t1800000062\tEnemy\t1944\t30000\t40000\tListener','Listener')
assert b.globals().sounds==2
b.execute('now=230;stamp=1800000200')
base['packet'](b,'S\t1800000100\tEnemy\t1944\t30000\t40000\tListener','Listener')
assert b.globals().sounds==2
base['command'](b,'alerts off')
base['packet'](b,'S\t1800000200\tEnemy\t1944\t30000\t40000\tListener','Listener')
assert b.globals().sounds==2
assert b.globals().ForeverKoS.GetSighting('Enemy').stamp==1800000200
print('PASS: fresh guild report triggers recipient chat/sound/aura with original spotter and correct location; duplicates, history, old reports and muted alerts stay silent.')
