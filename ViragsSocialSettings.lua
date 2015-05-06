local ViragsSocial = Apollo.GetAddon("ViragsSocial")

function ViragsSocial:OnToggleSettingsWnd()

    if self.tWndOptionsRefs == nil or self.tWndOptionsRefs.wndMain == nil
            or self.tWndRefs == nil or self.tWndRefs.wndMain == nil then return
    end

    if self.tWndOptionsRefs.wndMain:IsVisible() then
        self:OnCloseSettingsWnd()
        self.tWndRefs.wndMain:Show(true)
    else
        self:SetupSettingsWnd()

        local l, t, r, b = self.tWndRefs.wndMain:GetAnchorOffsets()
        self.tWndOptionsRefs.wndMain:SetAnchorOffsets(l, t, r, b)

        self.tWndOptionsRefs.wndMain:Show(true)
        self.tWndRefs.wndMain:Show(false)
    end
end

function ViragsSocial:OnCloseSettingsWnd()
    if self.tWndOptionsRefs and self.tWndOptionsRefs.wndMain then
        self.tWndOptionsRefs.wndMain:Show(false)
    end
end


function ViragsSocial:SetupSettingsWnd()
    local mainWnd = self.tWndOptionsRefs.wndMain
    if mainWnd == nil then return end

    self:SetupDefaultHomeWnd()
    --self:SetupDefaultSortingWnd() removed in v 0.37, but keeping code for now
    self:SetupScannerModeOption()
    self:SetupNotificationsOption()
    --self:SetupBarrensChatOption() --still have to implement it the right way
    self:SetupNetworkDisableOption()
    self:SetupInterfaceMenuOnlineCountTab()
    self:SetupDefaultTab()
end

function ViragsSocial:SetupDefaultHomeWnd()
    local mainWnd = self.tWndOptionsRefs.wndMain

    local defaultHomeWnd = mainWnd:FindChild("DefaultHouse")
    local defaultHouseEditBox = defaultHomeWnd:FindChild("EditBox")

    defaultHomeWnd:SetTooltip("Type player name here. \nThis player should be in your Neighbor List.\nEvery time you visit your home you will auto-port to his house.\n \n Reset with empty line or your character name")

    local defaultHome = self.tSettings.kstrDefaultHouse

    if defaultHome == "" or defaultHome == nil then
        defaultHome = self.kMyID
    end

    if defaultHome == nil then
        defaultHome = ""
    end

    defaultHouseEditBox:SetText(defaultHome)
end

function ViragsSocial:SetupDefaultSortingWnd()
    local mainWnd = self.tWndOptionsRefs.wndMain


    local defaultSortingWnd = mainWnd:FindChild("DefaultSorting")
    defaultSortingWnd:SetTooltip("Selected sorting will be the default for grid on login")
    local defaultSorting = self.tSettings.kStrDefaultSorting or "RosterSortBtnName"
    for k, tBtn in pairs(defaultSortingWnd:GetChildren()) do
        local bgWnd = tBtn:FindChild("BG")
        if bgWnd and tBtn:GetName() == self.tSettings.kStrDefaultSorting then
            bgWnd:SetBGColor("green")
        elseif bgWnd then
            bgWnd:SetBGColor("white")
        end
    end
end



