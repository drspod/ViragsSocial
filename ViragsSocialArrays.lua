local ViragsSocial = Apollo.GetAddon("ViragsSocial")


local kTradeskillIdToIcon = {
    [CraftingLib.CodeEnumTradeskill.Survivalist] = "IconSprites:Icon_Achievement_UI_Tradeskills_Survivalist",
    [CraftingLib.CodeEnumTradeskill.Architect] = "IconSprites:Icon_Achievement_UI_Tradeskills_Architect",
    [CraftingLib.CodeEnumTradeskill.Mining] = "IconSprites:Icon_Achievement_UI_Tradeskills_Miner",
    [CraftingLib.CodeEnumTradeskill.Relic_Hunter] = "IconSprites:Icon_Achievement_UI_Tradeskills_RelicHunter",
    [CraftingLib.CodeEnumTradeskill.Outfitter] = "IconSprites:Icon_Achievement_UI_Tradeskills_Outfitter",
    [CraftingLib.CodeEnumTradeskill.Armorer] = "IconSprites:Icon_Achievement_UI_Tradeskills_Armorer",
    [CraftingLib.CodeEnumTradeskill.Weaponsmith] = "IconSprites:Icon_Achievement_UI_Tradeskills_WeaponCrafting",
    [CraftingLib.CodeEnumTradeskill.Tailor] = "IconSprites:Icon_Achievement_UI_Tradeskills_Tailor",
    [CraftingLib.CodeEnumTradeskill.Augmentor] = "IconSprites:Icon_Achievement_UI_Tradeskills_Technologist",
}

local kTradeskillShortName = {
    [CraftingLib.CodeEnumTradeskill.Survivalist] = "Surv",
    [CraftingLib.CodeEnumTradeskill.Architect] = "Arch",
    [CraftingLib.CodeEnumTradeskill.Mining] = "Miner",
    [CraftingLib.CodeEnumTradeskill.Relic_Hunter] = "Relic",
    [CraftingLib.CodeEnumTradeskill.Outfitter] = "Outf",
    [CraftingLib.CodeEnumTradeskill.Armorer] = "Armor",
    [CraftingLib.CodeEnumTradeskill.Weaponsmith] = "Weapon",
    [CraftingLib.CodeEnumTradeskill.Tailor] = "Tailor",
    [CraftingLib.CodeEnumTradeskill.Augmentor] = "Tech",
}


local kTradeskillFullName = {
    [CraftingLib.CodeEnumTradeskill.Survivalist] = Apollo.GetString("Options_Survivalist"),
    [CraftingLib.CodeEnumTradeskill.Architect] = Apollo.GetString("Options_Architect"),
    [CraftingLib.CodeEnumTradeskill.Mining] = Apollo.GetString("Options_Miner"),
    [CraftingLib.CodeEnumTradeskill.Relic_Hunter] = "Relic Hunter",
    [CraftingLib.CodeEnumTradeskill.Outfitter] = Apollo.GetString("Options_Outfitter"),
    [CraftingLib.CodeEnumTradeskill.Armorer] = Apollo.GetString("CRB_Armorer"),
    [CraftingLib.CodeEnumTradeskill.Weaponsmith] = Apollo.GetString("CRB_Weaponsmith"),
    [CraftingLib.CodeEnumTradeskill.Tailor] = Apollo.GetString("Options_Tailor"),
    [CraftingLib.CodeEnumTradeskill.Augmentor] = Apollo.GetString("Options_Augmentor"),
}
local kTradeskillShortNameToID = {
    ["Surv"] = CraftingLib.CodeEnumTradeskill.Survivalist,
    ["Arch"] = CraftingLib.CodeEnumTradeskill.Architect,
    ["Miner"] = CraftingLib.CodeEnumTradeskill.Mining,
    ["Relic"] = CraftingLib.CodeEnumTradeskill.Relic_Hunter,
    ["Outf"] = CraftingLib.CodeEnumTradeskill.Outfitter,
    ["Armor"] = CraftingLib.CodeEnumTradeskill.Armorer,
    ["Weapon"] = CraftingLib.CodeEnumTradeskill.Weaponsmith,
    ["Tailor"] = CraftingLib.CodeEnumTradeskill.Tailor,
    ["Tech"] = CraftingLib.CodeEnumTradeskill.Augmentor,
}
local ktClass =
{
    [GameLib.CodeEnumClass.Medic] = Apollo.GetString("ClassMedic"),
    [GameLib.CodeEnumClass.Esper] = Apollo.GetString("CRB_Esper"),
    [GameLib.CodeEnumClass.Warrior] = Apollo.GetString("ClassWarrior"),
    [GameLib.CodeEnumClass.Stalker] = Apollo.GetString("ClassStalker"),
    [GameLib.CodeEnumClass.Engineer] = Apollo.GetString("ClassEngineer"),
    [GameLib.CodeEnumClass.Spellslinger] = Apollo.GetString("ClassSpellslinger"),
}

