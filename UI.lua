local api = ForeverKoS
local window, minimap, refresh
local page, selected, rows = 1, nil, {}
local SIZE = 7
local function usersMode() return api.IsUsersMode and api.IsUsersMode() end
local function guildMode() return api.IsGuildMode and api.IsGuildMode() and not api.IsPersonalMode() end
local function entryName(name) return guildMode() and name or api.DisplayName(name) end
local function sightingFor(name) return guildMode() and api.GetGuildSighting(name) or (not guildMode() and api.GetSighting(name)) end
local function pin(name) local s=name and sightingFor(name);if s then api.PinSighting(s.name) end end
local function label(parent, text, x, y, size)
    local f = parent:CreateFontString(nil,"OVERLAY",size or "GameFontNormal")
    f:SetPoint("TOPLEFT",x,y); f:SetText(text)
    return f
end
local function button(parent, text, x, y, width, action)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,24); b:SetPoint("TOPLEFT",x,y); b:SetText(text)
    b:SetScript("OnClick",action)
    return b
end
local function editBox(parent, x, y, width, limit)
    local e=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
    e:SetSize(width,24); e:SetPoint("TOPLEFT",x,y); e:SetAutoFocus(false); e:SetMaxLetters(limit)
    e:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    return e
end
local function createWindow()
    window=CreateFrame("Frame","ForeverKoSWindow",UIParent,"BackdropTemplate")
    window:SetSize(560,642); window:SetPoint("CENTER"); window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true); window:EnableMouse(true); window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart",function(self) self:StartMoving() end)
    window:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    window:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    local base=window:CreateTexture(nil,"BACKGROUND",nil,-8)
    base:SetAllPoints(window); base:SetColorTexture(0.025,0.025,0.03,1)
    local art=window:CreateTexture(nil,"BACKGROUND",nil,-7)
    window.art=art
    art:SetSize(510,510); art:SetPoint("CENTER",window,"CENTER",0,0)
    art:SetTexture("Interface\\AddOns\\InTheBinKoS\\Media\\GuildBackground.tga")
    local shade=window:CreateTexture(nil,"BACKGROUND",nil,-6)
    shade:SetAllPoints(window); shade:SetColorTexture(0.015,0.018,0.025,0.78)
    label(window,"<in the bin> KoS List",20,-18,"GameFontNormalLarge")
    local close=CreateFrame("Button",nil,window,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",-4,-4)
    table.insert(UISpecialFrames,"ForeverKoSWindow")
    window.status=label(window,"",20,-76,"GameFontHighlightSmall")
    window.status:SetWidth(515); window.status:SetJustifyH("LEFT")
    window.rank=label(window,"",300,-24,"GameFontHighlightSmall")
    window.rank:SetWidth(210); window.rank:SetJustifyH("RIGHT")
    local function switchList(value,guilds,users)
        if api.SetPersonalMode then api.SetPersonalMode(value) end
        if api.SetGuildMode then api.SetGuildMode(guilds) end
        if api.SetUsersMode then api.SetUsersMode(users) end
        page=1;selected=nil
        window.name:SetText("");window.reason:SetText("");window.search:SetText("")
        refresh()
    end
    window.guildTab=button(window,"Guild List",20,-44,110,function() switchList(false) end)
    window.personalTab=button(window,"Personal List",135,-44,120,function() switchList(true) end)
    window.guildsTab=button(window,"KoS Guilds",260,-44,115,function() switchList(false,true) end)
    window.usersTab=button(window,"Users & Access",380,-44,155,function() switchList(false,false,true) end)
    label(window,"Search",20,-107,"GameFontNormalSmall")
    window.search=editBox(window,78,-100,255,80)
    window.search:SetScript("OnTextChanged",function() page=1; if refresh then refresh() end end)
    window.sort=button(window,"Sort: Name",350,-100,185,function()
        if usersMode() then api.ToggleAccessFilter() else api.Settings().sortRecent=not api.Settings().sortRecent end; page=1;selected=nil;refresh()
    end)
    for i=1,SIZE do
        local row=CreateFrame("Button",nil,window)
        row:SetSize(516,40); row:SetPoint("TOPLEFT",20,-138-(i-1)*44)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row:RegisterForClicks("LeftButtonUp","RightButtonUp")
        row.name=label(row,"",6,-1,"GameFontHighlight")
        row.name:SetWidth(495); row.name:SetJustifyH("LEFT")
        row.reason=label(row,"",6,-15,"GameFontHighlightSmall")
        row.reason:SetWidth(495); row.reason:SetJustifyH("LEFT")
        row.seen=label(row,"",6,-28,"GameFontDisableSmall")
        row.seen:SetWidth(495); row.seen:SetJustifyH("LEFT")
        row:SetScript("OnClick",function(self,mouseButton)
            if not self.record then return end
            if usersMode() then
                selected=self.record.name
                window.accessName:SetText(self.record.name)
                refresh();return
            end
            if mouseButton=="RightButton" then
                if not (api.IsPersonalMode and api.IsPersonalMode()) and api.PinSighting then pin(self.record.name) end
                return
            end
            selected=self.record.name
            window.name:SetText(entryName(self.record.name)); window.reason:SetText(self.record.reason)
            refresh()
        end)
        row:SetScript("OnEnter",function(self)
            if not self.record then return end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(entryName(self.record.name))
            GameTooltip:AddLine(self.record.reason,1,1,1,true)
            if usersMode() then
                GameTooltip:AddLine("Select to fill the access controls below.",0.8,0.8,0.8,true)
                GameTooltip:Show();return
            end
            GameTooltip:AddLine("Edited by " .. api.DisplayName(self.record.editor),0.7,0.7,0.7,true)
            local s=self.record.sighting
            if s and api.SightingZone then
                GameTooltip:AddLine("Last seen: " .. api.SightingZone(s) .. " — " .. api.SightingAge(s),1,0.7,0.3,true)
                GameTooltip:AddLine("Reported by " .. api.DisplayName(s.spotter),0.8,0.8,0.8,true)
                if s.map~=0 then GameTooltip:AddLine(string.format("Spotter position: %.1f, %.1f",s.x*100,s.y*100),0.8,0.8,0.8,true) end
                if s.map~=0 then GameTooltip:AddLine("Right-click to pin this sighting",1,0.8,0.4,true) end
            else GameTooltip:AddLine("No sightings recorded yet",0.7,0.7,0.7,true) end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        rows[i]=row
    end
    window.empty=label(window,"Your KoS list is empty. Add a target or enter a player below.",26,-160,"GameFontHighlightSmall")
    window.prev=button(window,"Previous",20,-450,85,function() page=page-1; refresh() end)
    window.page=label(window,"",225,-456,"GameFontHighlightSmall")
    window.next=button(window,"Next",450,-450,85,function() page=page+1; refresh() end)
    window.nameLabel=label(window,"Player name",25,-484,"GameFontNormalSmall")
    window.reasonLabel=label(window,"Reason (optional)",280,-484,"GameFontNormalSmall")
    window.name=editBox(window,26,-503,235,100)
    window.reason=editBox(window,281,-503,250,60)
    window.add=button(window,"Add / Save",20,-536,100,function()
        local name=window.name:GetText()
        if selected and name==entryName(selected) then name=selected end
        api.Edit(name,window.reason:GetText(),false); refresh()
    end)
    window.target=button(window,"Add Target",125,-536,100,function()
        if guildMode() then
            local name=api.GetTargetGuildName()
            if name then
                selected=nil;window.name:SetText(name);window.reason:SetFocus()
            end
            return
        end
        api.AddTarget(window.reason:GetText()); refresh()
    end)
    window.remove=button(window,"Remove",230,-536,90,function()
        if selected then api.Edit(selected,"",true); selected=nil; window.name:SetText(""); window.reason:SetText("") end
        refresh()
    end)
    window.test=button(window,"Test Alert",325,-536,100,function() api.Test() end)
    window.sync=button(window,"Sync",430,-536,105,function() api.Sync() end)
    window.scan=button(window,"Refresh Users",380,-484,155,function() api.RequestAddonUsers(); refresh() end)
    window.pin=button(window,"Pin Last Seen",420,-573,115,function() if selected then pin(selected) end end)
    window.sound=CreateFrame("CheckButton",nil,window,"UICheckButtonTemplate")
    window.sound:SetPoint("TOPLEFT",18,-573); window.sound:SetSize(26,26)
    window.soundLabel=label(window,"Sound",48,-580,"GameFontHighlightSmall")
    window.sound:SetScript("OnClick",function(self) api.SetSound(self:GetChecked() and true or false) end)
    window.alerts=CreateFrame("CheckButton",nil,window,"UICheckButtonTemplate")
    window.alerts:SetPoint("TOPLEFT",125,-573); window.alerts:SetSize(26,26)
    window.alertsLabel=label(window,"Sighting alerts",155,-580,"GameFontHighlightSmall")
    window.alerts:SetScript("OnClick",function(self) api.SetAlerts(self:GetChecked() and true or false) end)
    window.footer=label(window,"Last seen = spotter position, not live enemy tracking • Esc to close",20,-614,"GameFontDisableSmall")
    window.accessLabel=label(window,"Grant list editing by character name (guild members only)",25,-613,"GameFontNormalSmall")
    window.accessStatus=label(window,"",26,-668,"GameFontHighlightSmall")
    window.accessStatus:SetWidth(505);window.accessStatus:SetJustifyH("LEFT")
    window.accessName=editBox(window,26,-636,225,100)
    window.grant=button(window,"Grant Access",265,-636,130,function() api.SetEditor(window.accessName:GetText(),true);refresh() end)
    window.revoke=button(window,"Revoke Access",400,-636,135,function() api.SetEditor(window.accessName:GetText(),false);refresh() end)
    refresh=function()
        local entries, canEdit, scope, sound, alerts=api.GetState()
        local private=api.IsPersonalMode and api.IsPersonalMode()
        local guilds=guildMode()
        local users=usersMode()
        window.usersTab:Show()
        window.usersTab:SetEnabled(not users)
        window.guildTab:SetEnabled(private or guilds or users)
        window.guildsTab:SetEnabled(not guilds)
        window.nameLabel:SetText(guilds and "Enemy guild name" or "Player name")
        window.target:SetText(guilds and "Target's Guild" or "Add Target")
        window.personalTab:SetEnabled(not private)
        local total=#entries
        local query=string.lower(window.search:GetText() or "")
        if query~="" then
            local filtered={}
            for _,r in ipairs(entries) do
                local s=r.sighting
                local haystack=r.name .. " " .. r.reason .. " " .. (s and (s.spotter .. " " .. api.SightingZone(s)) or "")
                if string.lower(haystack):find(query,1,true) then filtered[#filtered+1]=r end
            end
            entries=filtered
        end
        if not users and api.Settings().sortRecent then
            table.sort(entries,function(a,b)
                local at=a.sighting and a.sighting.stamp or 0
                local bt=b.sighting and b.sighting.stamp or 0
                if at~=bt then return at>bt end
                return a.name<b.name
            end)
        end
        window.sort:SetText(api.Settings().sortRecent and "Sort: Last Seen" or "Sort: Name")
        if users then window.sort:SetText(api.AccessFilterIsEditors() and "Show: KoS Editors" or "Show: Addon Users") end
        local pages=math.max(1,math.ceil(#entries/SIZE))
        page=math.max(1,math.min(page,pages))
        window.status:SetText((private and "PERSONAL — private, never shared" or (canEdit and "Editing enabled" or "View only — members can report sightings")) .. "  |  " .. #entries .. " / " .. total .. (guilds and " guilds" or " players"))
        if users then window.status:SetText("Users & Access — click Show to switch users/editors; select a player") end
        window.rank:SetText(api.GetRankLabel and api.GetRankLabel() or "Rank: Loading...")
        local exists=false
        for _, r in ipairs(entries) do if r.name==selected then exists=true end end
        if not exists then selected=nil end
        for i,row in ipairs(rows) do
            local r=entries[(page-1)*SIZE+i]; row.record=r
            if r then
                row.name:SetText((r.name==selected and "> " or "") .. (guilds and ("<" .. r.name .. ">") or api.DisplayName(r.name)))
                row.reason:SetText(r.reason~="" and r.reason or "No reason supplied")
                local s=r.sighting
                row.seen:SetText(private and "Private reminder — not shared with your guild" or (s and (api.SightingZone(s) .. " — " .. api.SightingAge(s) .. " — " .. api.DisplayName(s.spotter) .. (guilds and (" — " .. api.DisplayName(s.name)) or "")) or "Not seen yet"))
                if users then
                    row.seen:SetText((r.detail or "Addon detected") .. (r.delivery and (" — " .. r.delivery.status) or ""))
                end
                row:Show()
            else row:Hide() end
        end
        window.empty:SetShown(#entries==0)
        window.empty:SetText(total==0 and (private and "Your private avoid list is empty. Add a target or enter a name below." or (guilds and "Use Target's Guild to fill a name, then Add / Save to confirm." or "Your KoS list is empty. Add a target or enter a player below.")) or "No matching players. Try a different search.")
        if users then window.empty:SetText("No matching users. Try Refresh Users or switch Show: KoS Editors.") end
        window.page:SetText("Page " .. page .. " / " .. pages)
        window.prev:SetEnabled(page>1); window.next:SetEnabled(page<pages)
        window.add:SetEnabled(canEdit); window.target:SetEnabled(canEdit)
        window.remove:SetEnabled(canEdit and selected~=nil)
        for _,control in ipairs({window.nameLabel,window.reasonLabel,window.name,window.reason,
                window.add,window.target,window.remove,window.test,window.sync,window.pin,window.footer}) do
            control:SetShown(canEdit and not users)
        end
        if private then window.sync:Hide();window.pin:Hide() end
        window.scan:SetShown(users)
        window.alertsLabel:SetText(private and "Personal reminders" or "Sighting alerts")
        window.footer:SetText(private and "Private avoid list • Same-faction sightings and party/raid reminders" or "Last seen = spotter position, not live enemy tracking • Esc to close")
        if users then window.footer:SetText("No response does not prove absence • Presence is not an access grant") end
        local canManage=users and api.CanAdminGuildAccess() or (api.CanManageAccess and api.CanManageAccess())
        for _,control in ipairs({window.accessLabel,window.accessName,window.grant,window.revoke}) do control:SetShown(canManage and true or false) end
        local delivery=api.GetGrantDelivery and api.GetGrantDelivery(window.accessName:GetText())
        window.accessStatus:SetShown(canManage and true or false)
        window.accessStatus:SetText(delivery and delivery.status or "Select a player above, then Grant Access / Revoke Access")
        window.grant:SetEnabled(canManage and window.accessName:GetText()~="")
        window.revoke:SetEnabled(canManage and window.accessName:GetText()~="")
        window.footer:ClearAllPoints(); window.footer:SetPoint("TOPLEFT",20,canManage and -697 or -614)
        window:SetSize(560,canManage and 725 or (canEdit and 642 or 530))
        window.art:SetSize(canEdit and 510 or 470,canEdit and 510 or 470)
        local checkboxY=canEdit and -573 or -484
        window.sound:ClearAllPoints(); window.sound:SetPoint("TOPLEFT",18,checkboxY)
        window.alerts:ClearAllPoints(); window.alerts:SetPoint("TOPLEFT",125,checkboxY)
        window.soundLabel:ClearAllPoints(); window.soundLabel:SetPoint("TOPLEFT",48,checkboxY-7)
        window.alertsLabel:ClearAllPoints(); window.alertsLabel:SetPoint("TOPLEFT",155,checkboxY-7)
        local sighting=selected and sightingFor(selected)
        window.pin:SetEnabled(sighting~=nil and sighting.map~=0)
        window.sound:SetChecked(sound); window.alerts:SetChecked(alerts)
    end
    window:SetScript("OnShow",function() refresh() end)
    local elapsed=0
    window:SetScript("OnUpdate",function(_,delta)
        elapsed=elapsed+delta
        if elapsed>=0.5 then elapsed=0; refresh() end
    end)
    window:Hide()
end
function api.ToggleUI()
    if not window then createWindow() end
    if window:IsShown() then window:Hide() else window:Show() end
end
local function createMinimap()
    minimap=CreateFrame("Button","ForeverKoSMinimapButton",Minimap)
    minimap:SetSize(32,32); minimap:SetFrameStrata("MEDIUM"); minimap:SetFrameLevel(8)
    minimap:RegisterForClicks("LeftButtonUp"); minimap:RegisterForDrag("LeftButton")
    local icon=minimap:CreateTexture(nil,"BACKGROUND")
    icon:SetTexture("Interface\\Icons\\Ability_DualWield"); icon:SetSize(20,20); icon:SetPoint("CENTER")
    local rim=minimap:CreateTexture(nil,"OVERLAY")
    rim:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); rim:SetSize(54,54); rim:SetPoint("TOPLEFT")
    minimap:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local function position()
        local angle=math.rad(api.Settings().angle or 220)
        minimap:ClearAllPoints()
        minimap:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*(Minimap:GetWidth()/2+8),math.sin(angle)*(Minimap:GetHeight()/2+8))
    end
    local dragged=false
    minimap:SetScript("OnClick",function() if not dragged then api.ToggleUI() end; dragged=false end)
    minimap:SetScript("OnDragStart",function(self)
        dragged=true
        self:SetScript("OnUpdate",function()
            local x,y=GetCursorPosition(); local cx,cy=Minimap:GetCenter(); local scale=Minimap:GetEffectiveScale()
            api.Settings().angle=math.deg(math.atan2(y/scale-cy,x/scale-cx))
            position()
        end)
    end)
    minimap:SetScript("OnDragStop",function(self)
        self:SetScript("OnUpdate",nil); position()
        C_Timer.After(0,function() dragged=false end)
    end)
    minimap:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:SetText("<in the bin> KoS List")
        GameTooltip:AddLine("Click to open / close",1,1,1)
        GameTooltip:AddLine("Drag to move around the minimap",0.7,0.7,0.7); GameTooltip:Show()
    end)
    minimap:SetScript("OnLeave",function() GameTooltip:Hide() end)
    position()
end
local loader=CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent",function() createMinimap() end)
