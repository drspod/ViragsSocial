-----------------------------------------------------------------------------------------------
-- Client Lua Script for ViragsSocial
-- Copyright (c) NCsoft. All rights reserved
-- this code is extreamly messsy, because i had lots of feature requests and i know that it needs huge refactoring, but have no time for this
-- it started as 1 1.5k lines of code file and now there is 14 files 300-2k lines of code each and
-----------------------------------------------------------------------------------------------
-- TODO prof, prof, race, 6 housing spots, location

require"Window"
require"HousingLib"
require"FriendshipLib"
require"GameLib"
require"ICCommLib"
require"PlayerPathLib"
require"CraftingLib"

-----------------------------------------------------------------------------------------------
-- ViragsSocial Module Definition
-----------------------------------------------------------------------------------------------
local ViragsSocial = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local kSortingCmpFn
local tabsInfo = {}
local kAllRosters = {}

function ViragsSocial:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.kbDEBUG = false
    self.ADDON_VERSION = 0.387
    self.kUNDEFINED = -1
    self.tWndRefs = {}
    self.tWndRefsSmall = {}
    self.tWndRefsBig = {}
    self.tWndOptionsRefs = {}


    self.tSettings = {}

    self.kSelectedTab = 1
    self.ktPlayerInfoDB = {}
    self.ktRelationsDB = {} -- just db of bools {["name"] = {{[tabsID] = true}}}
    self.bNeedUpdateAddon = false
    self.bDisableLocationDetection = false
    self.knMyLastUpdate = nil
    self.kStrMyNote = ""
    self.kbCanRequestFullUpdateBroadcast = true
    self.kbCanMakeFullUpdateBroadcast = true
    self.kbNeedUpdateMyInfo = true

    self.kNeedUpdateInfo = true
    self.kBIsTimerOnCD = false
    self.kstrAddCircle = "Add Circle" --Just Button name
    self.kCurrGuild = nil
    self.canUpdateFriendlist = true
    self.JustLogedIn = true

    -- tab settings
    self.kDisplayOffline = {} --true/false for each tab
    self.kShowMyNote = {}     --true/false for each tab
    self.kSortingForTab = {}  -- {sortBy = "string from sort btn names", acsOrder = true/false } for each tab
    return o
end

function ViragsSocial:Init()
    local bHasConfigureFunction = false
    local strConfigureButtonText = ""
    local tDependencies = {-- "UnitOrPackageName",
    }
     -- dont change this. can only change if you will change order in all the forms(mini and main) in xml
    ViragsSocial.TabGuild = 1
    ViragsSocial.TabFriends = 2
    ViragsSocial.TabIgnoreAndRivals = 3
    ViragsSocial.TabNeighbors = 4
    ViragsSocial.TabCircle1 = 5
    ViragsSocial.TabCircle2 = 6
    ViragsSocial.TabCircle3 = 7
    ViragsSocial.TabCircle4 = 8
    ViragsSocial.TabCircle5 = 9
    ViragsSocial.Group = 10
    ViragsSocial.Warplot = 11
    ViragsSocial.Arena2v2 = 12
    ViragsSocial.Arena3v3 = 13
    ViragsSocial.Arena5v5 = 14
    ViragsSocial.ScannerMode = 15
    ViragsSocial.Who = 16

    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function ViragsSocial:OnSave(eType)
    -- Realm Level
    if eType == GameLib.CodeEnumAddonSaveLevel.Realm then
        local tSaveData = {}
        tSaveData.tNeigborNotes = self.ktNeigborNotes
        tSaveData.ktGuildNotes = self.ktGuildNotes
        tSaveData.tMainAddonDB = {}
        for k, v in pairs(self.ktPlayerInfoDB) do
            if k ~= self.kMyID and v.name then
                v.location = nil
                tSaveData.tMainAddonDB[k] = v
            end
        end
        tSaveData.kDisplayOffline = self.kDisplayOffline
        tSaveData.kShowMyNote = self.kShowMyNote
        tSaveData.ksSelectedWnd = self.tWndRefs.strName
        tSaveData.tSettings = self.tSettings
        tSaveData.kSortingForTab = self.kSortingForTab
        tSaveData.nInterfaceMenuTabOnlineCount = self.nInterfaceMenuTabOnlineCount

        return tSaveData
    end

    return nil
end

function ViragsSocial:OnRestore(eType, tLoad)
    if not tLoad then return end

    if eType == GameLib.CodeEnumAddonSaveLevel.Realm then
        self.kDisplayOffline = tLoad.kDisplayOffline or {}
        self.kShowMyNote =  tLoad.kShowMyNote or {}
        self.ktNeigborNotes = tLoad.tNeigborNotes or {}
        self.ktGuildNotes = tLoad.ktGuildNotes or {}
        self.ktPlayerInfoDB = tLoad.tMainAddonDB or {}
        self.ksSelectedWnd = tLoad.ksSelectedWnd
        self.tSettings = tLoad.tSettings or {}
        self.kSortingForTab = tLoad.kSortingForTab or {}
        self.nInterfaceMenuTabOnlineCount = tLoad.nInterfaceMenuTabOnlineCount or 1 -- 1 - is guild tab
        self.kSelectedTab = self.tSettings.nDefaultSelectedTab or 1

        if self.tSettings.bLocationScannerMode  then
            self:StartScannerMode()
        end
    end
end

