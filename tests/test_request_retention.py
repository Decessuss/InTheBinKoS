import runpy
ns=runpy.run_path('tests/test_requests.py')
base=ns['base']
a,m=ns['client']('Alice'),ns['client']('Member')
assert m.globals().ForeverKoS.SubmitRequest('Enemy Person','Review reason')
packets=base['sent'](m)
request_packet=next(msg for _,msg,_,_ in packets if msg.startswith('N\t'))
base['packet'](a,request_packet,'Member')
rid=a.globals().ForeverKoS.GetRequests()[1].id
a.globals().ForeverKoS.ReviewRequest(rid,False)
decision_packet=next(msg for _,msg,_,_ in base['sent'](a) if msg.startswith('D\t'))
base['packet'](m,decision_packet,'Alice')
for r in (a,m):
    r.execute('stamp=1800000000+3*86400-1')
    assert len(r.globals().ForeverKoS.GetRequests())==1
    r.execute('stamp=1800000000+3*86400')
    assert len(r.globals().ForeverKoS.GetRequests())==0
    db=r.globals().ForeverKoSDB.guilds['Guild']
    assert db.requests[rid] is None and db.requestResults[rid].status=='Declined'
# Neither old request replays nor duplicate decisions restart retention.
base['packet'](a,request_packet,'Member')
base['packet'](m,decision_packet,'Alice')
assert len(a.globals().ForeverKoS.GetRequests())==0
assert len(m.globals().ForeverKoS.GetRequests())==0
late=ns['client']('Member')
late.execute('stamp=1800000000+4*86400')
base['packet'](late,request_packet,'Alice','WHISPER')
base['packet'](late,decision_packet,'Alice','WHISPER')
assert len(late.globals().ForeverKoS.GetRequests())==0
base['packet'](late,request_packet,'Alice','WHISPER')
assert len(late.globals().ForeverKoS.GetRequests())==0
# A genuinely new submission for the same player remains allowed.
m.execute('now=200')
assert m.globals().ForeverKoS.SubmitRequest('Enemy Person','New incident')
assert len(m.globals().ForeverKoS.GetRequests())==1
assert m.globals().ForeverKoS.GetRequests()[1].id!=rid
print('PASS: three-day decline expiry, hidden sync tombstone, late-peer replay protection and fresh resubmission.')
