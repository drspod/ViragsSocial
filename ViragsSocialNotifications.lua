--
-- Created by IntelliJ IDEA.
-- User: Vestl_000
-- Date: 8/18/2014
-- Time: 12:58 PM
-- To change this template use File | Settings | File Templates.
--
local ViragsSocial = Apollo.GetAddon("ViragsSocial")

local ktFriendshipResult =
{
    [FriendshipLib.FriendshipResult_PlayerNotFound] = Apollo.GetString("Friends_PlayerNotFound"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_RealmNotFound] = Apollo.GetString("Friends_RealmNotFound"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_RequestDenied] = Apollo.GetString("Friends_RequestDenied"), --crColor = kcrColorMessage},
    [FriendshipLib.FriendshipResult_PlayerAlreadyFriend] = Apollo.GetString("Friends_AlreadyFriendsMsg"), --crColor = kcrColorMessage},
    [FriendshipLib.FriendshipResult_PlayerOffline] = Apollo.GetString("Friends_PlayerOffline"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_FriendshipNotFound] = Apollo.GetString("Friends_NotFound"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_InvalidType] = Apollo.GetString("Friends_InvalidType"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_RequestNotFound] = Apollo.GetString("Friends_RequestNotFound"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_RequestTimedOut] = Apollo.GetString("Friends_RequestTimeOut"), --crColor = kcrColorMessage},
    [FriendshipLib.FriendshipResult_Busy] = Apollo.GetString("Friends_BusyMsg"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_InvalidNote] = Apollo.GetString("Friends_InvalidNote"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_MaxFriends] = Apollo.GetString("Friends_MaxFriends"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_MaxRivals] = Apollo.GetString("Friends_MaxRivals"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_MaxIgnored] = Apollo.GetString("Friends_MaxIgnored"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_UnableToProcess] = Apollo.GetString("Friends_CannotProcess"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_PlayerNotFriend] = Apollo.GetString("Friends_PlayerNotFound"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_PlayerConsideringOtherFriend] = Apollo.GetString("Friends_MultipleRequests"), --crColor = kcrColorMessage},
    [FriendshipLib.FriendshipResult_RequestSent] = Apollo.GetString("Friends_RequestSent"), --crColor = kcrColorMessage},
    [FriendshipLib.FriendshipResult_PlayerAlreadyRival] = Apollo.GetString("Friends_AlreadyRival"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_PlayerAlreadyNeighbor] = Apollo.GetString("Friends_AlreadyNeighbor"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_PlayerAlreadyIgnored] = Apollo.GetString("Friends_AlreadyIgnored"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_PlayerOnIgnored] = Apollo.GetString("Friends_PlayerIgnored"), --crColor = kcrColorMessage},
    [FriendshipLib.FriendshipResult_PlayerNotRival] = Apollo.GetString("Friends_NotRival"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_PlayerNotIgnored] = Apollo.GetString("Friends_NotIgnored"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_PlayerNotNeighbor] = Apollo.GetString("Friends_NotNeighbor"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_PlayerNotOfThisRealm] = Apollo.GetString("Friends_NotOnRealm"), --crColor = kcrColorDominion},
    [FriendshipLib.FriendshipResult_FriendsBlocked] = Apollo.GetString("Friends_BlockingRequests"), --crColor = kcrColorMessage}
    [FriendshipLib.FriendshipResult_CannotInviteSelf] = Apollo.GetString("Friends_CannotInviteSelf"), --crColor = kcrColorMessage}
    [FriendshipLib.FriendshipResult_ThrottledRequest] = Apollo.GetString("Friends_ThrottledRequest"), --crColor = kcrColorMessage}
    [FriendshipLib.FriendshipResult_ContainsProfanity] = Apollo.GetString("Friends_ContainsProfanity"), --crColor = kcrColorMessage}
    [FriendshipLib.FriendshipResult_InvalidPublicNote] = Apollo.GetString("Friends_InvalidPublicNote"), --crColor = kcrColorMessage}
    [FriendshipLib.FriendshipResult_InvalidPublicDisplayName] = Apollo.GetString("Friends_InvalidPublicDisplayName"), --crColor = kcrColorMessage}
    [FriendshipLib.FriendshipResult_BlockedForStrangers] = Apollo.GetString("Friends_BlockedForStrangers"), --crColor = kcrColorMessage}
    [FriendshipLib.FriendshipResult_InvalidEmail] = Apollo.GetString("Friends_InvalidPublicDisplayName"), --crColor = kcrColorMessage}
    [FriendshipLib.FriendshipResult_InvalidAutoResponse] = Apollo.GetString("Friends_InvalidAutoResponse"), --crColor = kcrColorMessage}
    [FriendshipLib.FriendshipResult_NameUnavailable] = Apollo.GetString("Friends_NameUnavailable"), --crColor = kcrColorMessage}
}


local kNotificationText = "text"
local kNotificationSound = "sound"

local NotificationAll = 1
local NotificationOnline = 2
local NotificationOffline = 3
local NotificationLeave = 4
local NotificationJoin = 5

