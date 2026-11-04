-- Guild members may report sightings; this never grants list editing rights.
local api=ForeverKoS
local function now() return GetServerTime and GetServerTime() or time() end
local function encode(s) return (s:gsub("([^%w%-%. ])",function(c) return string.format("%%%02X",string.byte(c)) end)) end
local function decode(s) return (s:gsub("%%(%x%x)",function(c) return string.char(tonumber(c,16)) end)) end
local function records()
    local db,me=api.SightingContext()
    if not db then return end
    db.sightings=db.sightings or {}
    return db,me
end
local function active(db,name)
    local r=db.records[api.NameKey(name)]
    return r and not r.deleted
end
local function pack(r)
    return table.concat({"S",r.stamp,encode(r.name),r.map,math.floor(r.x*100000+0.5),math.floor(r.y*100000+0.5),encode(r.spotter)},"\t")
end
local function merge(db,r)
    local key=api.NameKey(r.name)
    local old=db.sightings[key]
    if not old or r.stamp>old.stamp or (r.stamp==old.stamp and r.spotter>old.spotter) then
        db.sightings[key]=r
        return true
    end
end
function api.RecordSighting(name)
    local db,me=records()
    if not db or not me or not active(db,name) then return end
    local map,x,y
    if api.SpotPosition then map,x,y=api.SpotPosition() end
    local r={name=name,spotter=me,stamp=now(),map=map or 0,x=x or 0,y=y or 0}
    if merge(db,r) then
        local message=pack(r)
        if #message<=250 then api.QueueSighting(message) end
    end
end
function api.ReceiveSighting(message,sender,isOfficer,isHistory)
    local db=records()
    if not db then return end
    local stamp,name,map,x,y,spotter=message:match("^S\t(%d+)\t([^\t]+)\t(%d+)\t(%d+)\t(%d+)\t([^\t]+)$")
    stamp,map,x,y=tonumber(stamp),tonumber(map),tonumber(x),tonumber(y)
    if not stamp or not map or not x or not y then return end
    name,spotter=decode(name),decode(spotter)
    if not api.NormalizeName(name) or not api.NormalizeName(spotter) then return end
    -- A member can speak only for themselves. Officers may relay saved history.
    if api.NameKey(spotter)~=api.NameKey(sender) and not isOfficer then return end
    if stamp>now()+120 or stamp<now()-7*86400 or x>100000 or y>100000 or map>100000 then return end
    if map==0 and (x~=0 or y~=0) then return end
    if map~=0 and x==0 and y==0 then return end
    if map~=0 and C_Map and C_Map.GetMapInfo and not C_Map.GetMapInfo(map) then return end
    if not active(db,name) then return end
    local r={name=name,spotter=spotter,stamp=stamp,map=map,x=x/100000,y=y/100000}
    local changed=merge(db,r)
    local age=now()-stamp
    if changed and not isHistory and age>=-15 and age<=30
            and api.NameKey(spotter)==api.NameKey(sender) and api.NotifyGuildSighting then
        api.NotifyGuildSighting(r)
    end
end
function api.PublishSightings(target)
    local db=records()
    if not db then return end
    -- Guild peers can serve requested history; unsolicited broadcasts remain officer-only.
    for _,r in pairs(db.sightings) do
        if active(db,r.name) and r.stamp>=now()-7*86400 then
            local message=pack(r)
            if target then message="H" .. message:sub(2) end
            if #message<=250 then api.QueueSighting(message,target) end
        end
    end
end
function api.GetSighting(name)
    local db=records()
    return db and db.sightings[api.NameKey(name)]
end
function api.SightingZone(r)
    if not r or r.map==0 then return "Location unavailable" end
    local info=C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(r.map)
    return info and info.name or "Unknown zone"
end
function api.SightingAge(r)
    if not r then return "Not seen yet" end
    local age=math.max(0,now()-r.stamp)
    if age<60 then return "Just now" end
    if age<3600 then return math.floor(age/60) .. "m ago" end
    if age<86400 then return math.floor(age/3600) .. "h ago" end
    return math.floor(age/86400) .. "d ago"
end
function api.PinSighting(name)
    local r=api.GetSighting(name)
    if not r or r.map==0 or not api.OpenSpotLink then return end
    api.OpenSpotLink(string.format("garrmission:foreverkos:%d:%d:%d",r.map,math.floor(r.x*100000+0.5),math.floor(r.y*100000+0.5)))
end
