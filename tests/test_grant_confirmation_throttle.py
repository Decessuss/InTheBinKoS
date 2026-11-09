import runpy
ns=runpy.run_path('tests/test_kos.py')
a,m=ns['client']('Alice'),ns['client']('Member')
for r in (a,m):ns['sent'](r)
api=a.globals().ForeverKoS
def confirmations():
    return [s for s in a.globals().notices.values() if 'Confirmed by recipient addon' in str(s)]
api.SetEditor('Member',True)
ns['deliver'](a,m,'Alice');ns['deliver'](m,a,'Member')
assert len(confirmations())==1
revision=api.GetGrantDelivery('Member').rev
for _ in range(5):
    ns['packet'](a,'J\t'+str(revision)+'\tA','Member','WHISPER')
assert len(confirmations())==1
# A later officer snapshot must remain silent even if the recipient ACKs again.
ns['packet'](a,'Q','Member')
ns['deliver'](a,m,'Alice');ns['deliver'](m,a,'Member')
assert len(confirmations())==1
api.SetEditor('Member',False)
ns['deliver'](a,m,'Alice');ns['deliver'](m,a,'Member')
assert len(confirmations())==2 and not m.globals().ForeverKoS.CanEditShared()
new_revision=api.GetGrantDelivery('Member').rev
ns['packet'](a,'J\t'+str(revision)+'\tA','Member','WHISPER')
ns['packet'](a,'J\t'+str(new_revision)+'\tR','Member','WHISPER')
assert len(confirmations())==2
assert api.GetGrantDelivery('Member').status=='Confirmed by recipient addon'
print('PASS: repeated ACKs and routine sync stay silent; new revocation confirms once and stale results cannot replace success.')