function ViragsSocial:InitNotifications()
    Apollo.RegisterEventHandler("FriendshipResult", "OnFriendshipResult", self)
    Apollo.RegisterEventHandler("GuildResult", "OnGuildResult", self) -- game client initiated events
    Apollo.RegisterEventHandler("GuildMessageOfTheDay", "OnGuildMessageOfTheDay", self)

    --FRIEND LIST UPDATES --todo fix this
    Apollo.RegisterEventHandler("FriendshipAdd", "FriendListUpdate", self)
    Apollo.RegisterEventHandler("FriendshipUpdate", "FriendListUpdate", self)
    Apollo.RegisterEventHandler("FriendshipUpdateOnline", "OnFriendshipUpdateOnline", self)
    Apollo.RegisterEventHandler("FriendshipRemove", "OnFriendshipRemove", self)

    Apollo.RegisterEventHandler("FriendshipRequest", "FriendListUpdate", self)
    Apollo.RegisterEventHandler("FriendshipRequestWithdrawn", "FriendListUpdate", self)

    Apollo.RegisterEventHandler("FriendshipInvitesRecieved", "OnFriendshipInvitesRecieved", self)
    Apollo.RegisterEventHandler("FriendshipInviteRemoved", "FriendListUpdate", self)
    Apollo.RegisterEventHandler("FriendshipAccountUpdateOnline", "OnFriendshipUpdateOnline", self)
    Apollo.RegisterEventHandler("FriendshipAccountInvitesRecieved", "OnFriendshipInvitesRecieved", self)
    Apollo.RegisterEventHandler("FriendshipAccountInviteRemoved", "FriendListUpdate", self)
    Apollo.RegisterEventHandler("FriendshipAccountFriendsRecieved", "FriendListUpdate", self)
    Apollo.RegisterEventHandler("FriendshipAccountFriendRemoved", "OnFriendshipRemove", self)
    Apollo.RegisterEventHandler("FriendshipAccountCharacterLevelUpdate", "FriendListUpdate", self)
    Apollo.RegisterEventHandler("FriendshipAccountDataUpdate", "FriendListUpdate", self)
    Apollo.RegisterEventHandler("FriendshipAccountPersonalStatusUpdate", "FriendListUpdate", self)
end

function ViragsSocial:OnFriendshipUpdateOnline(nFriendId)

    local tFriend = FriendshipLib.GetById(nFriendId)
    self:DEBUG("tFriend",tFriend)
    local bFriend = tFriend and (tFriend.bFriend == true or tFriend.nPresenceState ~= nil)
    if bFriend and tFriend.strCharacterName and tFriend.strCharacterName ~= "" then
        local strMessage
        local type
        if tFriend.fLastOnline == 0 then
            strMessage = String_GetWeaselString(Apollo.GetString("Friends_HasComeOnline"), tFriend.strCharacterName)
            type = NotificationOnline
        else
            strMessage = String_GetWeaselString(Apollo.GetString("Friends_HasGoneOffline"), tFriend.strCharacterName)
            type = NotificationOffline
        end
        self:PublishNotifications(type  ,strMessage,  ViragsSocial.TabFriends)

    end

    self:FriendListUpdate()
end

function ViragsSocial:OnFriendshipInvitesRecieved(tInviteList)

    for t,tFriend in pairs(tInviteList) do
        local msg
        if tFriend.strCharacterName then
            msg = tFriend.strCharacterName .. " wants to be your Friend"
        elseif tFriend.strDisplayName then
            msg = tFriend.strDisplayName .. " wants to be your Account Friend"
        end

        if  msg then
            self:PublishNotifications(NotificationJoin  ,msg,  ViragsSocial.TabFriends)
        end
    end
    self:FriendListUpdate()
end

function ViragsSocial:OnFriendshipRemove(nFriendId)

    local tFriends = self:GetRosterForGrid(ViragsSocial.TabFriends)
    if tFriends then
    for k,tFriend in pairs (tFriends) do
        if tFriend.nId == nFriendId then
            local bFriend = tFriend.bFriend == true or tFriend.nPresenceState ~= nil
            if tFriend and bFriend and tFriend.strCharacterName and tFriend.strCharacterName ~= "" then
                self:PublishNotifications(NotificationLeave  , "You lost a friend " .. tFriend.strCharacterName,  ViragsSocial.TabFriends)
            end

            break
        end
    end
    else
        self:PublishNotifications(NotificationLeave  , "You lost a friend",  ViragsSocial.TabFriends)
    end

    self:FriendListUpdate()
end



function ViragsSocial:OnFriendshipResult(strName, eResult)
    if eResult == FriendshipLib.FriendshipResult_LocationBusy then
        -- dont know why i get this. got some bg report that swiching tabs can show this
        -- dont have much time to figure out why, so just use this return
        return
    end

    local strMessage = ktFriendshipResult[eResult] or String_GetWeaselString(Apollo.GetString("Friends_UnknownResult"), eResult)

    if strName and strName ~= "" then
        strMessage = strMessage .. " (" .. strName .. ")"
    end

    self:PRINT(strMessage)
end



function ViragsSocial:OnGuildResult(guildSender, strName, nRank, eResult )
    local strAlertMessage = self:GenerateAlert( guildSender, strName, nRank, eResult )
    local guildId = self:GuildTabID(guildSender)

    if guildId then
        if eResult == GuildLib.GuildResult_MemberOnline then
            self:PublishNotifications(NotificationOnline  ,strAlertMessage,guildId, guildSender)
            return
        elseif eResult == GuildLib.GuildResult_MemberOffline then
            self:PublishNotifications(NotificationOffline  ,strAlertMessage,guildId, guildSender)
            return
        elseif eResult == GuildLib.GuildResult_MemberQuit or eResult == GuildLib.GuildResult_KickedMember then
            self:PublishNotifications(NotificationLeave  ,strAlertMessage,guildId, guildSender)
            return
        elseif eResult == GuildLib.GuildResult_InviteAccepted then
            self:PublishNotifications(NotificationJoin  ,strAlertMessage,guildId, guildSender)
            return
        end
    end



    if guildSender and guildSender:GetChannel() then
        guildSender:GetChannel():Post(strAlertMessage, "")
    else
        self:PRINT(strAlertMessage)
    end

