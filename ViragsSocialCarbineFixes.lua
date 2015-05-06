local ViragsSocial = Apollo.GetAddon("ViragsSocial")

function ViragsSocial:FixCarbineAddons()

    local NL = Apollo.GetAddon("NeighborList")
    if NL ~= nil then
        NL.OnChangeWorld = self.NLOnChangeWorld
        NL.OnGenericEvent_InitializeNeighbors = self.OnGenericEvent_InitializeNeighbors
    end

    local NN = Apollo.GetAddon("NeighborNotes")
    if NN ~= nil then
        NN.OnSocialWindowToggle = function()
            if NN.tCharacter.bOpenWithSocial then
                if ViragsSocial.kSelectedTab == ViragsSocial.TabNeighbors then
                    if NNMainForm ~= nil then
                        NNMainForm:Open(true);
                    end

                end
            end

        end
    end

    self:ContextMenuPlayerFix()
end
function ViragsSocial:OnGenericEvent_InitializeNeighbors(wndParent)
    --dont whant to init it ever
end

function ViragsSocial:NLOnChangeWorld()
    -----------------------------------------------------------------------------------------------
    -- ui\NeighborList\NeighborsList.lua:219: attempt to index field 'wndMain' (a nil value)
    -- stack trace:
    -- ui\NeighborList\NeighborsList.lua:219: in function <ui\NeighborList\NeighborsList.lua:217>
    -----------------------------------------------------------------------------------------------
    if self.wndMain and self.wndMain:IsValid() then
        self.wndRandomList:Show(false)
        self.wndMain:Show(true)
    end
end



function ViragsSocial:ContextMenuPlayerFix()
    if self.kbContextMenuPlayerFixed then return end

    local CMP = Apollo.GetAddon("ContextMenuPlayer")

    if CMP == nil then return end

    CMP.RedrawAllOld = CMP.RedrawAll
    CMP.RedrawAll = self.CMPRedrawAllHook

    CMP.RedrawAllFriendOld = CMP.RedrawAllFriend
    CMP.RedrawAllFriend = self.CMPRedrawAllFriendHook

    CMP.ViragSocialRedraw = self.CMPRedraw

    CMP.ProcessContextClickOld = CMP.ProcessContextClick
    CMP.ProcessContextClick = self.CMPProcessContextClickHook

    self.kbContextMenuPlayerFixed = true
end

function ViragsSocial:CMPRedraw()
    if self.wndMain == nil then return end
    local wndButtonList = self.wndMain:FindChild("ButtonList")
    if wndButtonList == nil then return end
    local addBtn = function(sIDName, sText)
        local wndNew = wndButtonList:FindChildByUserData(sIDName)
        if not wndNew then
            wndNew = Apollo.LoadForm(self.xmlDoc, "BtnRegular", wndButtonList, self)
            wndNew:SetData(sIDName)
        end
        wndNew:FindChild("BtnText"):SetText(sText)
    end
    local inv = ViragsSocial.FrInvContextMenuHelper
    if inv and inv.nRank == ViragsSocial.CharacterFriendshipType_Account_Invite then
        addBtn("BtnAcceptAccountFriendInvite", "Accept")
        addBtn("BtnRejectAccountFriendInvite", "Reject")
        return
    elseif inv and inv.nRank == ViragsSocial.CharacterFriendshipType_Invite then
        addBtn("BtnAcceptAndAddFriendInvite", "Accept and Add")
        addBtn("BtnAcceptFriendInvite", "Just Accept")
        addBtn("BtnRejectFriendInvite", "Reject")
        addBtn("BtnIgnoretFriendInvite", "Ignore")
        return
    end

    local myName = ""
    if GameLib.GetPlayerUnit() then myName = GameLib.GetPlayerUnit():GetName() end

    if not GroupLib.InGroup() and self.strTarget ~= myName then
        addBtn("BtnJoinRequest", "Join")
    end
    if HousingLib.IsHousingWorld() then
        local tCharacterData = GameLib.SearchRelationshipStatusByCharacterName(self.strTarget)
        if tCharacterData and tCharacterData.tNeighbor ~= nil then
            addBtn("BtnVisitRequest", "Visit Neighbor")
        end
    end


