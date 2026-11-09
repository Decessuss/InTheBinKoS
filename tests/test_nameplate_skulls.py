import runpy
from pathlib import Path
ns=runpy.run_path('tests/test_guild_targets.py')
r=ns['client']('Alice');base=ns['base']
r.globals().ForeverKoS.EditGuildTarget('Enemy Guild','Test',False)
r.execute('''
icons={};plates={}
function SetRaidTarget()error("Automatic protected marking must never be called")end
function newPlate()
 local plate={}
 function plate:CreateTexture()
  local t={shown=false}
  function t:SetSize()end;function t:SetTexture(v)self.texture=v end
  function t:SetTexCoord(a,b,c,d)self.coords={a,b,c,d}end;function t:SetPoint()end
  function t:SetVertexColor(a,b,c)self.color={a,b,c}end
  function t:Show()self.shown=true end;function t:Hide()self.shown=false end
  icons[#icons+1]=t;return t
 end
 return plate
end
C_NamePlate={GetNamePlateForUnit=function(unit)return plates[unit] end}
units.nameplate1={name="Enemy Person",faction="Horde",guild="Enemy Guild"}
plates.nameplate1=newPlate()
''')
r.execute(Path('Nameplates.lua').read_text(encoding='utf-8'))
r.execute('skullFrame=testFrame;skullFrame.OnEvent(skullFrame,"NAME_PLATE_UNIT_ADDED","nameplate1")')
assert r.globals().icons[1].shown
r.execute('''
units.nameplate2={name="Second Enemy",faction="Horde",guild="Enemy Guild"}
plates.nameplate2=newPlate()
skullFrame.OnEvent(skullFrame,"NAME_PLATE_UNIT_ADDED","nameplate2")
assert(icons[1].coords[1]==0.75 and icons[2].coords[1]==0.5)
assert(icons[1].coords[3]==0.25 and icons[1].coords[4]==0.5)
skullFrame.OnUpdate(skullFrame,0.2)
assert(icons[2].coords[1]==0.5)
skullFrame.OnEvent(skullFrame,"NAME_PLATE_UNIT_REMOVED","nameplate2")
''')
r.execute('units.nameplate1.faction="Alliance";skullFrame.OnUpdate(skullFrame,0.2)')
assert not r.globals().icons[1].shown
r.execute('units.nameplate1.faction="Horde";skullFrame.OnUpdate(skullFrame,0.2)')
assert r.globals().icons[1].shown
r.execute('skullFrame.OnUpdate(skullFrame,0.2);skullFrame.OnEvent(skullFrame,"NAME_PLATE_UNIT_REMOVED","nameplate1")')
assert not r.globals().icons[1].shown
r.execute('units.nameplate1.guild=nil;skullFrame.OnEvent(skullFrame,"NAME_PLATE_UNIT_ADDED","nameplate1")')
assert not r.globals().icons[1].shown
print('PASS: local guild skull, faction changes, recycled nameplate cleanup without raid markers.')
r.execute('''
units.nameplate1.guild="Enemy Guild"
skullFrame.OnUpdate(skullFrame,0.2)
local entries=ForeverKoS.GetNearbyKoS()
assert(#entries==1 and entries[1].name=="Enemy Person" and entries[1].marker==8)
units.nameplate1.faction="Alliance"
assert(#ForeverKoS.GetNearbyKoS()==0)
local texture={SetTexCoord=function(self,l,r,t,b)self.coords={l,r,t,b}end}
for index=1,8 do
 ForeverKoS.SetMarkerArtwork(texture,index)
 assert(texture.coords[2]-texture.coords[1]==0.25)
 assert(texture.coords[4]-texture.coords[3]==0.25)
end
local delegated=false
SetRaidTargetIconTexture=function(t,index)delegated=t==texture and index==8 end
ForeverKoS.SetMarkerArtwork(texture,8)
assert(delegated)
''')
assert 'pcall(SetRaidTarget,' not in Path('Nameplates.lua').read_text()
