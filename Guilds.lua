-- Guild-wide KoS rules; character records retain priority when both match.
local api=ForeverKoS
local mode=false
local function say(s) print("|cffff5555<in the bin> KoS List:|r " .. s) end
local function normalize(s)
    if type(s)~="string" or s:find("[%c|]") then return end
    s=s:match("^ *(.-) *$"):gsub(" +"," ")
    if s=="" or #s>100 then return end
    return s
end
api.NormalizeGuildName=normalize
local function key(s) local n=normalize(s);return n and string.lower(n) end
local function data()
    local db,me=api.SightingContext()
    if db then db.guildTargets=db.guildTargets or {} end
    return db,me
end
local function encode(s) return (s:gsub("([^%w%-%. ])",function(c) return string.format("%%%02X",string.byte(c)) end)) end
local function decode(s) return (s:gsub("%%(%x%x)",function(c)return string.char(tonumber(c,16))end)) end
local function pack(r,cached)
    return table.concat({cached and "U" or "T",r.rev,encode(r.editor),r.deleted and "1" or "0",encode(r.name),encode(r.reason)},"\t")
end
local function merge(db,r)
    local k=key(r.name);local old=db.guildTargets[k]
    db.clock=math.max(db.clock,r.rev)
    if not old or r.rev>old.rev or (r.rev==old.rev and r.editor>old.editor) then db.guildTargets[k]=r end
end
function api.EditGuildTarget(name,reason,deleted)
    local db,me=data()
    if not db or not api.CanEditShared() then say("Guild KoS editing requires officer or granted editor access.");return end
    name=normalize(name)
    if not name then say("Enter the full enemy guild name.");return end
    local r={name=name,reason=tostring(reason or ""):gsub("[%c|]"," "):sub(1,60),deleted=not not deleted,editor=me,rev=db.clock+1,kind="guild"}
    local message=pack(r)
    if #message>250 then say("Guild name/reason too long to sync.");return end
    merge(db,r);api.QueueGuildTarget(message)
    say((deleted and "Removed guild <" or "Added guild <") .. name .. ">.")
end
function api.ReceiveGuildTarget(message,sender,channel,canEdit,recentRequest)
    local opcode=message:sub(1,2)
    if opcode~="T\t" and opcode~="U\t" then return false end
    if opcode=="U\t" then
        if channel~="WHISPER" or not recentRequest then return true end
    elseif not canEdit then return true end
    local revision,editor,deleted,name,reason=message:match("^[TU]\t(%d+)\t([^\t]+)\t([01])\t([^\t]+)\t([^\t]*)$")
    revision=tonumber(revision)
    if not revision or revision>1000000000000 then return true end
    editor,name,reason=decode(editor),decode(name),decode(reason)
    name=normalize(name)
    if not api.NormalizeName(editor) or not name or #reason>60 or reason:find("[%c|]") then return true end
    local db=data()
    if db then merge(db,{rev=revision,editor=editor,deleted=deleted=="1",name=name,reason=reason,kind="guild"}) end
    return true
end
function api.PublishGuildTargets(target)
    local db=data();if not db then return end
    for _,r in pairs(db.guildTargets) do api.QueueGuildTarget(pack(r,target~=nil),target) end
end
local playerMatch=api.MatchRecord
function api.MatchRecord(name,guildName)
    local r=playerMatch(name)
    if r then return r end
    local db=data();local k=key(guildName)
    r=db and k and db.guildTargets[k]
    return r and not r.deleted and r or nil
end
function api.MatchReason(r)
    if r.kind=="guild" then return "Guild <" .. r.name .. ">" .. (r.reason~="" and (": " .. r.reason) or "") end
    return r.reason
end
function api.GetGuildSighting(name)
    local db=data();local k=key(name);local latest
    if not k then return end
    for _,s in pairs(db and db.sightings or {}) do
        if key(s.guildName)==k and (not latest or s.stamp>latest.stamp or (s.stamp==latest.stamp and s.name>latest.name)) then latest=s end
    end
    return latest
end
function api.IsGuildMode() return mode end
function api.SetGuildMode(value) mode=not not value end
local state,edit,target=api.GetState,api.Edit,api.AddTarget
function api.GetState()
    if not mode then return state() end
    local _,canEdit,scope,sound,alerts=state()
    local db=data();local rows={}
    for _,r in pairs(db and db.guildTargets or {}) do
        if not r.deleted then rows[#rows+1]={name=r.name,reason=r.reason,editor=r.editor,kind="guild",sighting=api.GetGuildSighting(r.name)} end
    end
    table.sort(rows,function(a,b)return a.name<b.name end)
    return rows,canEdit,scope,sound,alerts
end
function api.Edit(name,reason,deleted)
    if mode then return api.EditGuildTarget(name,reason,deleted) end
    return edit(name,reason,deleted)
end
function api.GetTargetGuildName()
    if not UnitIsPlayer("target") then say("Target an enemy guild member first.");return end
    local faction,own=UnitFactionGroup("target"),UnitFactionGroup("player")
    if not faction or not own or faction==own then say("Target a player from the opposing faction.");return end
    local name=GetGuildInfo("target")
    if not name then say("Target guild unavailable. Enter its full name manually.");return end
    return normalize(name)
end
function api.AddTarget(reason)
    if not mode then return target(reason) end
    local name=api.GetTargetGuildName()
    if name then return api.EditGuildTarget(name,reason,false) end
end
local slash=SlashCmdList.FOREVERKOS
SlashCmdList.FOREVERKOS=function(input)
    local command,rest=input:match("^(%S*)%s*(.-)$")
    if command=="addguild" or command=="removeguild" then
        local name,reason,problem=api.ParseNameReason(rest)
        if problem then say(problem);return end
        return api.EditGuildTarget(name,reason,command=="removeguild")
    end
    return slash(input)
end
