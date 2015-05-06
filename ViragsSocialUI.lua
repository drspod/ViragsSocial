local ViragsSocial = Apollo.GetAddon("ViragsSocial")




local kSideBarTabsPosition = {
    [ViragsSocial.TabGuild] = "Guild",
    [ViragsSocial.TabFriends] = "Friends",
    [ViragsSocial.TabIgnoreAndRivals] = "IgnoreAndRivals",
    [ViragsSocial.TabNeighbors] = "Neighbors",
    [ViragsSocial.TabCircle1] = "Circle1",
    [ViragsSocial.TabCircle2] = "Circle2",
    [ViragsSocial.TabCircle3] = "Circle3",
    [ViragsSocial.TabCircle4] = "Circle4",
    [ViragsSocial.TabCircle5] = "Circle5",
    [ViragsSocial.Group] = "Group",
    [ViragsSocial.Warplot] = "Warplot",
    [ViragsSocial.Arena2v2] = "Arena2v2",
    [ViragsSocial.Arena3v3] = "Arena3v3",
    [ViragsSocial.Arena5v5] = "Arena5v5",
    [ViragsSocial.ScannerMode] = "ScannerMode",
    [ViragsSocial.Who] = "Who",
}


function ViragsSocial:InitUI(xmlDoc)

    local bigWnd = Apollo.LoadForm(self.xmlDoc, "ViragsSocialMainForm", nil, self)
    local smallWnd = Apollo.LoadForm(self.xmlDoc, "ViragsSocialMiniForm", nil, self)
    self.tWndOptionsRefs.wndMain = Apollo.LoadForm(self.xmlDoc, "SettingsWnd", nil, self)

    if bigWnd == nil or smallWnd == nil then
        Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
        return
    end
    self.tWndOptionsRefs.wndMain:Show(false, true)

    self:InitWndFor(self.tWndRefsBig, bigWnd, "BigForm")
    self:InitWndFor(self.tWndRefsSmall, smallWnd, "SmallForm")

    self.tWndRefsSmall.wndMain:SetSizingMinimum(238, 250)

    if self.ksSelectedWnd == "SmallForm" then
        self:SetNewRefs(self.tWndRefsSmall)
    else
        self:SetNewRefs(self.tWndRefsBig)
    end
end

function ViragsSocial:InitWndFor(tRef, mainWnd, strName)
    if tRef == nil or mainWnd == nil or strName == nil then return end

    tRef.strName = strName

    -- Required
    tRef.wndMain = mainWnd

    self:DEBUG("tRef.wndGrid", tRef.wndGrid)
    tRef.wndGridHeader = tRef.wndMain:FindChild("RosterHeaderContainer")
    tRef.wndSideBar = tRef.wndMain:FindChild("SideBar")
    --optional

    tRef.wndAddonLogo = tRef.wndSideBar:FindChild("AddonLogo")

    tRef.wndRandomHouse = tRef.wndMain:FindChild("RandomHouseForm")

    tRef.wndScannerModeNav = tRef.wndMain:FindChild("ScannerModeNavigation")
    tRef.wndPlayerNav = tRef.wndMain:FindChild("PlayerNavigation")
    tRef.wndNeighborNav = tRef.wndMain:FindChild("NeighborNavigation")
    tRef.wndGroupNav = tRef.wndMain:FindChild("GroupNavigation")
    tRef.wndGuildNav = tRef.wndMain:FindChild("GuildNavigation")
    tRef.wndGuildPerks = tRef.wndMain:FindChild("GuildPerksWnd")
    tRef.wndGuildInfo = tRef.wndMain:FindChild("GuildInfoWnd")

    tRef.friendAcceptDialog = tRef.wndMain:FindChild("Dialogs:FriendAcceptDialog")
    tRef.editTextDialog = tRef.wndMain:FindChild("Dialogs:EditTextDialog")
    tRef.editTextHelperDialog = tRef.wndMain:FindChild("Dialogs:EditTextHelperDialog")
    tRef.confirmDialog = tRef.wndMain:FindChild("Dialogs:ConfirmDialog")

    tRef.wndEditRankPopout = tRef.wndMain:FindChild("EditRankPopout")
    tRef.wndUpdateButton = tRef.wndMain:FindChild("UpdateInformation")

    tRef.wndMainGrid = tRef.wndMain:FindChild("RosterGrid")
    tRef.wndTotalCount = tRef.wndMain:FindChild("TotalNumberText")

    tRef.neighborPlugsGrid = tRef.wndMain:FindChild("NeighborPlugsGrid")


    tRef.neighborFilter = tRef.wndMain:FindChild("NeighborFilterList")

    tRef.wndGrid = tRef.wndMainGrid
    tRef.wndMain:Show(false, true)
end


function ViragsSocial:IsMiniWnd()
    return self.tWndRefs.strName == "SmallForm"
end

function ViragsSocial:IsVisible()
    return self.tWndRefs ~= nil and self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsVisible()
end

function ViragsSocial:ToggleUI()
    if self:IsVisible() then
        self.tWndRefs.wndMain:Show(false)
    else
        self.tWndRefs.wndMain:Invoke()
    end
end

function ViragsSocial:GridClear()
    self.tWndRefs.wndGrid:DeleteAll() -- TODO remove this for better performance eventually
end

function ViragsSocial:GridSaveState()
    self.GridScrollPosition = self.tWndRefs.wndGrid:GetVScrollPos()
    self.GridFocusedPlayer = self:CurrentGridFocus()
end

function ViragsSocial:GridLoadState()
    local wndGrid = self.tWndRefs.wndGrid
    local player = self.GridFocusedPlayer


    if player and player.strName and wndGrid then
        local updateNav = true
        for i = 1, wndGrid:GetRowCount() do
            local cellData = wndGrid:GetCellData(i, 1)
            if cellData and cellData.strName == player.strName then
                wndGrid:SetCurrentRow(i)
                updateNav = false
                break
            end
        end

        if updateNav then
            -- we updating nav only if there is no more player with this name in the grid
            -- Usually changed tab or something like that
            -- no need to update if we still selecting the same name
            self:HelperUpdateNavigationForSelection(nil)
        end

    end


    wndGrid:SetVScrollPos(self.GridScrollPosition)
end

function ViragsSocial:OpenCircleRegistrationWnd()
    self.tWndRefs.wndGrid:DeleteAll()
    self.kCurrGuild = nil
    Event_FireGenericEvent("EventGeneric_OpenCircleRegistrationPanel", self.tWndRefs.wndMain)
end

function ViragsSocial:SetupSideBarUIForTabs(tabsInfo)
    if tabsInfo == nil then return end
    local sideBar = self.tWndRefs.wndSideBar

    for k, v in pairs(kSideBarTabsPosition) do
        local tab = sideBar:FindChild(v)
        if tab then tab:Show(false) end
    end

    if self.tWndRefs.wndAddonLogo then
        self.tWndRefs.wndAddonLogo:Show(tabsInfo[1] == nil) -- No Guild check
    end

    for key, tabInfo in pairs(tabsInfo) do
        local strBtnName = kSideBarTabsPosition[key]
        if strBtnName then
            self:SetupSideBarUIForTab(sideBar:FindChild(strBtnName), tabInfo)
        end
    end
end

function ViragsSocial:SetupSideBarUIForTab(wndTab, tabInfo)
    if wndTab == nil then return end

    local infoWnd = wndTab:FindChild("Info")
    local textWnd = wndTab:FindChild("Online")
    local nameWnd = wndTab:FindChild("SplashCirclesPickerBtnText")


    wndTab:Show(true)


    local showInfoTab

    if not self:IsMiniWnd() then
        showInfoTab = tabInfo.nOnline ~= nil
        if nameWnd then nameWnd:SetText(tabInfo.sName) end
        if infoWnd then infoWnd:Show(showInfoTab) end

    else
        textWnd = infoWnd

        wndTab:SetTooltip(tabInfo.sName)
        if infoWnd then infoWnd:Show(true) end
        showInfoTab = tabInfo.nOnline ~= nil
    end

    if showInfoTab then
        if textWnd then
            tabInfo.tView = textWnd
            textWnd:SetText(tabInfo.nOnline)
        end
    end
end

function ViragsSocial:CurrentGridFocus()
    local data = nil
    local focusRow = self.tWndRefs.wndGrid:GetCurrentRow()

    if focusRow and focusRow > 0 and focusRow <= self.tWndRefs.wndGrid:GetRowCount() then
        data = self.tWndRefs.wndGrid:GetCellData(focusRow, 1)
    end

    return data