end

-----------------------------------------------------------------------------------------------
-- Neighbor Invite Window
-----------------------------------------------------------------------------------------------

function ViragsSocial:OnNeighborInviteAccepted(strName)
    local strMessage = Apollo.GetString("Neighbors_InviteAcceptedSelf")

    if string.len(strName) > 1 then
        strMessage = String_GetWeaselString(Apollo.GetString("Neighbors_InviteAccepted"), strName)
    end

    self:PRINT(strMessage)
end

function ViragsSocial:OnNeighborInviteDeclined(strName)

    local strMessage = "Neighbor invitation declined" --Apollo.GetString("Neighbors_InvitationExpired")

    if string.len(strName) > 1 then
        strMessage = String_GetWeaselString(Apollo.GetString("Neighbors_RequestDeclined"), strName)
    end

    self:PRINT(strMessage)
end

function ViragsSocial:OnHousingResultInterceptResponse(eResult, wndIntercept, strAlertMsg)

    if not strAlertMsg then
        return
    end


    self:PRINT(String_GetWeaselString(Apollo.GetString("Neighbors_FriendsListError"), strAlertMsg))
end

-----------------------------------------------------------------------------------------------
-- Guild Invite Window
-----------------------------------------------------------------------------------------------
function ViragsSocial:OnGuildInvite(strGuildName, strInvitorName, guildType, tFlags)
    if self.wndGuildInvite ~= nil and self.wndGuildInvite:IsValid() then
        self.wndGuildInvite:Destroy()
    end

    local strDefaultText
    if guildType == GuildLib.GuildType_Guild then
        strDefaultText = Apollo.GetString("Guild_IncomingInvite")
    elseif guildType == GuildLib.GuildType_Circle then
        strDefaultText = Apollo.GetString("Guild_IncomingCircleInvite")
    end

    if strDefaultText == nil then return end

    if self:FilterRequest(strInvitorName) then
        self.wndGuildInvite = Apollo.LoadForm(self.xmlDoc, "GuildInviteConfirmation", nil, self)
        self.wndGuildInvite:FindChild("GuildInviteLabel"):SetText(String_GetWeaselString(strDefaultText, strGuildName, strInvitorName))
        self.wndGuildInvite:ToFront()
    else
        GuildLib.Decline()
    end
end

function ViragsSocial:OnGuildInviteAccept(wndHandler, wndControl)
    GuildLib.Accept()
    if self.wndGuildInvite then
        self.wndGuildInvite:Destroy()
        self.wndGuildInvite = nil
    end
end

function ViragsSocial:OnGuildInviteDecline() -- This can come from a variety of sources
    GuildLib.Decline()
    if self.wndGuildInvite then
        self.wndGuildInvite:Destroy()
        self.wndGuildInvite = nil
    end
end

function ViragsSocial:OnFilterBtn(wndHandler, wndControl)
    g_InterfaceOptions.Carbine.bFilterGuildInvite = wndHandler:IsChecked()
end

function ViragsSocial:FilterRequest(strInvitor)
    if not g_InterfaceOptions.Carbine.bFilterGuildInvite then
        return true
    end

    local bPassedFilter = false

    local tRelationships = GameLib.SearchRelationshipStatusByCharacterName(strInvitor)
    if tRelationships and (tRelationships.tFriend or tRelationships.tAccountFriend or tRelationships.tGuilds or tRelationships.nGuildIndex) then
        bPassedFilter = true
    end

    return bPassedFilter
end

function ViragsSocial:OnGuildMessageOfTheDay(guildSender)
    --[[
    -- ui\GuildAlerts\GuildAlerts.lua:74: attempt to index a nil value
    stack trace:
        ui\GuildAlerts\GuildAlerts.lua:74: in function <ui\GuildAlerts\GuildAlerts.lua:73>
     ]]

    local msg = guildSender:GetMessageOfTheDay()
    if msg and msg ~= "" then
        if guildSender and guildSender:GetChannel() then
            guildSender:GetChannel():Post(msg, Apollo.GetString("GuildInfo_MessageOfTheDay"))
        else
            self:PRINT(guildSender:GetName() .. " Message Of The Day: " .. msg)
        end
    end
end



function ViragsSocial:DefaultNotificationsForTab(nTabId)
    local list = {}

    if nTabId == ViragsSocial.TabGuild then
        list[NotificationAll] = { text = true, sound = true }
        list[NotificationOnline] = { text = true, sound = true }
        list[NotificationOffline] = { text = true, sound = true }
        list[NotificationLeave] = { text = true, sound = true }
        list[NotificationJoin] = { text = true, sound = true }
    elseif nTabId == ViragsSocial.TabFriends then
        list[NotificationAll] = { text = true, sound = true }
        list[NotificationOnline] = { text = true, sound = true }
        list[NotificationOffline] = { text = true, sound = true }
        list[NotificationLeave] = { text = true, sound = true }
        list[NotificationJoin] = { text = true, sound = true }
    elseif nTabId == ViragsSocial.TabCircle1 or
            nTabId == ViragsSocial.TabCircle2 or
            nTabId == ViragsSocial.TabCircle3 or
            nTabId == ViragsSocial.TabCircle4 or
            nTabId == ViragsSocial.TabCircle5 or
            nTabId == ViragsSocial.Warplot or
            nTabId == ViragsSocial.Arena2v2 or
            nTabId == ViragsSocial.Arena3v3 or
            nTabId == ViragsSocial.Arena5v5 then
        list[NotificationAll] = { text = true, sound = false }
        list[NotificationOnline] = { text = true, sound = false }
        list[NotificationOffline] = { text = true, sound = false }
        list[NotificationLeave] = { text = false, sound = false }
        list[NotificationJoin] = { text = false, sound = false }
    end
    return list
