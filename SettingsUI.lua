local api=ForeverKoS
local window
local function nearby()
    local s=api.Settings();s.nearby=s.nearby or {};return s.nearby
end
local function label(parent,text,x,y,style)
    local f=parent:CreateFontString(nil,"OVERLAY",style or "GameFontHighlightSmall")
    f:SetPoint("TOPLEFT",x,y);f:SetText(text);return f
end
function api.CreateSettingsPage(parent)
    if window then return window end
    window=CreateFrame("Frame","InTheBinKoSSettings",parent)
    window:SetSize(520,510);window:SetPoint("TOPLEFT",parent,"TOPLEFT",20,-80)
    label(window,"Settings",20,-20,"GameFontNormalLarge")
    label(window,"Nearby panel",20,-62,"GameFontNormal")
    window.fade=CreateFrame("CheckButton",nil,window,"UICheckButtonTemplate")
    window.fade:SetSize(24,24);window.fade:SetPoint("TOPLEFT",18,-86)
    label(window,"Auto-fade nearby panel",48,-92)
    label(window,"Fades only when empty and the mouse is away.",24,-122)
    window.value=label(window,"Faded opacity: 20%",24,-155,"GameFontNormal")
    window.opacity=CreateFrame("Slider",nil,window,"OptionsSliderTemplate")
    window.opacity:SetSize(360,18);window.opacity:SetPoint("TOPLEFT",28,-187)
    window.opacity:SetMinMaxValues(5,100);window.opacity:SetValueStep(1)
    if window.opacity.SetObeyStepOnDrag then window.opacity:SetObeyStepOnDrag(true) end
    label(window,"5%",24,-213);label(window,"100%",365,-213)
    label(window,"Populated or hovered panels always show at 100%.",24,-245)
    label(window,"PvP tooltips",20,-285,"GameFontNormal")
    window.pvpTooltip=CreateFrame("CheckButton",nil,window,"UICheckButtonTemplate")
    window.pvpTooltip:SetSize(24,24);window.pvpTooltip:SetPoint("TOPLEFT",18,-309)
    label(window,"Show PvP record in player tooltips",48,-315)
    label(window,"Wins and losses keep tracking when the tooltip is hidden.",24,-346)
    label(window,"Sighting sound",20,-385,"GameFontNormal")
    window.localSound=CreateFrame("CheckButton",nil,window,"UICheckButtonTemplate")
    window.localSound:SetSize(24,24);window.localSound:SetPoint("TOPLEFT",18,-409)
    label(window,"Only hear sightings in my zone",48,-415)
    label(window,"Unchecked: hear all sightings. Checked: yours and same-zone reports.",24,-446)
    label(window,"Shared chat and aura alerts still appear in either mode.",24,-470)
    window.localSound:SetScript("OnClick",function(self)
        api.Settings().sightingSoundSameZoneOnly=not not self:GetChecked()
    end)
    window.pvpTooltip:SetScript("OnClick",function(self)
        api.Settings().showPvPRecordTooltip=not not self:GetChecked()
    end)
    window.fade:SetScript("OnClick",function(self)
        nearby().autoFade=not not self:GetChecked()
        if api.RefreshNearby then api.RefreshNearby() end
    end)
    window.opacity:SetScript("OnValueChanged",function(_,value)
        value=math.max(5,math.min(100,math.floor(value+0.5)))
        nearby().opacity=value/100
        window.value:SetText("Faded opacity: " .. value .. "%")
        if api.RefreshNearby then api.RefreshNearby() end
    end)
    window:SetScript("OnShow",function()
        local s=nearby();window.fade:SetChecked(s.autoFade~=false)
        window.opacity:SetValue((tonumber(s.opacity) or 0.2)*100)
        window.pvpTooltip:SetChecked(api.Settings().showPvPRecordTooltip~=false)
        window.localSound:SetChecked(api.Settings().sightingSoundSameZoneOnly==true)
    end)
    window:Hide()
    return window
end
function api.ToggleSettings()
    if api.ShowSettings then api.ShowSettings() end
end
local slash=SlashCmdList.FOREVERKOS
SlashCmdList.FOREVERKOS=function(input)
    if input:match("^%s*settings%s*$") then api.ToggleSettings();return end
    return slash(input)
end
