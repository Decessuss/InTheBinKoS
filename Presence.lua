-- Session-only guild addon discovery. Presence never confers edit permissions.
local api=ForeverKoS
local scope,users,lastAnnounce,lastQuery=nil,{},-1000,-1000
local elapsed,mode=0,false
local function context()
    local db,me=api.SightingContext()
    if db~=scope then scope=db;users={};lastAnnounce=-1000;lastQuery=-1000 end
    return db,me
end
local function version()
    local query=C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local value=query and query("InTheBinKoS","Version") or "0.5.6"
    return type(value)=="string" and value:match("^%d+%.%d+%.%d+[%w%.%-]*$") and value or "0.5.6"
end
local function announce()
    local db,me=context();if not db or not me or GetTime()-lastAnnounce<30 then return end
    lastAnnounce=GetTime()
    users[api.NameKey(me)]={version=version(),stamp=GetTime()}
    api.QueuePresence("V\t" .. version())
end
function api.PresenceChanged() announce() end
function api.PresenceTick(delta)
    elapsed=elapsed+delta
    if elapsed>=300 then elapsed=0;announce() end
end
function api.ReceivePresence(message,sender,channel)
    if message=="P" then announce();return true end
    if message:sub(1,2)~="V\t" then return false end
    local value=message:match("^V\t(%d+%.%d+%.%d+[%w%.%-]*)$")
    if not value or #value>32 then return true end
    local db=context()
    local k=api.NameKey(sender)
    if db and k then users[k]={version=value,stamp=GetTime()} end
    return true
end
function api.RequestAddonUsers()
    if not api.CanManageAccess() then return end
    local db=context();if not db or GetTime()-lastQuery<30 then return end
    lastQuery=GetTime()
    announce();api.QueuePresence("P")
    if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
end
function api.GetAddonUsers()
    if not api.CanManageAccess() then return {} end
    local db,me=context();if not db then return {} end
    local rows={}
    for i=1,GetNumGuildMembers() do
        local name,rank,_,_,_,_,_,_,online=GetGuildRosterInfo(i)
        name=api.NormalizeName(name)
        if name and (online==true or online==1 or api.NameKey(name)==api.NameKey(me)) then
            local info=users[api.NameKey(name)]
            if api.NameKey(name)==api.NameKey(me) then info={version=version(),stamp=GetTime()} end
            local detected=info and GetTime()-info.stamp<=660
            rows[#rows+1]={name=name,editor=name,version=detected and info.version or nil,
                reason=detected and ("Addon " .. info.version .. " — " .. api.SharedAccessLabel(name)) or "No addon response yet",
                presence=true,rank=rank,detected=not not detected}
        end
    end
    table.sort(rows,function(a,b)
        if a.detected~=b.detected then return a.detected end
        return a.name<b.name
    end)
    return rows
end
function api.IsUsersMode()
    if mode and not api.CanManageAccess() then mode=false end
    return mode
end
function api.SetUsersMode(value)
    mode=value and api.CanManageAccess() or false
    if mode then
        api.SetPersonalMode(false);api.SetGuildMode(false)
        api.RequestAddonUsers()
    end
end
local state=api.GetState
function api.GetState()
    if not api.IsUsersMode() then return state() end
    local _,_,guild,sound,alerts=state()
    return api.GetAddonUsers(),false,guild,sound,alerts
end

local slash=SlashCmdList.FOREVERKOS
SlashCmdList.FOREVERKOS=function(input)
    local command=input:match("^(%S*)")
    if command=="guild" or command=="personal" then api.SetUsersMode(false) end
    return slash(input)
end
