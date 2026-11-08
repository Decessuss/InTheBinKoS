import runpy
ns=runpy.run_path('tests/test_guild_targets.py')
r=ns['client']('Alice')
base=ns['base']
api=r.globals().ForeverKoS
api.EditGuildTarget('Enemy Guild','Camping',False)
api.EditGuildTarget('Other Guild','Other',False)
base['sent'](r)
r.execute('units.mouseover={name="Enemy One",faction="Horde",guild="Enemy Guild"};testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")')
assert r.globals().sounds==1
# Another local player and a remotely reported player share the guild cooldown.
r.execute('now=110;stamp=1800000010;units.mouseover.name="Enemy Two";testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")')
assert r.globals().sounds==1
assert api.GetSighting('Enemy Two') is not None
base['packet'](r,'S\t1800000010\tEnemy Three\t1944\t10000\t20000\tMember\tEnemy Guild','Member')
assert r.globals().sounds==1 and api.GetSighting('Enemy Three') is not None
# A different guild remains independent.
base['packet'](r,'S\t1800000010\tOther Enemy\t1944\t10000\t20000\tMember\tOther Guild','Member')
assert r.globals().sounds==2
r.execute('now=159;stamp=1800000059')
base['packet'](r,'S\t1800000059\tEnemy Four\t1944\t10000\t20000\tMember\tEnemy Guild','Member')
assert r.globals().sounds==2
r.execute('now=160;stamp=1800000060')
base['packet'](r,'S\t1800000060\tEnemy Five\t1944\t10000\t20000\tMember\tEnemy Guild','Member')
assert r.globals().sounds==3 and len(r.globals().scans)==3
# Explicit player rules retain their independent player alert.
base['command'](r,'add "Named Enemy" Player rule')
base['packet'](r,'S\t1800000060\tNamed Enemy\t1944\t10000\t20000\tMember\tEnemy Guild','Member')
assert r.globals().sounds==4
print('PASS: shared local/remote 60-second guild alert throttle, independent guild/player rules and uninterrupted location updates.')
