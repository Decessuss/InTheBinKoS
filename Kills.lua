-- Personal PvP kill credit and losses, independent of guild and KoS membership.
local api=ForeverKoS
local frame=CreateFrame("Frame")
local recent={}
local recentTypes={}
local knownNames={}
local lossRecorded=false
local deathGeneration=0
local baselineRecap
local adoptCredits
local RECORD_EPOCH="0.6.0"
function api.EnsurePvPRecordEpoch()
    ForeverKoSDB=ForeverKoSDB or {guilds={}}
    if ForeverKoSDB.pvpRecordEpoch==RECORD_EPOCH then return end
    -- Start the official counting period once, across all characters on this account.
    ForeverKoSDB.pvpKills={}
    for _,db in pairs(ForeverKoSDB.guilds or {})do db.pvpLeaderboard={} end
    ForeverKoSDB.pvpRecordEpoch=RECORD_EPOCH
end
local function readable(value)
    return not issecretvalue or not issecretvalue(value)
end
local function trackingAllowed()
    if not IsInInstance then return true end
    local _,kind=IsInInstance()
    return readable(kind) and kind~="pvp" and kind~="arena"
end
local function playerGUID(guid)
    return readable(guid) and type(guid)=="string" and guid:match("^Player%-%w")~=nil
end
local function data()
    api.EnsurePvPRecordEpoch()
    local me=UnitGUID and UnitGUID("player")
    if not playerGUID(me) then return end
    ForeverKoSDB=ForeverKoSDB or {guilds={}}
    ForeverKoSDB.pvpKills=ForeverKoSDB.pvpKills or {}
    ForeverKoSDB.pvpKills[me]=ForeverKoSDB.pvpKills[me] or {}
    return ForeverKoSDB.pvpKills[me],me
end
local function remember(unit)
    if not unit or not UnitIsPlayer(unit) then return end
    local guid=UnitGUID(unit);local name=api.UnitCharacterName(unit)
    if playerGUID(guid) and name then
        knownNames[api.NameKey(name)]=guid
        if adoptCredits then adoptCredits(guid,name) end
    end
end
adoptCredits=function(guid,name)
    local db=data();local key=name and api.NameKey(name)
    local pending=db and db.namedCredits and key and db.namedCredits[key]
    if not pending or not playerGUID(guid) then return end
    local row=db[guid] or {count=0,losses=0}
    row.count=(row.count or 0)+pending.count;row.name=name
    row.assists=(row.assists or 0)+pending.count
    if not row.lastKill or pending.lastKill>=row.lastKill then row.lastKill=pending.lastKill;row.lastKillType="assist" end
    db[guid]=row;db.namedCredits[key]=nil
    if api.PvPStatsChanged then api.PvPStatsChanged() end
    local now=GetServerTime and GetServerTime() or time()
    if now-pending.lastKill>=0 and now-pending.lastKill<2 then recent["win:" .. guid]=GetTime();recentTypes["win:" .. guid]="assist" end
end
local function saveResult(opponent,loss,creditType)
    if not trackingAllowed() then return end
    if not playerGUID(opponent) then return end
    local db,me=data();if not db or opponent==me or (loss and lossRecorded) then return end
    local name
    if GetPlayerInfoByGUID then
        pcall(function()
            local _,_,_,_,_,first,surname=GetPlayerInfoByGUID(opponent)
            if readable(first) and readable(surname) then name=api.CharacterNameFromParts(first,surname) end
        end)
    end
    if name then adoptCredits(opponent,name);knownNames[api.NameKey(name)]=opponent end
    local stamp=GetTime()
    local dedup=(loss and "loss:" or "win:") .. opponent
    if recent[dedup] and stamp-recent[dedup]<2 then
        -- Honor credit may arrive before the killing-blow event. Upgrade its
        -- classification without awarding another win.
        local row=db[opponent]
        if not loss and creditType=="killingBlow" and recentTypes[dedup]=="assist" and row then
            row.assists=math.max(0,(row.assists or 0)-1)
            row.killingBlows=(row.killingBlows or 0)+1
            row.lastKillType="killingBlow";recentTypes[dedup]="killingBlow"
            if api.PvPStatsChanged then api.PvPStatsChanged() end
        end
        return
    end
    recent[dedup]=stamp
    recentTypes[dedup]=creditType
    -- Session deduplication only; prune to avoid growing a second permanent log.
    for guid,last in pairs(recent) do if stamp-last>5 then recent[guid]=nil;recentTypes[guid]=nil end end
    local row=db[opponent] or {count=0,losses=0}
    if loss then row.losses=(row.losses or 0)+1;lossRecorded=true
    else
        row.count=(row.count or 0)+1
        local field=creditType=="killingBlow" and "killingBlows" or "assists"
        row[field]=(row[field] or 0)+1;row.lastKillType=creditType
    end
    row[loss and "lastLoss" or "lastKill"]=GetServerTime and GetServerTime() or time()
    db[opponent]=row
    row.name=name or row.name
    if api.PvPStatsChanged then api.PvPStatsChanged() end
