import runpy
ns=runpy.run_path('tests/test_sightings.py');base=ns['ns']
r=ns['client']('Alice');api=r.globals().ForeverKoS
base['sent'](r)
# Build a full cached snapshot without dispatching it.
r.execute("""
local db=ForeverKoS.SightingContext()
for i=1,1000 do db.records['enemy '..i]={name='Enemy '..i,reason='Cached',editor='Alice',rev=i,deleted=false}end
""")
base['packet'](r,'Q','Member')
api.QueueSighting('S\t1800000000\tEnemy 1\t1944\t25000\t75000\tAlice')
r.execute('testFrame.OnUpdate(testFrame,0.21)')
assert r.globals().outgoing[1][2].startswith('S\t')
assert r.globals().outgoing[1][3]=='GUILD'
# Requests arriving a minute later must not append another pending snapshot.
r.execute('now=161')
base['packet'](r,'Q','Member')
base['command'](r,'status')
assert 'queued messages: 1000' in r.globals().notices[len(r.globals().notices)-1]
# Repeated exact queued packets are coalesced by destination.
for _ in range(20): api.QueuePresence('V\t0.6.2')
base['command'](r,'status')
assert 'queued messages: 1001' in r.globals().notices[len(r.globals().notices)-1]
# Only the latest live position per enemy is needed.
api.QueueSighting('S\t1800000001\tEnemy 2\t1944\t25000\t75000\tAlice')
api.QueueSighting('S\t1800000002\tEnemy 2\t1944\t26000\t75000\tAlice')
r.execute('testFrame.OnUpdate(testFrame,0.21)')
assert '1800000002' in r.globals().outgoing[2][2]
# A stale live report must never be sent after its alert validity window.
api.QueueSighting('S\t1800000003\tEnemy 3\t1944\t25000\t75000\tAlice')
r.execute('now=200;testFrame.OnUpdate(testFrame,0.21)')
assert not r.globals().outgoing[3][2].startswith('S\t')
# Guild change discards queues and their dedup indexes together.
r.execute('guildName="Other";testFrame.OnEvent(testFrame,"PLAYER_GUILD_UPDATE")')
api.QueueSighting('S\t1800000003\tEnemy 3\t1944\t25000\t75000\tAlice')
r.execute('testFrame.OnUpdate(testFrame,0.21)')
assert r.globals().outgoing[4][2].startswith('S\t')
print('PASS: live sighting priority over large snapshots, pending-sync suppression, exact dedup, latest-position coalescing, stale-report expiry and guild-reset isolation.')