end

function ViragsSocial:GetCustomisableNotificationsForTab(nTabId, nTabType, TabName)
    if nTabId == nil or TabName == nil then return {} end

    local list = {}
    if nTabId == ViragsSocial.TabFriends then
        list[NotificationAll] = TabName
        list[NotificationOnline] = "Friend Online"
        list[NotificationOffline] = "Friend Offline"
        list[NotificationLeave] = "Friend Leave or Remove"
        list[NotificationJoin] = "Friend Invite Received"
    elseif nTabType then --any guild because only guild have types
        list[NotificationAll] = TabName
        list[NotificationOnline] = "Member Online"
        list[NotificationOffline] = "Member Offline"
        list[NotificationLeave] = "Member Leave or Kick"
        list[NotificationJoin] = "Member Join"
    end

    return list
end

function ViragsSocial:ToggleNotificationStateForSetting(tabID, settingID, notificationType) -- type is sound or text
    local state = self:GetNotificationState(tabID, settingID, notificationType)
    self:SetNotificationState(tabID, settingID, notificationType, not state)
    return not state
end


function ViragsSocial:GetNotificationState(tabID, settingID, type)
    if self.tSettings and settingID and type  then
        if self.tSettings.tNotifications == nil then
            self.tSettings.tNotifications = {}
        end

        local sN = self.tSettings.tNotifications

        if  sN[tabID] == nil then
            sN[tabID] = self:DefaultNotificationsForTab(tabID)
        end

        if  sN[tabID][settingID] == nil then
            return false -- something is really wrong here
        end

        return  sN[tabID][settingID][type]
    end

    return nil
end

function ViragsSocial:SetNotificationState(tabID, settingID, notificationType, newState)
    if tabID and settingID and notificationType and self.tSettings then
        if self.tSettings.tNotifications == nil then
            self.tSettings.tNotifications = {}
        end

        if self.tSettings.tNotifications[tabID] == nil then
            self.tSettings.tNotifications[tabID] = self:DefaultNotificationsForTab(tabID)
        end
        if settingID == NotificationAll then
            for k,v in pairs (self.tSettings.tNotifications[tabID]) do
                v[notificationType] = newState
            end

        else
            self.tSettings.tNotifications[tabID][settingID][notificationType] = newState
        end

        return true
    end

    return false
end
function ViragsSocial:ToggleAllTextNotifications()
    local newState = not self.tSettings.bTextNotifications
    self.tSettings.bTextNotifications = newState

    for k,tab in pairs (self.tSettings.tNotifications) do
        for _,notification in pairs(tab) do
            notification[kNotificationText]  = newState
        end
    end
end

function ViragsSocial:ToggleAllSoundNotifications()
    local newState = not self.tSettings.bSoundNotifications
    self.tSettings.bSoundNotifications = newState

    for k,tab in pairs (self.tSettings.tNotifications) do
        for _,notification in pairs(tab) do
            notification[kNotificationSound]  = newState
        end
    end
end
function ViragsSocial:GetNotificationTextState(tabID, settingID)
    return self:GetNotificationState(tabID, settingID, kNotificationText)
end

function ViragsSocial:GetNotificationSound(tabID, settingID)
    return nil --todo
end

function ViragsSocial:GetNotificationSoundState(tabID, settingID)
    return self:GetNotificationState(tabID, settingID, kNotificationSound)
end
function ViragsSocial:ToggleTextNotification(nTabId, settingID)
    return self:ToggleNotificationStateForSetting(nTabId, settingID, kNotificationText)
end

function ViragsSocial:ToggleSoundNotification(nTabId, settingID)
    return self:ToggleNotificationStateForSetting(nTabId, settingID, kNotificationSound)
end


function ViragsSocial:OnGuildLoaded(guildLoaded)
    local tGuildFlags = guildLoaded:GetFlags()
    local channelGuild = guildLoaded:GetChannel()
    channelGuild:Post(String_GetWeaselString(Apollo.GetString("Guild_GuildWelcome"), guildLoaded:GetName()))
    channelGuild:Post(guildLoaded:GetMessageOfTheDay())

    if tGuildFlags.bTax then
        channelGuild:Post(Apollo.GetString("Guild_TaxActive"))
    end

    if self.wndMain and self.wndMain:IsShown() then
        self:OnToggleGuildWindow()
    end
end

function ViragsSocial:OnGuildFlags(guildUpdated)
    guildUpdated:GetChannel():Post(Apollo.GetString("Guild_FlagsChanged"))
end

function ViragsSocial:OnGuildName(guildUpdated)
    guildUpdated:GetChannel():Post(String_GetWeaselString(Apollo.GetString("Guild_NameChanged"), guildUpdated:GetName()))
end


function ViragsSocial:PublishNotifications(nEventInSettings, strAlertMessage, tabID, guildSender) --last param is optional
    local bShowText = self:GetNotificationTextState(tabID, nEventInSettings )
    local bPlaySound = self:GetNotificationSoundState(tabID, nEventInSettings )


    if bPlaySound then
        local sound = self:GetNotificationSound(tabID, nEventInSettings )
        if sound == nil then sound = Sound.PlayUISocialFriendAlert end

        Sound.Play(sound)
    end

    if bShowText then
        if guildSender and guildSender:GetChannel() then
            guildSender:GetChannel():Post(strAlertMessage, "")
        else
        if guildSender then
            self:PRINT(strAlertMessage,nil, self:strGuildNameAndType(guildSender:GetName(), guildSender:GetType()))
        else
            self:PRINT(strAlertMessage,nil, Apollo.GetString("Tooltips_Friend"))
        end
        end
    end
