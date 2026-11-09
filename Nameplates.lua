-- Local artwork only: never assigns or changes a real raid target marker.
local api=ForeverKoS
local frame=CreateFrame("Frame")
local tracked,textures={},setmetatable({},{__mode="k"})
local assigned,owners,identities={},{},{}
local order={8,7,6,5,4,3,2,1}
local elapsed=0
local function release(unit)
    local slot=assigned[unit]
    if slot then owners[slot]=nil end
    assigned[unit]=nil;identities[unit]=nil
end
local function hide(unit)
    local plate=tracked[unit]
    if plate and textures[plate] then textures[plate]:Hide() end
    tracked[unit]=nil
    release(unit)
end
local function matches(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    local faction,own=UnitFactionGroup(unit),UnitFactionGroup("player")
    if not faction or not own or faction==own then return end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then return end
    local name=api.UnitCharacterName(unit)
    local rule=name and api.MatchRecord(name,GetGuildInfo(unit))
    if rule and not rule.deleted then return api.NameKey(name) end
end
local function update(unit)
    local plate=C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    if tracked[unit] and tracked[unit]~=plate then hide(unit) end
    if not plate then tracked[unit]=false;return end
    tracked[unit]=plate
    if textures[plate] then textures[plate]:Hide() end
    local identity=matches(unit)
    if not identity then release(unit);return end
    if identities[unit]~=identity then release(unit);identities[unit]=identity end
    if not assigned[unit] then
        for slot=1,8 do
            if not owners[slot] then assigned[unit]=slot;owners[slot]=unit;break end
        end
    end
    if not textures[plate] then
        local icon=plate:CreateTexture(nil,"OVERLAY")
        icon:SetSize(28,28)
        icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        icon:SetPoint("BOTTOM",plate,"TOP",0,8)
        textures[plate]=icon
    end
    local index=order[assigned[unit] or 1]-1
    local column,row=index%4,math.floor(index/4)
    textures[plate]:SetTexCoord(column/4,(column+1)/4,row/2,(row+1)/2)
    -- More than eight visible matches retain a red skull rather than disappearing.
    textures[plate]:SetVertexColor(1,assigned[unit] and 1 or 0.3,assigned[unit] and 1 or 0.3)
    textures[plate]:Show()
end
frame:SetScript("OnEvent",function(_,event,unit)
    if event=="NAME_PLATE_UNIT_REMOVED" then hide(unit)
    elseif event=="NAME_PLATE_UNIT_ADDED" then pcall(update,unit) end
end)
frame:SetScript("OnUpdate",function(_,delta)
    elapsed=elapsed+delta
    if elapsed<0.2 then return end
    elapsed=0
    -- Recheck reused plates, delayed names, list edits and guild changes.
    for unit in pairs(tracked) do
        if not UnitExists(unit) then hide(unit) else pcall(update,unit) end
    end
end)
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
function api.GetNearbyKoS()
    local result,added={},{}
    for unit,plate in pairs(tracked) do
        if plate then
            local ok,identity=pcall(matches,unit)
            if ok and identity and not added[identity] then
                local level
                if UnitLevel then
                    local readable,value=pcall(UnitLevel,unit)
                    if readable and type(value)=="number" and (value==-1 or (value>=1 and value<=1000)) then level=value end
                end
                added[identity]=true
                local className,classToken
                if UnitClass then
                    local readable,a,b=pcall(UnitClass,unit)
                    if readable then className,classToken=a,b end
                end
                result[#result+1]={name=api.UnitCharacterName(unit),guildName=GetGuildInfo(unit),level=level,className=className,classToken=classToken,
                    marker=order[assigned[unit] or 1],slot=assigned[unit] or 9}
            end
        end
    end
    table.sort(result,function(a,b) if a.slot~=b.slot then return a.slot<b.slot end;return a.name<b.name end)
    return result
end
