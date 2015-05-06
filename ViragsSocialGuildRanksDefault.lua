local ViragsSocial = Apollo.GetAddon("ViragsSocial")

local ktRanks
local knSelectedRank

local knMyRank
local ktMyRankPermissions

function ViragsSocial:ShowRanksForGuild(guild, parent)
    local guild = self.kCurrGuild
    local parent = self.tWndRefs.wndMain

    self:CloseRanksForm() --will destroy it

    self.tWndRefs.ranksForm = Apollo.LoadForm(self.xmlDoc, "GuildRanksForm", parent, self)
    local wndPermissionContainer = self.tWndRefs.ranksForm:FindChild("PermiccionsContainer")



    local nHeight = 0
    for idx, tPermission in pairs(GuildLib.GetPermissions(guild:GetType())) do
        local wndPermission = Apollo.LoadForm(self.xmlDoc, "PermissionEntry", wndPermissionContainer, self)
        local wndPermissionText = wndPermission:FindChild("Text")
        wndPermissionText:SetText(tPermission.strName)
        wndPermissionText:SetData(tPermission)
        nHeight = nHeight + 23
    end

    wndPermissionContainer:ArrangeChildrenVert()


    local nLeft, nTop, nRight, nBottom = self.tWndRefs.ranksForm:GetAnchorOffsets()

    self.tWndRefs.ranksForm:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeight)


    ktRanks = guild:GetRanks()

    self:DEBUG("guild", guild)
    self:DEBUG("guild:GetRanks()", ktRanks)
    self:DEBUG("GuildLib.GetPermissions(guild:GetType())", GuildLib.GetPermissions(guild:GetType()))

    knMyRank = guild:GetMyRank()
    ktMyRankPermissions = ktRanks[knMyRank]

    self:InitRanksLabels()

    self:SelectRankTab(1)
    self.tWndRefs.ranksForm:Show(true)
end

function ViragsSocial:InitRanksLabels()
    local wndSideBar = self.tWndRefs.ranksForm:FindChild("RanksList")

    for _, rankLableWnd in ipairs(wndSideBar:GetChildren()) do
        rankLableWnd:Destroy()
    end

    for idx, tRankInfo in ipairs(ktRanks) do
        if tRankInfo.bValid then
            local rankBtn = Apollo.LoadForm(self.xmlDoc, "GuildRanksSideBarBtn", wndSideBar, self)
            rankBtn:SetData(idx)
            local rankText = rankBtn:FindChild("Text")
            rankText:SetText(tRankInfo.strName)
            rankText:SetData(tRankInfo)
        end
    end

    wndSideBar:ArrangeChildrenVert()
end

function ViragsSocial:CloseRanksForm()
    if self.tWndRefs.ranksForm then
        self.tWndRefs.ranksForm:Destroy()
        self.tWndRefs.ranksForm = nil
    end
end

function ViragsSocial:SelectRankTab(nTab)
    if nTab == nil or self.tWndRefs.ranksForm == nil then return end --todo validation

    knSelectedRank = nTab

    local wndPermissionContainer = self.tWndRefs.ranksForm:FindChild("PermiccionsContainer")
    local wndSideBar = self.tWndRefs.ranksForm:FindChild("RanksList")
    local nameEditBox = self.tWndRefs.ranksForm:FindChild("OptionString")

    nameEditBox:SetText(ktRanks[nTab].strName)

    for key, wndRank in pairs(wndSideBar:GetChildren()) do
        wndRank:FindChild("BG"):SetBGColor(knSelectedRank == wndRank:GetData() and "green" or "white")
    end

    for key, wndPermission in pairs(wndPermissionContainer:GetChildren()) do
        local txtWnd = wndPermission:FindChild("Text")
        local bActive = ktRanks[knSelectedRank][txtWnd:GetData().strLuaVariable]
        txtWnd:SetTextColor(bActive and "UI_TextHoloBodyHighlight" or "darkgray")
    end

    self:SetupAdminMenu()
end

