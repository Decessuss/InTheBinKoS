local api=ForeverKoS
local window,page,rows=nil,1,{}
local function label(parent,text,x,y)
    local f=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    f:SetPoint("TOPLEFT",x,y);f:SetText(text);return f
end
local function button(parent,text,x,y,w,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(w,24);b:SetPoint("TOPLEFT",x,y);b:SetText(text);b:SetScript("OnClick",fn);return b
end
local function input(parent,x,y,w,limit)
    local e=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
    e:SetSize(w,24);e:SetPoint("TOPLEFT",x,y);e:SetAutoFocus(false);e:SetMaxLetters(limit)
    e:SetScript("OnEscapePressed",function(self)self:ClearFocus()end);return e
end
function api.RefreshRequests()
    if not window or not window:IsShown() then return end
    local entries=api.GetRequests();local pages=math.max(1,math.ceil(#entries/5))
    page=math.max(1,math.min(page,pages))
    local admin=api.CanAdminGuildAccess()
    window.info:SetText(admin and "Guild requests — approve to add the player to KoS." or "Your requests — a reason is required. Officers review submissions.")
    window.paging:SetText(page .. " / " .. pages)
    for i,row in ipairs(rows) do
        local r=entries[(page-1)*5+i];row.record=r
        row:SetShown(r~=nil)
        if r then
            row.title:SetText(r.name .. " — " .. r.status)
            row.reason:SetText(r.reason)
            row.author:SetText("Requested by " .. r.requester)
            row.approve:SetShown(admin and r.status=="Pending")
            row.decline:SetShown(admin and r.status=="Pending")
        end
    end
    window.empty:SetShown(#entries==0)
end
function api.CreateRequestsPage(parent)
    if window then return window end
    window=CreateFrame("Frame","InTheBinKoSRequests",parent)
    window:SetSize(520,635);window:SetPoint("TOPLEFT",parent,"TOPLEFT",20,-80)
    label(window,"KoS Requests",20,-20)
    window.info=label(window,"",20,-48)
    label(window,"Player name",20,-80);label(window,"Reason (required, up to 60 characters)",230,-80)
    window.name=input(window,22,-104,190,100);window.reason=input(window,232,-104,270,60)
    button(window,"Use Target",20,-136,110,function()
        if UnitExists("target") and UnitIsPlayer("target") then
            window.name:SetText(api.UnitCharacterName("target") or "");window.reason:SetFocus()
        else print("|cffffb45b<in the bin> KoS List:|r Target a player first.") end
    end)
    button(window,"Submit Request",140,-136,140,function()
        if api.SubmitRequest(window.name:GetText(),window.reason:GetText()) then
            window.name:SetText("");window.reason:SetText("")
        end
    end)
    window.empty=label(window,"No requests to display.",20,-190)
    for i=1,5 do
        local row=CreateFrame("Frame",nil,window)
        row:SetSize(490,78);row:SetPoint("TOPLEFT",20,-180-(i-1)*80)
        row.title=label(row,"",0,0);row.reason=label(row,"",0,-18)
        row.reason:SetWidth(480);row.reason:SetJustifyH("LEFT")
        row.author=label(row,"",0,-40)
        row.author:SetWidth(300);row.author:SetJustifyH("LEFT")
        row.approve=button(row,"Approve",310,-40,85,function()if row.record then api.ReviewRequest(row.record.id,true) end end)
        row.decline=button(row,"Decline",400,-40,85,function()if row.record then api.ReviewRequest(row.record.id,false) end end)
        rows[i]=row
    end
    button(window,"Previous",20,-602,100,function()page=page-1;api.RefreshRequests()end)
    window.paging=label(window,"",245,-609)
    button(window,"Next",405,-602,100,function()page=page+1;api.RefreshRequests()end)
    window:SetScript("OnShow",api.RefreshRequests)
    window:Hide()
    return window
end
function api.ToggleRequests()
    if api.ShowRequests then api.ShowRequests() end
end
local slash=SlashCmdList.FOREVERKOS
SlashCmdList.FOREVERKOS=function(input)
    if input:match("^%s*requests%s*$") then api.ToggleRequests();return end
    return slash(input)
end
