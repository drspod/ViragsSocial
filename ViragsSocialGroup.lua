--
-- Created by IntelliJ IDEA.
-- User: Peter
-- Date: 17.08.14
-- Time: 13:49
-- To change this template use File | Settings | File Templates.
--
local ViragsSocial = Apollo.GetAddon("ViragsSocial")

local knReadyCheckTimeout = 60 -- in seconds

function ViragsSocial:InitGroupTab()
    --GROUP LIST UPDATES
    Apollo.RegisterEventHandler("Group_Join", 					"OnGroup_Join", self)
    Apollo.RegisterEventHandler("Group_Left", 					"OnGroup_Left", self)

    Apollo.RegisterEventHandler("Group_UpdatePosition", "OnGroupUpdatePosition", self)
    Apollo.RegisterEventHandler("Group_FlagsChanged",						"OnGroupUpdated", self)
    Apollo.RegisterEventHandler("Group_MemberFlagsChanged",					"OnGroup_MemberFlagsChanged", self)
    Apollo.RegisterEventHandler("Group_ReadyCheck",							"OnGroup_ReadyCheck", self)

    Apollo.RegisterTimerHandler("ReadyCheckTimeout", "OnReadyCheckTimeout", self)
    Apollo.CreateTimer("ReadyCheckTimeout", knReadyCheckTimeout, false)
    Apollo.StopTimer("ReadyCheckTimeout")

    Apollo.RegisterTimerHandler("GroupRecreationTimer", "OnGroupRecreationTimer", self)
    Apollo.CreateTimer("GroupRecreationTimer", 10.000, false)
    Apollo.StopTimer("GroupRecreationTimer")
end

function ViragsSocial:OnGroup_MemberFlagsChanged(nMemberIdx, bFromPromotion, tChangedFlags)
    if not self:IsGroupTabSelected()  or not self:IsVisible() then return end
    self:DEBUG("OnGroup_MemberFlagsChanged")
    self:DEBUG("nMemberIdx", nMemberIdx)
    self:DEBUG("bFromPromotion", bFromPromotion)
    self:DEBUG("tChangedFlags", tChangedFlags)
    local roster = self:GetRosterForGrid(ViragsSocial.Group)
    local player

    for k,v in pairs(roster) do
        if nMemberIdx == v.nMemberIdx then
            player = v
            break
        end
    end

    if player then
        for k,v in pairs(tChangedFlags) do
            player[k] = v
        end

    end

    self:UpdateGrid(false,false)


end
function ViragsSocial:OnGroup_Join()
    if self:IsGroupTabSelected() then
        self:ReloadGroupList()
    end

end
function ViragsSocial:OnGroup_Left()
    if self:IsGroupTabSelected() then
        self:ReloadGroupList()
    end
end

function ViragsSocial:OnGroup_ReadyCheck()
    self.ReadyCheckStarted = true
    Apollo.StartTimer("ReadyCheckTimeout")
    self:ReloadGroupList()
end

function ViragsSocial:OnReadyCheckTimeout()
    self.ReadyCheckStarted = false

end

function ViragsSocial:OnGroupUpdatePosition(arMembers)
    if self.kMyID == nil then return end -- need to init first then can do group updates
    if not self:IsGroupTabSelected() then return end
    --self:DEBUG("OnGroupUpdatePosition", arMembers)


    for key, member in pairs(arMembers) do
        local name = GroupLib.GetGroupMember(arMembers[key].nIndex).strCharacterName
        if self.ktPlayerInfoDB[name] == nil then
            self.ktPlayerInfoDB[name] = {}
        end

        local oldbCombat = self.ktPlayerInfoDB[name].bInCombat
        local oldLocation = self.ktPlayerInfoDB[name].location
        self.ktPlayerInfoDB[name].bInCombat = arMembers[key].bInCombat
        self.ktPlayerInfoDB[name].location = arMembers[key].tZoneMap.strName
    end

    if not self:IsVisible() then return end
    self:UpdateGrid(false, false)
end

function ViragsSocial:OnGroupUpdated()
    self:DEBUG("OnGroupUpdated")
    if self:IsGroupTabSelected() then
        self:SetNewRosterForGrid(self:CreateGroupList(), ViragsSocial.Group)
    end
