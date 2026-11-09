import runpy
from pathlib import Path
ns=runpy.run_path('tests/test_guild_targets.py')
r=ns['a']
r.execute('''
nearbyRows={{name="Example Enemy",guildName="Enemy Guild",level=60,className="Mage",classToken="MAGE",marker=8,slot=1},
 {name="Second Enemy",guildName="Enemy Guild",level=59,marker=7,slot=2}}
ForeverKoS.GetNearbyKoS=function()return nearbyRows end
ForeverKoS.PinSighting=function(name)pinnedNearby=name end
RAID_CLASS_COLORS={MAGE={r=0.25,g=0.78,b=0.92}}
''')
r.execute(Path('Nearby.lua').read_text(encoding='utf-8'))
r.execute('nearbyLoader=frames[#frames]')
r.execute(Path('SettingsUI.lua').read_text(encoding='utf-8'))
r.execute('''
assert(not ForeverKoS.Settings().nearby)
ForeverKoS.ToggleNearby()
assert(InTheBinKoSNearby:IsShown())
assert(InTheBinKoSNearby.title.text=="Nearby KoS  |  2")
assert(ForeverKoS.Settings().nearby.open)
for _,f in ipairs(frames) do
 if rawget(f,"record") and f.record.name=="Example Enemy" then
  f.name.SetTextColor=function(self,a,b,c)self.testColor={a,b,c}end
  InTheBinKoSNearby.scripts.OnUpdate(InTheBinKoSNearby,0.3)
  assert(f.name.testColor[1]==0.25 and f.guild.text:find("Level 60 Mage",1,true))
 end
end
InTheBinKoSNearby.SetAlpha=function(self,value)self.testAlpha=value end
MouseIsOver=function()return false end
InTheBinKoSNearby.scripts.OnUpdate(InTheBinKoSNearby,0.2)
assert(InTheBinKoSNearby.testAlpha==1)
MouseIsOver=function()return true end
InTheBinKoSNearby.scripts.OnUpdate(InTheBinKoSNearby,0.2)
assert(InTheBinKoSNearby.testAlpha==1)
InTheBinKoSNearby.pin.scripts.OnClick()
assert(ForeverKoS.Settings().nearby.locked)
InTheBinKoSNearby.scripts.OnDragStart(InTheBinKoSNearby)
assert(not InTheBinKoSNearby.dragging)
InTheBinKoSNearby.pin.scripts.OnClick()
assert(not ForeverKoS.Settings().nearby.locked)
for _,f in ipairs(frames) do
 if rawget(f,"name") and type(rawget(f,"record"))=="table" and f.record.name=="Example Enemy" then
  f.scripts.OnClick(f)
 end
end
assert(pinnedNearby=="Example Enemy")
InTheBinKoSNearby.collapse.scripts.OnClick()
assert(ForeverKoS.Settings().nearby.collapsed)
InTheBinKoSNearby.collapse.scripts.OnClick()
assert(not ForeverKoS.Settings().nearby.collapsed)
nearbyRows={}
MouseIsOver=function()return false end
InTheBinKoSNearby.scripts.OnUpdate(InTheBinKoSNearby,0.3)
assert(InTheBinKoSNearby.testAlpha==0.2)
ForeverKoSWindow.search:Show()
ForeverKoS.ToggleSettings()
assert(ForeverKoSWindow:IsShown() and InTheBinKoSSettings:IsShown())
assert(not ForeverKoSWindow.search:IsShown())
InTheBinKoSSettings.fade.GetChecked=function()return false end
InTheBinKoSSettings.fade.scripts.OnClick(InTheBinKoSSettings.fade)
assert(ForeverKoS.Settings().nearby.autoFade==false and InTheBinKoSNearby.testAlpha==1)
InTheBinKoSSettings.fade.GetChecked=function()return true end
InTheBinKoSSettings.fade.scripts.OnClick(InTheBinKoSSettings.fade)
assert(ForeverKoS.Settings().nearby.autoFade and InTheBinKoSNearby.testAlpha==0.2)
InTheBinKoSSettings.opacity.scripts.OnValueChanged(InTheBinKoSSettings.opacity,40)
assert(ForeverKoS.Settings().nearby.opacity==0.4 and InTheBinKoSNearby.testAlpha==0.4)
ForeverKoSWindow.guildTab.scripts.OnClick()
assert(not InTheBinKoSSettings:IsShown())
assert(ForeverKoSWindow.search:IsShown())
assert(InTheBinKoSNearby.title.text=="Nearby KoS  |  0")
assert(InTheBinKoSNearby.empty.shown)
InTheBinKoSNearby.GetPoint=function()return "TOPLEFT",UIParent,"TOPLEFT",100,-200 end
InTheBinKoSNearby.scripts.OnDragStop(InTheBinKoSNearby)
assert(ForeverKoS.Settings().nearby.x==100 and ForeverKoS.Settings().nearby.y==-200)
InTheBinKoSNearby.close.scripts.OnClick()
assert(not InTheBinKoSNearby:IsShown() and not ForeverKoS.Settings().nearby.open)
ForeverKoS.Settings().nearby.open=true
nearbyLoader.scripts.OnEvent(nearbyLoader,"PLAYER_LOGIN")
assert(InTheBinKoSNearby:IsShown())
''')
print('PASS: nearby panel toggle, count, pin click, collapse, live empty state, saved drag position and login restore.')