end
local function honorPattern(format)
    if type(format)~="string" then return end
    local pattern,captures,victim,index={},0,nil,1
    while index<=#format do
        local char=format:sub(index,index)
        if char=="%" then
            if format:sub(index+1,index+1)=="%" then pattern[#pattern+1]="%%";index=index+2
            else
                local rest=format:sub(index)
                local positional,kind=rest:match("^%%(%d+)%$([sd])")
                local token=positional and ("%" .. positional .. "$" .. kind) or rest:match("^%%[sd]")
                if not token then return end
                kind=kind or token:sub(-1);captures=captures+1
                if kind=="s" and ((positional and tonumber(positional)==1) or (not positional and not victim)) then victim=captures end
                pattern[#pattern+1]=kind=="s" and "(.+)" or "(%d+)"
                index=index+#token
            end
        else
            pattern[#pattern+1]=char:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")
            index=index+1
        end
    end
    if victim then return "^" .. table.concat(pattern) .. "$",victim end
end
local function honorCredit(message)
    if not trackingAllowed() then return end
    if not readable(message) or type(message)~="string" then return end
    local name
    for _,key in ipairs({"COMBATLOG_HONORGAIN","COMBATLOG_HONORGAIN_NO_RANK","COMBATLOG_HONORGAIN_EXHAUSTION","COMBATLOG_HONORGAIN_NO_RANK_EXHAUSTION"}) do
        local pattern,victim=honorPattern(_G[key])
        if pattern then local fields={message:match(pattern)};name=fields[victim];if name then break end end
    end
    name=name and api.NormalizeName(name)
    if not name then return end -- Bonus honor does not identify a defeated player.
    pcall(remember,"target");pcall(remember,"mouseover")
    local db=data();if not db then return end
    local key=api.NameKey(name);local guid=knownNames[key]
    if not guid then
        for candidate,row in pairs(db) do
            if playerGUID(candidate) and type(row)=="table" and row.name and api.NameKey(row.name)==key then guid=candidate;break end
        end
    end
    if guid then saveResult(guid,false,"assist");return end
    -- A named game credit can be retained before the player's GUID is observed.
    db.namedCredits=db.namedCredits or {}
    local row=db.namedCredits[key] or {count=0}
    local now=GetServerTime and GetServerTime() or time()
    if row.lastKill and now-row.lastKill<2 then return end
    row.count=row.count+1;row.lastKill=now;db.namedCredits[key]=row
    if api.PvPStatsChanged then api.PvPStatsChanged() end
end
function api.GetPersonalPvPRows()
    local db=data();local rows={}
    for guid,row in pairs(db or {}) do
        if playerGUID(guid) and type(row)=="table" then
            rows[#rows+1]={name=row.name or "Unknown player",wins=row.count or 0,losses=row.losses or 0,
                blows=row.killingBlows or 0,assists=row.assists or 0,lastKill=row.lastKill or 0,lastLoss=row.lastLoss or 0,
                lastKillType=row.lastKillType}
        end
    end
    for name,row in pairs(db and db.namedCredits or {}) do
        rows[#rows+1]={name=name,wins=row.count,losses=0,blows=0,assists=row.count,lastKill=row.lastKill,lastLoss=0,lastKillType="assist"}
    end
    return rows
end
local function record(attacker,victim)
    if not playerGUID(victim) or not readable(attacker) or type(attacker)~="string" then return end
    local _,me=data();if not me then return end
    if victim==me then saveResult(attacker,true);return end
    local pet=UnitGUID and UnitGUID("pet")
    if attacker==me or (readable(pet) and pet and attacker==pet) then saveResult(victim,false,"killingBlow") end
end
local function recapEntry()
    if not C_DeathRecap or not C_DeathRecap.GetRecapEvents then return end
    local events=C_DeathRecap.GetRecapEvents()
    local hit=type(events)=="table" and events[1]
    if type(hit)~="table" or not readable(hit.timestamp) or not readable(hit.sourceGUID) or not readable(hit.sourceName) then return end
    local signature=tostring(hit.timestamp) .. ":" .. tostring(hit.sourceGUID) .. ":" .. tostring(hit.sourceName)
    return hit,signature
end
local function inspectDeath()
    if lossRecorded then return end
    local hit,signature=recapEntry()
    if not hit or signature==baselineRecap or hit.event=="ENVIRONMENTAL_DAMAGE" then return end
    local guid=hit.sourceGUID
    if guid and not playerGUID(guid) then return end
    if not playerGUID(guid) then
        local name=api.NormalizeName(hit.sourceName)
        guid=name and knownNames[api.NameKey(name)]
    end
    if playerGUID(guid) then saveResult(guid,true) end
end
function api.GetPlayerKillCount(guid)
    if not playerGUID(guid) then return 0 end
    local db=data();local row=db and db[guid]
    return row and row.count or 0
end
function api.GetPlayerPvPRecord(guid)
    if not playerGUID(guid) then return 0,0 end
    local db=data();local row=db and db[guid]
    return row and row.count or 0,row and row.losses or 0
end
function api.GetPlayerPvPBreakdown(guid)
    if not playerGUID(guid) then return 0,0,0 end
    local db=data();local row=db and db[guid]
    local blows=row and row.killingBlows or 0
    local assists=row and row.assists or 0
    return blows,assists,math.max(0,(row and row.count or 0)-blows-assists)
end
local function tooltipLine(tooltip)
    if api.Settings().showPvPRecordTooltip==false then return end
    if not tooltip or not tooltip.GetUnit then return end
    local _,unit=tooltip:GetUnit()
    if not readable(unit) or not unit or not UnitIsPlayer(unit) then return end
    if UnitIsFriend then
        if UnitIsFriend("player",unit) then return end
    else
        local faction,own=UnitFactionGroup(unit),UnitFactionGroup("player")
        if not faction or not own or faction==own then return end
    end
    local guid=UnitGUID(unit)
    if not playerGUID(guid) then return end
    if tooltip.inTheBinKillsAdded then return end
    tooltip.inTheBinKillsAdded=true
    remember(unit)
    local wins,losses=api.GetPlayerPvPRecord(guid)
    tooltip:AddLine("Your PvP record: " .. wins .. " wins / " .. losses .. " losses",1,0.55,0.12)
    local blows,assists,unknown=api.GetPlayerPvPBreakdown(guid)
    tooltip:AddLine("Killing blows: " .. blows .. " | Assists: " .. assists,0.8,0.8,0.8)
    if unknown>0 then tooltip:AddLine("Earlier wins (unclassified): " .. unknown,0.65,0.65,0.65) end
end
local function guardedTooltip(tooltip) pcall(tooltipLine,tooltip) end
local function hookTooltips()
    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipCleared",function(self)self.inTheBinKillsAdded=nil end)
    end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,guardedTooltip)
    elseif GameTooltip and GameTooltip.HookScript then
        pcall(GameTooltip.HookScript,GameTooltip,"OnTooltipSetUnit",guardedTooltip)
    end
end
frame:SetScript("OnEvent",function(_,event,...)
    if event=="PLAYER_LOGIN" then pcall(hookTooltips) end
    if event=="PLAYER_LOGIN" or event=="PLAYER_ALIVE" or event=="PLAYER_UNGHOST" then
        api.EnsurePvPRecordEpoch()
        lossRecorded=false;deathGeneration=deathGeneration+1
        pcall(function()local _,signature=recapEntry();baselineRecap=signature end)
        return
    end
    if event=="PLAYER_DEAD" then
        deathGeneration=deathGeneration+1;local generation=deathGeneration
        if not trackingAllowed() then lossRecorded=true;return end
        pcall(inspectDeath)
        if C_Timer and C_Timer.After then
            for _,delay in ipairs({0.2,0.8,2}) do C_Timer.After(delay,function()if generation==deathGeneration then pcall(inspectDeath) end end) end
        end
        return
    end
    if event=="PLAYER_TARGET_CHANGED" then pcall(remember,"target");return end
    if event=="UPDATE_MOUSEOVER_UNIT" then pcall(remember,"mouseover");return end
    if event=="NAME_PLATE_UNIT_ADDED" then pcall(remember,...);return end
    if event=="PARTY_KILL" then pcall(record,...);return end
    if event=="CHAT_MSG_COMBAT_HONOR_GAIN" then pcall(honorCredit,...);return end
end)
frame:RegisterEvent("PLAYER_LOGIN")
for _,event in ipairs({"PLAYER_DEAD","PLAYER_ALIVE","PLAYER_UNGHOST","PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","NAME_PLATE_UNIT_ADDED"}) do frame:RegisterEvent(event) end
pcall(frame.RegisterEvent,frame,"PARTY_KILL")
frame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