-----------------------------------------------------------------------------------------------
-- ViragsSocial OnLoad
-----------------------------------------------------------------------------------------------
function ViragsSocial:OnLoad()

    -- load our form file
    self.xmlDoc = XmlDoc.CreateFromFile("ViragsSocial.xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- ViragsSocial OnDocLoaded
-----------------------------------------------------------------------------------------------
function ViragsSocial:OnDocLoaded()
    self:DEBUG("OnDocLoaded")
    if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
        self:InitUI(self.xmlDoc)

        --self.xmlDoc = nil

        --default wildstar behavior
        Apollo.RegisterEventHandler("ToggleGuild", "OnToggleGuild", self)
        Apollo.RegisterEventHandler("GenericEvent_OpenGuildPanel", "OnToggleGuild", self)
        Apollo.RegisterEventHandler("InvokeNeighborsList", "OnInvokeNeighborsList", self)
        Apollo.RegisterEventHandler("GenericEvent_OpenNeighborsPanel", "OnInvokeNeighborsList", self)
        Apollo.RegisterEventHandler("InvokeFriendsList", "OnInvokeFriendsList", self)
        Apollo.RegisterEventHandler("GenericEvent_OpenFriendsPanel", "OnInvokeFriendsList", self)
        Apollo.RegisterEventHandler("EventGeneric_OpenSocialPanel", "OnViragsSocialOn", self)

        --GENERIC EVENTS
        Apollo.RegisterSlashCommand("vsl", "OnViragsSocialOn", self)
        Apollo.RegisterSlashCommand("VSL", "OnViragsSocialOn", self)
        Apollo.RegisterSlashCommand("vis", "VisitRandomHouse", self)
        Apollo.RegisterSlashCommand("VIS", "VisitRandomHouse", self)

        Apollo.RegisterEventHandler("ToggleSocialWindow", "OnViragsSocialOn", self)
        Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)

        Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)

        Apollo.RegisterEventHandler("WhoResponse", "OnWhoResponse", self)

        --GUILD LIST UPDATES
        Apollo.RegisterEventHandler("GuildRoster", "OnGuildRoster", self)
        Apollo.RegisterEventHandler("GuildMemberChange", "OnGuildMemberChange", self) -- General purpose update method
        Apollo.RegisterEventHandler("GuildChange", "OnGuildChanged", self) -- notification that a guild was added / removed.
        Apollo.RegisterEventHandler("GuildName", "OnGuildChanged", self) -- notification that the guild name has changed.
        Apollo.RegisterEventHandler("GuildInvite", "OnGuildInvite", self) -- notification you got a guild/circle invite

        Apollo.RegisterEventHandler("GuildLoaded", "OnGuildLoaded", self) -- notification that your guild or a society has loaded.
        Apollo.RegisterEventHandler("GuildFlags", "OnGuildFlags", self) -- notification that your guild's flags have changed.
        Apollo.RegisterEventHandler("GuildName", "OnGuildName", self) -- notification that the guild name has changed.




        Apollo.RegisterTimerHandler("FriendlistUpdateTimer", "OnFriendListUpdate", self)
        Apollo.CreateTimer("FriendlistUpdateTimer", 0.010, false)
        Apollo.StopTimer("FriendlistUpdateTimer")

        Apollo.RegisterEventHandler("FriendshipLocation", "OnFriendshipLocation", self)
        Apollo.RegisterTimerHandler("UpdateLocationsTimer", "OnUpdateLocationsTimer", self)
        Apollo.CreateTimer("UpdateLocationsTimer", 20.000, true)
        Apollo.StartTimer("UpdateLocationsTimer")


        --NEIGHBOR LIST UPDATES
        -- Apollo.RegisterEventHandler("HousingNeighborInviteRecieved", 	"OnNeighborInviteRecieved", self)
        Apollo.RegisterEventHandler("HousingNeighborInviteAccepted", "OnNeighborInviteAccepted", self)
        Apollo.RegisterEventHandler("HousingNeighborInviteDeclined", "OnNeighborInviteDeclined", self)

        Apollo.RegisterEventHandler("HousingResultInterceptResponse", "OnHousingResultInterceptResponse", self)
        Apollo.RegisterEventHandler("HousingNeighborUpdate", "NeighborListUpdate", self)
        Apollo.RegisterEventHandler("HousingNeighborsLoaded", "NeighborListUpdate", self)
        Apollo.RegisterEventHandler("HousingRandomResidenceListRecieved", "OnRandomResidenceList", self)

        self:InitGroupTab()
        self:InitNotifications()

        --LOCATION UPDATES
        --Apollo.RegisterEventHandler("SubZoneChanged", 				"OnChangeZoneName", self)
        Apollo.RegisterEventHandler("VarChange_ZoneName", "OnChangeZoneName", self)



        -- refresh preformance timer
        Apollo.RegisterTimerHandler("RefreshRateTimeUpdate", "OnRefreshInfoTimeUpdate", self)
        Apollo.CreateTimer("RefreshRateTimeUpdate", 1.000, false)
        Apollo.StopTimer("RefreshRateTimeUpdate")

        --initial broadcast timer
        Apollo.RegisterTimerHandler("BroadcastUpdateTimer", "StartBroadcastFromQueue", self)
        Apollo.CreateTimer("BroadcastUpdateTimer", 0.100, false)
        Apollo.StopTimer("BroadcastUpdateTimer")

        Apollo.RegisterTimerHandler("UpdateOnlineCountTimer", "UpdateOnlineCount", self)
        Apollo.CreateTimer("UpdateOnlineCountTimer", 1.000, false)
        Apollo.StopTimer("UpdateOnlineCountTimer")

        Apollo.RegisterTimerHandler("LastOnlineTimeRefresher", "OnLastOnlineTimeRefresher", self)
        Apollo.CreateTimer("LastOnlineTimeRefresher", 60.000, true)
        Apollo.StartTimer("LastOnlineTimeRefresher")

        Apollo.RegisterTimerHandler("RandomSearchStopTimer", "OnNeighborRandomStopSearch", self)
        Apollo.CreateTimer("RandomSearchStopTimer", 10.000, false)
        Apollo.StopTimer("RandomSearchStopTimer")

        self:Setup()

    end
end

function ViragsSocial:OnLastOnlineTimeRefresher()
    self:ReloadGridFromServer()
end


function ViragsSocial:OnWindowManagementReady()
    if self.tWndRefsBig.wndMain and self.tWndRefsSmall.wndMain then
        Event_FireGenericEvent("WindowManagementAdd", { wnd = self.tWndRefsBig.wndMain, strName = "Virag's Social" })
        Event_FireGenericEvent("WindowManagementAdd", { wnd = self.tWndRefsSmall.wndMain, strName = "Virag's Social Mini" })
    end
end

function ViragsSocial:OnToggleGuild()
    self:CloseAllGuildPopupsAndMenus()
    self:OnViragsSocialOn()
    self:UpdateUIAfterTabSelection(ViragsSocial.TabGuild)
end

function ViragsSocial:OnInvokeNeighborsList()
    self:CloseAllGuildPopupsAndMenus()
    self:OnViragsSocialOn()
    self:UpdateUIAfterTabSelection(ViragsSocial.TabNeighbors)
end

function ViragsSocial:OnInvokeFriendsList()
    self:CloseAllGuildPopupsAndMenus()
    self:OnViragsSocialOn()
    self:UpdateUIAfterTabSelection(ViragsSocial.TabFriends)
end

function ViragsSocial:OnInterfaceMenuListHasLoaded()
    Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Virag's Social", { "ToggleSocialWindow", "Social", "Icon_Windows32_UI_CRB_InterfaceMenu_Social" })
end

-----------------------------------------------------------------------------------------------
-- ViragsSocial Init
-----------------------------------------------------------------------------------------------
function ViragsSocial:Setup()
    if self.kbDEBUG then
        self:DEBUG("Setup()")
        self:DEBUG("g_InterfaceOptions", g_InterfaceOptions)
        self:DEBUG("Apollo",Apollo )
        self:DEBUG("GameLib", GameLib)
        self:DEBUG("GroupLib", GroupLib)
        self:DEBUG("GuildLib", GuildLib)
        self:DEBUG("CraftingLib", CraftingLib)
        self:DEBUG("HousingLib", HousingLib)
        self:DEBUG("FriendshipLib", FriendshipLib)
        self:DEBUG("PlayerPathLib", PlayerPathLib)
        self:DEBUG("ChatSystemLib", ChatSystemLib)
        self:DEBUG("Item", Item)
        self:DEBUG("Sound", Sound)
    end


    self:InitSortFns()
    self:FixCarbineAddons()

    self:JoinICCommLibChannels()

    Apollo.RegisterTimerHandler("FirstBroadcastUpdateTimer", "BroadcastUpdate", self)
    Apollo.CreateTimer("FirstBroadcastUpdateTimer", 5.000, false)
    Apollo.StartTimer("FirstBroadcastUpdateTimer")

    self:UpdateSideBar()
    self:SetBarrensChatState()
    self.JustLogedIn = false
end


function ViragsSocial:UpdateSideBar()
    self:RegisterSidebarTabs()
    self:SetupSideBarUIForTabs(tabsInfo)
    self:UpdateUIAfterTabSelection(self.kSelectedTab)
    self:UpdateOnlineCount(true)
end



function ViragsSocial:TabName(tabID)
    if tabsInfo and tabID and
    tabsInfo[tabID] and tabsInfo[tabID].sName
    then return tabsInfo[tabID].sName end

    return ""
end
function ViragsSocial:TabFullName(tabID)
    if tabID == nil or tabsInfo == nil then return "" end

    local tab = tabsInfo[tabID]

    if tab == nil then return "" end

    local title = tab.sName or ""
    if  tab.nType~= nil then
        title = self:strGuildNameAndType(tab.sName, tab.nType)
    end



    return title or ""
