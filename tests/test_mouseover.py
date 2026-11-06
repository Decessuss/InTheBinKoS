import runpy
ns=runpy.run_path('tests/test_sightings.py')
a,b=ns['client']('Alice'),ns['client']('Member')
base=ns['ns']
base['command'](a,'add target Mouseover test')
base['deliver'](a,b,'Alice')
b.execute('''
units.mouseover={name="Enemy",faction="Horde"}
local original=UnitFullName
ready=false
UnitFullName=function(unit) if unit=="mouseover" and not ready then return nil end; return original(unit) end
testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")
assert(sounds==0)
ready=true
testFrame.OnUpdate(testFrame,0.21)
assert(sounds==1)
''')
base['deliver'](b,a,'Member')
assert a.globals().sounds==1
assert a.globals().ForeverKoS.GetSighting('Enemy').spotter=='Member'
print('PASS: initially unavailable mouseover name is retried without selecting player; ordinary member sends sighting and officer receives chat/aura.')
