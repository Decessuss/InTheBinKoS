import runpy
ns=runpy.run_path('tests/test_kos.py')
client,command,packet,records,sent=map(ns.get,['client','command','packet','records','sent'])
# Native own-player officer status repairs a false/unavailable cached rank lookup.
a=client('Bob')
a.execute('''
C_GuildInfo.GuildControlGetRankFlags=function() return {} end
C_GuildInfo.IsGuildOfficer=function() return true end
''')
assert a.globals().ForeverKoS.CanManageAccess()
assert a.globals().ForeverKoS.GetState()[1]
command(a,'add NativeOwner Native officer access')
assert records(a)['nativeowner'].reason=='Native officer access'
# The local native query must never authorize another member's edits/grants.
packet(a,'R\t900\tListener\t0\tForged\tNo','Listener')
packet(a,'G\t900\tListener\t0\tMember','Listener')
assert records(a)['forged'] is None
assert len(a.globals().ForeverKoSDB.guilds['Guild'].grants)==0
# Native officer works before the own-player roster row has arrived.
a.execute('members={{"Member",2}};testFrame.OnEvent(testFrame,"GUILD_ROSTER_UPDATE")')
assert a.globals().ForeverKoS.CanManageAccess()
a.execute('C_GuildInfo.IsGuildOfficer=function()return false end')
assert not a.globals().ForeverKoS.CanManageAccess()
# GUID rank order differs from the legacy roster rank index.
b=client('Member')
b.execute('''
C_GuildInfo.IsGuildOfficer=function()return false end
local old=GetGuildRosterInfo
GetGuildRosterInfo=function(i)
 local n,r,rank=old(i)
 return n,r,rank,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,n=="Bob" and "OfficerGUID" or nil
end
C_GuildInfo.GetGuildRankOrder=function(guid) if guid=="OfficerGUID" then return 2 end end
-- Simulate a legacy index that no longer agrees with the modern order.
members[2][2]=7
testFrame.OnEvent(testFrame,"GUILD_ROSTER_UPDATE")
''')
packet(b,'R\t20\tBob\t0\tEnemy\tGUID officer','Bob')
assert records(b)['enemy'].reason=='GUID officer'
packet(b,'G\t21\tBob\t0\tMember','Bob')
assert b.globals().ForeverKoS.GetState()[1]
# Demotion/rank changes take effect immediately, not from a saved officer cache.
b.execute('C_GuildInfo.GetGuildRankOrder=function()return 8 end;testFrame.OnEvent(testFrame,"GUILD_RANKS_UPDATE")')
packet(b,'R\t22\tBob\t1\tEnemy\t','Bob')
assert not records(b)['enemy'].deleted
command(b,'status')
assert any('native officer=' in str(s) for s in b.globals().notices.values())
print('PASS: native officer UI/access, unloaded own roster, GUID rank-order sender validation, spoof rejection and demotion.')