end
function ViragsSocial:GuildFullName(guild)
    if guild == nil then return end;

    local title = guild:GetName() or ""

    if  guild:GetType() ~= nil then
        title = self:strGuildNameAndType(guild:GetName(), guild:GetType())
    end


    return title or ""
end
local kGuildTypesToText = {
    [GuildLib.GuildType_Guild] = "Guild",
    [GuildLib.GuildType_Circle] = "Circle",
    [GuildLib.GuildType_ArenaTeam_2v2] = "Arena Team",
    [GuildLib.GuildType_ArenaTeam_3v3] = "Arena Team",
    [GuildLib.GuildType_ArenaTeam_5v5] = "Arena Team",
    [GuildLib.GuildType_WarParty] = "War Party",
}

function ViragsSocial:strGuildNameAndType(sName, nType)
    if sName and nType and kGuildTypesToText[nType] then
        return sName .. " (" .. kGuildTypesToText[nType] .. ")"
    end

    return sName or ""
end
function ViragsSocial:RegisterSidebarTabs()
    if self.sidebarTabsRegistered then return end
    self.sidebarTabsRegistered = true
    tabsInfo = {} --reset

    --Init Guild and Circles Tabs

    local nCurrCircle = 1
    local sortedGuilds = self:SortedGuildsList()
    for key, guildCurr in pairs(sortedGuilds) do
        local guildType = guildCurr:GetType()

        local tabPosition = 0
        if self.JustLogedIn then
            self:OnGuildMessageOfTheDay(guildCurr)
        end

        if guildType == GuildLib.GuildType_Circle then
            tabPosition = nCurrCircle + ViragsSocial.TabCircle1 - 1
            nCurrCircle = nCurrCircle + 1
        elseif guildType == GuildLib.GuildType_Guild then
            guildCurr:RequestEventLogList()
            tabPosition = ViragsSocial.TabGuild
        elseif guildType == GuildLib.GuildType_WarParty then
            tabPosition = ViragsSocial.Warplot
        elseif guildType == GuildLib.GuildType_ArenaTeam_2v2 then
            tabPosition = ViragsSocial.Arena2v2
        elseif guildType == GuildLib.GuildType_ArenaTeam_3v3 then
            tabPosition = ViragsSocial.Arena3v3
        elseif guildType == GuildLib.GuildType_ArenaTeam_5v5 then
            tabPosition = ViragsSocial.Arena5v5
        end

        if tabPosition ~= 0 then
            self:RegisterTab(tabPosition, guildCurr:GetName(),
                guildCurr:GetOnlineMemberCount(), guildCurr:GetMemberCount(), guildCurr:GetType(), true)
        end
    end

    if nCurrCircle <= 5 and not self:IsMiniWnd() then --5 is max circles number
        self:RegisterTab(nCurrCircle + ViragsSocial.TabCircle1 - 1, self.kstrAddCircle)
    end

    self:RegisterTab(ViragsSocial.TabFriends, "Friends", nil, nil, nil, true)

    self:RegisterTab(ViragsSocial.TabIgnoreAndRivals, "Ignore And Rivals")
    self:RegisterTab(ViragsSocial.TabNeighbors, "Neighbors")
    self:RegisterTab(ViragsSocial.Group, "Group")
    self:RegisterTab(ViragsSocial.ScannerMode, "Scanner Mode")
    self:RegisterTab(ViragsSocial.Who, "Who")
end

function ViragsSocial:RegisterTab(nId, sName, nOnline, nTotal, nType, bCustomNotifications)
    tabsInfo[nId] = {
        sName = sName,
        nOnline = nOnline,
        nTotal = nTotal,
        nType = nType,
        bNotifications = bCustomNotifications == true
    }
end
function ViragsSocial:UpdateGuildAndCircleLists()
    -- need this to take rosters for guilds and circles into memory
    -- to show correct common social groups
    local guilds = GuildLib.GetGuilds() or {}
    for key, guildCurr in pairs(guilds) do
        if guildCurr:GetType() == GuildLib.GuildType_Circle
        or guildCurr:GetType() == GuildLib.GuildType_Guild then
           guildCurr:RequestMembers()
        end
    end


end

function ViragsSocial:ListOfTabs()
    local list = {}
    for k,v in pairs(tabsInfo) do
        if v.sName ~= self.kstrAddCircle and k ~= ViragsSocial.Who then
            list[k] = v
        end
    end

    return list
end

function ViragsSocial:ListOfCustomNotificationsTabs()
    local list = {}
    for k,v in pairs(tabsInfo) do
        if v.bNotifications then
            list[k] = v
        end
    end

    return list
end
-----------------------------------------------------------------------------------------------
-- On EVENT handlers
-----------------------------------------------------------------------------------------------
-- on SlashCommand "/vsl"
function ViragsSocial:OnViragsSocialOn()
    --will propper update neighbor and frind rels so we can see them in common social tabs
    self:UpdateFriendsRelations()
    self:UpdateNeighborRelations()

    self:ToggleUI()

    if self:IsVisible() then
        self:OnCloseSettingsWnd()
        self:BroadcastRequestInfo()
        self:ReloadGridFromServer()
    else
        Event_FireGenericEvent("SocialWindowHasBeenClosed")
        self:StopScannerMode()
    end
end

function ViragsSocial:OnGuildChanged()
    self:DEBUG("OnGuildChanged()")

    self:GridClear() -- TODO remove this for better performance eventually
    self.sidebarTabsRegistered = false
    self:UpdateSideBar()
end

function ViragsSocial:OnChangeZoneName(oVar, strNewZone)

    if  HousingLib.IsHousingWorld() then
        if HousingLib.IsOnMyResidence() and self:DefaultHouseCheck() then return end
    end

    if self.kMyID == nil then return end

    local currZone = self:HelperCurrentZoneName()

    self:DEBUG("NEW: " .. currZone .. " OLD: " .. self.ktPlayerInfoDB[self.kMyID].location)

    if self.ktPlayerInfoDB[self.kMyID] and currZone == self.ktPlayerInfoDB[self.kMyID].location then return end

    self.kbNeedUpdateMyInfo = true

    self:BroadcastUpdate()
end

function ViragsSocial:VisitRandomHouse(cmd, playerName)
    if not HousingLib.IsHousingWorld() then
        self:PRINT("You have to be in a Housing World to use this")
        return
    end

    if playerName ~= "" then
        local tCharacterData = GameLib.SearchRelationshipStatusByCharacterName(playerName)

        if tCharacterData ~= nil and tCharacterData.tNeighbor ~= nil and tCharacterData.tNeighbor.nId then
            HousingLib.VisitNeighborResidence(tCharacterData.tNeighbor.nId)
            return
        end

        self:StartRandomNeighborSearch(playerName)

    end

end





function ViragsSocial:DefaultHouseCheck()
    if self.bReturnToRealHome then
        self.bReturnToRealHome = false
        return false
    end

        local defaultHouse = self.tSettings.kstrDefaultHouse
    self:DEBUG(defaultHouse)
    if HousingLib.IsHousingWorld() and defaultHouse and defaultHouse ~= "" then

        -- port to the default house
        for k, tNeighbor in pairs(HousingLib.GetNeighborList() or {}) do
            if tNeighbor.strCharacterName == defaultHouse then
                HousingLib.VisitNeighborResidence(tNeighbor.nId)
                return true
            end
        end
    end

    return false
end