end

function ViragsSocial:CMPRedrawAllFriendHook()
    self:ViragSocialRedraw()
    local inv = ViragsSocial.FrInvContextMenuHelper


    if inv and (inv.nRank == ViragsSocial.CharacterFriendshipType_Invite or
            inv.nRank == ViragsSocial.CharacterFriendshipType_Account_Invite) then
        self:ResizeAndRedraw()
        self.nInviteId = ViragsSocial.FrInvContextMenuHelper.nId

        return
    end

    ViragsSocial.FrInvContextMenuHelper = nil

    self:RedrawAllFriendOld()
end

function ViragsSocial:CMPRedrawAllHook()
    self:ViragSocialRedraw()
    self:RedrawAllOld()
end

function ViragsSocial:CMPProcessContextClickHook(eButtonType)


    if eButtonType == "BtnAcceptAccountFriendInvite" then
        FriendshipLib.AccountInviteRespond(self.nInviteId, true)
        ViragsSocial:CloseAllDialogs()
    elseif eButtonType == "BtnRejectAccountFriendInvite" then
        FriendshipLib.AccountInviteRespond(self.nInviteId, false)
        ViragsSocial:CloseAllDialogs()
    elseif eButtonType == "BtnAcceptAndAddFriendInvite" then
        FriendshipLib.RespondToInvite(self.nInviteId, FriendshipLib.FriendshipResponse_Mutual)
        ViragsSocial:CloseAllDialogs()
    elseif eButtonType == "BtnAcceptFriendInvite" then
        FriendshipLib.RespondToInvite(self.nInviteId, FriendshipLib.FriendshipResponse_Accept)
        ViragsSocial:CloseAllDialogs()
    elseif eButtonType == "BtnRejectFriendInvite" then
        FriendshipLib.RespondToInvite(self.nInviteId, FriendshipLib.FriendshipResponse_Decline)
        ViragsSocial:CloseAllDialogs()
    elseif eButtonType == "BtnIgnoretFriendInvite" then
        FriendshipLib.RespondToInvite(self.nInviteId, FriendshipLib.FriendshipResponse_Ignore)
        ViragsSocial:CloseAllDialogs()
    elseif eButtonType == "BtnInvite" then
        local name = self.strTarget
        local realm = GameLib.GetRealmName()

        local tCharacterData = GameLib.SearchRelationshipStatusByCharacterName(self.strTarget)

        if tCharacterData ~= nil
                and tCharacterData.tAccountFriend ~= nil
                and tCharacterData.tAccountFriend.arCharacters ~= nil
                and tCharacterData.tAccountFriend.arCharacters[1] ~= nil then
            name = tCharacterData.tAccountFriend.arCharacters[1].strCharacterName
            realm = tCharacterData.tAccountFriend.arCharacters[1].strRealm
        end

        if name and realm then
            GroupLib.Invite(name, realm)
        end
    elseif eButtonType == "BtnVisitRequest" then
        local tCharacterData = GameLib.SearchRelationshipStatusByCharacterName(self.strTarget)
        if tCharacterData ~= nil and tCharacterData.tNeighbor ~= nil and tCharacterData.tNeighbor.nId then
            HousingLib.VisitNeighborResidence(tCharacterData.tNeighbor.nId)
        end

    elseif eButtonType == "BtnJoinRequest" then
        local name = self.strTarget
        local realm = GameLib.GetRealmName()

        local tCharacterData = GameLib.SearchRelationshipStatusByCharacterName(self.strTarget)


        if tCharacterData ~= nil
                and tCharacterData.tAccountFriend ~= nil
                and tCharacterData.tAccountFriend.arCharacters ~= nil
                and tCharacterData.tAccountFriend.arCharacters[1] ~= nil then
            name = tCharacterData.tAccountFriend.arCharacters[1].strCharacterName
            realm = tCharacterData.tAccountFriend.arCharacters[1].strRealm
        end

        if name and realm then
            GroupLib.Join(name, realm)
            return
        end

    else
        self:ProcessContextClickOld(eButtonType)
    end
end