end
function ViragsSocial:DefaultWildstarSocialFire(nTab)
    if self.kSelectedTab == ViragsSocial.TabFriends then
        Event_FireGenericEvent("GenericEvent_DestroyFriends")
    elseif self.kSelectedTab == ViragsSocial.TabNeighbors then
        Event_FireGenericEvent("GenericEvent_DestroyNeighbors")
    elseif self.kSelectedTab == ViragsSocial.TabGuild then
        Event_FireGenericEvent("GenericEvent_DestroyGuild")
    end

    self.kSelectedTab = nTab

    if nTab == ViragsSocial.TabFriends then
        Event_FireGenericEvent("GenericEvent_InitializeFriends", self.tWndRefs.wndMain)
    elseif nTab == ViragsSocial.TabNeighbors then
        Event_FireGenericEvent("GenericEvent_InitializeNeighbors", self.tWndRefs.wndMain)
    elseif nTab == ViragsSocial.TabGuild then
        Event_FireGenericEvent("GenericEvent_InitializeGuild", self.tWndRefs.wndMain)
    end
end

function ViragsSocial:UpdateUIAfterTabSelection(nTab)
    self:DefaultWildstarSocialFire(nTab);



    self:CloseAllDialogs()

    self.tWndRefs.wndSideBar:SetRadioSel("Tabs", nTab)

    self.tWndRefs.wndGridHeader:FindChild("RosterSortBtnOnline:OnlineCheckBtn"):SetCheck(not self.kDisplayOffline[nTab] == false)

    local btnMyNote = self.tWndRefs.wndGridHeader:FindChild("MyNoteCheckBtn")
    if btnMyNote then
        btnMyNote:SetCheck(not self.kShowMyNote[nTab] == false)
        btnMyNote:Show(self:IsGuildTabSelected() or self:IsCircleTabSelected())
    end

    self:UpdateSelectedSortingTab()


    if nTab == ViragsSocial.ScannerMode then
        self:StartScannerMode()
    else
        self:StopScannerMode()
    end

    self:ReloadGridFromServer()


end
function ViragsSocial:UpdateSelectedSortingTab()

    local currentSort =  self:GetSortOrderForCurrentTab()
    if currentSort and currentSort[1] and self.tWndRefs.wndGridHeader then
        local sortingTabsWnds = self.tWndRefs.wndGridHeader:GetChildren()
        for k,v in pairs(sortingTabsWnds)do
           v:SetCheck(v:GetName() == currentSort[1])
        end
    end

end

function ViragsSocial:CloseAllGuildPopupsAndMenus()
    self:CloseRanksForm()

    if self.tWndRefs.wndGuildPerks
            and self.tWndRefs.wndGuildPerks:IsShown() then
        self:OnGuildPerksBntClick()
    end

    if self.tWndRefs.wndGuildInfo then
        self.tWndRefs.wndGuildInfo:Show(false)
    end
end

function ViragsSocial:AddRow(tData, eClass, ePath, nLvl, sName, fTime, sRank, sNote, strNameIcon, strRankIcon, strNoteIcon1, strNoteIcon2)

    if fTime > 0 and not self.kDisplayOffline[self.kSelectedTab] then return end
    if sName == nil or sName == "" then return end

    local strTextColor = "UI_TextHoloBodyHighlight"
    if fTime > 0 then -- offline
        strTextColor = "darkgray" --"UI_BtnTextGrayNormal"
    elseif fTime < 0 then --friendInvite
        strTextColor = "UI_BtnTextRedNormal"
    end

    local location = self:LocationOfPlayer(tData.strName)

    --Order: Class, Path, Lvl, Name, Online, Rank, Note
    local grid = self.tWndRefs.wndGrid

    local iCurrRow = grid:AddRow("")
    grid:SetCellLuaData(iCurrRow, 1, tData)

    local classIcon = self:ClassIcon(eClass)
    if classIcon then
        grid:SetCellImage(iCurrRow, 1, classIcon)
    end

    local pathIcon = self:PathIcon(ePath)
    if pathIcon then
        grid:SetCellImage(iCurrRow, 2, pathIcon)
    end


    if nLvl ~= nil and nLvl ~= ViragsSocial.kUNDEFINED then
        grid:SetCellDoc(iCurrRow, 3, "<T Font=\"CRB_InterfaceSmall\" TextColor=\"" .. strTextColor .. "\">" .. nLvl .. "</T>")
    end

    if strNameIcon then
        grid:SetCellImage(iCurrRow, 4, strNameIcon)
    end

    grid:SetCellDoc(iCurrRow, 5, "<T Font=\"CRB_InterfaceSmall\" TextColor=\"" .. strTextColor .. "\">" .. sName .. "</T>")


    grid:SetCellDoc(iCurrRow, 6, "<T Font=\"CRB_InterfaceSmall\" TextColor=\"" .. strTextColor .. "\">" .. self:HelperConvertToTime(fTime, location) .. "</T>")

    if strRankIcon then
        grid:SetCellImage(iCurrRow, 7, strRankIcon)
    end

    grid:SetCellDoc(iCurrRow, 8, "<T Font=\"CRB_InterfaceSmall\" TextColor=\"" .. strTextColor .. "\">" .. sRank .. "</T>")
    grid:SetCellDoc(iCurrRow, 9, "<T Font=\"CRB_InterfaceSmall\" TextColor=\"" .. strTextColor .. "\">" .. FixXMLString(sNote) .. "</T>")

    if strNoteIcon1 then
        grid:SetCellImage(iCurrRow, 10, strNoteIcon1)
    end

    if strNoteIcon2 then
        grid:SetCellImage(iCurrRow, 11, strNoteIcon2)
    end
end

-- when the Cancel button is clicked
function ViragsSocial:OnCancel()
    self:OnViragsSocialOn() --self.tWndRefs.wndMain:Close() -- hide the window
end

function ViragsSocial:OnToggleShowOfflineBtnClick(wndHandler, wndControl, eMouseButton)
    self.kDisplayOffline[self.kSelectedTab] = not self.kDisplayOffline[self.kSelectedTab]
    self:UpdateGrid(false, true)
end

function ViragsSocial:OnToggleShowMyNoteBtnClick(wndHandler, wndControl, eMouseButton)
    self.kShowMyNote[self.kSelectedTab] = not self.kShowMyNote[self.kSelectedTab]
    self:UpdateGrid(false, true)
end

function ViragsSocial:SetUITotalRosterSize(size)
    local sizeWnd = self.tWndRefs.wndTotalCount
    if sizeWnd and size then
        sizeWnd:SetText(size)
    end
end

function ViragsSocial:OnRosterSortToggle(wndHandler, wndControl)
    self:SetNewSortOrderForCurrentTab(wndHandler:GetName())
    wndHandler:SetCheck(true)
    self:UpdateGrid(false, true)
end


-- Right click on player in list
function ViragsSocial:OnRosterGridItemClick(wndControl, wndHandler, iRow, iCol, eMouseButton)

    local wndData = wndHandler:GetCellData(iRow, 1)
    self:CloseAllDialogs()
    self:HelperInviteRowCheck(wndData)
    self:HelperUpdateNavigationForSelection(wndData)


    if eMouseButton == GameLib.CodeEnumInputMouse.Right and wndData then

        if self:IsGroupTabSelected() then -- Group
            local playerUnit = GroupLib.GetUnitForGroupMember(wndData.nMemberIdx)

            Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", self.tWndRefs.wndMain, wndData.strCharacterName, playerUnit)
        end

        if wndData.strName == self.kMyID then return end

        if self:IsFriendTabSelected() or self:IsIgnoreTabSelected() then --Friendlist
            self.FrInvContextMenuHelper = wndData
            Event_FireGenericEvent("GenericEvent_NewContextMenuFriend", self.tWndRefs.wndMain, wndData.nId)
        elseif self:IsNeghborTabSelected() then -- Neighbor
            Event_FireGenericEvent("GenericEvent_NewContextMenuPlayer", self.tWndRefs.wndMain, wndData.strCharacterName)
        elseif self:IsScannerMode() and self:IsValidUnit(wndData.unit) then -- can inspect
            Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", self.tWndRefs.wndMain, wndData.unit:GetName(), wndData.unit)
        else
            Event_FireGenericEvent("GenericEvent_NewContextMenuPlayer", self.tWndRefs.wndMain, wndData.strName)
        end
    end
end

function ViragsSocial:FriendInviteDialogClose()
    local dialog = self.tWndRefs.friendAcceptDialog
    if dialog == nil then return end
    dialog:Show(false)
end

