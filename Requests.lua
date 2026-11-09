-- Suggestions are separate from KoS records and confer no edit permissions.
local api=ForeverKoS
local RETENTION=3*86400
local function now() return GetServerTime and GetServerTime() or time() end
local function expired(result)
    return result and result.status=="Declined" and result.reviewedAt and now()-result.reviewedAt>=RETENTION
end
local function say(s) print("|cffffb45b<in the bin> KoS List:|r " .. s) end
local function encode(s) return (s:gsub("([^%w%.%- ])",function(c)return string.format("%%%02X",c:byte())end)) end
local function decode(s) return (s:gsub("%%(%x%x)",function(c)return string.char(tonumber(c,16))end)) end
local function data()
    local db,me=api.SightingContext()
    if db then
        db.requests=db.requests or {};db.requestResults=db.requestResults or {}
        for id,result in pairs(db.requestResults) do
            -- Legacy decisions start their retention period when first loaded.
            if not result.reviewedAt then result.reviewedAt=now() end
            if expired(result) then db.requests[id]=nil end
        end
    end
    return db,me
end
local function pack(r)
    return table.concat({"N",encode(r.id),encode(r.requester),encode(r.name),encode(r.reason)},"\t")
end
local function decision(r)
    return table.concat({"D",encode(r.id),r.rev,r.status,encode(r.reviewer),r.reviewedAt or now()},"\t")
end
local function refresh() if api.RefreshRequests then api.RefreshRequests() end end
function api.GetRequests()
    local db,me=data();local rows={}
    for id,r in pairs(db and db.requests or {}) do
        if api.CanAdminGuildAccess() or api.NameKey(r.requester)==api.NameKey(me) then
            local result=db.requestResults[id]
            rows[#rows+1]={id=id,name=r.name,reason=r.reason,requester=r.requester,status=result and result.status or "Pending"}
        end
    end
    table.sort(rows,function(a,b)
        if (a.status=="Pending")~=(b.status=="Pending") then return a.status=="Pending" end
        return a.id>b.id
    end)
    return rows
end
function api.SubmitRequest(name,reason)
    local db,me=data()
    if not db or not me then say("Join a guild before submitting a request.");return end
    name=api.NormalizeName(name)
    if not name then say("Enter the player's full name.");return end
    if type(reason)~="string" or reason:find("[%c|]") or #reason>60 then say("Enter a reason of 1–60 characters.");return end
    reason=reason:match("^ *(.-) *$")
    if reason=="" then say("A reason is required.");return end
    if api.MatchRecord(name) then say("That player is already on the KoS list.");return end
    for id,r in pairs(db.requests) do
        if api.NameKey(r.name)==api.NameKey(name) and not db.requestResults[id] then say("A request for that player is already pending.");return end
    end
    if db.lastRequestSubmitted and GetTime()-db.lastRequestSubmitted<30 and GetTime()>=db.lastRequestSubmitted then say("Wait 30 seconds between requests.");return end
    db.requestSequence=(db.requestSequence or 0)+1
    local stamp=GetServerTime and GetServerTime() or time()
    local r={id=me .. ":" .. stamp .. ":" .. db.requestSequence,requester=me,name=name,reason=reason}
    local message=pack(r)
    if #message>250 then say("Request too long to sync. Shorten the reason.");return end
    db.requests[r.id]=r;db.lastRequestSubmitted=GetTime()
    api.QueueGuildTarget(message)
    say("Request submitted for " .. name .. ". Officers will review it when available.")
    refresh();return true
end
function api.ReviewRequest(id,approve)
    local db,me=data()
    if not db or not api.CanAdminGuildAccess() then say("Only officers can review requests.");return end
    local r=db.requests[id]
    if not r or db.requestResults[id] then return end
    if approve then api.EditSharedCharacter(r.name,r.reason) end
    db.clock=db.clock+1
    local result={id=id,rev=db.clock,status=approve and "Approved" or "Declined",reviewer=me,reviewedAt=now()}
    db.requestResults[id]=result;api.QueueGuildTarget(decision(result));refresh()
end
function api.ReceiveRequest(message,sender,channel,admin)
    local op=message:sub(1,2)
    if op~="N\t" and op~="D\t" then return false end
    local db,me=data();if not db then return true end
    if op=="N\t" then
        local id,requester,name,reason=message:match("^N\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)$")
        if not id then return true end
        id,requester,name,reason=decode(id),api.NormalizeName(decode(requester)),api.NormalizeName(decode(name)),decode(reason)
        if not requester or not name or #id>180 or id:find("[%c|]") or #reason>60 or reason:find("[%c|]") or not reason:find("%S") then return true end
        if api.NameKey(requester)~=api.NameKey(sender) and not admin then return true end
        if expired(db.requestResults[id]) then return true end
        if not db.requests[id] then
            db.requests[id]={id=id,requester=requester,name=name,reason=reason}
            if api.CanAdminGuildAccess() and channel=="GUILD" then say("New KoS request: " .. name .. " from " .. requester .. ". Open Requests to review.") end
        end
    else
        if not admin then return true end
        local id,rev,status,reviewer,reviewedAt=message:match("^D\t([^\t]+)\t(%d+)\t(%a+)\t([^\t]+)\t(%d+)$")
        if not id then id,rev,status,reviewer=message:match("^D\t([^\t]+)\t(%d+)\t(%a+)\t([^\t]+)$") end
        reviewedAt=tonumber(reviewedAt) or now()
        if reviewedAt>now()+120 then return true end
        rev=tonumber(rev)
        if not id or not rev or rev>1000000000000 or (status~="Approved" and status~="Declined") then return true end
        id,reviewer=decode(id),api.NormalizeName(decode(reviewer))
        if not reviewer or #id>180 or id:find("[%c|]") then return true end
        local old=db.requestResults[id]
        if not old or rev>old.rev or (rev==old.rev and reviewer>old.reviewer) then
            db.clock=math.max(db.clock,rev)
            db.requestResults[id]={id=id,rev=rev,status=status,reviewer=reviewer,reviewedAt=reviewedAt}
            local request=db.requests[id]
            if expired(db.requestResults[id]) then db.requests[id]=nil
            elseif request and api.NameKey(request.requester)==api.NameKey(me) and channel=="GUILD" then say("Your request for " .. request.name .. " was " .. status:lower() .. ".") end
        end
    end
    refresh();return true
end
function api.PublishRequests(target)
    local db,me=data();if not db or not target then return end
    local admin=api.CanAdminGuildAccess()
    for _,r in pairs(db.requests) do
        if admin or api.NameKey(r.requester)==api.NameKey(me) then api.QueueGuildTarget(pack(r),target) end
    end
    if admin then for _,r in pairs(db.requestResults) do api.QueueGuildTarget(decision(r),target) end end
end
