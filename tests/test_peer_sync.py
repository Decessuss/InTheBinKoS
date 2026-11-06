import runpy
ns=runpy.run_path('tests/test_kos.py')
client,command,packet,sent=ns['client'],ns['command'],ns['packet'],ns['sent']
a,m,n=client('Alice'),client('Member'),client('Listener')
for r in (a,m,n): sent(r)
command(a,'add Enemy First')
old=sent(a)
for _,msg,channel,_ in old: packet(m,msg,'Alice',channel)
# Alice is now offline: a regular member serves its cache to another member.
packet(m,'Q','Listener')
cached=sent(m)
assert cached and all(msg.startswith('C\t') and channel=='WHISPER' for _,msg,channel,_ in cached)
for _,msg,channel,_ in cached: packet(n,msg,'Member',channel)
assert ns['records'](n)['enemy'].reason=='First'
command(n,'remove Enemy')
assert not ns['records'](n)['enemy'].deleted
# Request cooldown and stale caches do not resurrect a removed entry.
command(a,'remove Enemy')
for _,msg,channel,_ in sent(a): packet(n,msg,'Alice',channel)
for _,msg,channel,_ in cached: packet(n,msg,'Member',channel)
assert ns['records'](n)['enemy'].deleted
packet(n,cached[0][1],'Stranger','WHISPER')
assert ns['records'](n)['enemy'].deleted
packet(n,'C\t999\tAlice\t0\tGuildbroadcast\tNo','Member','GUILD')
assert ns['records'](n)['guildbroadcast'] is None
print('PASS: member-to-member cached list sync without an online officer; editing remains denied; tombstone wins over older peer; non-guild sender and unsolicited guild cache broadcasts rejected.')