function ViragsSocial:FriendInviteDialogOpen(tFriend)
    self:CloseAllDialogs()
    local dialog = self.tWndRefs.friendAcceptDialog
    if dialog == nil then return end
    local dialogTextWnd = dialog:FindChild("Text")
    local acceptAndAddWnd = dialog:FindChild("AcceptAndAdd")
    local justAcceptWnd = dialog:FindChild("JustAccept")
    local ignoreWnd = dialog:FindChild("Ignore")
    local rejectWnd = dialog:FindChild("Decline")
    if tFriend.nRank == ViragsSocial.CharacterFriendshipType_Invite then
        if dialogTextWnd and tFriend.strName then dialogTextWnd:SetText("Friend Invite from " .. tFriend.strName .. ":") end
        self:SetBtnText(acceptAndAddWnd, Apollo.GetString("Friends_AcceptAndAdd"))
        self:SetBtnText(justAcceptWnd, Apollo.GetString("Friends_JustAccept"))
        if ignoreWnd then ignoreWnd:Show(true) end
        if acceptAndAddWnd then acceptAndAddWnd:SetData(function() FriendshipLib.RespondToInvite(tFriend.nId, FriendshipLib.FriendshipResponse_Mutual) end) end
        if justAcceptWnd then justAcceptWnd:SetData(function() FriendshipLib.RespondToInvite(tFriend.nId, FriendshipLib.FriendshipResponse_Accept) end) end
        if ignoreWnd then ignoreWnd:SetData(function() FriendshipLib.RespondToInvite(tFriend.nId, FriendshipLib.FriendshipResponse_Ignore) end) end
        if rejectWnd then rejectWnd:SetData(function() FriendshipLib.RespondToInvite(tFriend.nId, FriendshipLib.FriendshipResponse_Decline) end) end


        dialog:Show(true)
    elseif tFriend.nRank == ViragsSocial.CharacterFriendshipType_Account_Invite then
        if dialogTextWnd and tFriend.strName then dialogTextWnd:SetText("Account Friend Invite from " .. tFriend.strName .. ":") end
        self:SetBtnText(justAcceptWnd, Apollo.GetString("CRB_Accept"))
        if acceptAndAddWnd then acceptAndAddWnd:Show(false) end
        if ignoreWnd then ignoreWnd:Show(false) end
        if rejectWnd then rejectWnd:SetData(function() FriendshipLib.AccountInviteRespond(tFriend.nId, false) end) end
        if justAcceptWnd then justAcceptWnd:SetData(function() FriendshipLib.AccountInviteRespond(tFriend.nId, true) end) end

        dialog:Show(true)
    end
end


function ViragsSocial:SetBtnText(parent, text)
    if parent and text then
        local txtWnd = parent:FindChild("Text")
        if txtWnd then txtWnd:SetText(text) end
        parent:Show(true)
    end
end

function ViragsSocial:HelperInviteRowCheck(data)

    if self:IsFriendTabSelected() then --Friendlist
        self:FriendInviteDialogOpen(data)
    end
end

function ViragsSocial:HelperUpdateNavigationForSelection(data)

    if self:IsFriendTabSelected() then --Friendlist
        --todo
    elseif self:IsNeghborTabSelected() and self.tWndRefs.wndNeighborNav then --Neighborlist

        self.tWndRefs.wndNeighborNav:FindChild("ReturnBackWnd"):Show(HousingLib.IsHousingWorld())

        if data then
            local promoteWnd = self.tWndRefs.wndNeighborNav:FindChild("PromoteWnd")


            local strStatus = "Set Roommate"
            if data.nRank == HousingLib.NeighborPermissionLevel.Roommate then
                strStatus = "Remove RM"
            end

            promoteWnd:FindChild("Text"):SetText(strStatus)
            promoteWnd:Show(true)

            self.tWndRefs.wndNeighborNav:FindChild("RemoveWnd"):Show(true)

            self.tWndRefs.wndNeighborNav:FindChild("VisitWnd"):Show(HousingLib.IsHousingWorld())
            self.tWndRefs.wndNeighborNav:FindChild("EditNotesWnd"):Show(true)
        else
            self.tWndRefs.wndNeighborNav:FindChild("PromoteWnd"):Show(false)
            self.tWndRefs.wndNeighborNav:FindChild("RemoveWnd"):Show(false)
            self.tWndRefs.wndNeighborNav:FindChild("VisitWnd"):Show(false)
            self.tWndRefs.wndNeighborNav:FindChild("EditNotesWnd"):Show(false)
        end
    elseif self:IsCircleTabSelected() and self.tWndRefs.wndGuildNav then
        local n = self.tWndRefs.wndGuildNav

        local addNeighborBtn = n:FindChild("AddAsNeighborWnd")
        if addNeighborBtn == nil then return end
        addNeighborBtn:Show(false)

        if data and data.strName and data.strName  ~= self.kMyID then
        local tCharacterData = GameLib.SearchRelationshipStatusByCharacterName(data.strName)
        if tCharacterData ~= nil and tCharacterData.tNeighbor == nil then
            addNeighborBtn:Show(true)
        end
        end



    elseif (self:IsWarPartyTabSelected() or self:IsArenaTabSelected() or self:IsGuildTabSelected())
            and self.tWndRefs.wndGuildNav then
        local n = self.tWndRefs.wndGuildNav

        local addNeighborBtn = n:FindChild("AddAsNeighborWnd")
        if addNeighborBtn == nil then return end

        addNeighborBtn:Show(false)

    elseif self:IsGroupTabSelected() then
        local n = self.tWndRefs.wndGroupNav
        --todo
    end
end

--Select sidebar tab
function ViragsSocial:OnSocialListSelected(wndHandler, wndControl, eMouseButton)
    self:CloseAllGuildPopupsAndMenus()

    local name = wndHandler:GetName()

    for k, v in pairs(kSideBarTabsPosition) do
        if name == v then
            self:UpdateUIAfterTabSelection(k)
        end
    end

    if wndHandler:FindChild("SplashCirclesPickerBtnText") and
            wndHandler:FindChild("SplashCirclesPickerBtnText"):GetText() == self.kstrAddCircle then
        self:OpenCircleRegistrationWnd()
    end
end

function ViragsSocial:OnGenerateGridTooltip(wndHandler, wndControl, eType, iRow, iColumn)
    local tData = wndHandler:GetCellData(iRow + 1, 1)
    local text
    if tData then
        local playerInfo = self.ktPlayerInfoDB[tData.strName]
        if iColumn == 0 then
            text = self:ClassName(tData.eClass)
        elseif iColumn == 1 then
            text = self:PathName(tData.ePathType)
        elseif iColumn == 3 then
            text = self:NameIconTooltipFor(tData)
        elseif iColumn == 9 and playerInfo and playerInfo.ts1 then
            text = self:FullNameForTradeSkillShortName(playerInfo.ts1)
        elseif iColumn == 10 and playerInfo and playerInfo.ts2 then
            text = self:FullNameForTradeSkillShortName(playerInfo.ts2)
        elseif iColumn == 6 and playerInfo then --attune
            text = self:GetAttuneTooltipForPlayer(playerInfo.raidAttunStep)
        end

    end

    if text == nil then text = "" end

    wndHandler:SetTooltip(text)
end

function ViragsSocial:GetAttuneTooltipForPlayer(currPlayerKeyInfo)
    if currPlayerKeyInfo == false then return "No Key in the Keyslot" end

    if  currPlayerKeyInfo and currPlayerKeyInfo.nId then
        local key = Item.GetDataFromId(currPlayerKeyInfo.nId)
        if key then
            local keyInfo = key:GetDetailedInfo()
            if keyInfo and keyInfo.tPrimary then
                local keyData = keyInfo.tPrimary
                if currPlayerKeyInfo.bCompleted and keyData.strName  then return keyData.strName .. " DONE \n 13/13 Completed" end
                if keyData and keyData.strName and keyData.arImbuements and currPlayerKeyInfo.step
                        and keyData.arImbuements[currPlayerKeyInfo.step] then
                    local step = keyData.arImbuements[currPlayerKeyInfo.step]

                    local progressDetaledInfo = ""

                    if step.queImbuement and currPlayerKeyInfo.currentProgress then
                        self:DEBUG("step.queImbuement", step.queImbuement)


                        local tasks = step.queImbuement:GetVisibleObjectiveData()

                        if tasks then
                            for k, v in pairs(currPlayerKeyInfo.currentProgress) do
                                local task = tasks[k]
                                if task and task.strDescription then
                                    progressDetaledInfo = "\n"
                                    if v.nCompleted ~= nil and v.nNeeded ~= nil then
                                        progressDetaledInfo = progressDetaledInfo .. "(" .. v.nCompleted .. "/" .. v.nNeeded .. ") - "
                                    end

                                    progressDetaledInfo = progressDetaledInfo .. task.strDescription
                                end
                            end
                        end
                    end

                    return string.format("%s (%d) \n%s \n%s", keyData.strName or "", currPlayerKeyInfo.step, step.strName or "", progressDetaledInfo)
                end
            end
        end
    end

    return nil