--TODO TODO TODO
function ViragsSocial:UpdatePlugsInfo(strNewZone)
    local name = strNewZone:match("%[([A-Za-z]+)%]")

    if name then
        local plotData = self.tNeighborPlugsDB[name]
        if  plotData == nil then
            plotData   = {}
        end

        plotData.nlastUpdate =  self:HelperServerTime()
        plotData.tPlots = {}
        local nPlotCount = HousingLib.GetPlotCount()
        self:DEBUG ("nPlotCount", nPlotCount)
        for idx = 1, nPlotCount do
            self:DEBUG ("Plot",HousingLib.GetPlot(idx))
            plotData.tPlots[idx] =  HousingLib.GetPlot(idx)
        end

        self:DEBUG ("Plot",plotData)

        self.tNeighborPlugsDB[name] = plotData

    end

end

function ViragsSocial:OnGuildRoster(guildCurr, tRoster) -- Event from CPP
    local currGID = self:GuildTabID(guildCurr)

    if kAllRosters[currGID] == nil then
        kAllRosters[currGID] = {}
        self:UpdateRelations(tRoster, currGID)
    end

    self:DEBUG("OnGuildRoster Got Data Event from CPP: " .. guildCurr:GetName())

    if not self:needRosterUpdate(guildCurr) then return end

    self:SetNewRosterForGrid(tRoster, currGID)
end


function ViragsSocial:OnGuildMemberChange(guildCurr)
    self:DEBUG("OnGuildMemberChange Got Data: " .. guildCurr:GetName())

    --Updating tooltip anyway

    for k, v in pairs(tabsInfo) do
        if self:isSameGuild(v.sName, v.nType, guildCurr:GetName(), guildCurr:GetType()) then
            self:UpdateOnlineCountFor(v, guildCurr:GetOnlineMemberCount(), guildCurr:GetMemberCount())
        end
    end

    if not self:needRosterUpdate(guildCurr) then return end


    self.kCurrGuild:RequestMembers()
end



function ViragsSocial:GuildTabID(guildCurr)
    if guildCurr == nil then return nil end

    for k, v in pairs(tabsInfo) do
        if self:isSameGuild(v.sName, v.nType, guildCurr:GetName(), guildCurr:GetType()) then
            return k
        end
    end

    return nil
end

function ViragsSocial:needRosterUpdate(guildCurr)
    if not self:IsVisible() then return false end
    if self.kCurrGuild then
        return self:isSameGuild(self.kCurrGuild:GetName(),
            self.kCurrGuild:GetType(),
            guildCurr:GetName(),
            guildCurr:GetType())
    end

    return false
end

function ViragsSocial:isSameGuild(strName1, nType1, strName2, nType2)
    return strName1 == strName2 and nType1 == nType2
end




--on RefreshRateTimeUpdate event
function ViragsSocial:OnRefreshInfoTimeUpdate()
    self.kBIsTimerOnCD = false

    if self.kNeedUpdateInfo then
        self.kNeedUpdateInfo = false
        if self.kCurrGuild then
            self:DEBUG("OnRefreshInfoTimeUpdate Changing: " .. self.kCurrGuild:GetName())

            self:UpdateGrid(true, false)
        end
    end
end



function ViragsSocial:FriendListUpdate()
    if self:IsFriendTabSelected() or self:IsIgnoreTabSelected() then
        if self.canUpdateFriendlist and self:IsVisible() then
            Apollo.StartTimer("FriendlistUpdateTimer")
        end
    end
end

function ViragsSocial:NeighborListUpdate()

    if self:IsNeghborTabSelected() and self.canUpdateFriendlist and self:IsVisible() then

        Apollo.StartTimer("FriendlistUpdateTimer")
    end
end

--FriendlistUpdateTimer
function ViragsSocial:OnFriendListUpdate()
    self.canUpdateFriendlist = true
    self:ReloadGridFromServer()
end




-----------------------------------------------------------------------------------------------
-- Location Updates
-----------------------------------------------------------------------------------------------
function ViragsSocial:OnUpdateLocationsTimer()

    if self:IsVisible() then
        local tFriendList = FriendshipLib.GetList() or {}

        local tOnlineFriends = {}
        for key, tFriend in pairs(tFriendList) do
            if tFriend.nId and tFriend.fLastOnline == 0 then -- online
                local friendDBrecord = self:DBRecord(tFriend.strCharacterName, false)
                if friendDBrecord then
                    if friendDBrecord.addonVersion and friendDBrecord.location then--skip
                    else table.insert(tOnlineFriends, tFriend.nId) end
                else
                    table.insert(tOnlineFriends, tFriend.nId)
                end
            end
        end
        FriendshipLib.GetLocations(tOnlineFriends)
    end
end


function ViragsSocial:OnFriendshipLocation(tLocations)

    if self:IsVisible() then
        local bUpdate = false
        for idx, tLocInfo in pairs(tLocations) do
            local tFriend = FriendshipLib.GetById(tLocInfo.nId)
            local name = tFriend.strCharacterName

            if tFriend.arCharacters then -- account frined
                name = self:HelperAccounFriendName(tFriend)
            end
            if name then
                local friendDBrecord = self:DBRecord(name, true)

                if friendDBrecord.location ~= tLocInfo.strWorldZone then
                    bUpdate = true
                    friendDBrecord.location = tLocInfo.strWorldZone
                end
            end
        end


        if bUpdate then self:UpdateGrid(false, false) end
    end
end

-----------------------------------------------------------------------------------------------
-- ViragsSocial Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
function ViragsSocial:InitMyInfo()
    self:DEBUG("InitMyInfo() ")

    if self.kbNeedUpdateMyInfo == false and self.kMyID then return end

    local player, id, ts1, ts2, class, path, lvl, guild, location, raidAttunKey

    player = GameLib.GetPlayerUnit()

    if player == nil then return end

    id = player:GetName()
    class = player:GetClassId()
    lvl = player:GetLevel()
    path = player:GetPlayerPathType()

    if id == nil or class == nil or lvl == nil or path == nil then return end

    local tKnownTS = CraftingLib.GetKnownTradeskills()
    if tKnownTS ~= nil then
        for idx, tCurrTradeskill in ipairs(tKnownTS) do
            local currTsShortName = self:ShortNameForTradeSkillID(tCurrTradeskill.eId)
            if currTsShortName and CraftingLib.GetTradeskillInfo(tCurrTradeskill.eId).bIsActive then
                if ts1 then ts2 = currTsShortName
                else ts1 = currTsShortName
                end
            end
        end
    end

    local tGuildList = GuildLib.GetGuilds()
    if tGuildList ~= nil then
        for key, guildCurr in pairs(tGuildList) do
            if guildCurr:GetType() == GuildLib.GuildType_Guild then
                guild = guildCurr:GetName()
            end
        end
    end

    if guild == nil then guild = "" end

    location = self:HelperCurrentZoneName()

    if location == nil or location == "" then return end

    local items = player:GetEquippedItems()
    local key = self:GetRaidAttuneKeyFromItems(items)
    raidAttunKey = self:GetRaidAttuneInfoFromKey(key)

    local DBPlayerRecord = self:DBRecord(id, true)
    self.kMyID = id
    DBPlayerRecord.version = self.ICCommLib_PROTOCOL_VERSION
    DBPlayerRecord.addonVersion = self.ADDON_VERSION
    DBPlayerRecord.name = id
    DBPlayerRecord.level = lvl
    DBPlayerRecord.class = class
    DBPlayerRecord.path = path
    DBPlayerRecord.ts1 = ts1
    DBPlayerRecord.ts2 = ts2
    DBPlayerRecord.guild = guild
    DBPlayerRecord.location = location
    DBPlayerRecord.raidAttunStep = raidAttunKey

    self.kbNeedUpdateMyInfo = false
    self.bMyInfoInitialized = true

    -- need this to take rosters for guilds and circles into memory
    -- to show correct common social groups
    self:UpdateGuildAndCircleLists()

    self:UpdateGrid(false, false)
