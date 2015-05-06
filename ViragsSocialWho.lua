--
-- Created by IntelliJ IDEA.
-- User: Peter
-- Date: 15.08.14
-- Time: 15:50
-- To change this template use File | Settings | File Templates.
--
local ViragsSocial = Apollo.GetAddon("ViragsSocial")
local karRaceToString =
{
    [GameLib.CodeEnumRace.Human] 	= Apollo.GetString("CRB_ExileHuman"),
    [GameLib.CodeEnumRace.Granok] 	= Apollo.GetString("RaceGranok"),
    [GameLib.CodeEnumRace.Aurin] 	= Apollo.GetString("RaceAurin"),
    [GameLib.CodeEnumRace.Draken] 	= Apollo.GetString("RaceDraken"),
    [GameLib.CodeEnumRace.Mechari] 	= Apollo.GetString("RaceMechari"),
    [GameLib.CodeEnumRace.Chua] 	= Apollo.GetString("RaceChua"),
    [GameLib.CodeEnumRace.Mordesh] 	= Apollo.GetString("CRB_Mordesh"),
}
function ViragsSocial:OnWhoResponse(arResponse, eWhoResult)
    if eWhoResult == GameLib.CodeEnumWhoResult.OK or eWhoResult == GameLib.CodeEnumWhoResult.Partial then
        if arResponse == nil or #arResponse == 0 then
            self:PRINT(Apollo.GetString("Who_NoResults"))
            return
        end

        for _, tWho in ipairs(arResponse) do
             self:DEBUG(tWho.strName, tWho)
            tWho.eClass = tWho.eClassId or ViragsSocial.UNDEFINED
            tWho.ePathType = tWho.ePlayerPathType or ViragsSocial.UNDEFINED
            tWho.nRank = ViragsSocial.UNDEFINED
            tWho.strNote = karRaceToString[tWho.eRaceId] or ""
            tWho.fLastOnline   = 0
        end
        self:SetNewRosterForGrid(arResponse, ViragsSocial.Who)
    elseif eWhoResult == GameLib.CodeEnumWhoResult.UnderCooldown then
        self:PRINT(Apollo.GetString("Who_UnderCooldown"))
    end


    if not self:IsVisible() then
        self:OnViragsSocialOn()
        self:UpdateUIAfterTabSelection(ViragsSocial.Who)
    end

    self:SetNewRosterForGrid(self:GetRosterForGrid (ViragsSocial.Who), ViragsSocial.Who)

end

function ViragsSocial:ReloadWhoList()

end

function ViragsSocial:OnWho()
    local cancelString = Apollo.GetString(1)
    local cmd

    if     cancelString  == "Cancel"    then   cmd = "/who"
    elseif cancelString  == "Abbrechen" then   cmd = "/wer"
    elseif cancelString  == "Annuler"   then   cmd = "/qui"
    end

    if cmd then
        ChatSystemLib.Command(cmd)
        self:PRINT("/who")
        self:UpdateUIAfterTabSelection(ViragsSocial.Who)
    else
        self:PRINT("Report your localiztion to me and i will fix this. Currently works for fr, en, de")
    end

end

function ViragsSocial:LocationFromWho(sName)

    local tWhoRoster =  self:GetRosterForGrid (ViragsSocial.Who)
    for k,v in ipairs(tWhoRoster) do
        if v.strName == sName then
            return v.strZone
        end
    end
end


function ViragsSocial:DrawWhoList(tRoster)

    if tRoster == nil then
        self:ReloadWhoList()
        return
    end
    self:DEBUG("UpdateGrid!!!!!!: DrawWhoList")
    self:DEBUG("DrawWhoList()", tRoster)

    local cmpFn = self:cmpFn()
    if cmpFn then
        self:SelectionSort( tRoster, cmpFn )--    table.sort(tRoster, cmpFn)
    end
    local currTab = self.kSelectedTab
    for key, tCurr in pairs(tRoster) do
        local nameIcon = self:RelationsIconForPlayer(tCurr.strName, currTab)
        self:AddRow(tCurr, tCurr.eClass, tCurr.ePathType, tCurr.nLevel, tCurr.strName, tCurr.fLastOnline, "", tCurr.strNote, nameIcon, nil, noteIcon1, noteIcon2)
    end

end