local ktClassIcon =
{
    [GameLib.CodeEnumClass.Medic] = "Icon_Windows_UI_CRB_Medic",
    [GameLib.CodeEnumClass.Esper] = "Icon_Windows_UI_CRB_Esper",
    [GameLib.CodeEnumClass.Warrior] = "Icon_Windows_UI_CRB_Warrior",
    [GameLib.CodeEnumClass.Stalker] = "Icon_Windows_UI_CRB_Stalker",
    [GameLib.CodeEnumClass.Engineer] = "Icon_Windows_UI_CRB_Engineer",
    [GameLib.CodeEnumClass.Spellslinger] = "Icon_Windows_UI_CRB_Spellslinger",
}

local ktPath =
{
    [PlayerPathLib.PlayerPathType_Soldier] = Apollo.GetString("PlayerPathSoldier"),
    [PlayerPathLib.PlayerPathType_Settler] = Apollo.GetString("PlayerPathSettler"),
    [PlayerPathLib.PlayerPathType_Scientist] = Apollo.GetString("PlayerPathScientist"),
    [PlayerPathLib.PlayerPathType_Explorer] = Apollo.GetString("PlayerPathExplorer"),
}

local ktPathIcon =
{
    [PlayerPathLib.PlayerPathType_Soldier] = "Icon_Windows_UI_CRB_Soldier",
    [PlayerPathLib.PlayerPathType_Settler] = "Icon_Windows_UI_CRB_Colonist",
    [PlayerPathLib.PlayerPathType_Scientist] = "Icon_Windows_UI_CRB_Scientist",
    [PlayerPathLib.PlayerPathType_Explorer] = "Icon_Windows_UI_CRB_Explorer",
}

ViragsSocial.CharacterFriendshipType_Account_Invite = 100
ViragsSocial.CharacterFriendshipType_Invite = 200

ViragsSocial.ktFriendRanks =
{
    [FriendshipLib.CharacterFriendshipType_Ignore] = "Ignore",
    [FriendshipLib.CharacterFriendshipType_Rival] = "Rival",
    [FriendshipLib.CharacterFriendshipType_Friend] = "Friend",
    [FriendshipLib.CharacterFriendshipType_Account] = "Account Friend",
    [ViragsSocial.CharacterFriendshipType_Invite] = "Invite (Friend)",
    [ViragsSocial.CharacterFriendshipType_Account_Invite] = "Invite (Account Friend)",
}
ViragsSocial.ktFriendlistIcons = {
    [FriendshipLib.CharacterFriendshipType_Ignore] = "CRB_CharacterCreateSprites:sprCharC_ClassFooterIconDisabled",
    [FriendshipLib.CharacterFriendshipType_Rival] = nil,
    [FriendshipLib.CharacterFriendshipType_Friend] = "BK3:sprHolo_Friends_Single",
    [FriendshipLib.CharacterFriendshipType_Account] = "BK3:sprHolo_Friends_Account",
    [ViragsSocial.CharacterFriendshipType_Invite] = "BK3:sprHolo_Friends_Single",
    [ViragsSocial.CharacterFriendshipType_Account_Invite] = "BK3:sprHolo_Friends_Account",
}



function ViragsSocial:IconForTradeSkillShortName( tsName )
    if tsName == nil then return nil end
    local tsId = kTradeskillShortNameToID[tsName]
    if tsId == nil then return nil end
    return kTradeskillIdToIcon[tsId]
end

function ViragsSocial:ShortNameForTradeSkillID( nID )
    if nID == nil then return nil end

    return kTradeskillShortName[nID]
end

function ViragsSocial:FullNameForTradeSkillShortName( tsName )
    if tsName == nil then return nil end
    local tsId = kTradeskillShortNameToID[tsName]
    if tsId == nil then return nil end
    return kTradeskillFullName[tsId]
end

function ViragsSocial:ClassIcon(nClass)
    if nClass ~= nil then
        return ktClassIcon[nClass]
    end
    return nil
end

function ViragsSocial:ClassName(nClass)
    if nClass == nil or
       ktClass[nClass] == nil then
        return ""
    end

    return ktClass[nClass]
end


function ViragsSocial:PathIcon(nPath)
    if nPath ~= nil then
        return ktPathIcon[nPath]
    end
    return nil
end

function ViragsSocial:PathName(nPath)
    if nPath == nil or
            ktPath[nPath] == nil then
        return ""
    end

    return ktPath[nPath]
end



