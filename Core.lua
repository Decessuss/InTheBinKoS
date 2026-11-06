-- Shared guild list. Only current officer-chat speakers may publish records.
local PREFIX = "ForeverKoS1"
local frame = CreateFrame("Frame")
local guild, db, me
local roster, queue, requests, seen = {}, {}, {}, {}
local rosterGUIDs={}
local accessDelivery={}
local announced={}
local debugEnabled=false
local accessDebug=false
local debugSeen={}
local elapsed, refresh, lastRequest = 0, 0, -100
ForeverKoS = {}
local function say(s) print("|cffff5555<in the bin> KoS List:|r " .. s) end
local function clean(s) return (tostring(s or ""):gsub("[%c|]", " ")) end
local function accessTrace(text) if accessDebug then say("ACCESS: " .. clean(text)) end end
local function displayName(s) return clean(s):match("^[^-]+") or "" end
ForeverKoS.DisplayName = displayName
-- Character identity is the full first/last name only. Legacy realm suffixes
-- are discarded at every input boundary, including roster and addon messages.
local function full(s)
    if type(s)~="string" or s:find("[%c|]") then return nil end
    s=s:match("^ *(.-) *$"):gsub(" +"," ")
    s=s:match("^([^-]+)") or ""
    s=s:match("^ *(.-) *$")
    if s=="" or #s>100 then return nil end
    return s
end
-- Quoted names support spaces while keeping existing single-name commands compatible.
local function parseNameReason(input)
    local text = input:match("^ *(.-) *$")
    local quote = text:sub(1,1)
    if quote == '"' or quote == "'" then
        local finish = text:find(quote,2,true)
        if not finish then return nil,nil,"Close the quoted player name." end
        local tail = text:sub(finish+1)
        if tail ~= "" and not tail:match("^%s") then return nil,nil,"Put a space after the quoted player name." end
        local name = text:sub(2,finish-1)
        if name == "" then return nil,nil,"Enter a player name inside the quotes." end
        return name,tail:match("^%s*(.*)$")
    end
    return text:match("^(%S+)%s*(.*)$")
end
ForeverKoS.ParseNameReason = parseNameReason
local function key(s) local n = full(s); return n and string.lower(n) end
local function unitName(unit)
    local n,surname=UnitFullName(unit)
    if not n and UnitName then n=UnitName(unit) end
    -- Forever returns first name and surname in the two UnitFullName slots.
    -- A real realm value is still ignored, for compatibility with standard clients.
    local realm=GetRealmName and GetRealmName()
    local normalizedRealm=GetNormalizedRealmName and GetNormalizedRealmName()
    if n and surname and surname~="" and not n:find(" ",1,true)
        and surname~=realm and surname~=normalizedRealm then n=n .. " " .. surname end
    return full(n)