end


function ViragsSocial:NameIconTooltipFor(tPlayer)
    if tPlayer and tPlayer.strName then
        local rel = self.ktRelationsDB[tPlayer.strName]
        local currTab = self.kSelectedTab
        --self:DEBUG("self.ktRelationsDB", self.ktRelationsDB)
        if rel then
            local text = ""
            for k, v in pairs(rel) do
                if k ~= currTab and v then
                    text = text .. self:TabName(k) .. " \n"
                end
            end

            return text
        end
    end

    return nil
end


function ViragsSocial:OnGuildEditNotesBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    if self.kCurrGuild then
        local id, data = self:HelperSelectedRosterData()
        if data and data.strName and data.strName ~= self.kMyID then

            self:PopupEnterTextDialog("Edit Private Note for " .. data.strName .. ":", self.ktGuildNotes[data.strName] or "",
                function()
                    local strEditBoxText = self:GetTextFromEditBox(nil)

                    self:SaveGuildNote(data.strName, strEditBoxText, id)

                    local btnMyNote = self.tWndRefs.wndGridHeader:FindChild("MyNoteCheckBtn")
                    if btnMyNote then btnMyNote:SetCheck(true) end
                end)
            return
        end

        self:PopupEnterTextDialog("Edit My Note: ", self.kStrMyNote or "",
            function()
                if self.kCurrGuild == nil then return end
                local strEditBoxText = self:GetTextFromEditBox(32)
                if strEditBoxText and strEditBoxText ~= self.kStrMyNote then
                    self.kStrMyNote = strEditBoxText
                    self.kCurrGuild:SetMemberNoteSelf(strEditBoxText)
                end
            end)
    end
end

function ViragsSocial:GetTextFromEditBox(nMax)
    local strEditBoxText = nil

    if self.tWndRefs.editTextDialog then
        local editBox = self.tWndRefs.editTextDialog:FindChild("EditBox")
        if editBox then
            strEditBoxText = editBox:GetText()
            if nMax and string.len(strEditBoxText) > nMax then
                strEditBoxText = string.sub(strEditBoxText, 1, nMax)
            end
        end
    end

    return strEditBoxText
end

function ViragsSocial:OnGuildAddPlayerBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    if self.kCurrGuild then
        self:PopupEnterTextDialog("Invite Player to " .. self.kCurrGuild:GetName() .. " :", "",
            function()
                if self.kCurrGuild == nil then return end
                local strEditBoxText = self:GetTextFromEditBox(nil)
                if strEditBoxText then
                    self.kCurrGuild:Invite(strEditBoxText)
                end
            end)
    end
end
function ViragsSocial:OnGuildAddAsNeighborBntClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    local data = self:CurrentGridFocus()
    if data and data.strName and data.strName ~= self.kMyID then
        wndHandler:Show(false)
        HousingLib.NeighborInviteByName(data.strName)
    end

end


function ViragsSocial:OnGuildKickPlayerBtn(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    if self.kCurrGuild == nil then return end

    local data = self:CurrentGridFocus()
    if data and data.strName and data.strName ~= self.kMyID then
        self:PopupConfirmDialog("Kick " .. data.strName .. " from " .. self.kCurrGuild:GetName() .. "?",
            function()
                if self.kCurrGuild == nil then return end
                self.kCurrGuild:Kick(data.strName)
            end)
    else
        self:PopupEnterTextDialog("Kick player from " .. self.kCurrGuild:GetName() .. " :", "",
            function()

                if self.kCurrGuild == nil then return end
                if self:GetTextFromEditBox(nil) then self.kCurrGuild:Kick(self:GetTextFromEditBox(nil)) end
            end)
    end
end



function ViragsSocial:OnGuildPromoteBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    if self.kCurrGuild == nil then return end

    local data = self:CurrentGridFocus()
    if data and data.strName and data.strName ~= self.kMyID then
        self:PopupConfirmDialog("Promote " .. data.strName .. " in " .. self.kCurrGuild:GetName() .. "?",
            function()
                if self.kCurrGuild == nil then return end
                self.kCurrGuild:Promote(data.strName)
            end)

    else
        self:PopupEnterTextDialog("Promote player in " .. self.kCurrGuild:GetName() .. " :", "",
            function()
                if self.kCurrGuild == nil then return end
                local strEditBoxText = self:GetTextFromEditBox(nil)
                if strEditBoxText then self.kCurrGuild:Promote(strEditBoxText) end
            end)
    end
end

function ViragsSocial:OnGuildDemoteBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    if self.kCurrGuild == nil then return end
    local data = self:CurrentGridFocus()
    if data and data.strName and data.strName ~= self.kMyID then
        self:PopupConfirmDialog("Demote " .. data.strName .. " in " .. self.kCurrGuild:GetName() .. "?",
            function()
                if self.kCurrGuild == nil then return end
                self.kCurrGuild:Demote(data.strName)
            end)

    else
        self:PopupEnterTextDialog("Demote player in " .. self.kCurrGuild:GetName() .. " :", "",
            function()
                if self.kCurrGuild == nil then return end
                local strEditBoxText = self:GetTextFromEditBox(nil)
                if strEditBoxText then self.kCurrGuild:Demote(strEditBoxText) end
            end)
    end
end

function ViragsSocial:OnGuildLeaveBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)

    if self.kCurrGuild == nil then return end
    local GuildName = self.kCurrGuild:GetName();
    local GuildType = self.kCurrGuild:GetType();

    local rank = self.kCurrGuild:GetMyRank()
    local strMsg = "Leave " .. self:GuildFullName(self.kCurrGuild) .. "?"


    local fn = function()
        if self.kCurrGuild == nil then return end
        self.kCurrGuild:Leave()
    end

    if rank == 1 then -- GM
        strMsg = "Disband " .. self:GuildFullName(self.kCurrGuild) .. "?"

        if (GuildType == GuildLib.GuildType_Guild) then
            strMsg = self:GuildFullName(self.kCurrGuild) .. "WARNING: A YOU SURE YOU WANT TO DISBAND YOUR MAIN GUILD" .."?"
        end

        fn = function()
            if self.kCurrGuild == nil then return end
            if self.kCurrGuild:GetName() == GuildName and
               self.kCurrGuild:GetType() == GuildType then
                self.kCurrGuild:Disband()
            end
        end
    end


    self:PopupConfirmDialog(strMsg, fn)
end

function ViragsSocial:OnGuildRanksBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)

    local ranksForm = self.tWndRefs.ranksForm
    if ranksForm and ranksForm:IsVisible() then
        self:CloseRanksForm()
    else
        self:ShowRanksForGuild()
    end
end

function ViragsSocial:OnGuildMoreInfoBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    local bVis = self.tWndRefs.wndGuildNav:FindChild("GuildHelperNavigation"):IsShown()
    self.tWndRefs.wndGuildNav:FindChild("GuildHelperNavigation"):Show(not bVis)
end

function ViragsSocial:OnGuildPerksBntClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)

    if self.kCurrGuild == nil or self.kCurrGuild:GetType() ~= GuildLib.GuildType_Guild then return end

    self.tWndRefs.wndGuildInfo:Show(false)

    if self.tWndRefs.wndGuildPerks:IsShown() then
        Event_FireGenericEvent("GuildWindowHasBeenClosed")
        self.tWndRefs.wndMain:SetData(nil)
    else
        self.tWndRefs.wndMain:SetData(self.kCurrGuild)
        Event_FireGenericEvent("GuildWindowHasBeenClosed")
        Event_FireGenericEvent("Guild_TogglePerks", self.tWndRefs.wndGuildPerks)
        local perksWnd = self.tWndRefs.wndMain:FindChild("GuildPerksForm")

        --if perksWnd then --todo remove this and fix xml after patch
            -- perksWnd:SetStyle("NoClip",  true)
        --    perksWnd:SetAnchorOffsets(45, 0, 800, 568)
        --end
    end

    local bShowUI = self.tWndRefs.wndGuildPerks:IsShown()
    self.tWndRefs.wndGrid:Show(bShowUI)
    self.tWndRefs.wndSideBar:Show(bShowUI)
    self.tWndRefs.wndGridHeader:FindChild("RosterHeaderContainer"):Show(bShowUI)
    self.tWndRefs.wndGuildPerks:Show(not bShowUI)
