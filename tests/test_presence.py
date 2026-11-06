import runpy
from pathlib import Path
ns=runpy.run_path('tests/test_guild_targets.py');base=ns['base']
def client(name):
    r=ns['client'](name)
    r.execute('''
local old=GetGuildRosterInfo
GetGuildRosterInfo=function(i)
 local n,rank,index=old(i)
 return n,rank,index,nil,nil,nil,nil,nil,true
end
''')
    r.execute('savedCoreFrame=testFrame')
    r.execute(Path('Personal.lua').read_text(encoding='utf-8'))
    r.execute('testFrame=savedCoreFrame')
    r.execute(Path('Presence.lua').read_text(encoding='utf-8'))
    r.execute('testFrame.OnEvent(testFrame,"GUILD_ROSTER_UPDATE")')
    return r
# Real addon packets, including ordinary-member replies through the send queue.
a,m,n=client('Alice'),client('Member'),client('Listener')
for r in (a,m,n):base['sent'](r)
a.globals().ForeverKoS.RequestAddonUsers()
base['deliver'](a,m,'Alice-Realm')
m.execute('now=140')
a.execute('now=140')
base['packet'](m,'P','Alice-Realm')
reply=base['sent'](m)
assert any(msg=='V\t0.5.8' for _,msg,_,_ in reply)
for _,msg,ch,_ in reply:base['packet'](a,msg,'Member-Realm',ch)
rows=a.globals().ForeverKoS.GetAddonUsers()
member=next(row for row in rows.values() if row.name=='Member-Realm')
assert not any(row.name=='Listener-Realm' for row in rows.values())
assert member.version=='0.5.8' and member.detected and member.access=='Member'

assert len(m.globals().ForeverKoS.GetAddonUsers())==0
m.globals().ForeverKoS.SetUsersMode(True)
assert not m.globals().ForeverKoS.IsUsersMode()
assert not m.globals().ForeverKoS.CanManageAccess()
# Presence claims never confer edit/grant rights; outsiders/malformed data ignored.
base['packet'](m,'V\t0.5.6','Listener-Realm')
assert not m.globals().ForeverKoS.GetState()[1]
base['packet'](a,'V\t9.9.9','Outsider-Realm')
base['packet'](a,'V\tbad\tforged','Listener-Realm')
assert not any(row.name=='Listener-Realm' for row in a.globals().ForeverKoS.GetAddonUsers().values())
# Existing officer controls applied to a discovered user synchronize normally.
a.globals().ForeverKoS.SetEditor(member.name,True)
base['deliver'](a,m,'Alice-Realm')
assert m.globals().ForeverKoS.GetState()[1]
assert not m.globals().ForeverKoS.CanManageAccess()
a.globals().ForeverKoS.SetEditor(member.name,False)
base['deliver'](a,m,'Alice-Realm')
assert not m.globals().ForeverKoS.GetState()[1]
# Session reports expire and disappear when the roster marks the member offline.
a.execute('now=900')
assert not any(row.name=='Member-Realm' for row in a.globals().ForeverKoS.GetAddonUsers().values())
a.execute('''
local old=GetGuildRosterInfo
GetGuildRosterInfo=function(i) local n,r,k=old(i);return n,r,k,nil,nil,nil,nil,nil,n~="Member-Realm" end
''')
assert not any(row.name=='Member-Realm' for row in a.globals().ForeverKoS.GetAddonUsers().values())
# Guild switch resets discovery. Demotion closes officer-only view immediately.
a.globals().ForeverKoS.SetUsersMode(True)
assert a.globals().ForeverKoS.IsUsersMode()
a.execute('members[1][2]=3;testFrame.OnEvent(testFrame,"GUILD_RANKS_UPDATE")')
assert not a.globals().ForeverKoS.IsUsersMode()
print('PASS: version discovery, member replies, officer-only view, unknown/offline/expired states, spoof rejection and named grants.')

# Exercise the actual UI row selection and Grant/Revoke buttons.
u=ns['a']
u.execute("ForeverKoS.SetPersonalMode(false);ForeverKoS.SetGuildMode(false)")
u.execute(Path('Presence.lua').read_text(encoding='utf-8'))
u.execute('ForeverKoS.ReceivePresence("V\\t0.5.8","Member-Realm","GUILD")')
u.execute(''' 
local old=GetGuildRosterInfo
GetGuildRosterInfo=function(i)local n,r,k=old(i);return n,r,k,nil,nil,nil,nil,nil,true end
ForeverKoS.PresenceChanged()
for _,f in ipairs(frames) do if rawget(f,"text")=="Users & Access" then f.scripts.OnClick() end end
assert(ForeverKoS.IsUsersMode())
local selectedRow
for _,f in ipairs(frames) do
 local r=rawget(f,"record")
 if r and r.name=="Member-Realm" then selectedRow=f end
end
assert(selectedRow);selectedRow.scripts.OnClick(selectedRow,"LeftButton")
local filled=false
for _,f in ipairs(frames) do
 if rawget(f,"template")=="InputBoxTemplate" and f:GetText()=="Member-Realm" then filled=true end
end
assert(filled)
for _,f in ipairs(frames) do if rawget(f,"text")=="Grant Access" then f.scripts.OnClick() end end
assert(ForeverKoS.SharedAccessLabel("Member-Realm")=="Granted editor")
for _,f in ipairs(frames) do if rawget(f,"text")=="Revoke Access" then f.scripts.OnClick() end end
assert(ForeverKoS.SharedAccessLabel("Member-Realm")=="Member")
''')
print('PASS: selecting an Addon Users row fills the name and actual UI Grant/Revoke actions apply to that player.')