end

function ViragsSocial:GetRaidAttuneInfoFromKey(key)
    local raidAttunKey
    if key then
        raidAttunKey = {}
        local keyInfo = key:GetDetailedInfo()

        local steps = keyInfo.tPrimary.arImbuements or {}
        for k,step in pairs(steps) do
            if not step.bComplete and step.bActive then
                raidAttunKey.step  =  k

                raidAttunKey.currentProgress = {}
                local tasks = step.queImbuement:GetVisibleObjectiveData() or {}
                for k,task in pairs(tasks) do
                    if task.bIsRequired and task.nCompleted ~= task.nNeeded then
                        raidAttunKey.currentProgress[k] = {nCompleted = task.nCompleted , nNeeded = task.nNeeded}
                    end

                end
                break
            end
        end
        if raidAttunKey.currentProgress == nil then
            raidAttunKey.bCompleted = true
        end

        raidAttunKey.nId = keyInfo.tPrimary.nId
    else
        return false -- false means there is no key in keyslot and nill means something wrong happend here
    end

    return raidAttunKey
end

function ViragsSocial:GetRaidAttuneKeyFromItems(items)

    local key
    self:DEBUG("items", items)
    for k, item in pairs(items) do
        if item:GetItemType() == 300 then
            key = item
            break
        end

    end

   return key

end

function ViragsSocial:UpdateMyInfo()
    self:DEBUG("UpdateMyInfo()")

    if self.bMyInfoInitialized then
        --update only location
        local location = self:HelperCurrentZoneName()

        if location == nil or location == "" then return end
        self:DBRecord(self.kMyID, false).location = location

        self.kbNeedUpdateMyInfo = false
    else
        self:InitMyInfo()
    end
end

function ViragsSocial:UpdateRelations(tRoster, nTabID)
    if nTabID == ViragsSocial.TabGuild or (nTabID >= ViragsSocial.TabCircle1 and nTabID <= ViragsSocial.TabCircle5) then --circle or guild
        for k, v in pairs(tRoster) do
            local resultRel = self.ktRelationsDB[v.strName]
            if resultRel == nil then
                resultRel = {}
                self.ktRelationsDB[v.strName] = resultRel
            end
            resultRel[nTabID] = true
        end
    end
end
function ViragsSocial:UpdateNeighborRelations()
    if self.bNeighborRelationsUpdated then return end
    self.bNeighborRelationsUpdated = true

    local neighborList = HousingLib.GetNeighborList() or{}
    for k,v in pairs (neighborList) do
        local name = v.strCharacterName
        if not self.ktRelationsDB[name] then
            self.ktRelationsDB[name] = {}
        end

        self.ktRelationsDB[name][ViragsSocial.TabNeighbors] = true
    end
end

function ViragsSocial:UpdateFriendsRelations()
    if self.bFriendsRelationsUpdated then return end
    self.bFriendsRelationsUpdated = true

    local friendlist = FriendshipLib.GetList() or {}

    for k,v in pairs(friendlist) do
        local name = v.strCharacterName
        if not self.ktRelationsDB[name] then
            self.ktRelationsDB[name] = {}
        end

        self.ktRelationsDB[name][ViragsSocial.TabFriends] = true
    end
end

function ViragsSocial:RelationsIconForPlayer(strPlayer, excludTab)
    local rel = self.ktRelationsDB[strPlayer]

    if rel then
        for k,v in pairs(rel) do
            if k~= excludTab and v then
                return  "achievements:sprAchievements_Icon_Group"
             end
        end

    end

    return nil
end



function ViragsSocial:ReloadGridFromServer()
    if not self:IsVisible() then return end

    self:DEBUG("ReloadGridFromServer")

    Apollo.StopTimer("RefreshRateTimeUpdate")

    self.kBIsTimerOnCD = false
    self.kCurrGuild = nil


    if self:IsFriendTabSelected()
            or self:IsIgnoreTabSelected() then self:ReloadFriendList()
    elseif self:IsNeghborTabSelected() then self:ReloadNeighborList()
    elseif self:IsGroupTabSelected() then self:ReloadGroupList()
    elseif self:IsScannerMode() then self:ReloadUnitScannerList()
    elseif self:IsWhoTabSelected() then self:ReloadWhoList()
    elseif tabsInfo[self.kSelectedTab] then self:ReloadGuildList(tabsInfo[self.kSelectedTab])  end

    self:OnUpdateLocationsTimer() -- will update locations info from friendlist



    self:SetupNavigationMenu()
end

function ViragsSocial:SetNewRosterForGrid(tRoster, id)
    if id == nil then
        id = self.kSelectedTab
    end

    kAllRosters[id] = tRoster
    self:UpdateGrid(false, false)
end

function ViragsSocial:GetRosterForGrid (id)
    if id and  kAllRosters[id] then return  kAllRosters[id]   end
end

function ViragsSocial:UpdateGrid(isTimerUpdate, bForceUpdate)
    if self:IsVisible() then
        self:DEBUG("UpdateGrid(isTimerUpdate, bForceUpdate)")
        self:DEBUG("ktPlayerInfoDB[tCurr.strName]", self.ktPlayerInfoDB)



        if self:isUpdateNeededNow(isTimerUpdate, bForceUpdate) == false then return end -- will refresh in RefreshRateTimeUpdate time


        self:GridSaveState()
        self:GridClear() -- TODO remove this for better performance eventually

        local currRoster = self:GetRosterForGrid (self.kSelectedTab)
        self:DEBUG("currRoster", currRoster)
        if currRoster == nil then return end

        self:SetUITotalRosterSize(#currRoster)

        if self:IsFriendTabSelected()
        or self:IsIgnoreTabSelected() then self:DrawFriendList(currRoster)
        elseif self:IsNeghborTabSelected() then self:DrawNeighborList(currRoster)
        elseif self:IsGroupTabSelected() then self:DrawGroupList(currRoster)
        elseif self:IsScannerMode() then  self:DrawUnitScannerList(currRoster)
        elseif self:IsWhoTabSelected() then  self:DrawWhoList(currRoster)
        elseif self.kCurrGuild then self:DrawGuildList(currRoster)
        end

        self:GridLoadState()
    end
end

function ViragsSocial:ReloadGuildList(tabInfo)
    local currGuild
    for key, guild in pairs(GuildLib.GetGuilds()) do
        if self:isSameGuild(tabInfo.sName, tabInfo.nType, guild:GetName(), guild:GetType()) then
            currGuild = guild
        end
    end

    if not currGuild then return end

    self.kCurrGuild = currGuild
    currGuild:RequestMembers()
end


-- 1) Guilds and Circles
function ViragsSocial:DrawGuildList(tRoster)

    local guildCurr = self.kCurrGuild
    local currTab = self.kSelectedTab
    self:DEBUG("UpdateGrid!!!!!!: " .. guildCurr:GetName())


    if guildCurr == nil or tRoster == nil then return end
    local cmpFn = self:cmpFn()
    if cmpFn then
        self:SelectionSort( tRoster, cmpFn ) --table.sort(tRoster, cmpFn)
    end

    local tRanks = guildCurr:GetRanks()
    if tRanks == nil then
        return --New guild and we have not yet recieved the data
    end

    for key, tCurr in pairs(tRoster) do
        local strRank = Apollo.GetString("Circles_UnknownRank")

        if tRanks[tCurr.nRank] and tRanks[tCurr.nRank].strName then
            strRank = tRanks[tCurr.nRank].strName
            strRank = FixXMLString(strRank)
        end

        local strIcon = self:RelationsIconForPlayer(tCurr.strName, currTab)
        if strIcon == nil then
            if tCurr.nRank == 1 then strIcon = "CRB_Basekit:kitIcon_Holo_Profile" -- "Guild_Leader_Icon"
            elseif tCurr.nRank == 2 then strIcon = "CRB_Basekit:kitIcon_Holo_Actions" -- "Guild_Council_Icon"
            end
        end

        if tCurr.strName == self.kMyID then self.kStrMyNote = tCurr.strNote end

        local note = tCurr.strNote or ""
        local bHaveNote = note ~= ""
        local playerInfo = self.ktPlayerInfoDB[tCurr.strName]

        local noteIcon1
        local noteIcon2
        local rankIcon = self:ImgForAttuneInfo(playerInfo)
        if playerInfo then
            noteIcon1 = self:IconForTradeSkillShortName(playerInfo.ts1)
            noteIcon2 = self:IconForTradeSkillShortName(playerInfo.ts2)

            if guildCurr:GetType() == GuildLib.GuildType_Circle and playerInfo.guild and playerInfo.guild ~= "" then
                note = playerInfo.guild
                if bHaveNote then note = note .. " (" .. tCurr.strNote .. ")" end

            elseif guildCurr:GetType() == GuildLib.GuildType_Guild then
            end



        end

        if self.kShowMyNote[self.kSelectedTab] then
            note = ""
            if  self.ktGuildNotes and self.ktGuildNotes[tCurr.strName] then
                note = self.ktGuildNotes[tCurr.strName]
            end

        end



        self:AddRow(tCurr, tCurr.eClass, tCurr.ePathType, tCurr.nLevel, tCurr.strName, tCurr.fLastOnline, strRank, note, strIcon, rankIcon, noteIcon1, noteIcon2)
    end