end

function ViragsSocial:OnGuildInfoBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    local gInfoWnd = self.tWndRefs.wndGuildInfo
    if gInfoWnd == nil then return end

    local bVis = gInfoWnd:IsShown()

    if not bVis then --setup
        if self.kCurrGuild == nil then return end
        local MotD = self.kCurrGuild:GetMessageOfTheDay()
        local AddInfo = self.kCurrGuild:GetInfoMessage()
        local logs = self.kCurrGuild:GetEventLogs()
        gInfoWnd:FindChild("MsgOfTheDayWnd:Text"):SetText(MotD)
        gInfoWnd:FindChild("DescriptionWnd:Text"):SetText(AddInfo)

        self:SetupTaxBtn(self.kCurrGuild:GetFlags().bTax)

        local logGrid = gInfoWnd:FindChild("EventsWnd:Grid")

        if logs and logGrid then
            logGrid:DeleteAll()

            for k, v in pairs(logs) do self:AddGuildLogRecord(logGrid, v) end
        end
        gInfoWnd:FindChild("MsgOfTheDayWnd:Save"):Show(false)
        gInfoWnd:FindChild("DescriptionWnd:Save"):Show(false)

        local rank = self.kCurrGuild:GetMyRank()
        if rank then
            local myPermissions = self.kCurrGuild:GetRanks()[rank]
            if myPermissions then
                --
                gInfoWnd:FindChild("MsgOfTheDayWnd:Text"):SetStyleEx("ReadOnly", not myPermissions.bMessageOfTheDay)
                gInfoWnd:FindChild("DescriptionWnd:Text"):SetStyleEx("ReadOnly", not myPermissions.bMessageOfTheDay)
                gInfoWnd:FindChild("MsgOfTheDayWnd:Save"):Show(myPermissions.bMessageOfTheDay)
                gInfoWnd:FindChild("DescriptionWnd:Save"):Show(myPermissions.bMessageOfTheDay)
            end
        end
        --if self.kCurrGuildthen return end
    end

    gInfoWnd:Show(not bVis)
end


function ViragsSocial:SetupTaxBtn(bTax)
    local taxWnd = self.tWndRefs.wndGuildInfo:FindChild("TaxWnd")


    taxWnd:FindChild("TaxInfoText"):SetText(String_GetWeaselString(Apollo.GetString("Guild_GuildTaxLabel"), bTax and Apollo.GetString("MatchMaker_FlagOn") or Apollo.GetString("MatchMaker_FlagOff")))
    taxWnd:FindChild("ChangeBtn:Text"):SetText(bTax and Apollo.GetString("MatchMaker_FlagOff") or Apollo.GetString("MatchMaker_FlagOn"))
    taxWnd:FindChild("ChangeBtn:BG"):SetBGColor(bTax and "AddonError" or "AddonOk")

    taxWnd:FindChild("ChangeBtn"):Show(self.kCurrGuild:GetType() == GuildLib.GuildType_Guild and self.kCurrGuild:GetMyRank() == 1)
end

function ViragsSocial:AddGuildLogRecord(LogGrid, tEventLog)
    local strName = tEventLog.strMemberName or ""
    local strTime = self:HelperConvertToTime(math.abs(tEventLog.fCreationTime))
    local strEvent = ""
    local strTextColor = "UI_TextHoloBodyHighlight"

    if tEventLog.eType == GuildLib.CodeEnumGuildEventType.Achievement and tEventLog.achEarned ~= nil then
        strEvent = String_GetWeaselString(Apollo.GetString("Guild_AchievementEarned"), "", tEventLog.achEarned:GetName())
        strName = self.kCurrGuild:GetName()
    elseif tEventLog.eType == GuildLib.CodeEnumGuildEventType.PerkUnlock and tEventLog.tGuildPerk ~= nil then
        strEvent = String_GetWeaselString(Apollo.GetString("Guild_UnlockedPerk"), "", tEventLog.tGuildPerk.strTitle)
        strName = self.kCurrGuild:GetName()
    elseif tEventLog.eType == GuildLib.CodeEnumGuildEventType.PerkActivate and tEventLog.tGuildPerk ~= nil then
        strEvent = String_GetWeaselString(Apollo.GetString("Guild_AchievementEarned"), "", tEventLog.tGuildPerk.strTitle)
        strName = self.kCurrGuild:GetName()
    elseif tEventLog.eType == GuildLib.CodeEnumGuildEventType.MemberAdded then
        strEvent = String_GetWeaselString(Apollo.GetString("Guild_MemberJoined"), "")
        strTextColor = "UI_BtnTextGreenNormal"
    elseif tEventLog.eType == GuildLib.CodeEnumGuildEventType.MemberRemoved then
        strEvent = String_GetWeaselString(Apollo.GetString("Guild_MemberLeft"), "")
        strTextColor = "UI_BtnTextRedNormal"
    elseif tEventLog.eType == GuildLib.CodeEnumGuildEventType.MemberRankChanged then
        strEvent = " " .. Apollo.GetString("Guild_Promoted")
        strTextColor = "AttributeDexterity"
        if tEventLog.nOldRank < tEventLog.nNewRank then
            strEvent = " " .. Apollo.GetString("Guild_Demoted")
            strTextColor = "ItemQuality_Superb"
        end

    elseif tEventLog.eType == GuildLib.CodeEnumGuildEventType.MessageOfTheDay then
        strEvent = Apollo.GetString("Guild_MOTDUpdated")
    else
        -- Error: Unhandled EventLog type
        strName = "Error"
        strEvent = "Error Event"
        return
    end

    local iCurrRow = LogGrid:AddRow("")
    LogGrid:SetCellLuaData(iCurrRow, 1, tEventLog)
    LogGrid:SetCellDoc(iCurrRow, 1, "<T Font=\"CRB_InterfaceSmall\" TextColor=\"" .. strTextColor .. "\">" .. strTime .. "</T>")
    LogGrid:SetCellDoc(iCurrRow, 2, "<T Font=\"CRB_InterfaceSmall\" TextColor=\"" .. strTextColor .. "\">" .. strName .. "</T>")
    LogGrid:SetCellDoc(iCurrRow, 3, "<T Font=\"CRB_InterfaceSmall\" TextColor=\"" .. strTextColor .. "\">" .. strEvent .. "</T>")
end

function ViragsSocial:OnGuildSaveMessageOfTheDay(wndHandler, wndControl, eMouseButton)

    if self.kCurrGuild == nil then return end

    local txtWnd = self.tWndRefs.wndGuildInfo:FindChild("MsgOfTheDayWnd:Text")
    local text = txtWnd:GetText()

    txtWnd:ClearFocus()

    self.kCurrGuild:SetMessageOfTheDay(text)
end

function ViragsSocial:OnGuildSaveInfo(wndHandler, wndControl, eMouseButton)
    if self.kCurrGuild == nil then return end

    local txtWnd = self.tWndRefs.wndGuildInfo:FindChild("DescriptionWnd:Text")
    local text = txtWnd:GetText()

    txtWnd:ClearFocus()
    if text then
        self.kCurrGuild:SetInfoMessage(text)
        self:PRINT("New Guild Info: " .. text)
    end
end


function ViragsSocial:GuildOnGMChangeBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    self:PopupEnterTextDialog("Enter new Guild Master name: ", self.kMyID or "", function()
        if self.kCurrGuild == nil then return end
        local strEditBoxText = self:GetTextFromEditBox(nil)

        if strEditBoxText then self.kCurrGuild:PromoteMaster(strEditBoxText) end
    end)
end

function ViragsSocial:OnGuildTaxToggle(wndHandler, wndControl)


    local bNewTax = not self.kCurrGuild:GetFlags().bTax
    self.kCurrGuild:SetFlags({ bTax = bNewTax })

    self:SetupTaxBtn(bNewTax)
end

function ViragsSocial:OnFriendListEditStatusBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)

    self:PopupEnterTextDialog("My " .. Apollo.GetString("CRB_Status"), FriendshipLib.GetPersonalStatus().strPublicNote,
        function()
            local strEditBoxText = self:GetTextFromEditBox(nil)
            if strEditBoxText then

                FriendshipLib.SetPublicNote(strEditBoxText)
            end
        end)
end

function ViragsSocial:OnFriendListEditNoteBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)

    local id, data = self:HelperSelectedRosterData()

    if data then
        if data.nRank == self.CharacterFriendshipType_Invite
                or data.nRank == self.CharacterFriendshipType_Account_Invite then
            return
        end

        local note = data.strPrivateNote or data.strNote

        self:PopupEnterTextDialog(data.strName .. " " .. Apollo.GetString("AccountServices_NoteHeader"), note,
            function()

                local strEditBoxText = self:GetTextFromEditBox(nil)
                if strEditBoxText then
                    if data.nRank == FriendshipLib.CharacterFriendshipType_Account then
                        FriendshipLib.SetFriendPrivateData(data.nId, strEditBoxText)
                    elseif data.nRank ~= self.CharacterFriendshipType_Invite and data.nRank ~= self.CharacterFriendshipType_Account_Invite then
                        FriendshipLib.SetNote(data.nId, strEditBoxText)
                    end
                end
            end)
    end
end

--[CharacterFriendshipType_Invite] = "Invite (Friend)",
--[CharacterFriendshipType_Account_Invite] = "Invite (Account Friend)",
function ViragsSocial:OnFriendListAddBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    local type = FriendshipLib.CharacterFriendshipType_Friend
    local infoText = "Add Friend"
    --Apollo.GetString("Friends_MessageHeader")
    if wndHandler:GetName() == "AddRivalWnd" then
        type = FriendshipLib.CharacterFriendshipType_Rival
        infoText = "Add Rival"
    elseif wndHandler:GetName() == "AddIgnoreWnd" then
        type = FriendshipLib.CharacterFriendshipType_Ignore
        infoText = "Ignore"
    end


    self:PopupEnterTextDialog(infoText, "",
        function()
            local strEditBoxText = self:GetTextFromEditBox(nil)
            if strEditBoxText then FriendshipLib.AddByName(type, strEditBoxText) end
        end)
end

function ViragsSocial:OnFriendListAddAccountBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)

    self:PopupEnterTextDialog("Email or name or name@realm", "",
        function()
            local text = self:GetTextFromEditBox(nil)
            local msg = self.tWndRefs.editTextHelperDialog:FindChild("EditBox"):GetText() or ""
            local foundEmail = text:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?")


            if foundEmail then
                FriendshipLib.AccountAddByEmail(text, msg)
                return
            end

            local foundName, foundServer = text:match("([A-Za-z]+)@([A-Za-z]+)")
            if foundName and foundServer then
                FriendshipLib.AddByName(FriendshipLib.CharacterFriendshipType_Account, foundName, foundServer, msg)
                return
            end

            foundName = text:match("([A-Za-z]+)")

            if foundName then
                FriendshipLib.AddByName(FriendshipLib.CharacterFriendshipType_Account, text, GameLib.GetRealmName(), msg)
                return
            end
            self:PRINT("Incorrect Account name. Can enter only email/name/name@realm")
        end, Apollo.GetString("Friends_MessageHeader"))
end


function ViragsSocial:OnFriendListRemoveBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)

    local id, data = self:HelperSelectedRosterData()

    if data and data.nId then

        if data.nRank == self.CharacterFriendshipType_Invite
                or data.nRank == self.CharacterFriendshipType_Account_Invite then
            return
        end

        local fn = function()
            FriendshipLib.Remove(data.nId, data.nRank)
        end
        if data.nRank == FriendshipLib.CharacterFriendshipType_Account then
            fn = function() FriendshipLib.AccountRemove(data.nId) end
        end

        self:PopupConfirmDialog("Remove " .. data.strName .. " from " .. self.ktFriendRanks[data.nRank] .. " list?", fn)
    end
end

function ViragsSocial:OnFriendInviteActionSelected(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    self:CloseAllDialogs()
    local fn = wndHandler:GetData()
    if fn then fn() end
end


function ViragsSocial:OnNeighborEditNotesBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    local id, data = self:HelperSelectedRosterData()

    if data then
        local note = data.strNote
        self:PopupEnterTextDialog(data.strName .. " " .. Apollo.GetString("AccountServices_NoteHeader"), note,
            function()
                self:SaveNeighborNote(data.strName, self:GetTextFromEditBox(nil), id)
            end)
    end
end

function ViragsSocial:OnNeighborAddPlayerBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    self:PopupEnterTextDialog("Invite player to neighbor list:", "",
        function()

            local strEditBoxText = self:GetTextFromEditBox(nil)
            if strEditBoxText and strEditBoxText ~= "" then
                HousingLib.NeighborInviteByName(strEditBoxText)
            end
        end)
end

function ViragsSocial:OnNeighborPromoteBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)

    local id, data = self:HelperSelectedRosterData()

    if id and data then
        self:NeighborTogglePermissionLevel(id)
    end
end

function ViragsSocial:OnNeighborVisitBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    local data = self:CurrentGridFocus()
    if data then
        self:PopupConfirmDialog("Visit " .. data.strName .. "?",
            function()
                HousingLib.VisitNeighborResidence(data.nId)
            end)
    end
end

function ViragsSocial:OnNeighborRemoveBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    local data = self:CurrentGridFocus()
    if data then
        self:PopupConfirmDialog("Remove " .. data.strName .. " from neighbor list?",
            function()
                HousingLib.NeighborEvict(data.nId)
            end)
    end
end

function ViragsSocial:OnNeighborReturnHomeBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    self:PopupConfirmDialog("Teleport back to your house?",
        function()
            if eMouseButton == GameLib.CodeEnumInputMouse.Left then
                if not self:DefaultHouseCheck() then
                    HousingLib.RequestTakeMeHome()
                end
            else
            self.bReturnToRealHome = true
                HousingLib.RequestTakeMeHome()
            end


        end)
end

function ViragsSocial:OnNeighborRandomHouseBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    local mainRandomHouseForm = self.tWndRefs.wndRandomHouse
    if mainRandomHouseForm and mainRandomHouseForm:IsVisible() then
        self:OnNeighborRandomCloseBtnClick()
    elseif mainRandomHouseForm then
        mainRandomHouseForm:Show(true)
        if self.tWndRefs.neighborFilter then
            self.tWndRefs.neighborFilter:Show(false)
        end

        HousingLib.RequestRandomResidenceList()
    end
end

function ViragsSocial:OnRandomResidenceList()

    local tRandomHeighborsList = HousingLib.GetRandomResidenceList()

    self:OnUpdateRandomResidenceListView(tRandomHeighborsList)

    for k, v in pairs(tRandomHeighborsList) do
        if v.strCharacterName == self.strRandomNeighborToFind then
            self:PRINT("Found " .. self.strRandomNeighborToFind .. " public random neighbor home")
            self:OnNeighborRandomStopSearch(true)
            HousingLib.RequestRandomVisit(v.nId)
            break
        end
    end

    if self.strRandomNeighborToFind then
        HousingLib.RequestRandomResidenceList()
    else
        self:OnNeighborRandomStopUIelementsSearch()
    end
end

function ViragsSocial:OnNeighborRandomStopSearch(bNoInfoMsg)
    if self.strRandomNeighborToFind and not bNoInfoMsg then
        self:PRINT("Random neighbor search stopped after 10 secs, Can't find public house for player " .. self.strRandomNeighborToFind)
    end

    Apollo.StopTimer("RandomSearchStopTimer")
    self.strRandomNeighborToFind = nil
end

function ViragsSocial:OnUpdateRandomResidenceListView(tRandomHeighborsList)
    local mainRandomHouseForm = self.tWndRefs.wndRandomHouse

    if mainRandomHouseForm == nil or not mainRandomHouseForm:IsVisible() then return end

    local randomHouseGrid = mainRandomHouseForm:FindChild("RandomNeighborGrid")

    if randomHouseGrid == nil then return end

    randomHouseGrid:DeleteAll()
    for k, v in pairs(tRandomHeighborsList) do
        local nId = v.nId or -1
        local name = v.strCharacterName or ""
        local color = "UI_TextHoloBodyHighlight"
        local textSize = "CRB_InterfaceSmall"
        if name == self.strRandomNeighborToFind then
            color = "UI_BtnTextRedNormal"
            textSize = "CRB_InterfaceBig"
        end

        local house = v.strResidenceName or ""

        local iCurrRow = randomHouseGrid:AddRow("")
        randomHouseGrid:SetCellLuaData(iCurrRow, 1, nId)
        randomHouseGrid:SetCellDoc(iCurrRow, 1, "<T Font=\"" .. textSize .. "\" TextColor=\"" .. color .. "\">" .. name .. "</T>")
        randomHouseGrid:SetCellDoc(iCurrRow, 2, "<T Font=\"" .. textSize .. "\" TextColor=\"" .. color .. "\">" .. house .. "</T>")
    end
