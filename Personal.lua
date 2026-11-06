-- Character-private avoid list. Nothing in this module queues guild messages.
local api=ForeverKoS
local personal=false
local seen,present={},{}
local function say(text) print("|cffffb45bPersonal avoid list:|r " .. text) end
local function clean(s) return tostring(s or ""):gsub("[%c|]"," ") end
local function nameOf(unit)
    return api.UnitCharacterName(unit)
end
local function data()
    ForeverKoSDB=ForeverKoSDB or {guilds={}}
    local me=nameOf("player")
    if not me then return end
    ForeverKoSDB.personal=ForeverKoSDB.personal or {}
    local root=ForeverKoSDB.personal
    if not root[me] or not root[me].realmFreeNames then
        local merged={records={},realmFreeNames=true}
        local names={}
        for oldName in pairs(root) do if api.NameKey(oldName)==api.NameKey(me) then names[#names+1]=oldName end end
        table.sort(names)
        -- The existing canonical entry wins over legacy variants for private notes/settings.
        for i=#names,1,-1 do
            local source=root[names[i]]
            for k,v in pairs(source) do if k~="records" then merged[k]=v end end
            for _,old in pairs(source.records or {}) do
                local row={};for k,v in pairs(old) do row[k]=v end
                row.name=api.NormalizeName(row.name);row.editor=api.NormalizeName(row.editor)
                if row.name then merged.records[api.NameKey(row.name)]=row end
            end
        end
        merged.realmFreeNames=true;root[me]=merged
    end
    return ForeverKoSDB.personal[me],me
end
function api.IsPersonalMode() return personal end
function api.SetPersonalMode(value) personal=value and true or false;if api.SetGuildMode then api.SetGuildMode(false) end end
local guildState,guildEdit,guildTarget=api.GetState,api.Edit,api.AddTarget
local guildSound,guildAlerts,guildTest,guildAccess=api.SetSound,api.SetAlerts,api.Test,api.CanManageAccess
function api.GetState()
    if not personal then return guildState() end
    local d=data();local rows={}
    for _,r in pairs(d and d.records or {}) do rows[#rows+1]={name=r.name,reason=r.reason,editor=r.editor} end
    table.sort(rows,function(a,b)return a.name<b.name end)
    return rows,d~=nil,"Personal — private",d and d.sound~=false,d and d.enabled~=false
end
local function notify(r,context)
    local d=data()
    if not d or d.enabled==false then return end
    say(api.DisplayName(r.name) .. " — " .. context .. (r.reason~="" and (" — " .. r.reason) or ""))
    if d.sound~=false then PlaySound(8959,"Master") end
end
function api.Edit(name,reason,deleted)
    if not personal then return guildEdit(name,reason,deleted) end
    local d,me=data();name=api.NormalizeName(name)
    if not d or not name then say("Enter a player name.");return end
    if deleted then d.records[api.NameKey(name)]=nil
    else d.records[api.NameKey(name)]={name=name,reason=clean(reason):sub(1,160),editor=me} end
    say((deleted and "Removed " or "Saved ") .. api.DisplayName(name) .. ". This entry is private.")
    if api.CheckPersonalGroup then api.CheckPersonalGroup() end
end
function api.AddTarget(reason)
    if not personal then return guildTarget(reason) end
    if not UnitIsPlayer("target") then say("Target a player first.");return end
    api.Edit(nameOf("target"),reason,false)
end
function api.SetSound(value)
    if not personal then return guildSound(value) end
    local d=data();if d then d.sound=value end
end
function api.SetAlerts(value)
    if not personal then return guildAlerts(value) end
    local d=data();if d then d.enabled=value end
end
function api.Test()
    if not personal then return guildTest() end
    notify({name="Example",reason="Private reminder test"},"Personal alert test")
end
function api.CanManageAccess() return not personal and guildAccess() end
function api.CheckPersonal(unit)
    local d=data()
    if not d or d.enabled==false or not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    if UnitFactionGroup(unit)~=UnitFactionGroup("player") then return end
    local name=nameOf(unit);local k=name and api.NameKey(name);local r=k and d.records[k]
    if not r or (seen[k] and GetTime()-seen[k]<60) then return end
    seen[k]=GetTime();notify(r,"On your personal avoid list")
end
function api.CheckPersonalGroup()
    local d=data();if not d or d.enabled==false then return end
    local current={}
    local raid=IsInRaid and IsInRaid()
    local count=raid and (GetNumGroupMembers and GetNumGroupMembers() or 0) or (GetNumSubgroupMembers and GetNumSubgroupMembers() or 0)
    for i=1,count do
        local name=nameOf((raid and "raid" or "party") .. i)
        local k=name and api.NameKey(name);local r=k and d.records[k]
        if r then
            current[k]=true
            if not present[k] then notify(r,"IN YOUR " .. (raid and "RAID" or "PARTY")) end
        end
    end
    present=current
end
local groupFrame=CreateFrame("Frame")
groupFrame:RegisterEvent("GROUP_ROSTER_UPDATE");groupFrame:RegisterEvent("PLAYER_LOGIN")
groupFrame:SetScript("OnEvent",function() pcall(api.CheckPersonalGroup) end)
local originalSlash=SlashCmdList.FOREVERKOS
SlashCmdList.FOREVERKOS=function(input)
    local command,rest=input:match("^(%S*)%s*(.-)$")
    command=string.lower(command or "")
    if command=="personal" or command=="guild" then api.SetPersonalMode(command=="personal");return end
    if personal and (command=="add" or command=="remove") then
        local name,reason,problem=api.ParseNameReason(rest)
        if problem then say(problem);return end
        if not name or name=="target" then name=nameOf("target") end
        return api.Edit(name,reason or "",command=="remove")
    end
    if personal and command=="list" then
        local rows=api.GetState();say(#rows .. " private entries.")
        for _,r in ipairs(rows) do say(api.DisplayName(r.name) .. " — " .. r.reason) end
        return
    end
    if personal and command=="test" then return api.Test() end
    if personal and (command=="sound" or command=="alerts") then
        if command=="sound" then api.SetSound(rest~="off") else api.SetAlerts(rest~="off") end
        return
    end
    originalSlash(input)
end
