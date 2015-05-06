--
-- Created by IntelliJ IDEA.
-- User: Peter
-- Date: 12.08.14
-- Time: 12:39
-- To change this template use File | Settings | File Templates.
--

local ViragsSocial = Apollo.GetAddon("ViragsSocial")
local ktFaction = {
    [Unit.CodeEnumFaction.DominionPlayer] = Apollo.GetString("CRB_Dominion"),
    [Unit.CodeEnumFaction.ExilesPlayer] = Apollo.GetString("CRB_Exiles")
}

local UnitArraySize = 1
local ScannerUnitArrayHelper = {}
--local ScannerModeDB = {}

function ViragsSocial:StartScannerMode()

    if not self.bLocationScannerMode then
        self.bLocationScannerMode = true
        Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
        Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
        Apollo.RegisterTimerHandler("UnitScannerCleaner", "UnitScannerCleanup", self)
        Apollo.CreateTimer("UnitScannerCleaner", 90.000, true)
        Apollo.StartTimer("UnitScannerCleaner")
        Apollo.RegisterTimerHandler("DelayedLoader", "OnDelayedLoad", self)
        Apollo.CreateTimer("DelayedLoader", 1.000, false)
        Apollo.StopTimer("DelayedLoader")


        Apollo.RegisterTimerHandler("InspectDelayTimer", "OnInspectDelayTimer", self)
        Apollo.CreateTimer("InspectDelayTimer", 0.700, true)
        Apollo.StopTimer("InspectDelayTimer")

        self:PRINT("Scanner mode start. Will track close units (only NEW) -- Can permanently activate it in settings => will see ALL close units")
    end

    if self:IsScannerMode() then self:UpdateGrid(false, true) end
end

function ViragsSocial:StopScannerMode()
    self:StopAttunesScann()
    if not self.tSettings.bLocationScannerMode then
        if self.bLocationScannerMode then
            self.bLocationScannerMode = false
            if not self.tSettings.bLocationScannerMode then
                Apollo.RemoveEventHandler("UnitCreated", self)
                Apollo.RemoveEventHandler("UnitDestroyed", self)
                Apollo.StopTimer("UnitScannerCleaner")

                UnitArraySize = 1
                ScannerUnitArrayHelper = {}
                self:SetNewRosterForGrid({}, ViragsSocial.ScannerMode)

                self:PRINT("Scanner mode stop")
            end
        end
    end
end

local unitQueue = {}
local unitLoadTimerCD = false
function ViragsSocial:OnUnitCreated(tUnit)
    if tUnit and tUnit:IsACharacter() and tUnit:GetName() and tUnit:GetName() ~= "" then
        unitQueue[tUnit:GetName()] = tUnit
        if not unitLoadTimerCD then
            unitLoadTimerCD = true
            Apollo.StartTimer("DelayedLoader")
        end
    end
end

function ViragsSocial:OnDelayedLoad()
    if self.scannerLocked then
        Apollo.StartTimer("DelayedLoader")
        return
    end

    self.scannerLocked = true
    for name, tUnit in pairs(unitQueue) do
        if self:IsValidUnit(tUnit) then
            local ScannerModeDB = self:GetRosterForGrid(ViragsSocial.ScannerMode)
            if ScannerModeDB == nil then
                self:SetNewRosterForGrid({}, ViragsSocial.ScannerMode)
                ScannerModeDB = self:GetRosterForGrid(ViragsSocial.ScannerMode)
            end

            local record
            local idInDB = ScannerUnitArrayHelper[name]
            if idInDB then
                record = ScannerModeDB[idInDB]
            end

            if not record then

                record = {}
                ScannerUnitArrayHelper[name] = UnitArraySize
                ScannerModeDB[UnitArraySize] = record
                UnitArraySize = UnitArraySize + 1
            end

            record.strName = tUnit:GetName()
            record.nRank = tUnit:GetFaction() or ViragsSocial.UNDEFINED
            record.nLevel = tUnit:GetLevel() or ViragsSocial.UNDEFINED
            record.eClass = tUnit:GetClassId() or ViragsSocial.UNDEFINED
            record.ePathType = tUnit:GetPlayerPathType() or ViragsSocial.UNDEFINED
            record.strNote = tUnit:GetGuildName() or ""
            local location = self:HelperCurrentZoneName()
            if location then location = location .. " [S]" end
            record.location = location
            record.unit = tUnit
            record.fLastOnline = 0
        end
    end


    unitQueue = {}
    unitLoadTimerCD = false
    self.scannerLocked = false
    if self:IsScannerMode() then
        self:UpdateGrid(false, true)
    end