end
ForeverKoS.UnitCharacterName=unitName
-- Migrate active records without modifying the retained legacy snapshots.
local function migrateGuild(scope)
    local root=ForeverKoSDB.guilds
    local target=root[scope] or {clock=0,records={}}
    if target.realmFreeNames then return target end
    local result={clock=target.clock or 0,records={},grants={},sightings={},guildTargets={},realmFreeNames=true}
    for k,v in pairs(target) do
        if k~="records" and k~="grants" and k~="sightings" and k~="guildTargets" then result[k]=v end
    end
    local function mergeMap(source,field)
        for _,old in pairs(source[field] or {}) do
            local row={};for k,v in pairs(old) do row[k]=v end
            row.editor=row.editor and full(row.editor)
            row.spotter=row.spotter and full(row.spotter)
            if field~="guildTargets" then row.name=full(row.name) end
            local k=field=="guildTargets" and row.name and string.lower(row.name) or key(row.name)
            if k then
                local previous=result[field][k]
                local stamp=field=="sightings" and (row.stamp or 0) or (row.rev or 0)
                local oldStamp=previous and (field=="sightings" and (previous.stamp or 0) or (previous.rev or 0)) or -1
                local editor=row.editor or row.spotter or ""
                local oldEditor=previous and (previous.editor or previous.spotter or "") or ""
                if not previous or stamp>oldStamp or (stamp==oldStamp and (editor>oldEditor or (editor==oldEditor and row.deleted))) then result[field][k]=row end
                if field~="sightings" then result.clock=math.max(result.clock,row.rev or 0) end
            end
        end
    end
    for oldScope,source in pairs(root) do
        if oldScope==scope or oldScope:sub(1,#scope+1)==scope .. "@" then
            for _,field in ipairs({"records","grants","sightings","guildTargets"}) do mergeMap(source,field) end
        end
    end
    result.realmFreeNames=true
    root[scope]=result
    return result
end
local function nativeOfficer()
    local query=C_GuildInfo and C_GuildInfo.IsGuildOfficer or IsGuildOfficer
    if type(query)~="function" then return nil end
    local ok,value=pcall(query)
    if ok and type(value)=="boolean" then return value end
end
local function rankOrder(name)
    local k=key(name)
    local guid=k and rosterGUIDs[k]
    if k and k==key(me) and UnitGUID then guid=UnitGUID("player") or guid end
    if guid and C_GuildInfo and C_GuildInfo.GetGuildRankOrder then
        local ok,value=pcall(C_GuildInfo.GetGuildRankOrder,guid)
        if ok and type(value)=="number" and value>=1 then return value end
    end
    local rank=k and roster[k]
    if rank==nil and k and k==key(me) then
        local _,_,ownRank=GetGuildInfo("player")
        rank=ownRank
    end
    return type(rank)=="number" and rank+1 or nil
end
local function rankFlags(order)
    if not order or not (C_GuildInfo and C_GuildInfo.GuildControlGetRankFlags) then return nil end
    local ok,flags=pcall(C_GuildInfo.GuildControlGetRankFlags,order)
    return ok and type(flags)=="table" and flags or nil
end
local function isOfficer(name)
    local k=key(name)
    if not k then return false end
    -- The server's own-player check does not depend on the guild roster cache.
    -- Never use it to authorize another character or a claimed addon message.
    if k==key(me) and GetGuildInfo("player") and nativeOfficer()==true then return true end
    local order=rankOrder(name)
    if order==1 then return true end
    local flags=rankFlags(order)
    return flags~=nil and flags[4]==true
end
local function permitted(name)
    if isOfficer(name) then return true end
    local k=key(name)
    local grant=db and db.grants and db.grants[k]
    return k~=nil and roster[k]~=nil and grant~=nil and not grant.deleted
end
local function rebuild()
    local g = GetGuildInfo("player")
    me = unitName("player")
    local scope = g
    if scope ~= guild then
        guild, db = scope, nil
        queue, seen, requests = {}, {}, {}
        announced={};accessDelivery={}
        lastRequest = -100
        if scope then
            db=migrateGuild(scope)
        end
    end
    roster,rosterGUIDs = {},{}
    if not g then return end
    for i=1, GetNumGuildMembers() do
        local n, _, rank, _, _, _, _, _, _, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)
        local k=key(n)
        if k then roster[k]=rank;rosterGUIDs[k]=guid end
    end
end
local function encode(s) return (s:gsub("([^%w%-%. ])", function(c) return string.format("%%%02X", string.byte(c)) end)) end
local function decode(s) return (s:gsub("%%(%x%x)", function(c) return string.char(tonumber(c,16)) end)) end
local function pack(r)
    return table.concat({"R", r.rev, encode(r.editor), r.deleted and "1" or "0", encode(r.name), encode(r.reason)}, "\t")
end
local function merge(r)
    if not db then return end
    r.name=full(r.name);r.editor=full(r.editor)
    local k = key(r.name)
    if not k or not r.editor then return end
    local old = db.records[k]
    db.clock = math.max(db.clock, r.rev)
    if not old or r.rev > old.rev or (r.rev == old.rev and r.editor > old.editor) then
        db.records[k] = r
        return true
    end
