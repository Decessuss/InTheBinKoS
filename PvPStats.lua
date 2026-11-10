-- Share member summaries only. Personal opponent histories stay on this client.
local api=ForeverKoS
local scope,lastSent,lastReply,lastQuery,elapsed=nil,-1000,-1000,-1000,0
local dirty,queried=true,false
local function now()return GetServerTime and GetServerTime() or time()end
local function encode(s)return(s:gsub("([^%w%.%- ])",function(c)return string.format("%%%02X",c:byte())end))end
local function decode(s)return(s:gsub("%%(%x%x)",function(c)return string.char(tonumber(c,16))end))end
local function context()
    api.EnsurePvPRecordEpoch()
    local db,me=api.SightingContext()
    if scope~=db then scope=db;lastSent=-1000;lastReply=-1000;lastQuery=-1000;dirty=true;queried=false end
    if db then db.pvpLeaderboard=db.pvpLeaderboard or {} end
    return db,me
end
local function summary()
    local result={wins=0,losses=0,blows=0,assists=0,topName="",topCount=0}
    for _,r in ipairs(api.GetPersonalPvPRows()) do
        for _,key in ipairs({"wins","losses","blows","assists"})do result[key]=result[key]+r[key]end
        if r.wins>result.topCount or (r.wins==result.topCount and r.name<result.topName) then result.topName=r.name;result.topCount=r.wins end
    end
    return result
end
local function publish(force)
    local db,me=context();if not db or not me or (not force and GetTime()-lastSent<10) then return end
    local r=summary();r.name=me;r.stamp=now()
    local message=table.concat({"L","0.6.0",r.stamp,r.wins,r.losses,r.blows,r.assists,encode(r.topName),r.topCount},"\t")
    if #message>250 then return end
    db.pvpLeaderboard[api.NameKey(me)]=r
    api.QueuePresence(message);lastSent=GetTime();dirty=false
end
function api.PvPStatsChanged()dirty=true end
function api.PvPStatsGuildChanged()
    local db=context()
    if db and not queried then queried=true;api.QueuePresence("l") end
end
function api.PvPStatsTick(delta)
    elapsed=elapsed+delta;if elapsed<1 then return end;elapsed=0
    context()
    if dirty or GetTime()-lastSent>=300 then publish(false) end
end
function api.RequestPvPLeaderboard()
    local db=context();if not db or GetTime()-lastQuery<30 then return end
    lastQuery=GetTime();api.QueuePresence("l");publish(false)
end
function api.ReceivePvPStats(message,sender)
    if message=="l" then
        context()
        if GetTime()-lastReply>=30 then lastReply=GetTime();publish(true) end
        return true
    end
    if message:sub(1,2)~="L\t" then return false end
    local stamp,wins,losses,blows,assists,top,topCount=message:match("^L\t0%.6%.0\t(%d+)\t(%d+)\t(%d+)\t(%d+)\t(%d+)\t([^\t]*)\t(%d+)$")
    if not stamp then return true end
    stamp,wins,losses,blows,assists,topCount=tonumber(stamp),tonumber(wins),tonumber(losses),tonumber(blows),tonumber(assists),tonumber(topCount)
    if stamp>now()+120 or wins>1e9 or losses>1e9 or blows+assists>wins or topCount>wins then return true end
    top=decode(top)
    if top~="" then top=api.NormalizeName(top);if not top then return true end end
    if (topCount>0 and top=="") or (topCount==0 and top~="") then return true end
    local db=context();local name=api.NormalizeName(sender);if not db or not name then return true end
    local key=api.NameKey(name);local old=db.pvpLeaderboard[key]
    if not old or stamp>old.stamp or (stamp==old.stamp and wins+losses>=old.wins+old.losses) then
        db.pvpLeaderboard[key]={name=name,stamp=stamp,wins=wins,losses=losses,blows=blows,assists=assists,topName=top,topCount=topCount}
    end
    return true
end
function api.GetPvPStatsRows(mode)
    local rows={}
    if mode=="guild" then
        local db,me=context()
        for _,r in pairs(db and db.pvpLeaderboard or {})do
            if api.IsCurrentGuildMember(r.name) and api.NameKey(r.name)~=api.NameKey(me) then rows[#rows+1]=r end
        end
        if db and me then local r=summary();r.name=me;r.stamp=now();rows[#rows+1]=r end
    else
        for _,r in ipairs(api.GetPersonalPvPRows())do
            r.last=math.max(r.lastKill,r.lastLoss)
            if (mode=="deaths" and r.losses>0) or (mode=="recent" and r.last>0) or (mode=="kills" and r.wins>0) then rows[#rows+1]=r end
        end
    end
    local field=mode=="deaths" and "losses" or (mode=="recent" and "last" or "wins")
    table.sort(rows,function(a,b)if a[field]~=b[field] then return a[field]>b[field] end;return a.name<b.name end)
    while #rows>10 do table.remove(rows)end
    return rows
end