end

function ViragsSocial:ReloadUnitScannerList()
    self:DEBUG("ReloadUnitScannerList")

end

function ViragsSocial:StartAttunesScann()
    if self.bAttuneScanerStarted then return end
    self.bAttuneScanerStarted = true
    self:PRINT("Attunement Scanner Started. It will collect info from nearby players. Auto-stops on tab change or window close. This feature WILL DISABLE your \"Inspect\" addon while active. So you have to stop it if you want to use inspect")
    self:DEBUG("StartAttunesScann()")



    local ScannerModeDB = self:GetRosterForGrid(ViragsSocial.ScannerMode)

    if ScannerModeDB and #ScannerModeDB > 0 then
        local InspectAddon = Apollo.GetAddon("Inspect")
        if InspectAddon == nil then
            self:PRINT("Can't find default Inspect addon, can't scan attunes")
            self:StopAttunesScann()
            return
        end

       -- InspectAddon.OldOnInspect = InspectAddon.OnInspect
       -- InspectAddon.OnInspect = self.OnInspect
       Apollo.RegisterEventHandler("Inspect", "OnInspect", self)
       Apollo.RemoveEventHandler("Inspect", InspectAddon)
       Apollo.StartTimer("InspectDelayTimer")
        return
    end

    self:StopAttunesScann()
end
local nUnitAttuneScanned = 1

function ViragsSocial:OnInspectDelayTimer()
    if not self.bAttuneScanerStarted then
        nUnitAttuneScanned = 1
        local InspectAddon = Apollo.GetAddon("Inspect")
        if InspectAddon == nil then
            return
        end

        Apollo.StopTimer("InspectDelayTimer")
        Apollo.RegisterEventHandler("Inspect", "OnInspect", InspectAddon)
        Apollo.RemoveEventHandler("Inspect", self)
        return
    end

    local ScannerModeDB = ViragsSocial:GetScanerDB()
    local stop = false
    for i = nUnitAttuneScanned, #ScannerModeDB do
        local record = ScannerModeDB[nUnitAttuneScanned]
        if record then
            if self:IsValidUnit(record.unit) then
                local db = self.ktPlayerInfoDB[record.strName]
                if db == nil or (db and db.raidAttunStep == nil) then
                    record.unit:Inspect()
                    self:DEBUG("INSPECTING: " .. record.strName .." "..nUnitAttuneScanned)
                    stop = true
                end
            end

            nUnitAttuneScanned = nUnitAttuneScanned + 1
        end

        i = nUnitAttuneScanned
        if stop then return end
    end

    nUnitAttuneScanned = 1

end



function ViragsSocial:StopAttunesScann()
    if not self.bAttuneScanerStarted then return end
    self.bAttuneScanerStarted = false
    self:PRINT("Attunement Scanner Stopped")
end

function ViragsSocial:OnInspect(unitInspecting, arItems)

    local ScannerModeDB = self:GetScanerDB()
    if arItems and unitInspecting then

        local name = unitInspecting:GetName()


        if name and name ~= "" and ScannerUnitArrayHelper[name] and ScannerModeDB[ScannerUnitArrayHelper[name]] then
            local record = ScannerModeDB[ScannerUnitArrayHelper[name]]

            local key = self:GetRaidAttuneKeyFromItems(arItems)

            local raidAttunKey = self:GetRaidAttuneInfoFromKey(key)
            if raidAttunKey ~= nil then
                self:SaveNewAttuneInfoForPlayer(name, raidAttunKey)
            end

        end
    end

end

