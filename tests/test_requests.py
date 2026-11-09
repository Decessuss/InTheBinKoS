import runpy
from pathlib import Path
ns=runpy.run_path('tests/test_sightings.py');base=ns['ns']
def client(name):
    r=ns['client'](name)
    r.execute(Path('Requests.lua').read_text(encoding='utf-8'))
    return r
a,m,n=client('Alice'),client('Member'),client('Listener')
api=m.globals().ForeverKoS
assert not api.SubmitRequest('Enemy Person','   ')
assert api.SubmitRequest('Enemy Person','Repeated camping')
assert not api.MatchRecord('Enemy Person')
assert not api.SubmitRequest('Enemy Person','Duplicate')
assert not api.SubmitRequest('Another Enemy','Too fast')
base['deliver'](m,a,'Member');base['deliver'](m,n,'Member')
request=a.globals().ForeverKoS.GetRequests()[1]
assert request.status=='Pending' and request.requester=='Member'
assert len(n.globals().ForeverKoS.GetRequests())==0
api.ReviewRequest(request.id,True)
assert not api.MatchRecord('Enemy Person')
# A member cannot forge a review result or submit under someone else's name.
base['packet'](a,'D\t'+request.id+'\t999\tApproved\tMember','Member')
assert a.globals().ForeverKoS.GetRequests()[1].status=='Pending'
base['packet'](a,'N\tfake\tListener\tForged Enemy\tReason','Member')
assert len(a.globals().ForeverKoS.GetRequests())==1
a.globals().ForeverKoS.ReviewRequest(request.id,True)
base['deliver'](a,m,'Alice')
assert api.MatchRecord('Enemy Person').reason=='Repeated camping'
assert api.GetRequests()[1].status=='Approved'
assert m.globals().sounds==0
# New requests can be declined without creating a KoS entry.
m.execute('now=140;stamp=1800000040')
assert api.SubmitRequest('Other Enemy','Reason to review')
base['deliver'](m,a,'Member')
pending=next(r for r in a.globals().ForeverKoS.GetRequests().values() if r.status=='Pending')
a.globals().ForeverKoS.ReviewRequest(pending.id,False)
base['deliver'](a,m,'Alice')
assert not api.MatchRecord('Other Enemy')
assert any(r.status=='Declined' for r in api.GetRequests().values())
# Own requests persist and are replayed to an officer who comes online later.
m.execute('now=180;stamp=1800000080')
assert api.SubmitRequest('Offline Enemy','Officer offline')
base['sent'](m)
late=client('Bob')
base['packet'](m,'Q','Bob')
base['deliver'](m,late,'Member')
assert any(r.name=='Offline Enemy' for r in late.globals().ForeverKoS.GetRequests().values())
late.execute('guildName="Different Guild";testFrame.OnEvent(testFrame,"PLAYER_GUILD_UPDATE")')
assert len(late.globals().ForeverKoS.GetRequests())==0
print('PASS: member request submission, mandatory reason, duplicate/cooldown checks, officer approval/decline, spoof rejection, pending silence, delayed officer sync and guild isolation.')

# Exercise the actual submission and approval buttons with the existing UI mock.
ui=runpy.run_path('tests/test_guild_targets.py')['a']
ui.execute(Path('Requests.lua').read_text(encoding='utf-8'))
ui.execute(Path('RequestUI.lua').read_text(encoding='utf-8'))
ui.execute('''
ForeverKoS.ToggleRequests()
assert(ForeverKoSWindow:IsShown())
assert(InTheBinKoSRequests:IsShown())
assert(not ForeverKoSWindow.search:IsShown())
InTheBinKoSRequests.name:SetText("UI Enemy")
InTheBinKoSRequests.reason:SetText("UI reason")
for _,f in ipairs(frames) do if f.text=="Submit Request" then f.scripts.OnClick() end end
assert(#ForeverKoS.GetRequests()==1)
for _,f in ipairs(frames) do if f.text=="Approve" and f.shown then f.scripts.OnClick() end end
assert(ForeverKoS.MatchRecord("UI Enemy").reason=="UI reason")
assert(ForeverKoS.GetRequests()[1].status=="Approved")
ForeverKoSWindow.guildTab.scripts.OnClick()
assert(not InTheBinKoSRequests:IsShown())
ForeverKoSWindow.requests.scripts.OnClick()
assert(InTheBinKoSRequests:IsShown())
''')
print('PASS: Requests window, mandatory-reason submission form and actual Approve button.')