end

function ViragsSocial:OnNeighborVisitRandomBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    if not HousingLib.IsHousingWorld() then
        self:PRINT(Apollo.GetString("Neighbors_MustBeOnPlot"))

        return
    end

    if self.tWndRefs.wndRandomHouse == nil then return end

    local randomHouseGrid = self.tWndRefs.wndRandomHouse:FindChild("RandomNeighborGrid")
    local id = randomHouseGrid:GetCurrentRow()

    self:DEBUG("OnNeighborVisitRandomBtnClick id", id)


    if id and id ~= ViragsSocial.kUNDEFINED then
        HousingLib.RequestRandomVisit(id)
    else
        self:PRINT("Select player and press again")
    end
end

function ViragsSocial:OnNeighborRefreshRandomBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    HousingLib.RequestRandomResidenceList()
end

function ViragsSocial:OnNeighborToggleFilterBtnClick(wndHandler, wndControl, eMouseButton)
    local filterSideBar = self.tWndRefs.neighborFilter

    if filterSideBar then
        if self.tWndRefs.wndRandomHouse then
            self:OnNeighborRandomCloseBtnClick()
        end

        filterSideBar:Show(not filterSideBar:IsShown())
    end
    Print("Filter is not implemented yet. Will come soon. Will be like ranks permissions in guild")
end

function ViragsSocial:OnNeighborUpdateAllBtnClick(wndHandler, wndControl, eMouseButton)
    Print("Scan is not implemented yet. will come soon")
end


function ViragsSocial:OnNeighborSearchRandomHouseBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    if self.strRandomNeighborToFind then
        self:OnNeighborRandomStopUIelementsSearch()
    else
        self:PopupEnterTextDialog("Player name (Case sensitive)): ", "", function()
            local find = self:GetTextFromEditBox(nil)

            if find == nil or find == "" then return end

            local mainWnd = self.tWndRefs.wndRandomHouse
            local btnBG = mainWnd:FindChild("SearchBtnBG")
            local btnTxt = mainWnd:FindChild("SearchBtnText")

            local infoWnd = mainWnd:FindChild("StatusAnimation")
            local nameWnd = mainWnd:FindChild("SearchName")
            local infoWorningWnd = mainWnd:FindChild("InfoWorning")

            btnTxt:SetText(Apollo.GetString("CRB_Stop"))
            btnBG:SetSprite("CRB_Raid:sprRaid_HealthProgBar_Red")
            btnBG:SetBGColor("AddonError")

            infoWnd:Show(true)
            nameWnd:Show(true)
            infoWorningWnd:Show(true)
            nameWnd:SetText(find)

           self:StartRandomNeighborSearch(find)
        end)
    end
end
function ViragsSocial:StartRandomNeighborSearch(strName)

    if strName and strName ~= "" then
        self:OnNeighborRandomStopSearch(true) -- stoping prev search if have

        Apollo.StartTimer("RandomSearchStopTimer")

        self.strRandomNeighborToFind = strName
        HousingLib.RequestRandomResidenceList()
        self:PRINT("Trying to find random house for " .. strName)
    end

end


function ViragsSocial:OnNeighborRandomStopUIelementsSearch()
    self:OnNeighborRandomStopSearch(true)

    local mainWnd = self.tWndRefs.wndRandomHouse

    if mainWnd then
        local btnBG = mainWnd:FindChild("SearchBtnBG")
        local btnTxt = mainWnd:FindChild("SearchBtnText")

        local infoWnd = mainWnd:FindChild("StatusAnimation")
        local nameWnd = mainWnd:FindChild("SearchName")
        local infoWorningWnd = mainWnd:FindChild("InfoWorning")
        btnTxt:SetText(Apollo.GetString("CRB_Search"))
        btnBG:SetSprite("CRB_ActionBarIconSprites:sprAS_GreenBorder")
        btnBG:SetBGColor("AddonOk")

        infoWnd:Show(fslse)
        nameWnd:Show(false)
        infoWorningWnd:Show(false)
    end
end

function ViragsSocial:OnNeighborRandomCloseBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    self:OnNeighborRandomStopUIelementsSearch()
    if self.tWndRefs.wndRandomHouse == nil then return end
    self.tWndRefs.wndRandomHouse:Show(false)
end

function ViragsSocial:OnGroupReadyCheckBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)

    self:PopupEnterTextDialog("Text (optional):", "", function()
        local strEditBoxText = self:GetTextFromEditBox(nil) or ""
        GroupLib.ReadyCheck(strEditBoxText)
    end)
end

function ViragsSocial:OnGroupAddPlayerBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    self:PopupEnterTextDialog("Player Name:", "", function()
        local strEditBoxText = self:GetTextFromEditBox(nil) or ""

        GroupLib.Invite(strEditBoxText)
    end)
end

function ViragsSocial:OnGroupConvertToRaidBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    local leaderName = self:GroupLeaderName()
    if leaderName and leaderName ~= self.kMyID then
        self:PRINT("Only leader (" .. leaderName .. ") can convert to raid")
        return
    end
    if not GroupLib.InRaid() then
        GroupLib.ConvertToRaid()
    else
        self:PRINT("Already in raid")
    end
end

function ViragsSocial:OnGroupDisbandBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    local leaderName = self:GroupLeaderName()
    if leaderName and leaderName ~= self.kMyID then
        self:PRINT("Only leader (" .. leaderName .. ") can disband this group ")
        return
    end

    self:PopupConfirmDialog("Disband group?",
        function()
            self:GroupDisband()
        end)
end

function ViragsSocial:OnGroupRecreateBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)


    self:PopupConfirmDialog("Recreate last disbanded group?",
        function()
            self:GroupRecreate()
        end)
end

function ViragsSocial:OnGroupKickBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)


    local data = self:CurrentGridFocus()
    if data and data.strName and data.strName ~= self.kMyID then
        self:PopupConfirmDialog("Kick " .. data.strName .. "?",
            function()
                GroupLib.Kick(data.nMemberIdx)
            end)
    else
        self:PRINT("Select player in grid")
    end
end

function ViragsSocial:OnGroupLeaveBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    self:PopupConfirmDialog("Disband group?",
        function()
            GroupLib.LeaveGroup()
        end)
end

function ViragsSocial:CloseAllDialogs()
    self:OnPopupDialogCancel() --close other dialog
    self:FriendInviteDialogClose()
    self:OnConfirmDialogCancel()
end

function ViragsSocial:OnScanerModeAttuneScanBtnClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    if self.bAttuneScanerStarted then
        self:StopAttunesScann()
    else
        self:StartAttunesScann()
    end

    self:UpdateScanerModeAttuneScanBtn()

end

function ViragsSocial:UpdateScanerModeAttuneScanBtn()
    local n = self.tWndRefs.wndScannerModeNav
    if n == nil then return end

    local attuneBtn = n:FindChild("ScanAttunes")
    if attuneBtn == nil then return end

    local textWnd = attuneBtn:FindChild("Text")
    if textWnd then
        local text
        if self.bAttuneScanerStarted then
            text = "Stop Attunement Scanner"
        else
            text = "Start Attunement Scanner"
        end
        textWnd:SetText(text)
    end
end

-----------------------------------------------------------------------------------------------
-- ViragsSocial CONFIRMATION DIALOG
-----------------------------------------------------------------------------------------------
function ViragsSocial:PopupConfirmDialog(strText, onYesFN)
    self:CloseAllDialogs()
    local confirmDialog = self.tWndRefs.confirmDialog
    if strText and onYesFN and confirmDialog then
        self:OnPopupDialogCancel()
        if confirmDialog:IsShown() then
            confirmDialog:Show(false)
            return
        end

        confirmDialog:Show(true)

        local data = {}
        data.infoText = strText
        data.onYesFN = onYesFN


        confirmDialog:SetData(data)
        confirmDialog:FindChild("Text"):SetText(strText)
    end
end