function ViragsSocial:SaveNewAttuneInfoForPlayer(name, raidAttunKey)
    if name == nil or raidAttunKey == nil then return end

    local playerInfo = self.ktPlayerInfoDB[name]
    if not playerInfo then
        playerInfo = {}
        self.ktPlayerInfoDB[name] = playerInfo
    end

    playerInfo.raidAttunStep = raidAttunKey
    self:UpdateGrid(false, false)
end

function ViragsSocial:GetScanerDB()
    local ScannerModeDB = self:GetRosterForGrid(ViragsSocial.ScannerMode)
    if ScannerModeDB == nil then
        self:SetNewRosterForGrid({}, ViragsSocial.ScannerMode)
        ScannerModeDB = self:GetRosterForGrid(ViragsSocial.ScannerMode)
    end
    return ScannerModeDB
end

function ViragsSocial:UnitScannerCleanup()
    if self.scannerLocked then
        return
    end

    self:DEBUG("UnitScannerCleanup")

    local cleanUnits = {}
    local cleanHelper = {}
    local lastId = 1

    local ScannerModeDB = self:GetRosterForGrid(ViragsSocial.ScannerMode)
    for k, v in pairs(ScannerModeDB) do

        if self:IsValidUnit(v.unit) then
            cleanUnits[lastId] = v
            cleanHelper[v.strName] = lastId
            lastId = lastId + 1
        end
    end

    UnitArraySize = lastId
    ScannerUnitArrayHelper = cleanHelper
    self:SetNewRosterForGrid(cleanUnits, ViragsSocial.ScannerMode)
end

function ViragsSocial:IsValidUnit(tData)
    return tData and tData:GetName() ~= nil and tData:GetName() ~= ""
end

function ViragsSocial:LocationFromScanner(strName)
    local id = ScannerUnitArrayHelper[strName]
    local ScannerModeDB = self:GetRosterForGrid(ViragsSocial.ScannerMode)
    if id and ScannerModeDB[id] then
        local data = ScannerModeDB[id]
        if self:IsValidUnit(data.unit) then
            --  if self:IsValidUnit(data.unit) and data.unit:GetName() == strName then
            return data.location
        end
    end

    return nil
end

function ViragsSocial:ScannerListSort(array, helperArray, cmpFn)
    if array and helperArray and cmpFn then
        self:SelectionSort(array, cmpFn)
        -- table.sort(array, cmpFn)
        for k, v in pairs(array) do
            helperArray[v.strName] = k
        end
    end
end


function ViragsSocial:DrawUnitScannerList(tUnitList)
    if tUnitList == nil then return end

    self:DEBUG("UpdateGrid!!!!!!: DrawUnitScannerList")
    self:DEBUG(#tUnitList .. " = " .. UnitArraySize)
    self:DEBUG("self.ktPlayerInfoDB",self.ktPlayerInfoDB )
    if self.scannerLocked then
        self:UpdateGrid(false, false) -- will delay for 1 sec
        return
    end

    self.scannerLocked = true


    self:ScannerListSort(tUnitList, ScannerUnitArrayHelper, self:cmpFn()) --custom sort



    local currTab = self.kSelectedTab
    for key, tCurr in pairs(tUnitList) do
        local strRank = ktFaction[tCurr.nRank] or ""
        local nameIcon = self:RelationsIconForPlayer(tCurr.strName, currTab)
        local unit = tCurr.unit
        if self:IsValidUnit(unit) then

            local strName = unit:GetName()
            local nRank = unit:GetFaction() or ViragsSocial.UNDEFINED
            local nLevel = unit:GetLevel() or ViragsSocial.UNDEFINED
            local eClass = unit:GetClassId() or ViragsSocial.UNDEFINED
            local ePathType = unit:GetPlayerPathType() or ViragsSocial.UNDEFINED
            tCurr.strNote = tCurr.strNote or unit:GetGuildName()
            if not tCurr.strNote then
                tCurr.strNote = ""
            end

            local rankIcon = self:ImgForAttuneInfo(self.ktPlayerInfoDB[strName])


            self:AddRow(tCurr, eClass, ePathType, nLevel, strName, tCurr.fLastOnline, strRank, tCurr.strNote, nameIcon, rankIcon, noteIcon1, noteIcon2)
        end
    end
    self.scannerLocked = false
end