function ViragsSocial:SetupAdminMenu()
    local wndAdmin = self.tWndRefs.ranksForm:FindChild("RankMenu")
    local deleteBtn = wndAdmin:FindChild("RanksDelete")
    local addBtn = wndAdmin:FindChild("RanksNewRank")

    deleteBtn:Show(false)
    addBtn:Show(false)

    local bShowAdminMenu = false

    if self:CanDeleteCurrentRank() then
        bShowAdminMenu = true
        deleteBtn:Show(true)
    end

    if self:CanCreateNewRank() then
        bShowAdminMenu = true
        addBtn:Show(true)
    end

    wndAdmin:Show(bShowAdminMenu)

    local renameWnd = self.tWndRefs.ranksForm:FindChild("RankChangeNameMenu")
    renameWnd:Show(self:CanRenameCurrentRank())
end

function ViragsSocial:OnGuildRankSelectedClick(wndHandler, wndControl, eMouseButton) -- from  GuildRanksSideBarBtn
    self:SelectRankTab(wndHandler:GetData())
end

function ViragsSocial:OnGuildRankTogglePermissionClick(wndPermission, wndControl, eMouseButton) -- from PermissionEntry
    if self:CanEditCurrentRankPermissions() then
        local txtWnd = wndPermission:FindChild("Text")
        local bCurrPerm = ktRanks[knSelectedRank][txtWnd:GetData().strLuaVariable]
        ktRanks[knSelectedRank][txtWnd:GetData().strLuaVariable] = not bCurrPerm
        txtWnd:SetTextColor(bCurrPerm and "darkgray" or "UI_TextHoloBodyHighlight")
        self.kCurrGuild:ModifyRank(knSelectedRank, ktRanks[knSelectedRank])
    end
end

function ViragsSocial:CanDeleteCurrentRank()
    return ktMyRankPermissions.bRankCreate and knMyRank < knSelectedRank
end

function ViragsSocial:CanCreateNewRank()
    return ktMyRankPermissions.bRankCreate
            and table.getn(self.tWndRefs.ranksForm:FindChild("RanksList"):GetChildren()) < 10
end

function ViragsSocial:CanEditCurrentRankPermissions()
    return ktMyRankPermissions.bChangeRankPermissions and knMyRank < knSelectedRank
end

function ViragsSocial:CanRenameCurrentRank()
    return ktMyRankPermissions.bRankRename
end

function ViragsSocial:OnRankSettingsNameChanging(wndControl, wndHandler, strText)
    local newName = wndControl:GetText()
    self.kCurrGuild:RenameRank(knSelectedRank, newName)

    if string.len(newName) > 16 then
        self:PRINT("Rank name can be only 16 character long")
        return
    end

    if knMyRank > knSelectedRank then return end

    local oldName = ktRanks[knSelectedRank].strName

    local wndSideBar = self.tWndRefs.ranksForm:FindChild("RanksList")
    for key, wndRank in pairs(wndSideBar:GetChildren()) do
        local textWnd = wndRank:FindChild("Text")
        if oldName == textWnd:GetText() then
            textWnd:SetText(newName)
        end
    end

    ktRanks[knSelectedRank].strName = newName
end

function ViragsSocial:OnGuildRankCreateBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    local nRankIdx = nil
    local newRankDefaultName
    for idx, tRank in ipairs(ktRanks) do
        if not tRank.bValid then
            nRankIdx = idx
            newRankDefaultName = "New Rank " .. nRankIdx
            tRank.strName = newRankDefaultName
            tRank.bValid = true
            break
        end
    end

    if nRankIdx == nil then return end

    self.kCurrGuild:AddRank(nRankIdx, newRankDefaultName)
    self:InitRanksLabels()
    self:SelectRankTab(nRankIdx)
end

function ViragsSocial:OnGuildRankDeleteBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)

    self.kCurrGuild:RemoveRank(knSelectedRank)

    if knSelectedRank == 1 or
            knSelectedRank == 2 or
            knSelectedRank == 10 then
        return
    end

    ktRanks[knSelectedRank].bValid = false
    self:InitRanksLabels()

    self:SelectRankTab(knSelectedRank - 1)
end