end

function ViragsSocial:ImgForAttuneInfo(playerInfo)
    if playerInfo == nil then return nil end

    local rankIcon

    if playerInfo.raidAttunStep then
        if playerInfo.raidAttunStep.bCompleted then
            rankIcon = "achievements:sprAchievements_Icon_Complete"
        else
            rankIcon = "CRB_SpellslingerSprites:sprSlingerSealActive_Small"
        end

    elseif playerInfo.raidAttunStep == false then
        rankIcon = "CRB_CharacterCreateSprites:sprCharC_ClassFooterIconDisabled"
    end

    return rankIcon
end


function ViragsSocial:ReloadFriendList()
    local tFriendList = FriendshipLib.GetList() or {}
    local tAccountFriendList = FriendshipLib.GetAccountList() or {}
    local tAccountInvitesList = FriendshipLib.GetAccountInviteList() or {}
    local tInvitesList = FriendshipLib.GetInviteList() or {}

    -- NEED to have strName nRank nLevel eClass ePathType strNote fLastOnline vars
    -- this is much easier than to wright 4 different cmp fns sets. like 40 fns vs 10
    local lastFriendKey = 1
    local resultList = {}
    for key, player in pairs(tFriendList) do
        if player.strCharacterName then --who knows why thay will send data without a name... lol
            player.strName = player.strCharacterName

            if player.fLastOnline == nil then
                player.fLastOnline = 10000 -- just random big numver
            end

            if player.bFriend then player.nRank = FriendshipLib.CharacterFriendshipType_Friend
            elseif player.bRival then player.nRank = FriendshipLib.CharacterFriendshipType_Rival
            elseif player.bIgnore then player.nRank = FriendshipLib.CharacterFriendshipType_Ignore
            end

            if player.nClassId then player.eClass = player.nClassId
            else player.eClass = ViragsSocial.kUNDEFINED
            end

            if player.nPathId then player.ePathType = player.nPathId
            else player.ePathType = ViragsSocial.kUNDEFINED
            end

            if player.nLevel == nil then
                player.nLevel = ViragsSocial.kUNDEFINED
            end
            local bAdd = player.nRank == FriendshipLib.CharacterFriendshipType_Friend and self:IsFriendTabSelected()
            if self:IsIgnoreTabSelected() then
                bAdd = player.nRank == FriendshipLib.CharacterFriendshipType_Rival or player.nRank == FriendshipLib.CharacterFriendshipType_Ignore
            end

            if bAdd then
                resultList[lastFriendKey] = player
                lastFriendKey = lastFriendKey + 1
            end
        end
    end

    if self:IsIgnoreTabSelected() then
        self:SetNewRosterForGrid(resultList, ViragsSocial.TabIgnoreAndRivals)
        return
    end

    local currentRealm = GameLib.GetRealmName()

    for key, player in pairs(tAccountFriendList) do
        if player.strCharacterName then --who knows why thay will send data without a name... lol

            if player.fLastOnline == 0 and player.arCharacters and player.arCharacters[1] then -- online and we have more info about him
                local tCharacterInfo = player.arCharacters[1]
                if tCharacterInfo then
                    player.strName = self:HelperAccounFriendName(player)
                    player.nLevel = tCharacterInfo.nLevel
                    player.eClass = tCharacterInfo.nClassId
                    player.ePathType = tCharacterInfo.nPathId

                    self:HelperUpdateLocationFromAccounFriendInfo(player, currentRealm)
                end
            else
                -- some big number, because player is not online
                --it is just wildstar bug
                if player.fLastOnline == 0 then player.fLastOnline = 1000 end

                player.strName = player.strCharacterName
                player.eClass = ViragsSocial.kUNDEFINED
                player.ePathType = ViragsSocial.kUNDEFINED
                player.nLevel = ViragsSocial.kUNDEFINED
            end

            player.nRank = FriendshipLib.CharacterFriendshipType_Account
            player.strNote = player.strPrivateNote
            if player.strPublicNote ~= "" then player.strNote = player.strNote .. " Status: " .. player.strPublicNote end

            resultList[lastFriendKey] = player --adding to the friend list
            lastFriendKey = lastFriendKey + 1
        end
    end

    for key, player in pairs(tAccountInvitesList) do
        if player.strDisplayName then --who knows why thay will send data without a name... lol

            player.strName = player.strDisplayName
            player.eClass = ViragsSocial.kUNDEFINED
            player.ePathType = ViragsSocial.kUNDEFINED
            player.nLevel = ViragsSocial.kUNDEFINED
            player.fLastOnline = -1 * player.fDaysUntilExpired
            player.nRank = self.CharacterFriendshipType_Account_Invite
            resultList[lastFriendKey] = player --adding to the friend list
            lastFriendKey = lastFriendKey + 1
        end
    end

    for key, player in pairs(tInvitesList) do
        if player.strCharacterName then --who knows why thay will send data without a name... lol

            player.strName = player.strCharacterName
            player.fLastOnline = -1 * player.fDaysUntilExpired
            player.nRank = self.CharacterFriendshipType_Invite


            if player.nClassId then player.eClass = player.nClassId
            else player.eClass = ViragsSocial.kUNDEFINED
            end

            if player.nPathId then player.ePathType = player.nPathId
            else player.ePathType = ViragsSocial.kUNDEFINED
            end

            if player.nLevel == nil then
                player.nLevel = ViragsSocial.kUNDEFINED
            end
            resultList[lastFriendKey] = player --adding to the friend list
            lastFriendKey = lastFriendKey + 1
        end
    end

    self:SetNewRosterForGrid(resultList, ViragsSocial.TabFriends)
end

