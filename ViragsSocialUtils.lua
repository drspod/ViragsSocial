local ViragsSocial = Apollo.GetAddon("ViragsSocial")

function ViragsSocial:DBRecord(name, bCreateIfNil)
    if self.ktPlayerInfoDB[name] then return self.ktPlayerInfoDB[name] end

    if bCreateIfNil then
        self.ktPlayerInfoDB[name] = {}
    end

    return self.ktPlayerInfoDB[name]
end


function ViragsSocial:HelperCurrentZoneName()
    local zoneName = ""
    local currZone = GameLib.GetCurrentZoneMap()

    if currZone == nil or currZone.strName == nil then return "" end

    zoneName = currZone.strName
    if HousingLib.IsHousingWorld() then --house
        local currZoneName = GetCurrentZoneName()
        if currZoneName then
            zoneName = "HS: " .. currZoneName
            if HousingLib.IsOnMyResidence() and GameLib.GetPlayerUnit() then
                local name = GameLib.GetPlayerUnit():GetName()
                if name then
                    zoneName = zoneName .. " [" .. name .. "]"
                end
            end
        end
    end

    return zoneName
end
function ViragsSocial:PRINT(msg, nChannel, sender)
    if msg == nil then return end

    ChatSystemLib.PostOnChannel(nChannel or ChatSystemLib.ChatChannel_System, msg, sender or "Virag's Social")
end
function ViragsSocial:ChannelPRINT(msg, tChannel, sender)
    if msg == nil then return end
    if tChannel then
        tChannel:Post(msg, sender or "Virag's Social")
    end


end
function ViragsSocial:LocationOfPlayer(sName)
    local location = nil

    if self.ktPlayerInfoDB[sName] and self.ktPlayerInfoDB[sName].location then
        location = self.ktPlayerInfoDB[sName].location
    end

    if not location and self:IsWhoTabSelected() then
        location = self:LocationFromWho(sName)
    end

    if not location then
        location = self:LocationFromScanner(sName)
    end



    return location

end




function ViragsSocial:SelectionSort( f, cmpfn )
    if f == nil or cmpfn == nil then return end

    for k = 1, #f-1 do
        if f[k] then
            local idx = k
            for i = k+1, #f do
                if f[i] then
                    if cmpfn(f[i], f[idx]) then
                        idx = i
                    end
                end
            end
            f[k], f[idx] = f[idx], f[k]
        end
    end
end


function ViragsSocial:HelperConvertToTime(fDays, sLocation)

    if fDays == 0 then
        if sLocation and sLocation ~= "" then
            return sLocation
        end
        return Apollo.GetString("Friends_Online")
    end

    if fDays == 1 then return Apollo.GetString("Friends_Offline") end

    if fDays == nil or fDays == 10000 then return "" end

    local bExpireTime = fDays < 0
    if bExpireTime then fDays = -1 * fDays end

    local tTimeInfo = { ["name"] = "", ["count"] = nil }

    if fDays >= 365 then -- Years
        tTimeInfo["name"] = Apollo.GetString("CRB_Year")
        tTimeInfo["count"] = math.floor(fDays / 365)
    elseif fDays >= 30 then -- Months
        tTimeInfo["name"] = Apollo.GetString("CRB_Month")
        tTimeInfo["count"] = math.floor(fDays / 30)
    elseif fDays >= 7 then
        tTimeInfo["name"] = Apollo.GetString("CRB_Week")
        tTimeInfo["count"] = math.floor(fDays / 7)
    elseif fDays >= 1 then -- Days
        tTimeInfo["name"] = Apollo.GetString("CRB_Day")
        tTimeInfo["count"] = math.floor(fDays)
    else
        local fHours = fDays * 24
        local nHoursRounded = math.floor(fHours)
        local nMin = math.floor(fHours * 60)

        if nHoursRounded > 0 then
            tTimeInfo["name"] = Apollo.GetString("CRB_Hour")
            tTimeInfo["count"] = nHoursRounded
        elseif nMin > 0 then
            tTimeInfo["name"] = Apollo.GetString("CRB_Min")
            tTimeInfo["count"] = nMin
        else
            tTimeInfo["name"] = Apollo.GetString("CRB_Min")
            tTimeInfo["count"] = 1
        end
    end

    if bExpireTime then
        return String_GetWeaselString(Apollo.GetString("Friends_ExpiresText"), tTimeInfo)
    end

    return String_GetWeaselString(Apollo.GetString("CRB_TimeOffline"), tTimeInfo)
end