end
local function enqueue(msg, channel, target)
    if #msg <= 250 and #queue < 5000 then
        queue[#queue+1] = {msg, channel or "GUILD", target}
    end
end
local function packGrant(r)
    return table.concat({"G",r.rev,encode(r.editor),r.deleted and "1" or "0",encode(r.name)},"\t")
end
local function mergeGrant(r)
    db.grants=db.grants or {}
    r.name=full(r.name);r.editor=full(r.editor)
    local k=key(r.name)
    if not k or not r.editor then return end
    local old=db.grants[k]
    db.clock=math.max(db.clock,r.rev)
    if not old or r.rev>old.rev or (r.rev==old.rev and r.editor>old.editor) then db.grants[k]=r end
end
function ForeverKoS.CanAdminGuildAccess() return db~=nil and isOfficer(me) end
function ForeverKoS.CanManageAccess() return ForeverKoS.CanAdminGuildAccess() end
function ForeverKoS.GetGrantDelivery(name)
    return accessDelivery[key(name)]
end
function ForeverKoS.SetEditor(name,enabled)
    if not db or not isOfficer(me) then say("Only guild officers can grant or revoke access."); return end
    name=full(name)
    if not name or roster[key(name)]==nil then say("Enter a current guild member's character name."); return end
    local r={name=name,editor=me,rev=db.clock+1,deleted=not enabled}
    local message=packGrant(r)
    if #message>250 then say("Character name is too long to sync."); return end
    mergeGrant(r); accessDelivery[key(name)]={rev=r.rev,status="Waiting for recipient addon"};enqueue(message)
    say((enabled and "Queued list-editing grant for " or "Queued named-access revocation for ") .. displayName(name)
        .. (not enabled and ". Guild officer permissions still apply." or "."))
end
local function publish(target)
    if not db or (not target and not permitted(me)) then return end
    -- Access records require a real officer sender; ordinary peer caches cannot confer permissions.
    if isOfficer(me) then
        for _,r in pairs(db.grants or {}) do enqueue(packGrant(r),target and "WHISPER" or "GUILD",target) end
    end
    for _, r in pairs(db.records) do
        local message=pack(r)
        -- Requested peer snapshots are explicitly distinct from officer edits.
        if target then message="C" .. message:sub(2) end
        enqueue(message, target and "WHISPER" or "GUILD", target)
    end
    if ForeverKoS.PublishGuildTargets then ForeverKoS.PublishGuildTargets(target) end
    if ForeverKoS.PublishSightings then ForeverKoS.PublishSightings(target) end
end
local function request()
    if not db or GetTime() - lastRequest < 30 then return end
    lastRequest = GetTime()
    enqueue("Q")
end
local function receive(prefix, message, channel, sender)
    if prefix ~= PREFIX or not db or type(message) ~= "string" or #message > 250 then return end
    if channel ~= "GUILD" and channel ~= "WHISPER" then return end
    local senderKey = key(sender)
    if message:sub(1,2)=="G\t" then
        accessTrace("Grant received from [" .. tostring(sender) .. "]; key=[" .. tostring(senderKey)
            .. "]; roster rank=" .. tostring(senderKey and roster[senderKey]) .. "; self=[" .. tostring(me) .. "]")
    end
    if not senderKey or roster[senderKey] == nil or senderKey == key(me) then return end
    if ForeverKoS.ReceivePresence and ForeverKoS.ReceivePresence(message,sender,channel) then return end
    if ForeverKoS.ReceiveGuildTarget and ForeverKoS.ReceiveGuildTarget(message,sender,channel,permitted(sender),GetTime()-lastRequest<=1200) then return end
    if message:sub(1,2)=="J\t" then
        local revision,result=message:match("^J\t(%d+)\t([AR])$")
        local pending=accessDelivery[senderKey]
        if channel=="WHISPER" and pending and pending.rev==tonumber(revision) then
            pending.status=result=="A" and "Confirmed by recipient addon" or "Rejected: officer not recognized on their client"
            say(displayName(sender) .. ": " .. pending.status)
        end
        return
    end
    if message:sub(1,2)=="G\t" then
        local revision,editor,deleted,name=message:match("^G\t(%d+)\t([^\t]+)\t([01])\t([^\t]+)$")
        revision=tonumber(revision)
        if not revision or revision>1000000000000 then return end
        editor,name=full(decode(editor)),full(decode(name))
        if not full(editor) or not full(name) then return end
        if not isOfficer(sender) then
            accessTrace("Grant rejected: sender officer permission unavailable.")
            if key(name)==key(me) then enqueue("J\t" .. revision .. "\tR","WHISPER",sender) end
            return
        end
        mergeGrant({name=name,editor=editor,rev=revision,deleted=deleted=="1"})
        accessTrace("Grant target=[" .. tostring(name) .. "]; target matches self=" .. tostring(key(name)==key(me))
            .. "; editing=" .. tostring(permitted(me)))
        if key(name)==key(me) then
            local current=db.grants[key(name)]
            if current.rev==revision and current.editor==editor and current.deleted==(deleted=="1") then
                enqueue("J\t" .. revision .. "\tA","WHISPER",sender)
            end
        end
        return
    end
    if message:sub(1,2) == "S\t" then
        if ForeverKoS.ReceiveSighting then ForeverKoS.ReceiveSighting(message, sender, isOfficer(sender),channel~="GUILD") end
        return
    end
    if message:sub(1,2)=="H\t" then
        if channel=="WHISPER" and GetTime()-lastRequest<=1200 and ForeverKoS.ReceiveSighting then
            ForeverKoS.ReceiveSighting("S" .. message:sub(2),sender,true,true)
        end
        return
    end
    if message == "Q" then
        if GetTime() - (requests[senderKey] or -100) >= 60 then
            requests[senderKey] = GetTime()
            publish(sender)
        end
        return
    end
    local cached=message:sub(1,2)=="C\t"
    if cached then
        if channel~="WHISPER" or GetTime()-lastRequest>1200 then return end
        message="R" .. message:sub(2)
    elseif not permitted(sender) then return end
    local v, editor, deleted, name, reason = message:match("^R\t(%d+)\t([^\t]+)\t([01])\t([^\t]+)\t([^\t]*)$")
    v = tonumber(v)
    if not v or v > 1000000000000 then return end
    editor, name, reason = decode(editor), decode(name), decode(reason)
    if not full(editor) or not full(name) or #reason > 60 or reason:find("[%c|]") then return end
    merge({rev=v, editor=editor, deleted=deleted=="1", name=name, reason=reason})
end
local function edit(name, reason, deleted)
    if not db or not permitted(me) then say("Editing requires current officer-chat speak permission and a loaded guild roster."); return end
    name = full(name)
    if not name then say("Use the full first and last character name."); return end
    -- Bound encoded record size, including multibyte names. Never save unsyncable edits.
    local r = {rev=db.clock+1, editor=me, name=name, reason=clean(reason):sub(1,60), deleted=deleted}
    if #pack(r) > 250 then say("Name/reason too long to sync; use a shorter reason."); return end
    merge(r)
    enqueue(pack(r))
    say((deleted and "Removed " or "Added ") .. displayName(name) .. ".")
end
function ForeverKoS.PlaySightingSound()
    if type(PlaySoundFile)=="function" then
        local ok,played=pcall(PlaySoundFile,"Interface\\AddOns\\InTheBinKoS\\Media\\EnemySpotted.mp3","Master")
        if ok and played then return end
    end
    -- Keep alerts audible if the client cannot load the bundled clip.
    PlaySound(8959,"Master")
end
local function alert(name, reason, test, sighting)
    if not test then
        local k=key(name)
        if k and announced[k] and GetTime()-announced[k]<60 then return end
        if k then announced[k]=GetTime() end
    end
    local location = ""
    if sighting then
        local link=sighting.map~=0 and ForeverKoS.LinkForPosition and ForeverKoS.LinkForPosition(sighting.map,sighting.x,sighting.y)
        location=link and (" — " .. link) or " — location unavailable"
    elseif ForeverKoS.MakeSpotLink then
        local ok, link = pcall(ForeverKoS.MakeSpotLink)
        location = ok and link and (" — " .. link) or " — location unavailable"
    end
    say((test and "TEST: " or "Spotted: ") .. displayName(name)
        .. " spotted by " .. displayName(sighting and sighting.spotter or me or unitName("player") or "you")
        .. (reason ~= "" and (" — " .. clean(reason)) or "") .. location)
    if db and db.sound ~= false then ForeverKoS.PlaySightingSound() end
    local wa = ForeverAuras or WeakAuras
    local zone=sighting and ForeverKoS.SightingZone and ForeverKoS.SightingZone(sighting) or GetZoneText() or ""
    if wa and wa.ScanEvents then wa.ScanEvents("FOREVER_KOS_SPOTTED", name, reason, zone,
        sighting and sighting.spotter or me) end
end
function ForeverKoS.NotifyGuildSighting(sighting)
    if not db or db.enabled==false then return end
    local r=ForeverKoS.MatchRecord(sighting.name,sighting.guildName)
    if r and not r.deleted then alert(sighting.name,ForeverKoS.MatchReason(r),false,sighting) end
end
local function check(unit)
    local function explain(message)
        if debugEnabled then
            local tag=unit .. ": " .. message
            if not debugSeen[tag] or GetTime()-debugSeen[tag]>=10 then
                debugSeen[tag]=GetTime();say("DEBUG " .. tag)
            end
        end
    end
    if not db then explain("No active guild list.");return end
    if not UnitExists(unit) then explain("No unit available.");return end
    if not UnitIsPlayer(unit) then explain("Unit is not a player.");return end
    local faction, own = UnitFactionGroup(unit), UnitFactionGroup("player")
    if not faction or not own then explain("Faction unavailable.");return end
    if faction == own then explain("Same faction.");return end
    local name = unitName(unit)
    local k = key(name)
    local enemyGuild
    if ForeverKoS.NormalizeGuildName then
        local ok,value=pcall(function() return ForeverKoS.NormalizeGuildName(GetGuildInfo(unit)) end)
        if ok then enemyGuild=value end
    end
    local r = ForeverKoS.MatchRecord(name,enemyGuild)
    if not name then explain("Player name unavailable.");return end
    if not r or r.deleted then explain("Not on this list: " .. name);return end
    if seen[k] and GetTime()-seen[k]<60 then explain("Sighting cooldown: " .. math.ceil(60-(GetTime()-seen[k])) .. "s");return end
    explain("Matched " .. name .. "; recording and sending sighting.")
    seen[k] = GetTime()
    if ForeverKoS.RecordSighting then ForeverKoS.RecordSighting(name,enemyGuild) end
    if db.enabled ~= false then alert(name, ForeverKoS.MatchReason(r), false) end
end
local function guardedCheck(unit)
    if ForeverKoS.CheckPersonal then pcall(ForeverKoS.CheckPersonal,unit) end
    -- A restricted/secret unit value must never break the rest of the addon.
    local ok,err=pcall(check, unit)
    if not ok and debugEnabled then
        local tag=tostring(err)
        if not debugSeen[tag] or GetTime()-debugSeen[tag]>=10 then debugSeen[tag]=GetTime();say("DEBUG error: " .. tag) end
    end
end
-- Small UI interface; all changes still go through the same permission checks.
function ForeverKoS.GetState()
    local rows = {}
    if db then
        for _, r in pairs(db.records) do
            if not r.deleted then rows[#rows+1] = {name=r.name, reason=r.reason, editor=r.editor,
                sighting=ForeverKoS.GetSighting and ForeverKoS.GetSighting(r.name)} end
        end
    end
    table.sort(rows, function(a,b) return a.name < b.name end)
    return rows, db ~= nil and permitted(me), guild or "No guild", db and db.sound ~= false, db and db.enabled ~= false
end
function ForeverKoS.Settings()
    ForeverKoSDB.ui = ForeverKoSDB.ui or {angle=220}
    return ForeverKoSDB.ui
end
function ForeverKoS.GetRankLabel()
    local guildName,rankName=GetGuildInfo("player")
    if not guildName then return "Not in a guild" end
    return "Rank: " .. clean(rankName or "Loading...")
end
function ForeverKoS.MatchRecord(name)
    local k=key(name);local r=db and k and db.records[k]
    return r and not r.deleted and r or nil
end
function ForeverKoS.MatchReason(r) return r.reason end
function ForeverKoS.CanEditShared() return db~=nil and permitted(me) end
function ForeverKoS.SharedAccessLabel(name)
    if isOfficer(name) then return "Officer" end
    return permitted(name) and "Granted editor" or "Member"
end
function ForeverKoS.QueuePresence(message) if db then enqueue(message) end end
function ForeverKoS.QueueGuildTarget(message,target) enqueue(message,target and "WHISPER" or "GUILD",target) end
function ForeverKoS.SightingContext() return db, me end
function ForeverKoS.NameKey(name) return key(name) end
function ForeverKoS.NormalizeName(name) return full(name) end
function ForeverKoS.QueueSighting(message, target)
    if GetGuildInfo("player") then enqueue(message, target and "WHISPER" or "GUILD", target) end
end
function ForeverKoS.Edit(name, reason, deleted) edit(name, reason, deleted) end
function ForeverKoS.AddTarget(reason)
    if not UnitIsPlayer("target") then say("Target a player first."); return end
    edit(unitName("target"), reason or "", false)
end
function ForeverKoS.Test() alert("Example", "Test alert", true) end
function ForeverKoS.Sync() request() end
function ForeverKoS.SetSound(value) if db then db.sound = value end end
function ForeverKoS.SetAlerts(value) if db then db.enabled = value end end
SLASH_FOREVERKOS1 = "/kos"
SlashCmdList.FOREVERKOS = function(input)
    local command, rest = input:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")
    if command == "" or command == "ui" then
        if ForeverKoS.ToggleUI then ForeverKoS.ToggleUI() end
    elseif command == "add" or command == "remove" then
        local name, reason, problem = parseNameReason(rest)
        if problem then say(problem); return end
        if not name or name == "target" then
            if not UnitIsPlayer("target") then say("Target a player first."); return end
            name = unitName("target")
        end
        edit(name, reason or "", command == "remove")
    elseif command == "debug" then
        debugEnabled=rest~="off";debugSeen={};say("Detection diagnostics " .. (debugEnabled and "on. Hover the enemy and copy the DEBUG line." or "off."))
    elseif command == "sync" then request(); say("Requested cached list from online guild members (30-second cooldown).")
    elseif command == "publish" then publish(); say("Publish requested; officer permission is required.")
    elseif command == "test" then alert("Example", "Test alert", true)
    elseif command == "sound" and db then db.sound = rest ~= "off"; say("Sound " .. (db.sound and "on" or "off"))
    elseif command == "alerts" and db then db.enabled = rest ~= "off"; say("Alerts " .. (db.enabled and "on" or "off"))
    elseif command == "list" and db then
        local names = {}
        for _, r in pairs(db.records) do if not r.deleted then names[#names+1] = displayName(r.name) .. " — " .. r.reason .. " (" .. displayName(r.editor) .. ")" end end
        table.sort(names)
        say(#names .. " active entries.")
        for _, n in ipairs(names) do say(clean(n)) end
    elseif command == "accessdebug" then
        accessDebug=rest~="off"
        say("Access diagnostics " .. (accessDebug and "on. Ask the officer to grant access again; copy ACCESS lines." or "off."))
        if accessDebug then
            local n,r=UnitFullName("player")
            accessTrace("UnitFullName=[" .. tostring(n) .. "]; surname/realm=[" .. tostring(r) .. "]; identity=[" .. tostring(me) .. "]")
            accessTrace("Guild roster rows=" .. tostring(GetNumGuildMembers()))
            local matches=0
            for i=1,GetNumGuildMembers() do
                local name,rankName,rank=GetGuildRosterInfo(i)
                if key(name)==key(me) or (name and name:lower():find("oven",1,true)) or i<=3 then
                    if matches<8 then
                        accessTrace("Row " .. i .. ": name=[" .. tostring(name) .. "]; key=[" .. tostring(key(name))
                            .. "]; rank=[" .. tostring(rankName) .. "]; index=" .. tostring(rank))
                        matches=matches+1
                    end
                end
            end
        end
    elseif command == "status" then
        say("Addon version: " .. ((C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("InTheBinKoS","Version")) or (GetAddOnMetadata and GetAddOnMetadata("InTheBinKoS","Version")) or "0.5.11"))
        say("Guild: " .. (guild or "none") .. "; editing: " .. (permitted(me) and "allowed" or "unavailable") .. "; queued messages: " .. #queue)
        local order=rankOrder(me);local flags=rankFlags(order)
        say("Permissions: native officer=" .. tostring(nativeOfficer()) .. "; roster rank=" .. tostring(roster[key(me)])
            .. "; rank order=" .. tostring(order) .. "; officer-chat speak=" .. tostring(flags and flags[4]))
    else
        say("/kos add [Name|target] [reason] (quote names with spaces); /kos remove [Name|target]; /kos list; /kos sync; /kos publish; /kos test; /kos status; /kos sound on|off; /kos alerts on|off")
    end
end
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= "InTheBinKoS" and ... ~= "ForeverKoS" then return end
        ForeverKoSDB = ForeverKoSDB or {guilds={}}
        ForeverKoSDB.guilds = ForeverKoSDB.guilds or {}
        if C_ChatInfo then C_ChatInfo.RegisterAddonMessagePrefix(PREFIX) end
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_GUILD_UPDATE" or event == "GUILD_ROSTER_UPDATE" or event == "GUILD_RANKS_UPDATE" then
        rebuild()
        if event ~= "GUILD_ROSTER_UPDATE" and C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
        request()
        if ForeverKoS.PresenceChanged then ForeverKoS.PresenceChanged() end
    elseif event == "CHAT_MSG_ADDON" then receive(...)
    elseif event == "NAME_PLATE_UNIT_ADDED" then guardedCheck(...)
    elseif event == "PLAYER_TARGET_CHANGED" then guardedCheck("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then guardedCheck("mouseover") end
end)
frame:SetScript("OnUpdate", function(_, delta)
    elapsed, refresh = elapsed + delta, refresh + delta
    if ForeverKoS.PresenceTick then ForeverKoS.PresenceTick(delta) end
    if elapsed >= 0.2 then
        elapsed = 0
        -- Mouseover identity can become readable after the initial event. Retry
        -- while it exists; the per-enemy cooldown prevents duplicate reports.
        if UnitExists("mouseover") then guardedCheck("mouseover") end
        local item = table.remove(queue, 1)
        if item and db and C_ChatInfo then
            -- Recheck permissions at send time in case an officer was demoted.
            local cacheReply=item[2]=="WHISPER" and (item[1]:sub(1,2)=="C\t" or item[1]:sub(1,2)=="H\t" or item[1]:sub(1,2)=="U\t")
            if item[1] == "Q" or item[1]=="P" or item[1]:sub(1,2)=="V\t" or item[1]:sub(1,2)=="J\t" or item[1]:sub(1,2) == "S\t" or cacheReply or permitted(me) then C_ChatInfo.SendAddonMessage(PREFIX, item[1], item[2], item[3]) end
        end
    end
    if refresh >= 300 then
        refresh = 0
        if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
        request()
    end
end)
for _, e in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_GUILD_UPDATE", "GUILD_ROSTER_UPDATE", "GUILD_RANKS_UPDATE", "CHAT_MSG_ADDON", "NAME_PLATE_UNIT_ADDED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT"}) do frame:RegisterEvent(e) end
