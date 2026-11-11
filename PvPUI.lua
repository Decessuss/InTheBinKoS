local api=ForeverKoS
local window,mode,rows=nil,"kills",{}
local function label(parent,text,x,y,style)
    local f=parent:CreateFontString(nil,"OVERLAY",style or "GameFontHighlightSmall")
    f:SetPoint("TOPLEFT",x,y);f:SetText(text);return f
end
function api.RefreshPvPStats()
    if not window or not window:IsShown() then return end
    local entries=api.GetPvPStatsRows(mode)
    for key,button in pairs(window.tabs)do button:SetEnabled(key~=mode)end
    window.description:SetText(mode=="slain" and "Latest KoS defeats. Counts show each guild member's confirmed killing blows." or mode=="guild" and "Guild records since 0.6.0. Wins include credited assists." or (mode=="recent" and "Recent opponents, showing the latest recorded encounter with each." or "Your top 10 since 0.6.0. Wins include credited assists."))
    window.empty:SetShown(#entries==0)
    window.empty:SetText(mode=="guild" and "Join a guild to see shared member records." or "No tracked encounters yet.")
    for i,row in ipairs(rows)do
        local r=entries[i];row:SetShown(r~=nil)
        if r then
            if mode=="slain" then
                row.title:SetText(r.enemy .. " has been slain by " .. r.name)
                row.detail:SetText(r.count .. (r.count==1 and " time" or " times"))
                row.extra:SetText("Last slain: " .. api.SightingAge({stamp=r.stamp}))
            else
            row.title:SetText(i .. ". " .. r.name .. "  |  " .. r.wins .. " wins / " .. r.losses .. " losses")
            if mode=="guild" then
                row.detail:SetText(r.topCount>0 and ("Top opponent: " .. r.topName .. " (" .. r.topCount .. ")") or "No tracked wins yet")
                row.extra:SetText("Last shared: " .. api.SightingAge({stamp=r.stamp}))
            else
                local unknown=math.max(0,r.wins-r.blows-r.assists)
                row.detail:SetText("Killing blows: " .. r.blows .. " | Assists: " .. r.assists .. (unknown>0 and (" | Earlier: " .. unknown) or ""))
                local stamp=math.max(r.lastKill,r.lastLoss)
                local result=r.lastLoss>r.lastKill and "Loss" or (r.lastKillType=="killingBlow" and "Killing blow" or (r.lastKillType=="assist" and "Assist" or "Win (unclassified)"))
                row.extra:SetText(stamp>0 and (result .. " — " .. api.SightingAge({stamp=stamp})) or "")
            end
            end
        end
    end
end
function api.CreatePvPPage(parent)
    if window then return window end
    window=CreateFrame("Frame","InTheBinKoSPvP",parent)
    window:SetSize(520,560);window:SetPoint("TOPLEFT",parent,"TOPLEFT",20,-80)
    label(window,"PvP Records",0,-10,"GameFontNormalLarge")
    window.tabs={}
    local choices={{"kills","Top Kills"},{"deaths","Most Deaths"},{"recent","Recent Opponents"},{"guild","Guild"},{"slain","KoS Slain"}}
    for i,choice in ipairs(choices)do
        local key=choice[1]
        local b=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
        b:SetSize(100,24);b:SetPoint("TOPLEFT",(i-1)*104,-40);b:SetText(choice[2])
        b:SetScript("OnClick",function()mode=key;if mode=="guild" or mode=="slain" then api.RequestPvPLeaderboard() end;api.RefreshPvPStats()end)
        window.tabs[key]=b
    end
    window.description=label(window,"",0,-76)
    window.description:SetWidth(515);window.description:SetJustifyH("LEFT")
    window.empty=label(window,"No tracked encounters yet.",0,-110)
    for i=1,10 do
        local row=CreateFrame("Frame",nil,window);row:SetSize(515,43);row:SetPoint("TOPLEFT",0,-105-(i-1)*43)
        row.title=label(row,"",0,0,"GameFontNormal")
        row.title:SetWidth(515);row.title:SetJustifyH("LEFT")
        row.detail=label(row,"",0,-14);row.detail:SetWidth(515);row.detail:SetJustifyH("LEFT")
        row.extra=label(row,"",0,-27,"GameFontDisableSmall")
        row.extra:SetWidth(515);row.extra:SetJustifyH("LEFT")
        rows[i]=row
    end
    window:SetScript("OnShow",api.RefreshPvPStats);window:Hide();return window
end
