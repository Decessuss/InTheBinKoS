-- Character-private PvP killing blows; independent of guild and KoS membership.
local api=ForeverKoS
local frame=CreateFrame("Frame")
local recent={}
local knownNames={}
local lossRecorded=false
local deathGeneration=0
local baselineRecap
local function readable(value)
    return not issecretvalue or not issecretvalue(value)
end
local function playerGUID(guid)
    return readable(guid) and type(guid)=="string" and guid:match("^Player%-%w")~=nil
end
local function data()
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
    if playerGUID(guid) and name then knownNames[api.NameKey(name)]=guid end
end
local function saveResult(opponent,loss)
    if not playerGUID(opponent) then return end
    local db,me=data();if not db or opponent==me or (loss and lossRecorded) then return end
    local stamp=GetTime()
    local dedup=(loss and "loss:" or "win:") .. opponent
    if recent[dedup] and stamp-recent[dedup]<2 then return end
    recent[dedup]=stamp
    -- Session deduplication only; prune to avoid growing a second permanent log.
    for guid,last in pairs(recent) do if stamp-last>5 then recent[guid]=nil end end
    local row=db[opponent] or {count=0,losses=0}
    if loss then row.losses=(row.losses or 0)+1;lossRecorded=true
    else row.count=(row.count or 0)+1 end
    row[loss and "lastLoss" or "lastKill"]=GetServerTime and GetServerTime() or time()
    db[opponent]=row
    if GetPlayerInfoByGUID then
        pcall(function()
            local _,_,_,_,_,name,surname=GetPlayerInfoByGUID(opponent)
            if readable(name) and readable(surname) then row.name=api.CharacterNameFromParts(name,surname) or row.name end
        end)
    end
end
local function record(attacker,victim)
    if not playerGUID(victim) or not readable(attacker) or type(attacker)~="string" then return end
    local _,me=data();if not me then return end
    if victim==me then saveResult(attacker,true);return end
    local pet=UnitGUID and UnitGUID("pet")
    if attacker==me or (readable(pet) and pet and attacker==pet) then saveResult(victim,false) end
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
        lossRecorded=false;deathGeneration=deathGeneration+1
        pcall(function()local _,signature=recapEntry();baselineRecap=signature end)
        return
    end
    if event=="PLAYER_DEAD" then
        deathGeneration=deathGeneration+1;local generation=deathGeneration
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
end)
frame:RegisterEvent("PLAYER_LOGIN")
for _,event in ipairs({"PLAYER_DEAD","PLAYER_ALIVE","PLAYER_UNGHOST","PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","NAME_PLATE_UNIT_ADDED"}) do frame:RegisterEvent(event) end
pcall(frame.RegisterEvent,frame,"PARTY_KILL")
