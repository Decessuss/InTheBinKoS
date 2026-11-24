import runpy
ns=runpy.run_path('tests/test_kos.py')
r=ns['client']('Alice');api=r.globals().ForeverKoS
ns['sent'](r)
r.execute("""
onlineFlags={Member=true,Listener=true}
local oldRoster=GetGuildRosterInfo
function GetGuildRosterInfo(i)
 local n,rank,index=oldRoster(i)
 return n,rank,index,nil,nil,nil,nil,nil,onlineFlags[n]
end
ERR_CHAT_PLAYER_NOT_FOUND_S="No player named '%s' is currently playing."
""")
# One recipient logs off while a large snapshot for them is still queued.
for i in range(100): api.QueueGuildTarget('C\t'+str(i)+'\tAlice\t0\tEnemy '+str(i)+'\tTest','Member')
api.QueueGuildTarget('C\t1\tAlice\t0\tOther Enemy\tTest','Listener')
r.execute('onlineFlags.Member=false')
msgs=ns['sent'](r)
assert len(msgs)==1 and msgs[0][3]=='Listener'
# Explicitly offline targets cannot refill the queue.
api.QueueGuildTarget('C\t2\tAlice\t0\tEnemy\tTest','Member')
assert ns['sent'](r)==[]
# A stale roster can say online; the server failure then cancels the remainder.
r.execute('onlineFlags.Member=true;now=200')
for i in range(10):api.QueueGuildTarget('C\t'+str(i)+'\tAlice\t0\tTest '+str(i)+'\tReason','Member')
r.execute('testFrame.OnUpdate(testFrame,0.21)')
r.globals().testFrame.OnEvent(r.globals().testFrame,"CHAT_MSG_SYSTEM", "No player named 'Member' is currently playing.")
assert len(ns['sent'](r))==1  # The initial failed attempt, but none of the remaining nine.
api.QueueGuildTarget('C\t99\tAlice\t0\tEnemy\tTest','Member')
assert ns['sent'](r)==[]
# Guild traffic continues, and the block expires rather than permanently blacklisting.
api.QueuePresence('V\t0.6.4')
assert ns['sent'](r)[0][2]=='GUILD'
r.execute('now=261')
api.QueueGuildTarget('C\t100\tAlice\t0\tEnemy\tTest','Member')
assert ns['sent'](r)[0][3]=='Member'
# Unrelated system messages do not cancel another recipient's queue.
api.QueueGuildTarget('C\t101\tAlice\t0\tEnemy\tTest','Listener')
api.HandleOfflineSystemMessage("No player named 'Stranger' is currently playing.")
assert ns['sent'](r)[0][3]=='Listener'
print('PASS: offline recipient cancellation, stale-roster server errors, temporary backoff, unrelated-message isolation and unaffected online/guild delivery.')