end



function ViragsSocial:GenerateAlert(guildSender, strName, nRank, eResult )
    local strResult = String_GetWeaselString(Apollo.GetString("Guild_UnknownResult"), eResult) -- just in case

    local eGuildType = nil

    if guildSender then
        eGuildType = guildSender:GetType()
    end

    local strGuildType = nil
    if eGuildType == GuildLib.GuildType_Circle then
        strGuildType = Apollo.GetString("Guild_GuildTypeCircle")
    elseif eGuildType == GuildLib.GuildType_ArenaTeam_2v2 or eGuildType == GuildLib.GuildType_ArenaTeam_3v3 or eGuildType == GuildLib.GuildType_ArenaTeam_5v5 then
        strGuildType = Apollo.GetString("Guild_GuildTypeArena")
    elseif eGuildType == GuildLib.GuildType_WarParty then
        strGuildType = Apollo.GetString("Guild_GuildTypeWarparty")
    else --if eGuildType == GuildLib.GuildType_Guild then
        strGuildType = Apollo.GetString("Guild_GuildTypeGuild")
    end



    local strResidence = Apollo.GetString("Guild_ResidenceNameDefault")
    if eGuildType == GuildLib.GuildType_WarParty then
        strResidence = Apollo.GetString("CRB_Warplot")
    end

    local strRank = ""

    local strGuildMaster = nil
    if guildSender then
        strGuildMaster = guildSender:GetRanks()[1].strName

        if nRank and nRank ~= 0 then
            strRank = guildSender:GetRanks()[nRank].strName
            if not strRank or not string.len(strRank) then
                strRank = '#' .. tostring(nRank)
            end
        end
    end

    strName = tostring(strName) -- just in case.

    local tName = {["strLiteral"] = strName}
    local tRank = {["strLiteral"] = strRank}

    --[[
        -- TODO remove these strings

        ArenaRegister_ResultBusy
        GuildRegistration_GuildBusy
        GuildRegistration_YouJoinedGuild
        GuildRegistration_NeedMoreRenown
        GuildResult_VendorOutOfRange
        GuildRegistration_GuildCreated
        GuildDesigner_InvalidStandard
        GuildDesigner_SystemError
        ArenaRegister_ResultNameUnavailable
        GuildDesigner_NameUnavailable
        GuildResult_NameUnavailable
        GuildDesigner_InvalidRankName
        GuildDesigner_InvalidRank
        GuildRegistration_InvalidName
        GuildDesigner_InvalidGuildName
        ArenaRegister_ResultInvaidName
        GuildRegistration_CannotCreate
        ArenaRegister_ResultMaxCount
        GuildResult_MaxGuilds
        GuildResult_MaxCircles
    ]]--


    if eResult == GuildLib.GuildResult_Success then									strResult = Apollo.GetString("GuildResult_Success")

    elseif eResult == GuildLib.GuildResult_AtMaxGuildCount then 					strResult = String_GetWeaselString(Apollo.GetString("GuldResult_AtMaxCount"), strGuildType)
    elseif eResult == GuildLib.GuildResult_MaxWarPartyCount then 					strResult = String_GetWeaselString(Apollo.GetString("GuldResult_AtMaxCount"), strGuildType)
    elseif eResult == GuildLib.GuildResult_AtMaxCircleCount then 					strResult = String_GetWeaselString(Apollo.GetString("GuldResult_AtMaxCount"), strGuildType)
    elseif eResult == GuildLib.GuildResult_MaxArenaTeamCount then 					strResult = Apollo.GetString("GuildResult_MaxArenaTeamForSize")

    elseif eResult == GuildLib.GuildResult_CannotModifyResidenceWithActiveGame then strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CannotModifyWithActiveGame"), strResidence)
    elseif eResult == GuildLib.GuildResult_GenericActiveGameFailure then 			strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CannotModifyWithActiveGame"), strGuildType)
    elseif eResult == GuildLib.GuildResult_CannotChangeRanksWithActiveGame then 	strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CannotModifyWithActiveGame"), strGuildType)
    elseif eResult == GuildLib.GuildResult_CannotChangePermissionsWithActiveGame then strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CannotModifyWithActiveGame"), strGuildType)
    elseif eResult == GuildLib.GuildResult_CannotEditBankWithActiveGame then 		strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CannotModifyWithActiveGame"), strGuildType)

    elseif eResult == GuildLib.GuildResult_InvalidGuildName then					strResult = String_GetWeaselString(Apollo.GetString("GuildResult_InvalidGuildName"), tName, strGuildType)
    elseif eResult == GuildLib.GuildResult_NotInThatGuild then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_NotInThatGuild"), strGuildType)
    elseif eResult == GuildLib.GuildResult_RankLacksSufficientPermissions then 		strResult = Apollo.GetString("GuildResult_InsufficientPermissions")
    elseif eResult == GuildLib.GuildResult_UnknownCharacter then 					strResult = String_GetWeaselString(Apollo.GetString("GuildResult_UnknownCharacter"), tName)
    elseif eResult == GuildLib.GuildResult_CharacterCannotJoinMoreGuilds then 		strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CharacterMaxGuilds"), tName, strGuildType)
    elseif eResult == GuildLib.GuildResult_CharacterAlreadyHasAGuildInvite then		strResult = String_GetWeaselString(Apollo.GetString("GuildResult_AlreadyHasInvite"), tName)
    elseif eResult == GuildLib.GuildResult_CharacterInvited then 					strResult = String_GetWeaselString(Apollo.GetString("GuildResult_AlreadyInvited"), tName, strGuildType)
    elseif eResult == GuildLib.GuildResult_GuildmasterCannotLeaveGuild then 		strResult = String_GetWeaselString(Apollo.GetString("GuildResult_GuildmasterCannotLeave"), strGuildMaster, strGuildType)
    elseif eResult == GuildLib.GuildResult_CharacterNotInYourGuild then				strResult = String_GetWeaselString(Apollo.GetString("GuildResult_NotInYourGuild"), tName, strGuildType)
    elseif eResult == GuildLib.GuildResult_CannotKickHigherOrEqualRankedMember then	strResult = String_GetWeaselString(Apollo.GetString("GuildResult_UnableToKick"), tName)
    elseif eResult == GuildLib.GuildResult_KickedMember then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_HasBeenKicked"), tName)
    elseif eResult == GuildLib.GuildResult_NoPendingInvites then 					strResult = String_GetWeaselString(Apollo.GetString("GuildResult_NoPendingInvites"), strGuildType)
    elseif eResult == GuildLib.GuildResult_PendingInviteExpired then 				strResult = String_GetWeaselString(Apollo.GetString("GuildResult_InviteExpired"), tName)
    elseif eResult == GuildLib.GuildResult_CannotPromoteMemberAboveYourRank then 	strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CannotPromote"),	tName)
    elseif eResult == GuildLib.GuildResult_PromotedToGuildMaster then 				strResult = String_GetWeaselString(Apollo.GetString("GuildResult_PromotedToLeader"), tName, strGuildMaster)
    elseif eResult == GuildLib.GuildResult_PromotedMember then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_PlayerPromoted"), tName)
    elseif eResult == GuildLib.GuildResult_CanOnlyDemoteLowerRankedMembers then 	strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CannotDemote"), tName)
    elseif eResult == GuildLib.GuildResult_MemberIsAlreadyLowestRank then 			strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CannotDemoteLowestRank"), tName)
    elseif eResult == GuildLib.GuildResult_DemotedMember then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_MemberDemoted"), tName)
    elseif eResult == GuildLib.GuildResult_InvalidRank then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_InvalidRank"), tRank)
    elseif eResult == GuildLib.GuildResult_InvalidRankName then						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_InvalidRankName"), strGuildType, tName)
    elseif eResult == GuildLib.GuildResult_CanOnlyDeleteEmptyRanks then				strResult = Apollo.GetString("GuildResult_CanOnlyDeleteEmptyRank")
    elseif eResult == GuildLib.GuildResult_VoteAlreadyInProgress then 				strResult = Apollo.GetString("GuildResult_VoteInProgress")
    elseif eResult == GuildLib.GuildResult_AlreadyCastAVote then 					strResult = Apollo.GetString("GuildResult_AlreadyVoted")
    elseif eResult == GuildLib.GuildResult_InvalidElection  then 					strResult = String_GetWeaselString(Apollo.GetString("GuildResult_VoteInvalidated"), tName)
    elseif eResult == GuildLib.GuildResult_VoteFailedToPass then 					strResult = String_GetWeaselString(Apollo.GetString("GuildResult_VoteFailed"), tName)
    elseif eResult == GuildLib.GuildResult_NoVoteInProgress then 					strResult = Apollo.GetString("GuildResult_NoVoteInProgress")
    elseif eResult == GuildLib.GuildResult_MemberAlreadyGuildMaster then 			strResult = String_GetWeaselString(Apollo.GetString("GuildResult_AlreadyLeader"), tName, strGuildType)
    elseif eResult == GuildLib.GuildResult_VoteStarted then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_VoteStarted"), strGuildType, tName)
    elseif eResult == GuildLib.GuildResult_InviteAccepted then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_PlayerJoined"), tName, strGuildType)
    elseif eResult == GuildLib.GuildResult_InviteDeclined then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_InviteDeclined"), tName, strGuildType)

    elseif eResult == GuildLib.GuildResult_GuildNameUnavailable then  				strResult = String_GetWeaselString(Apollo.GetString("GuildRegistration_NameUnavailable"), strGuildType)

    elseif eResult == GuildLib.GuildResult_GuildDisbanded then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_Disbanded"), tName)
    elseif eResult == GuildLib.GuildResult_RankModified then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_RankModified"), tRank, tName)
    elseif eResult == GuildLib.GuildResult_RankCreated then							strResult = String_GetWeaselString(Apollo.GetString("GuildResult_RankCreated"), tName)
    elseif eResult == GuildLib.GuildResult_RankDeleted then							strResult = String_GetWeaselString(Apollo.GetString("GuildResult_RankDeleted"), tRank, tName)
    elseif eResult == GuildLib.GuildResult_UnableToProcess then						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_UnableToProcess"), strGuildType)
    elseif eResult == GuildLib.GuildResult_MemberQuit then 							strResult = String_GetWeaselString(Apollo.GetString("GuildResult_MemberQuit"), tName, strGuildType)
    elseif eResult == GuildLib.GuildResult_Voted then 								strResult = String_GetWeaselString(Apollo.GetString("GuildResult_Voted"), tName)
    elseif eResult == GuildLib.GuildResult_VotePassed then 							strResult = String_GetWeaselString(Apollo.GetString("GuildResult_VotePassed"), tName, strGuildType)
    elseif eResult == GuildLib.GuildResult_GuildLoading then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_Loading"), strGuildType)
    elseif eResult == GuildLib.GuildResult_KickedYou then 							strResult = String_GetWeaselString(Apollo.GetString("GuildResult_YouHaveBeenKicked"),	strGuildType)
    elseif eResult == GuildLib.GuildResult_CanOnlyModifyRanksBelowYours then 		strResult = Apollo.GetString("GuildResult_CanOnlyModifyLowerRanks")
    elseif eResult == GuildLib.GuildResult_YouQuit then 							strResult = String_GetWeaselString(Apollo.GetString("GuildResult_YouLeft"), tName)
    elseif eResult == GuildLib.GuildResult_YouJoined then 							strResult = String_GetWeaselString(Apollo.GetString("GuildResult_YouJoined"),	tName)
    elseif eResult == GuildLib.GuildResult_RankRenamed then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_RankRenamed"), tRank, tName)
    elseif eResult == GuildLib.GuildResult_MemberOnline then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_MemberOnline"), tName)
    elseif eResult == GuildLib.GuildResult_MemberOffline then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_MemberOffline"),	tName)
    elseif eResult == GuildLib.GuildResult_CannotInviteGuildFull then 				strResult = String_GetWeaselString(Apollo.GetString("GuildResult_GuildFull"),	tName, strGuildType)
    elseif eResult == GuildLib.GuildResult_VoteTooRecentToHaveAnother then 			strResult = String_GetWeaselString(Apollo.GetString("GuildResult_TooSoonToVote"),	strGuildType)
    elseif eResult == GuildLib.GuildResult_NotInAGuild then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_NotInAGuild"), strGuildType)
    elseif eResult == GuildLib.GuildResult_InvalidFlags then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_InvalidFlags"), strGuildType)
    elseif eResult == GuildLib.GuildResult_StandardChanged then 					strResult = String_GetWeaselString(Apollo.GetString("GuildResult_BannerChanged"),	strGuildType)
    elseif eResult == GuildLib.GuildResult_NotAGuild then 							strResult = Apollo.GetString("GuildResult_NotAGuild")
    elseif eResult == GuildLib.GuildResult_InvalidStandard then 					strResult = String_GetWeaselString(Apollo.GetString("GuildResult_InvalidBanner"),	strGuildType)
    elseif eResult == GuildLib.GuildResult_YouCreated then 							strResult = String_GetWeaselString(Apollo.GetString("GuildResult_GuildCreated"), tName)
    elseif eResult == GuildLib.GuildResult_VendorOutOfRange then 					strResult = Apollo.GetString("GuildDesigner_OutOfRange")
    elseif eResult == GuildLib.GuildResult_NotABankTab then 						strResult = Apollo.GetString("GuildResult_NotABankTab")
    elseif eResult == GuildLib.GuildResult_BankerOutOfRange then 					strResult = Apollo.GetString("GuildResult_BankerOutOfRange")
    elseif eResult == GuildLib.GuildResult_NoBank then 								strResult = Apollo.GetString("GuildResult_NoBank")
    elseif eResult == GuildLib.GuildResult_BankTabAlreadyLoaded then 				strResult = Apollo.GetString("GuildResult_BankTabAlreadyLoaded")
    elseif eResult == GuildLib.GuildResult_NoBankItemSelected  then 				strResult = Apollo.GetString("GuildResult_NoBankItemSelected")
    elseif eResult == GuildLib.GuildResult_BankItemMoved then 						strResult = Apollo.GetString("GuildResult_BankItemMoved")
    elseif eResult == GuildLib.GuildResult_RankLacksRankRenamePermission then 		strResult = Apollo.GetString("GuildResult_NoRenamePermission")
    elseif eResult == GuildLib.GuildResult_InvalidBankTabName then 					strResult = String_GetWeaselString(Apollo.GetString("GuildResult_InvalidBankTabName"), tName)
    elseif eResult == GuildLib.GuildResult_CannotWithdrawBankItem then 				strResult = Apollo.GetString("GuildResult_CanNotWithdrawBankItem")
    elseif eResult == GuildLib.GuildResult_BankTabNotLoaded then 					strResult = String_GetWeaselString(Apollo.GetString("GuildResult_BankTabNotLoaded"), tRank)
    elseif eResult == GuildLib.GuildResult_CannotDepositBankItem then 				strResult = Apollo.GetString("GuildResult_CannotDepositItem")
    elseif eResult == GuildLib.GuildResult_AlreadyAMember then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_AlreadyAMember"), tName)
    elseif eResult == GuildLib.GuildResult_BankTabWithdrawsExceeded then 			strResult = Apollo.GetString("GuildResult_BankWithdrawsExceeded")
    elseif eResult == GuildLib.GuildResult_BankTabNotVisible then 					strResult = Apollo.GetString("GuildResult_BankTabNotVisible")
    elseif eResult == GuildLib.GuildResult_BankTabDoesNotAcceptDeposits then 		strResult = Apollo.GetString("GuildResult_BankTabDoesNotAcceptDeposits")
    elseif eResult == GuildLib.GuildResult_BankTabRequiresAuthenticator then 		strResult = Apollo.GetString("GuildResult_BankTabRequiresAuthenticator")
    elseif eResult == GuildLib.GuildResult_BankTabCannotWithdraw then 				strResult = Apollo.GetString("GuildResult_BankTabCannotWithdraw")
    elseif eResult == GuildLib.GuildResult_InsufficientInfluence then				strResult = Apollo.GetString("GuildDesigner_NotEnoughInfluence")
    elseif eResult == GuildLib.GuildResult_RequiresPrereq then 						strResult = Apollo.GetString("GuildResult_RequiresPrereq")
    elseif eResult == GuildLib.GuildResult_BankTabBought then 						strResult = String_GetWeaselString(Apollo.GetString("GuildResult_BankTabBought"), tName)
    elseif eResult == GuildLib.GuildResult_ExceededMoneyWithdrawLimitToday then 	strResult = Apollo.GetString("GuildResult_WithdrawLimitExceeded")
    elseif eResult == GuildLib.GuildResult_InsufficientMoneyInGuild then 			strResult = Apollo.GetString("GuildResult_NotEnoughMoneyInGuild")
    elseif eResult == GuildLib.GuildResult_InsufficientMoneyOnCharacter then 		strResult = Apollo.GetString("GuildResult_NotEnoughMoneyOnCharacter")
    elseif eResult == GuildLib.GuildResult_NotEnoughRenown then                     strResult = Apollo.GetString("GuildResult_NotEnoughRenown")
    elseif eResult == GuildLib.GuildResult_CannotDisbandTeamWithActiveGame then 	strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CannotDisbandWithActiveGame"), strGuildType)
    elseif eResult == GuildLib.GuildResult_CannotLeaveTeamWithActiveGame then 		strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CannotLeaveTeamWithActiveGame"), strGuildType)
    elseif eResult == GuildLib.GuildResult_CannotRemoveFromTeamWithActiveGame then 	strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CannotKickWithActiveGame"), strGuildType)
    elseif eResult == GuildLib.GuildResult_InsufficientWarCoins then 				strResult = Apollo.GetString("GuildResult_InsufficientWarCoins")
    elseif eResult == GuildLib.GuildResult_PerkDoesNotExist then 					strResult = Apollo.GetString("GuildResult_PerkDoesNotExist")
    elseif eResult == GuildLib.GuildResult_PerkIsAlreadyUnlocked then 				strResult = Apollo.GetString("GuildResult_PerkAlreadyUnlocked")
    elseif eResult == GuildLib.GuildResult_PerkIsAlreadyActive then 				strResult = Apollo.GetString("GuildResult_PerkIsAlreadyActive")
    elseif eResult == GuildLib.GuildResult_RequiresPerkPurchase then 				strResult = Apollo.GetString("GuildResult_PerkPrereqNotMet")
    elseif eResult == GuildLib.GuildResult_PerkNotActivateable then 				strResult = Apollo.GetString("GuildResult_PerkCanNotActivate")

        --The only way we can get this result and have eGuildType to be nil is if we're invited to a warparty
    elseif eResult == GuildLib.GuildResult_NotHighEnoughLevel then					strResult = (eGuildType or eGuildType ~= GuildLib.GuildType_Warparty) and String_GetWeaselString(Apollo.GetString("GuildRegistration_NotHighEnoughLevel"), strGuildType, GuildLib.GetMinimumLevel(eGuildType))
            or String_GetWeaselString(Apollo.GetString("Warparty_NotHighEnoughLevel"), Apollo.GetString("Guild_GuildTypeWarparty"), GuildLib.GetMinimumLevel(GuildLib.GuildType_WarParty))

    elseif eResult == GuildLib.GuildResult_InvalidMessageOfTheDay then 				strResult = Apollo.GetString("GuildResult_InvalidMotD")
    elseif eResult == GuildLib.GuildResult_InvalidMemberNote then 					strResult = Apollo.GetString("GuildResult_InvalidNote")
    elseif eResult == GuildLib.GuildResult_InsufficentMembers then 					strResult = Apollo.GetString("GuildResult_InsufficientMembers")
    elseif eResult == GuildLib.GuildResult_NotAWarParty then 						strResult = Apollo.GetString("GuildResult_NotAWarParty")
    elseif eResult == GuildLib.GuildResult_RequiresAchievement then 				strResult = Apollo.GetString("GuildResult_PerkRequiresAchievement")
    elseif eResult == GuildLib.GuildResult_NotAValidWarPartyItem then				strResult = Apollo.GetString("GuildResult_NotAValidWarPartyItem")
    elseif eResult == GuildLib.GuildResult_InvalidGuildInfo then 					strResult = Apollo.GetString("GuildResult_InvalidGuildInfo")
    elseif eResult == GuildLib.GuildResult_NotEnoughCredits then					strResult = Apollo.GetString("GuildRegistration_NeedMoreCredit")
    elseif eResult == GuildLib.GuildResult_CannotDeleteDefaultRanks then 			strResult = String_GetWeaselString(Apollo.GetString("GuildResult_CannotDeleteDefaultRanks"), tRank)
    elseif eResult == GuildLib.GuildResult_DuplicateRankName then 					strResult = String_GetWeaselString(Apollo.GetString("GuildResult_DuplicateRankName"), tName)
    elseif eResult == GuildLib.GuildResult_InviteSent then 							strResult = String_GetWeaselString(Apollo.GetString("Guild_InviteSent"), tName, strGuildType)
    elseif eResult == GuildLib.GuildResult_BankTabInvalidPermissions then			strResult = String_GetWeaselString(Apollo.GetString("GuildResult_BankTabInvalidPermissions"), tName, strGuildType)
    elseif eResult == GuildLib.GuildResult_Busy then								strResult = String_GetWeaselString(Apollo.GetString("GuildResult_Busy"), strGuildType)
    elseif eResult == GuildLib.GuildResult_CannotCreateWhileInQueue then			strResult = Apollo.GetString("GuildResult_CannotCreateWhileInQueue")
    end

    return strResult
end