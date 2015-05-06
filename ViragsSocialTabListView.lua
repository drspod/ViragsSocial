--
-- Created by IntelliJ IDEA.
-- User: Vestl_000
-- Date: 9/10/2014
-- Time: 7:31 AM
-- To change this template use File | Settings | File Templates.
--

local ViragsSocial = Apollo.GetAddon("ViragsSocial")

--tabs should be just array of default tabinfos
--fn should be fn(nTabId, tabinfo) ... end

function ViragsSocial:ShowTabsList(containerView, tArrayTabs, fn)

    if fn == nil or tArrayTabs == nil or tArrayTabs == {} or containerView == nil then return end
    if containerView:IsShown() then
        return -- will autoclose on external click
    end

    for _, tabWnd in ipairs(containerView:GetChildren()) do
        tabWnd:Destroy()
    end

    local height = 0

    for nTabId, tab in pairs(tArrayTabs) do

        local OnFn = function()
            containerView:Show(false)
            fn(nTabId, tab)
        end
        self:AddTabWndToTheList(containerView, self:TabFullName(nTabId), OnFn)
        height = height + 22 --xml value dont change only here
    end

    local nLeft, nTop, nRight, nBottom = containerView:GetAnchorOffsets()
    containerView:SetAnchorOffsets(nLeft, nTop, nRight, nTop + height)
    containerView:ArrangeChildrenVert()
    containerView:Show(true)

end

function ViragsSocial:AddTabWndToTheList(parent, text , OnFn)
        local wnd = Apollo.LoadForm(self.xmlDoc, "TabListEntry", parent, self)
        wnd:SetData(OnFn)
        local txtWnd = wnd:FindChild("Text")
        txtWnd:SetText(text or "")
end