function ViragsSocial:OnSettingsDefaultSortingChanged(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
    self.tSettings.kStrDefaultSorting = wndHandler:GetName()
    self:SetupDefaultSortingWnd()
end

function ViragsSocial:OnNewDefaultHomeBtnClick(wndControl, wndHandler, strText)
    local strNewHome = wndHandler:GetText()

    if strNewHome then
        if (self.kMyID and strNewHome == self.kMyID) or strNewHome == "" then
            local myName = self.kMyID or ""
            self.tSettings.kstrDefaultHouse = ""
            self:PRINT("Default Home: " .. myName)
            wndHandler:SetText(myName)
            return
        end

        for k, tNeighbor in pairs(HousingLib.GetNeighborList() or {}) do
            if tNeighbor.strCharacterName == strNewHome then
                self.tSettings.kstrDefaultHouse = strNewHome
                self:PRINT("New Default Home: " .. strNewHome)
                return
            end
        end
    end

    self:PRINT("Cannot find neighbor with that name: " .. strNewHome)

    local defaultHome = self.tSettings.kstrDefaultHouse
    if defaultHome == "" or defaultHome == nil then
        defaultHome = self.kMyID
    end

    if defaultHome == nil then
        defaultHome = ""
    end

    wndHandler:SetText(defaultHome)
end

function ViragsSocial:SetupScannerModeOption()
    self.tWndOptionsRefs.wndMain:FindChild("ScannerModeMenu"):SetTooltip("Scanner mode will show players near you. \nIf this option is Active, you will always have up to date and valid info of ppl near you in Scanner Mode tab \n \nActive =  always running backgroud task \nInactive = only scans new units in Scanner tab and shuts down in any other grid state \n \nActivate and Reload ui (/reloadui) to update full list of ppl near you")

    local textWnd = self.tWndOptionsRefs.wndMain:FindChild("ScannerModeMenuText")
    local strText = "Active"
    local color = "UI_TextHoloBodyHighlight"
    if not self.tSettings.bLocationScannerMode then
        strText = "Inactive"
        color = "UI_BtnTextGrayNormal"
    end

    if textWnd then
        self:DEBUG("SetupScannerModeOption")
        textWnd:SetText(strText)
        textWnd:SetTextColor(color)
    end
end


function ViragsSocial:SetupNotificationsOption()
    self:DEBUG("self.tSettings.tNotifications", self.tSettings.tNotifications)
    local listOfChangableSettings = self:ListOfCustomNotificationsTabs() or {}

    local mainWnd = self.tWndOptionsRefs.wndMain

    if not mainWnd then return end

    local parent = mainWnd:FindChild("NotificationsWnd")

    if not parent then return end

    local scrollOffset = parent:GetVScrollPos()

    for _, rankLableWnd in ipairs(parent:GetChildren()) do
        rankLableWnd:Destroy()
    end


    self:SetupNotificationsHeader(parent)

    for nTabId, tab in pairs(listOfChangableSettings) do
        local title = self:TabFullName(nTabId)

        local customisableNotificationsList = self:GetCustomisableNotificationsForTab(nTabId, tab.nType, title)

        if customisableNotificationsList ~= nil and customisableNotificationsList ~= {} then


            local containerParent = Apollo.LoadForm(self.xmlDoc, "NotificationsContainer", parent, self)
            local container = containerParent:FindChild("Container")

            local height = 0

            for settingID, v in pairs(customisableNotificationsList) do
                local toggleTextFn = function(wnd)
                    local show = self:ToggleTextNotification(nTabId, settingID)
                    self:SetupNotificationsOption()
                end

                local toggleSoundFn = function(wnd)
                    local show = self:ToggleSoundNotification(nTabId, settingID)
                    self:SetupNotificationsOption()
                end
                local bText = self:GetNotificationTextState(nTabId, settingID)
                local bSound = self:GetNotificationSoundState(nTabId, settingID)
                self:SetupNotificationWnd(v, container, toggleTextFn, toggleSoundFn, bText, bSound)
                height = height + 22 --xml value dont change only here
            end

            local nLeft, nTop, nRight, nBottom = containerParent:GetAnchorOffsets()
            containerParent:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + height)
            container:ArrangeChildrenVert()
        end
    end

    parent:ArrangeChildrenVert()
    self:DEBUG("After self.tSettings.tNotifications", self.tSettings.tNotifications)
    parent:SetVScrollPos(scrollOffset)
end


function ViragsSocial:SetupNotificationsHeader(parent)
    if self.tSettings.tNotifications == nil then
        self.tSettings.tNotifications = {}
        self.tSettings.bTextNotifications = true
        self.tSettings.bSoundNotifications = true
    end

    local containerParent = Apollo.LoadForm(self.xmlDoc, "NotificationsContainer", parent, self)
    local container = containerParent:FindChild("Container")
    local ChatMsgesOn = self.tSettings.bTextNotifications == true
    local SoundsOn = self.tSettings.bSoundNotifications == true

    self:SetupNotificationWnd("Chat notifications", container,
        function(wnd)
            self:ToggleAllTextNotifications()
            self:SetupNotificationsOption()
        end,
        function(wnd)
            self:ToggleAllSoundNotifications()
            self:SetupNotificationsOption()
        end, ChatMsgesOn, SoundsOn)
    local headerHeight = 22 --xml value dont change only here
    local nLeft, nTop, nRight, nBottom = containerParent:GetAnchorOffsets()
    containerParent:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + headerHeight)
    container:ArrangeChildrenVert()

end


function ViragsSocial:WipeNotifications()
    self.tSettings.tNotifications = nil
    self:SetupNotificationsOption()
end



function ViragsSocial:SetupNotificationWnd(text, parent, OnTextFn, OnSoundBtnFn, bCurrTextState, bCurrSoundState)
    local wnd = Apollo.LoadForm(self.xmlDoc, "NotificationEntry", parent, self)
    local msgWnd = wnd:FindChild("TextMsg")
    local soundWnd = wnd:FindChild("Sound")

    msgWnd:SetData(OnTextFn)
    soundWnd:SetData(OnSoundBtnFn)

    local msgTxtWnd = msgWnd:FindChild("Text")
    local soundTxtWnd = soundWnd:FindChild("Text")

    msgTxtWnd:SetTextColor(bCurrTextState and "UI_TextHoloBodyHighlight" or "UI_BtnTextGrayNormal")
    soundTxtWnd:SetTextColor(bCurrSoundState and "UI_TextHoloBodyHighlight" or "UI_BtnTextGrayNormal")

    msgTxtWnd:SetText(text)
end

function ViragsSocial:OnNotificationToggleBtnClick(wndHandler, wndControl, eMouseButton)
    local fn = wndHandler:GetData()
    if fn then fn(wndHandler) end
