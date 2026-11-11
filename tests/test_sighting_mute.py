import runpy
ns=runpy.run_path('tests/test_sightings.py');base=ns['ns']
r=ns['client']('Alice');api=r.globals().ForeverKoS
base['sent'](r)
base['command'](r,'test')
count=len(r.globals().scans)
assert '[Mute 30m]' in r.globals().notices[len(r.globals().notices)]
api.HandleMuteLink('garrmission:kosmute:mute:Example')
base['command'](r,'test')
assert len(r.globals().scans)==count
r.execute('now=131')
assert api.IsSightingMuted('Example')
r.execute('now=1901')
assert not api.IsSightingMuted('Example')
base['command'](r,'test')
assert len(r.globals().scans)==count+1
api.HandleMuteLink('garrmission:kosmute:mute:Example')
api.HandleMuteLink('garrmission:kosmute:unmute:Example')
assert not api.IsSightingMuted('Example')
count=len(r.globals().scans)
# Real sightings are blocked at the recording boundary, not just in chat.
base['command'](r,'add Enemy Test');base['sent'](r)
api.HandleMuteLink('garrmission:kosmute:mute:Enemy')
api.RecordSighting('Enemy',None,None)
assert base['sent'](r)==[]
assert not api.GetSighting('Enemy')
# Other spotters' reports are still delivered despite our own local mute.
base['packet'](r,'S\t1800000000\tEnemy\t1944\t25000\t75000\tMember','Member')
assert api.GetSighting('Enemy').spotter=='Member'
assert len(r.globals().scans)==count+1
print('PASS: local alert suppression, per-name expiry/unmute, zero test traffic, real outgoing suppression and other-spotter delivery.')