end


function ViragsSocial:ReloadGroupList()
    self:SetNewRosterForGrid(self:CreateGroupList(), ViragsSocial.Group)
end

function ViragsSocial:CreateGroupList()
    local nGroupMemberCount = GroupLib.GetMemberCount()

    local tGroupList = {}
    for idx = 1, nGroupMemberCount do
        tGroupList[idx] = GroupLib.GetGroupMember(idx)
    end

    for key, player in pairs(tGroupList) do

        player.strName = player.strCharacterName or ""
        player.nRank = 0 --todo implement dps/healer/tank ranks
        player.eClass = player.eClassId or ViragsSocial.kUNDEFINED
        player.strNote = ""
        player.fLastOnline = player.bIsOnline and 0 or 1

        if self.ktPlayerInfoDB[player.strName] and self.ktPlayerInfoDB[player.strName].bInCombat then
            player.strNote = "In Combat"
        end
    end
    return  tGroupList
end

-- 4) Groups
function ViragsSocial:DrawGroupList(tMemberList)

    if tMemberList == nil then return end
    self:DEBUG("UpdateGrid!!!!!!: DrawGroupList")
    self:DEBUG("DrawGroupList :tMemberList", tMemberList)
    local cmpFn = self:cmpFn()
    if cmpFn then
        self:SelectionSort( tMemberList, cmpFn )
        --  table.sort(tMemberList, cmpFn)
    end

    for key, tCurr in pairs(tMemberList) do

        local fOnline = 0
        if tCurr.bIsOnline == false then
            fOnline = 1
        end

        local strNameIcon
        local strRoleIcon

        if tCurr.bIsLeader then
            strNameIcon = "CRB_Raid:sprRaid_Icon_Leader"
        end

        if tCurr.bHealer then --strRoleIcon = "CRB_Raid:sprRaid_Icon_RoleHealer"
        elseif tCurr.bTank then --strRoleIcon = "CRB_Raid:sprRaid_Icon_RoleTank"
        elseif tCurr.bDPS then --strRoleIcon = "Crafting_CoordSprites:sprCoord_SmallCircle_Green"
        end
        local strReadyCheckIcon

        if  self.ReadyCheckStarted then
            if tCurr.bHasSetReady and tCurr.bReady then
                strReadyCheckIcon = "CRB_Raid:sprRaid_Icon_ReadyCheckDull"
            elseif tCurr.bHasSetReady and not tCurr.bReady then
                strReadyCheckIcon ="CRB_Raid:sprRaid_Icon_NotReadyDull"
            end
        end


        local note = ""

        if self.ktPlayerInfoDB[tCurr.strCharacterName] then
            if self.ktPlayerInfoDB[tCurr.strCharacterName].bInCombat then
                note = "In Combat"
            end

            if self.ktPlayerInfoDB[tCurr.strCharacterName].location then
                tCurr.zone = self.ktPlayerInfoDB[tCurr.strCharacterName].location
            end
        end

        self:AddRow(tCurr, tCurr.eClassId, tCurr.ePathType, tCurr.nLevel, tCurr.strCharacterName, fOnline, "", note, strNameIcon, strReadyCheckIcon)
    end
end

function ViragsSocial:GetGroupLeader()

    local roster = self:GetRosterForGrid (ViragsSocial.Group) or {}

    for k,v in pairs(roster) do
        if v.bIsLeader then
            return  v

        end
    end

    return nil

end
local currGroupList

function ViragsSocial:GroupDisband()
    currGroupList =  self:GetRosterForGrid (ViragsSocial.Group) or {}
    GroupLib.DisbandGroup()
end

function ViragsSocial:GroupRecreate()
    if not currGroupList then
        self:PRINT("Need to disband group first")
        return
    end

    for k,v in pairs(currGroupList) do
        if v.strName ~= self.kMyID then
            GroupLib.Invite(v.strName)
        end
    end
end


function ViragsSocial:GroupLeaderName()
    local leader = self:GetGroupLeader()
    if not leader then return nil end
    return leader.strName
end