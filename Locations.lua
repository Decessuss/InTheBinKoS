-- Clickable, private sighting locations. Coordinates belong to the local spotter
-- at detection time, never to the enemy or the spotter's later position.
local api = ForeverKoS
local function valid(map, x, y)
    return type(map)=="number" and map>0 and map==math.floor(map)
        and type(x)=="number" and type(y)=="number"
        and x>=0 and x<=1 and y>=0 and y<=1 and not (x==0 and y==0)
end
function api.SpotPosition()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return end
    local map=C_Map.GetBestMapForUnit("player")
    if not map then return end
    local position=C_Map.GetPlayerMapPosition(map,"player")
    if not position then return end
    local x,y=position:GetXY()
    if not valid(map,x,y) then return end
    return map,x,y
end
function api.MakeSpotLink()
    local map,x,y=api.SpotPosition()
    if not map then return end
    return api.LinkForPosition(map,x,y)
end
function api.LinkForPosition(map,x,y)
    if not valid(map,x,y) then return end
    local info=C_Map.GetMapInfo and C_Map.GetMapInfo(map)
    local zone=(info and info.name or GetZoneText() or "Location"):gsub("[%c|%[%]]"," ")
    -- garrmission is also used by WeakAuras custom links on this client.
    return string.format("|cff66ccff|Hgarrmission:foreverkos:%d:%d:%d|h[%s %.1f, %.1f]|h|r",
        map,math.floor(x*100000+0.5),math.floor(y*100000+0.5),zone,x*100,y*100)
end
function api.OpenSpotLink(link)
    if type(link)~="string" then return false end
    local map,x,y=link:match("^garrmission:foreverkos:(%d+):(%d+):(%d+)$")
    map,x,y=tonumber(map),tonumber(x),tonumber(y)
    if not map or not x or not y then return false end
    x,y=x/100000,y/100000
    if not valid(map,x,y) then return false end
    if C_Map and C_Map.GetMapInfo and not C_Map.GetMapInfo(map) then return false end
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(map) then
            print("<in the bin> KoS List: This map does not support a waypoint."); return true
        end
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map,x,y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
        print("<in the bin> KoS List: Native map pin set at the spotter's sighting location.")
    elseif TomTom and TomTom.AddWaypoint then
        TomTom:AddWaypoint(map,x,y,{title="KoS sighting — spotter's position",persistent=false,minimap=true,world=true,crazy=true})
    else
        print("<in the bin> KoS List: Enable TomTom to pin this sighting location on this client.")
    end
    return true
end
if hooksecurefunc and SetItemRef then
    hooksecurefunc("SetItemRef",function(link)
        if type(link)=="string" and link:match("^garrmission:foreverkos:") then
            local ok=pcall(api.OpenSpotLink,link)
            if not ok then print("<in the bin> KoS List: Could not place this location pin.") end
        end
    end)
end