-- 2) Friends
local karStatusText =
{
    [FriendshipLib.AccountPresenceState_Available]	= "",
    [FriendshipLib.AccountPresenceState_Away]		= "AFK ",
    [FriendshipLib.AccountPresenceState_Busy]		= "DND ",
    --[FriendshipLib.AccountPresenceState_Invisible]	= Apollo.GetString("Friends_StatusInvisibleBtn"),
}
function ViragsSocial:DrawFriendList(tRoster)
    if tRoster == nil then return end

    self:DEBUG("UpdateGrid!!!!!!: BuildFriendList")
    self:DEBUG("FriendList", tRoster)
    local currTab = self.kSelectedTab
    local cmpFn = self:cmpFn()
    if cmpFn then
        self:SelectionSort(tRoster,  function(a, b)
            if a.fLastOnline < 0 then return true end
            if b.fLastOnline < 0 then return false end
            return cmpFn(a, b)
        end)
    end
    for key, tCurr in pairs(tRoster) do
        local strRankIcon = self.ktFriendlistIcons[tCurr.nRank]
        local strRank = self.ktFriendRanks[tCurr.nRank]
        local playerInfo = self.ktPlayerInfoDB[tCurr.strName]
        local noteIcon1
        local noteIcon2
         local nameIcon = self:RelationsIconForPlayer(tCurr.strName, currTab)
        if playerInfo then
            noteIcon1 = self:IconForTradeSkillShortName(playerInfo.ts1)
            noteIcon2 = self:IconForTradeSkillShortName(playerInfo.ts2)
        end
        local name = tCurr.strName
        if tCurr.nPresenceState and  karStatusText[tCurr.nPresenceState] then
            name =  karStatusText[tCurr.nPresenceState]   .. name
        end

        self:AddRow(tCurr, tCurr.eClass, tCurr.ePathType, tCurr.nLevel, name , tCurr.fLastOnline, strRank, tCurr.strNote, nameIcon, strRankIcon, noteIcon1, noteIcon2)
    end
end


function ViragsSocial:ReloadNeighborList()
    local tNeighborList = HousingLib.GetNeighborList() or {}

    for key, player in pairs(tNeighborList) do


        player.strName = player.strCharacterName or ""
        player.nRank = player.ePermissionNeighbor or HousingLib.NeighborPermissionLevel.Normal
        player.eClass = player.nClassId or ViragsSocial.kUNDEFINED
        player.ePathType = player.nPathId or ViragsSocial.kUNDEFINED
        player.strNote = ""
        if self.ktNeigborNotes and self.ktNeigborNotes[player.strName] then
            player.strNote = self.ktNeigborNotes[player.strName]
        end
    end

    self:SetNewRosterForGrid(tNeighborList, ViragsSocial.TabNeighbors)
end

function ViragsSocial:DrawNeighborList(tRoster)
    if tRoster == nil then return end
    self:DEBUG("UpdateGrid!!!!!!: BuildNeighborList")
    self:DEBUG("BuildNeighborList()", tRoster)

    local currTab = self.kSelectedTab
    local cmpFn = self:cmpFn()
    if cmpFn then
        self:SelectionSort( tRoster, cmpFn )
      --  table.sort(tRoster, cmpFn)
    end
    for key, tCurr in pairs(tRoster) do

        local status = "Roommate"
        if tCurr.nRank == HousingLib.NeighborPermissionLevel.Normal then
            status = "None"
        end

        local playerInfo = self.ktPlayerInfoDB[tCurr.strName]
        local noteIcon1
        local noteIcon2
        local nameIcon = self:RelationsIconForPlayer(tCurr.strName, currTab)
        if playerInfo then
            noteIcon1 = self:IconForTradeSkillShortName(playerInfo.ts1)
            noteIcon2 = self:IconForTradeSkillShortName(playerInfo.ts2)
        end

        -- tCurrNeighbor, nClassId, nPathId, nLevel, strCharacterName, fLastOnline

        self:AddRow(tCurr, tCurr.nClassId, tCurr.nPathId, tCurr.nLevel, tCurr.strCharacterName, tCurr.fLastOnline, status, tCurr.strNote, nameIcon, nil, noteIcon1, noteIcon2)

    end
end



-----------------------------------------------------------------------------------------------
-- ViragsSocial Random Useful FNs
-----------------------------------------------------------------------------------------------
function ViragsSocial:GetSortOrderForCurrentTab()
    if self.kSortingForTab[self.kSelectedTab] == nil then
        if self.tSettings and self.tSettings.kStrDefaultSorting then
            return {self.tSettings.kStrDefaultSorting, true}
        end

        return {"RosterSortBtnName", true}
    end

    return self.kSortingForTab[self.kSelectedTab]
end

function ViragsSocial:SetNewSortOrderForCurrentTab(strSortBy)

    if strSortBy == nil or kSortingCmpFn[strSortBy] == nil then return end

    local sort = self.kSortingForTab[self.kSelectedTab]
    local order = true

    if self.kSortingForTab[self.kSelectedTab] then
        local currOreder = self.kSortingForTab[self.kSelectedTab][2]
        order = not currOreder
    end

    self.kSortingForTab[self.kSelectedTab] = {strSortBy, order}
end

function ViragsSocial:cmpFn()
    local sort = self:GetSortOrderForCurrentTab()
    if sort == nil then return nil end

    local sortBy = sort[1]
    local ascOrder = sort[2]
    if sortBy == nil or ascOrder == nil then return nil end

    local cmpFn = kSortingCmpFn[sortBy]
    if cmpFn == nil then return nil end

    local sortFN

    if ascOrder then
        sortFN = function(b, a)
            local cmpRez = cmpFn(a, b)
            if cmpRez == 0 then return a.strName > b.strName
            else return cmpRez > 0
            end
        end
    else
        sortFN = function(a, b)
            local cmpRez = cmpFn(a, b)
            if cmpRez == 0 then return a.strName > b.strName
            else return cmpRez > 0
            end
        end
    end

    return sortFN
end

function ViragsSocial:UpdateOnlineCountFor(tData, nNewOnline, nNewTotal)
    if tData == nill then return end

    local online = nNewOnline or 0
    local total = nNewTotal or 0

    if online ~= tData.nOnline or tData.nTotal ~= total then
        tData.nOnline = online
        tData.nTotal = total
        if self.isUpdatingOnlineCount == false then
            self.isUpdatingOnlineCount = true
            Apollo.StartTimer("UpdateOnlineCountTimer")
        end
    end
end

function ViragsSocial:UpdateOnlineCount(forceUpdate)
    self.isUpdatingOnlineCount = false
    if tabsInfo == nil then return end

    local strTooltip = ""
    local lastType
    for k, v in pairs(tabsInfo) do
        if v.sName and v.nOnline and v.nTotal then
            if lastType ~= v.nType then
                lastType = v.nType
                strTooltip = strTooltip .. "\n \n"
            end
            strTooltip = strTooltip .. v.sName .. ": " .. v.nOnline .. "/" .. v.nTotal .. "\n"
            if v.tView then v.tView:SetText(v.nOnline) end
        end
    end
    local onlineCount = 0
    if self.nInterfaceMenuTabOnlineCount and  tabsInfo[self.nInterfaceMenuTabOnlineCount] and tabsInfo[self.nInterfaceMenuTabOnlineCount].nOnline then
        onlineCount = tabsInfo[self.nInterfaceMenuTabOnlineCount].nOnline
    end


    Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "Virag's Social", { false, "\n" .. strTooltip, onlineCount})
end

