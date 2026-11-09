import runpy
from pathlib import Path
ns=runpy.run_path('tests/test_sightings.py');base=ns['ns']
def client(name):
    r=ns['client'](name)
    r.execute(Path('Guilds.lua').read_text(encoding='utf-8'))
    r.execute('''
GetGuildInfo=function(unit) if unit=="player" then return guildName end;return units[unit] and units[unit].guild end
units.mouseover={name="New Enemy",faction="Horde",guild="Bad-Guild People"}
''')
    return r
a,m,n=client('Alice'),client('Member'),client('Listener')
a.globals().ForeverKoS.EditGuildTarget('Bad-Guild People','Guild camping',False)
base['deliver'](a,m,'Alice')
base['deliver'](a,n,'Alice') # queue drained: explicitly sync remaining member below
assert m.globals().ForeverKoS.MatchRecord('New Enemy','bad-guild people').kind=='guild'
assert m.globals().ForeverKoS.MatchRecord('New Enemy','Other') is None
m.globals().ForeverKoS.EditGuildTarget('Forbidden','no',False)
assert m.globals().ForeverKoS.MatchRecord('Somebody','Forbidden') is None
base['packet'](m,'T\t999\tMember\t0\tForged\tno','Member')
assert m.globals().ForeverKoS.MatchRecord('Somebody','Forged') is None
# Ordinary member mouseover generates fresh guild-wide report to the officer.
m.execute('testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")')
assert m.globals().sounds==1
base['deliver'](m,a,'Member')
s=a.globals().ForeverKoS.GetGuildSighting('Bad-Guild People')
assert s.name=='New Enemy' and s.spotter=='Member'
assert a.globals().sounds==1
assert any('Guild <Bad-Guild People>' in str(x) for x in a.globals().notices.values())
# Same-faction and guildless players do not match; cooldown stays per character.
m.execute('''now=200;stamp=1800000100;units.mouseover.name="Friendly Person";units.mouseover.faction="Alliance";testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")''')
assert m.globals().sounds==1
m.execute('units.mouseover.faction="Horde";units.mouseover.guild=nil;testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")')
assert m.globals().sounds==1
m.execute('units.mouseover.guild="Bad-Guild People";testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")')
assert m.globals().sounds==2
# Player entries take precedence and guild-only entries never create player rows.
base['command'](a,'add "New Enemy" Personal reason')
assert a.globals().ForeverKoS.MatchRecord('New Enemy','Bad-Guild People').reason=='Personal reason'
a.globals().ForeverKoS.SetGuildMode(True)
rows=a.globals().ForeverKoS.GetState()[0]
assert len(rows)==1 and rows[1].name=='Bad-Guild People' and rows[1].sighting.name=='New Enemy'
# Cached member reply serves rules and history without an officer online.
base['packet'](m,'Q','Listener')
cache=base['sent'](m)
assert any(msg.startswith('U\t') for _,msg,_,_ in cache)
for _,msg,ch,_ in cache:base['packet'](n,msg,'Member',ch)
assert n.globals().ForeverKoS.MatchRecord('Unknown','Bad-Guild People') is not None
# Remove/tombstone wins over stale snapshots; guild change isolates the rules.
a.globals().ForeverKoS.EditGuildTarget('Bad-Guild People','',True)
base['deliver'](a,m,'Alice')
assert m.globals().ForeverKoS.MatchRecord('Unknown','Bad-Guild People') is None
for _,msg,ch,_ in cache:base['packet'](m,msg,'Listener',ch)
assert m.globals().ForeverKoS.MatchRecord('Unknown','Bad-Guild People') is None
m.execute('guildName="Other Guild";testFrame.OnEvent(testFrame,"PLAYER_GUILD_UPDATE")')
assert m.globals().ForeverKoS.MatchRecord('Unknown','Bad-Guild People') is None
a.globals().ForeverKoS.EditGuildTarget('Bad-Guild People','UI test',False)
# UI construction, guild selection and personal-mode separation using frame mocks.
a.execute('''
frames={};UISpecialFrames={};UIParent={};Minimap={}
local methods={}
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:SetText(v) self.text=v end
function methods:GetText() return rawget(self,"text") or "" end
function methods:SetShown(v) self.shown=v end
function methods:Show() self.shown=true;if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:CreateFontString() return CreateFrame("FontString") end
function methods:CreateTexture() return CreateFrame("Texture") end
function CreateFrame(kind,name,parent,template)
 local f={scripts={},shown=false,template=template};setmetatable(f,{__index=function(_,k)return methods[k] or function()end end})
 frames[#frames+1]=f;if name then _G[name]=f end;return f
end
''')
a.execute(Path('Personal.lua').read_text(encoding='utf-8'))
a.execute(Path('UI.lua').read_text(encoding='utf-8'))
a.execute('''
ForeverKoS.ToggleUI();assert(ForeverKoSWindow:IsShown())
for _,f in ipairs(frames) do if f.text=="KoS Guilds" then f.scripts.OnClick() end end
assert(ForeverKoS.IsGuildMode())
units.target={name="Target Person",faction="Horde",guild="Target-Guild People"}
ForeverKoSWindow.reason:SetText("Target test")
ForeverKoSWindow.target.scripts.OnClick()
assert(ForeverKoSWindow.name:GetText()=="Target-Guild People")
assert(not ForeverKoS.MatchRecord("Target Person","Target-Guild People"))
ForeverKoSWindow.add.scripts.OnClick()
assert(ForeverKoS.MatchRecord("Target Person","Target-Guild People").reason=="Target test")
-- Selecting an unseen guild must disable pinning, without falling back to a player sighting.
ForeverKoSWindow.pin.SetEnabled=function(self,value)self.testEnabled=value end
local oldSighting=ForeverKoS.GetSighting
ForeverKoS.GetSighting=function(name)
 if name=="Target-Guild People" then return {name=name,map=1944} end
 return oldSighting(name)
end
for _,f in ipairs(frames) do
 if type(rawget(f,"record"))=="table" and f.record.name=="Target-Guild People" then
  f.scripts.OnClick(f,"LeftButton")
  assert(ForeverKoSWindow.pin.testEnabled==false)
  f.scripts.OnClick(f,"RightButton")
 end
end
ForeverKoS.GetSighting=oldSighting
units.target.guild=nil
assert(ForeverKoS.GetTargetGuildName()==nil)
units.target.guild="Friendly Guild";units.target.faction="Alliance"
assert(ForeverKoS.GetTargetGuildName()==nil)
units.target=nil
assert(ForeverKoS.GetTargetGuildName()==nil)
for _,f in ipairs(frames) do if f.text=="Personal List" then f.scripts.OnClick() end end
assert(ForeverKoS.IsPersonalMode() and not ForeverKoS.IsGuildMode())
''')
base['deliver'](a,m,'Alice')
# Restore the member's original guild after the isolation test above.
m.execute('guildName="Guild";testFrame.OnEvent(testFrame,"PLAYER_GUILD_UPDATE")')
base['packet'](a,'Q','Member')
base['deliver'](a,m,'Alice')
assert m.globals().ForeverKoS.MatchRecord('Target Person','Target-Guild People').reason=='Target test'
print('PASS: guild rules, permissions, matching, fresh alerts, member cache, tombstones, faction/guild isolation and three-tab UI.')