function ViragsSocial:OnConfirmDialogOK(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    if self.tWndRefs.confirmDialog then
        local data = self.tWndRefs.confirmDialog:GetData()
        self.tWndRefs.confirmDialog:Show(false)
        if data and data.onYesFN then
            data.onYesFN()
        end
    end
end

function ViragsSocial:OnConfirmDialogCancel(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    if self.tWndRefs.confirmDialog then
        self.tWndRefs.confirmDialog:Show(false)
    end
end

-----------------------------------------------------------------------------------------------
-- ViragsSocial EDIT TEXT DIALOG
-----------------------------------------------------------------------------------------------
function ViragsSocial:PopupEnterTextDialog(strText, strDefaultValue, onYesFN, strExtraInfoWndMsg)
    self:CloseAllDialogs()
    local editDialog = self.tWndRefs.editTextDialog
    if strText and onYesFN and strDefaultValue and editDialog then

        if editDialog:IsShown() then
            self:OnPopupDialogCancel()
            return
        end

        editDialog:Show(true)
        if strExtraInfoWndMsg and strExtraInfoWndMsg ~= "" then
            self.tWndRefs.editTextHelperDialog:Show(true)
        end
        local data = {}
        data.infoText = strText
        data.onYesFN = onYesFN
        data.editText = strDefaultValue

        local editBox = editDialog:FindChild("EditBox")
        editBox:SetFocus()
        editBox:SetText(strDefaultValue)
        editDialog:SetData(data)
        editDialog:FindChild("Text"):SetText(strText)
    end
end

function ViragsSocial:OnPopupDialogConfirm(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    if self.tWndRefs.editTextDialog then
        local data = self.tWndRefs.editTextDialog:GetData()
        self:OnPopupDialogCancel()
        if data and data.onYesFN then
            data.onYesFN()
        end
    end
end

function ViragsSocial:OnPopupDialogCancel(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    if self.tWndRefs.editTextDialog then
        self.tWndRefs.editTextDialog:Show(false)
        if self.tWndRefs.editTextHelperDialog then
            self.tWndRefs.editTextHelperDialog:Show(false)
        end
    end
end

function ViragsSocial:IsGuildTabSelected() return self.kSelectedTab == ViragsSocial.TabGuild end

function ViragsSocial:IsFriendTabSelected() return self.kSelectedTab == ViragsSocial.TabFriends end

function ViragsSocial:IsIgnoreTabSelected() return self.kSelectedTab == ViragsSocial.TabIgnoreAndRivals end

function ViragsSocial:IsNeghborTabSelected() return self.kSelectedTab == ViragsSocial.TabNeighbors end

function ViragsSocial:IsCircleTabSelected() return self.kSelectedTab >= ViragsSocial.TabCircle1 and self.kSelectedTab <= ViragsSocial.TabCircle5 end

function ViragsSocial:IsGroupTabSelected() return self.kSelectedTab == ViragsSocial.Group end

function ViragsSocial:IsWarPartyTabSelected() return self.kSelectedTab == ViragsSocial.Warplot end

function ViragsSocial:IsArenaTabSelected() return self.kSelectedTab == ViragsSocial.Arena2v2 or self.kSelectedTab == ViragsSocial.Arena3v3 or self.kSelectedTab == ViragsSocial.Arena5v5 end

function ViragsSocial:IsScannerMode() return self.kSelectedTab == ViragsSocial.ScannerMode end

function ViragsSocial:IsWhoTabSelected() return self.kSelectedTab == ViragsSocial.Who end

function ViragsSocial:SetupNavigationMenu()
    if self.tWndRefs.wndGuildNav == nil then return end

    self.tWndRefs.wndGuildNav:Show(false)
    self.tWndRefs.wndPlayerNav:Show(false)
    self.tWndRefs.wndScannerModeNav:Show(false)
    self.tWndRefs.wndNeighborNav:Show(false)
    self.tWndRefs.wndGroupNav:Show(false)
    if self:IsFriendTabSelected() or self:IsIgnoreTabSelected() then --Friends
        self:SetupFriendListMenu()
    elseif self:IsNeghborTabSelected() then --Neighbors
        self:SetupNeighborListMenu()
    elseif self:IsGroupTabSelected() then -- Group
        self:SetupGroupListMenu()
    elseif self:IsGuildTabSelected() or self:IsCircleTabSelected()
            or self:IsWarPartyTabSelected() or self:IsArenaTabSelected() then --Guild or Circle
        self:SetupGuildMenu()
    elseif self:IsScannerMode() then
        self:UpdateScanerModeAttuneScanBtn()
        self.tWndRefs.wndScannerModeNav:Show(true)
    end
end

function ViragsSocial:SetupGroupListMenu()
    local n = self.tWndRefs.wndGroupNav
    if n == nil then return end
    n:Show(true)
end

function ViragsSocial:SetupNeighborListMenu()
    local n = self.tWndRefs.wndNeighborNav
    if n == nil then return end

    n:Show(true)
end

function ViragsSocial:SetupFriendListMenu()
    local n = self.tWndRefs.wndPlayerNav
    if n == nil then return end

    n:Show(true)
    -- n:FindChild("MyStatusWnd"):SetText("   My Status: " .. FriendshipLib.GetPersonalStatus().strPublicNote)
end

function ViragsSocial:SetupGuildMenu()
    local n = self.tWndRefs.wndGuildNav
    if n == nil or self.kCurrGuild == nil then return end
    n:Show(true)

    local nGType = self.kCurrGuild:GetType()
    local rank = self.kCurrGuild:GetMyRank()
    if rank == nil then return end


    --local noteBtn = n:FindChild("RowTwo:EditNoteWnd") Always on
    --local ranksBtn = n:FindChild("RowTwo:RanksWnd") Always on
    local addBtn = n:FindChild("AddPlayerWnd")
    local guildPerksBtn = n:FindChild("GuildPerksBtnWnd")
    local guildInfoBtn = n:FindChild("GuildInfoBtnWnd")
    local promoteBtn = n:FindChild("GuildHelperNavigation:PromoteWnd")
    local demoteBtn = n:FindChild("GuildHelperNavigation:DemoteWnd")
    local kickBtn = n:FindChild("GuildHelperNavigation:KickWnd")
    local leaveBtn = n:FindChild("GuildHelperNavigation:LeaveWnd")
    local gmChangeBtn = n:FindChild("GuildHelperNavigation:ChangeGuildMasterWnd")
    local ranksBtn = n:FindChild("RanksBtnWnd")

    leaveBtn:FindChild("Text"):SetText("Leave")
    leaveBtn:FindChild("Text"):SetTooltip("Leave")
    if rank == 1 then --GM
        leaveBtn:FindChild("Text"):SetText("Disband")
        leaveBtn:FindChild("Text"):SetTooltip("Disband")
    end

    guildPerksBtn:Show(nGType == GuildLib.GuildType_Guild)
    guildInfoBtn:Show(nGType == GuildLib.GuildType_Guild
            or nGType == GuildLib.GuildType_Circle
            or nGType == GuildLib.GuildType_WarParty)

    local myPermissions = self.kCurrGuild:GetRanks()[rank]

    if myPermissions == nil then return end

    kickBtn:Show(myPermissions.bKick)
    addBtn:Show(myPermissions.bInvite)
    if nGType == GuildLib.GuildType_Guild
            or nGType == GuildLib.GuildType_Circle
            or nGType == GuildLib.GuildType_WarParty then
        promoteBtn:Show(myPermissions.bChangeMemberRank)
        demoteBtn:Show(myPermissions.bChangeMemberRank)
        ranksBtn:Show(true)
    else
        promoteBtn:Show(false)
        demoteBtn:Show(false)
        ranksBtn:Show(false)
    end

    gmChangeBtn:Show(rank == 1)
end

--UPDATE UI FLAG
function ViragsSocial:ShowUpdateAddonInfoWnd()
    if self.tWndRefs and self.tWndRefs.wndMain then
        local wndUpdateInformation = self.tWndRefs.wndUpdateButton
        if wndUpdateInformation then
            wndUpdateInformation:Show(self.bNeedUpdateAddon)
        end
    end
end

function ViragsSocial:OnToggleMainWndBtnClick(wndHandler, wndControl, eMouseButton)

    self:OnViragsSocialOn()
    self.sidebarTabsRegistered = false
    if self.tWndRefs.strName == self.tWndRefsBig.strName then
        self:SetNewRefs(self.tWndRefsSmall)
    else
        self:SetNewRefs(self.tWndRefsBig)
    end
    self:ShowUpdateAddonInfoWnd()
    self:UpdateSideBar()
    self:OnViragsSocialOn()
end

function ViragsSocial:SetNewRefs(tRefs)
    --self.tWndRefs = tRefs
    -- its just hack not to show real memory consumtion in buggy carbin menu

    for k,v in pairs(tRefs or {}) do
        self.tWndRefs[k] = v
    end

    for k,v in pairs(self.tWndRefs or {}) do
        if tRefs[k] == nil then
            self.tWndRefs[k] = nil
        end
    end
end