end


function ViragsSocial:OnScannerModeToggleBtnClick(wndHandler, wndControl, eMouseButton)

    self.tSettings.bLocationScannerMode = not self.tSettings.bLocationScannerMode

    if self.tSettings.bLocationScannerMode then
        self:StopScannerMode()
    else
        self:StartScannerMode()
    end

    self:SetupScannerModeOption()
end

function ViragsSocial:OnBarrensChatToggleBtnClick(wndHandler, wndControl, eMouseButton)
    self.tSettings.bBarenceChatInactive = not self.tSettings.bBarenceChatInactive

    self:SetBarrensChatState()

    self:SetupBarrensChatOption()
end

function ViragsSocial:SetupBarrensChatOption()
    self.tWndOptionsRefs.wndMain:FindChild("BarrensChat"):SetTooltip("Global single-faction channel")

    local textWnd = self.tWndOptionsRefs.wndMain:FindChild("BarrensChatText")
    local strText = "Active on Login"
    local color = "UI_TextHoloBodyHighlight"
    if self.tSettings.bBarenceChatInactive then
        strText = "Inactive on Login"
        color = "UI_BtnTextGrayNormal"
    end

    if textWnd then
        self:DEBUG("SetupScannerModeOption")
        textWnd:SetText(strText)
        textWnd:SetTextColor(color)
    end
end

function ViragsSocial:SetupNetworkDisableOption()
    local maiWnd = self.tWndOptionsRefs.wndMain
    
    if maiWnd == nil then return end

    local disableNetOptionWnd = maiWnd:FindChild("DisableNetwork")

    if disableNetOptionWnd == nil then return end

    disableNetOptionWnd:SetTooltip("Location, Attunement and Tradeskill bradcasting network")

    local strText = "Active (Reload UI on change)"
    local color = "UI_TextHoloBodyHighlight"
    if self.tSettings.bDisableNetwork then
        strText = "Inactive (Reload UI on change)"
        color = "UI_BtnTextGrayNormal"
    end

    local textWnd = maiWnd:FindChild("DisableNetworkMenuText")
    if textWnd then
        self:DEBUG("SetupScannerModeOption")
        textWnd:SetText(strText)
        textWnd:SetTextColor(color)
    end
end

function ViragsSocial:OnNetworkDisableToggleBtnClick(wndHandler, wndControl, eMouseButton)
    self.tSettings.bDisableNetwork = not self.tSettings.bDisableNetwork

    if self.tSettings.bDisableNetwork then
        self:BroadcastUpdate()
        self:PRINT("Network is shutting down. Reload ui in 2 sec")
        Apollo.RegisterTimerHandler("NetworkShutDownTimer", "ReloadUI", self)
        Apollo.CreateTimer("NetworkShutDownTimer", 2.000, false)
        Apollo.StartTimer("NetworkShutDownTimer")
    else

        self:SetupNetworkDisableOption()
        self:PRINT("Network Active.")
        self:ReloadUI()
    end

end
function ViragsSocial:SetupDefaultTab()
    local maiWnd = self.tWndOptionsRefs.wndMain

    if maiWnd == nil then return end

    local DefaultTabBtnText = maiWnd:FindChild("DefaultTabBtnText")

    if DefaultTabBtnText == nil then return end
    DefaultTabBtnText:SetText(self:TabFullName(self.tSettings.nDefaultSelectedTab))
end

function ViragsSocial:OnDefaultTabChanged(wndControl, wndHandler, strText)
    local containerView = wndHandler:FindChild("Container")


    self:ShowTabsList(containerView, self:ListOfTabs(),
        function(id,tab)
            self.tSettings.nDefaultSelectedTab = id
            self:SetupDefaultTab()
        end)
end
function ViragsSocial:SetupInterfaceMenuOnlineCountTab()
    local maiWnd = self.tWndOptionsRefs.wndMain

    if maiWnd == nil then return end

    local InterfaceMenuOnlineCountBtnText = maiWnd:FindChild("InterfaceMenuOnlineCountBtnText")

    if InterfaceMenuOnlineCountBtnText == nil then return end
    InterfaceMenuOnlineCountBtnText:SetText(self:TabFullName(self.nInterfaceMenuTabOnlineCount))
end

function ViragsSocial:OnInterfaceMenuOnlineCountTabChanged( wndHandler, wndControl, eMouseButton )
    local containerView = wndHandler:FindChild("Container")

    local listofTabs = {}
    for k,tab in pairs(self:ListOfTabs()) do
        if tab.nOnline ~= nil then
            listofTabs[k] = tab
        end
    end

    self:ShowTabsList(containerView, listofTabs, function(id, tab)
        self.nInterfaceMenuTabOnlineCount = id
        self:UpdateOnlineCount(true)
        self:SetupInterfaceMenuOnlineCountTab()
    end)
end

function ViragsSocial:ReloadUI()
    RequestReloadUI()
end