function ViragsSocial:SortedGuildsList()
    local arGuilds = GuildLib.GetGuilds()

    table.sort(arGuilds, function(guildLhs, guildRhs)
        local chanLhs = guildLhs and guildLhs:GetChannel()
        local chanRhs = guildRhs and guildRhs:GetChannel()
        local strCommandLhs = chanLhs and chanLhs:GetCommand() or ""
        local strCommandRhs = chanRhs and chanRhs:GetCommand() or ""
        return strCommandLhs < strCommandRhs
    end)

    return arGuilds or {}
end

function ViragsSocial:isUpdateNeededNow(isTimerUpdate, bForceUpdate)

    if bForceUpdate or isTimerUpdate then
        self.kBIsTimerOnCD = false
        self.kNeedUpdateInfo = false
        Apollo.StopTimer("RefreshRateTimeUpdate")
        return true
    end

    if self.kBIsTimerOnCD then
        self.kNeedUpdateInfo = true
        return false
    end

    Apollo.StopTimer("RefreshRateTimeUpdate")
    Apollo.StartTimer("RefreshRateTimeUpdate")
    self.kBIsTimerOnCD = true
    self.kNeedUpdateInfo = false

    return true
end

function ViragsSocial:HelperAccounFriendName(player)
    if player == nil then return "" end

    local playerName = ""

    if player.arCharacters and player.arCharacters[1] then
        playerName = " (" .. player.arCharacters[1].strCharacterName .. "@" .. player.arCharacters[1].strRealm .. ")"
    end

    return player.strCharacterName .. playerName
end

function ViragsSocial:HelperUpdateLocationFromAccounFriendInfo(tAccountFriend, currentRealm)
    if tAccountFriend.fLastOnline ~= 0 or
            tAccountFriend == nil or
            tAccountFriend.arCharacters == nil or
            tAccountFriend.arCharacters[1] == nil then return
    end

    local character = tAccountFriend.arCharacters[1]
    local characterName = character.strCharacterName

    local accountFriendDBrecord = self:DBRecord(self:HelperAccounFriendName(tAccountFriend), true)
    accountFriendDBrecord.location = character.strWorldZone

    if currentRealm ~= character.strRealm then return end

    local friendDBrecord = self:DBRecord(characterName, true)

    if friendDBrecord.addonVersion then return end -- no need to refresh addon info

    friendDBrecord.location = character.strWorldZone
end

function ViragsSocial:HelperSelectedRosterData()
    local focusRow = nil
    local data = self:CurrentGridFocus()
    if data then
        local roster = self:GetRosterForGrid (self.kSelectedTab)

        if roster then
            for k, v in pairs(roster) do
                if v.strName == data.strName then
                    focusRow = k
                end
            end
        end

    end
    return focusRow, data
end

function ViragsSocial:NeighborTogglePermissionLevel(idInRoster)
    local roster = self:GetRosterForGrid (self.kSelectedTab)

    if idInRoster == nil or roster == nil or roster[idInRoster] == nil then return end

    local data = roster[idInRoster]

    if data.nRank == HousingLib.NeighborPermissionLevel.Roommate then --roommate
        roster[idInRoster].nRank = HousingLib.NeighborPermissionLevel.Normal
        HousingLib.NeighborSetPermission(data.nId, HousingLib.NeighborPermissionLevel.Normal)
    elseif data.nRank == HousingLib.NeighborPermissionLevel.Normal then -- no permissions
        roster[idInRoster].nRank = HousingLib.NeighborPermissionLevel.Roommate
        HousingLib.NeighborSetPermission(data.nId, HousingLib.NeighborPermissionLevel.Roommate)
    end

    self:UpdateGrid(false, true)
end

function ViragsSocial:SaveNeighborNote(strName, strNote, idInRoster)
    if not strName or not strNote then return end

    if self.ktNeigborNotes == nil then
        self.ktNeigborNotes = {}
    end
    local roster = self:GetRosterForGrid (self.kSelectedTab)
    if roster and idInRoster and roster[idInRoster]
            and roster[idInRoster].strName == strName then
        roster[idInRoster].strNote = strNote
    end

    self.ktNeigborNotes[strName] = strNote
    self:UpdateGrid(false, false)
end

function ViragsSocial:SaveGuildNote(strName, strNote, idInRoster)
    if not strName or not strNote then return end

    if self.ktGuildNotes == nil then
        self.ktGuildNotes = {}
    end

    self.ktGuildNotes[strName] = strNote
    self.kShowMyNote[self.kSelectedTab] = true
    self:UpdateGrid(false, false)
end


function ViragsSocial:DEBUG(strName, rData)
    local R = Apollo.GetAddon("Rover")
    if self.kbDEBUG and R then
        if rData then  R:AddWatch(strName, rData, R.ADD_ALL)
        else Print(strName)  end
    end
end

-----------------------------------------------------------------------------------------------
-- ViragsSocial COMPARE fUNCTIONS
-----------------------------------------------------------------------------------------------


function ViragsSocial:InitSortFns()
    if self.sortFnInited then return end
    self.sortFnInited = true

    local cmpFn = function(a, b)
        if a == b then return 0
        elseif a < b then return -1
        else return 1
        end
    end

    kSortingCmpFn = {
        ["RosterSortBtnName"] = function(a, b) return cmpFn(a.strName, b.strName) end,
        ["RosterSortBtnRank"] = function(a, b) return cmpFn(a.nRank, b.nRank) end,
        ["RosterSortBtnLevel"] = function(a, b) return -1 * cmpFn(a.nLevel, b.nLevel) end,
        ["RosterSortBtnClass"] = function(a, b) return cmpFn(a.eClass, b.eClass) end,
        ["RosterSortBtnPath"] = function(a, b) return cmpFn(a.ePathType, b.ePathType) end,
        ["RosterSortBtnNote"] = function(a, b)
            if (self:IsCircleTabSelected() or self:IsGuildTabSelected()) and self.kShowMyNote[self.kSelectedTab] then
                local anote = ""
                local bnote = ""
                if self.ktGuildNotes and self.ktGuildNotes[a.strName] then
                    anote = self.ktGuildNotes[a.strName]
                end
                if self.ktGuildNotes and self.ktGuildNotes[b.strName] then
                    bnote = self.ktGuildNotes[b.strName]
                end
                return -1 * cmpFn(anote, bnote)
            end

            if self:IsCircleTabSelected() then --circles
                local aGuild = ""
                local bGuild = ""
                if self.ktPlayerInfoDB[a.strName] and self.ktPlayerInfoDB[a.strName].guild then
                    aGuild = self.ktPlayerInfoDB[a.strName].guild
                end
                if self.ktPlayerInfoDB[b.strName] and self.ktPlayerInfoDB[b.strName].guild then
                    bGuild = self.ktPlayerInfoDB[b.strName].guild
                end

                if aGuild ~= "" and bGuild ~= "" then return -1 * cmpFn(aGuild, bGuild)
                elseif aGuild ~= "" then return -1
                elseif bGuild ~= "" then return 1
                end
            end

            return -1 * cmpFn(a.strNote, b.strNote)
        end,
        ["RosterSortBtnOnline"] = function(a, b)
            local atime = a.fLastOnline
            local btime = b.fLastOnline

            if (atime == 0) and (btime == 0) then
                local aZone = self:LocationOfPlayer(a.strName)
                local bZone = self:LocationOfPlayer(b.strName)

                if aZone and bZone then return -1 * cmpFn(aZone, bZone)
                elseif aZone then return -1
                elseif bZone then return 1
                end
            end

            return cmpFn(atime, btime)
        end,
    }
end



local ViragsSocialInst = ViragsSocial:new()
ViragsSocialInst:Init()
