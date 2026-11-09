local api=ForeverKoS
local window,rows,offset=nil,{},0
local function settings()
    local s=api.Settings();s.nearby=s.nearby or {};return s.nearby
end
local function label(parent,text,x,y,size)
    local f=parent:CreateFontString(nil,"OVERLAY",size or "GameFontHighlightSmall")
    f:SetPoint("TOPLEFT",x,y);f:SetText(text);return f
end
local function button(parent,text,x,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(22,22);b:SetPoint("TOPRIGHT",x,-5);b:SetText(text);b:SetScript("OnClick",fn);return b
end
local function refresh()
    if not window or not window:IsShown() then return end
    local entries=api.GetNearbyKoS and api.GetNearbyKoS() or {}
    local s=settings();local count=#entries
    window.populated=count>0
    local hover=MouseIsOver and MouseIsOver(window) or window:IsMouseOver()
    local opacity=math.max(0.05,math.min(1,tonumber(s.opacity) or 0.2))
    window:SetAlpha((s.autoFade==false or count>0 or window.dragging or hover) and 1 or opacity)
    offset=math.max(0,math.min(offset,math.max(0,count-8)))
    window.title:SetText("Nearby KoS  |  " .. count)
    window.collapse:SetText(s.collapsed and "+" or "-")
    window.pin:SetText(s.locked and "U" or "P")
    window.empty:SetShown(not s.collapsed and count==0)
    local shown=s.collapsed and 0 or math.min(8,count)
    window:SetHeight(s.collapsed and 32 or (count==0 and 66 or 38+shown*43+(count>8 and 18 or 0)))
    window.more:SetShown(not s.collapsed and count>8)
    window.more:SetText("Scroll for more (" .. (offset+1) .. "–" .. math.min(count,offset+8) .. ")")
    for i,row in ipairs(rows) do
        local r=not s.collapsed and entries[offset+i]
        row.record=r;row:SetShown(r~=nil)
        if r then
            local index=r.marker-1;local col,line=index%4,math.floor(index/4)
            row.icon:SetTexCoord(col/4,(col+1)/4,line/2,(line+1)/2)
            row.icon:SetVertexColor(1,r.slot<=8 and 1 or 0.3,r.slot<=8 and 1 or 0.3)
            row.name:SetText(r.name)
            local color=r.classToken and ((CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[r.classToken]) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[r.classToken]))
            row.name:SetTextColor(color and color.r or 1,color and color.g or 1,color and color.b or 1)
            local detail="Level " .. (r.level and (r.level==-1 and "??" or r.level) or "?") .. (r.className and (" " .. r.className) or "")
            row.guild:SetText(detail .. (r.guildName and ("  <" .. r.guildName .. ">") or ""))
        end
    end
end
local function create()
    window=CreateFrame("Frame","InTheBinKoSNearby",UIParent,"BackdropTemplate")
    window.dragging=false
    window:SetSize(280,66);window:SetFrameStrata("MEDIUM");window:SetClampedToScreen(true)
    window:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
    window:SetBackdropColor(0.025,0.025,0.03,0.94);window:SetBackdropBorderColor(1,0.42,0.06,0.85)
    local s=settings()
    window:SetPoint(s.point or "RIGHT",UIParent,s.relativePoint or "RIGHT",s.x or -40,s.y or 0)
    window:EnableMouse(true);window:SetMovable(not s.locked);window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart",function(self)
        if not settings().locked then self.dragging=true;self:SetAlpha(1);self:StartMoving() end
    end)
    window:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing()
        self.dragging=false
        local point,_,relativePoint,x,y=self:GetPoint()
        local saved=settings();saved.point=point;saved.relativePoint=relativePoint;saved.x=x;saved.y=y
    end)
    window.title=label(window,"Nearby KoS  |  0",12,-12,"GameFontNormal")
    window.title:SetWidth(170);window.title:SetJustifyH("LEFT")
    window.title:SetTextColor(1,0.55,0.12)
    window.collapse=button(window,"-",-31,function()local saved=settings();saved.collapsed=not saved.collapsed;refresh()end)
    window.pin=button(window,"P",-56,function()
        local saved=settings();saved.locked=not saved.locked
        window:SetMovable(not saved.locked);refresh()
    end)
    window.pin:SetScript("OnEnter",function(self)
        window:SetAlpha(1)
        GameTooltip:SetOwner(self,"ANCHOR_TOP")
        GameTooltip:SetText(settings().locked and "Unpin position" or "Pin position")
        GameTooltip:Show()
    end)
    window.pin:SetScript("OnLeave",function()GameTooltip:Hide()end)
    window.close=button(window,"x",-6,function()settings().open=false;window:Hide()end)
    window.empty=label(window,"No KoS players currently visible.",12,-43)
    window.more=label(window,"",12,-386)
    window.more:ClearAllPoints();window.more:SetPoint("BOTTOMLEFT",12,8)
    for i=1,8 do
        local row=CreateFrame("Button",nil,window);row:SetSize(258,40);row:SetPoint("TOPLEFT",11,-36-(i-1)*43)
        row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetSize(22,22);row.icon:SetPoint("LEFT",0,0)
        row.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        row.name=label(row,"",29,-4);row.name:SetWidth(225);row.name:SetJustifyH("LEFT")
        row.guild=label(row,"",29,-21);row.guild:SetWidth(225);row.guild:SetJustifyH("LEFT");row.guild:SetTextColor(0.65,0.65,0.65)
        row:SetScript("OnClick",function(self)
            if self.record and api.PinSighting then api.PinSighting(self.record.name) end
        end)
        rows[i]=row
    end
    window:EnableMouseWheel(true)
    window:SetScript("OnMouseWheel",function(_,delta)offset=offset-delta;refresh()end)
    local elapsed=0
    window:SetScript("OnEnter",function(self)self:SetAlpha(1)end)
    window:SetScript("OnUpdate",function(self,delta)
        elapsed=elapsed+delta
        if elapsed>=0.1 then
            elapsed=0
            refresh()
        end
    end)
    window:SetAlpha(0.2)
    window:SetScript("OnShow",refresh)
    window:Hide()
end
api.RefreshNearby=refresh
function api.ToggleNearby()
    if not window then create() end
    local s=settings();s.open=not window:IsShown()
    if s.open then window:Show() else window:Hide() end
end
local loader=CreateFrame("Frame");loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent",function()
    if settings().open then if not window then create() end;window:Show() end
end)
local slash=SlashCmdList.FOREVERKOS
SlashCmdList.FOREVERKOS=function(input)
    if input:match("^%s*nearby%s*$") then api.ToggleNearby();return end
    return slash(input)
end
