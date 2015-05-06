require "ICCommLib"
require "ICComm"
require "ApolloTimer"

-----------------------------------------------------------------------------------------------
-- ViragsSocial Broadcasting
-----------------------------------------------------------------------------------------------
local ViragsSocial = Apollo.GetAddon("ViragsSocial")
local JSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage
local List = {}

ViragsSocial.ICCommLib_PROTOCOL_VERSION = 0.001

ViragsSocial.MSG_CODES = {
    ["REQUEST_INFO"] = 1,
    ["UPDATE_FOR_TARGET"] = 2,
    ["UPDATE_FOR_ALL"] = 3,

}

function ViragsSocial:JoinICCommLibChannels()
    if self.tSettings.bDisableNetwork then return end
    self.DEBUG("JoinICCommLibChannels()")
    local arGuilds = GuildLib.GetGuilds()

    if arGuilds == nil then return end

    if self.InfoChannels == nil then self.InfoChannels = {} end

    for key, guildCurr in pairs(arGuilds) do
        local guildName = guildCurr:GetName()
        if guildName and (guildCurr:GetType() == GuildLib.GuildType_Circle
                or guildCurr:GetType() == GuildLib.GuildType_Guild) then
            local chanelName = "ViragSocial" .. guildName

            if self.InfoChannels[guildName] == nil then
                self.DEBUG("Join " .. chanelName)
                self.InfoChannels[guildName] = ICCommLib.JoinChannel(chanelName, ICCommLib.CodeEnumICCommChannelType.Group) --"OnBroadcastReceived", self)
                self.channelTimer = ApolloTimer.Create(1, true, "SetICCommCallback", self)
            end
        end
    end
end

function ViragsSocial:SetICCommCallback()
    if not self.channel then
        self.channel = ICCommLib.JoinChannel("ViragSocial", ICCommLib.CodeEnumICCommChannelType.Group)
    end
    if self.channel:IsReady() then
        self.channel:SetReceivedMessageFunction("OnBroadcastReceived", self)
        self.channelTimer = nil
    end
end


--SEND MSG_CODES["UPDATE_FOR_ALL"] 
function ViragsSocial:BroadcastUpdate()

    if self.InfoChannels then
        for key, channel in pairs(self.InfoChannels) do
            self:AddToBroadcastQueue(channel, self.MSG_CODES["UPDATE_FOR_ALL"], nil)
        end
    end
end

--SEND MSG_CODES["REQUEST_INFO"]
function ViragsSocial:BroadcastRequestInfo()

    if self.kbCanRequestFullUpdateBroadcast and self.InfoChannels then
        self.kbCanRequestFullUpdateBroadcast = false

        for key, channel in pairs(self.InfoChannels) do
            self:AddToBroadcastQueue(channel, self.MSG_CODES["REQUEST_INFO"], nil)
        end
    end
end

--SEND MSG_CODES["UPDATE_FOR_TARGET"]
function ViragsSocial:BroadcastToTarget(chanell, target)

    if target and chanell then
        self:AddToBroadcastQueue(chanell, self.MSG_CODES["UPDATE_FOR_TARGET"], target)
    end
end

function ViragsSocial:AddToBroadcastQueue(chanell, code, target)

    if code == self.MSG_CODES["REQUEST_INFO"]
            or code == self.MSG_CODES["UPDATE_FOR_TARGET"]
            or code == self.MSG_CODES["UPDATE_FOR_ALL"] then
        local queueValue = { tChanell = chanell, nCode = code, strTarget = target }

        if self.msgQueue == nil then
            self.msgQueue = List.new()
        end

        List.pushleft(self.msgQueue, queueValue)
        Apollo.StartTimer("BroadcastUpdateTimer")
    end
end

function ViragsSocial:StartBroadcastFromQueue()

    if self.kMyID == nil or self.kbNeedUpdateMyInfo then
        self:UpdateMyInfo()
        if self.kMyID == nil or self.kbNeedUpdateMyInfo then --fail
            Apollo.StartTimer("BroadcastUpdateTimer")
            return
        end
        self:UpdateGrid(false, false)
    end


    local v = List.popright(self.msgQueue)

    if v then self:Broadcast(v.tChanell, self.ktPlayerInfoDB[self.kMyID], v.nCode, v.strTarget) end

    if List.hasmore(self.msgQueue) then Apollo.StartTimer("BroadcastUpdateTimer") end
end

-- SEND
function ViragsSocial:Broadcast(chanell, msg, code, target)

    if self:ValidateBroadcast(msg) and chanell and code then

        if self.kbDEBUG then
            local strTarget = ""
            if target then strTarget = " to " .. target end

            local strCode = "REQUEST_INFO"
            if code == self.MSG_CODES["UPDATE_FOR_TARGET"] then                 strCode = "UPDATE_FOR_TARGET"
            elseif code == self.MSG_CODES["UPDATE_FOR_ALL"] then                 strCode = "UPDATE_FOR_ALL"
            end

            self:DEBUG("Broadcsting " .. strCode .. strTarget)
            self:DEBUG("Broadcast() " .. strCode .. strTarget, msg)
            self:DEBUG("self.ktPlayerInfoDB", self.ktPlayerInfoDB)
        end --debug end

        if code == self.MSG_CODES["UPDATE_FOR_ALL"] then
            self.knMyLastUpdate = self:HelperServerTime()
        end

        if self.ktPlayerInfoDB[self.kMyID].onlineTime == nil then
            self.ktPlayerInfoDB[self.kMyID].onlineTime = self:HelperServerTime()
        end

        if self.tSettings.bDisableNetwork then
            local newMsg = {}
            newMsg.version = self.ICCommLib_PROTOCOL_VERSION
            newMsg.addonVersion = self.ADDON_VERSION
            newMsg.name = msg.name
            newMsg.level = msg.level
            newMsg.class = msg.class
            newMsg.path = msg.path
            msg = newMsg
        end

        msg.target = target
        msg.MSG_CODE = code

        chanell:SendMessage(JSON.encode(msg))

    end
end

--RECEIVE
function ViragsSocial:OnBroadcastReceived(chanell, msg_encoded)
    local msg = JSON.decode(msg_encoded)

    if msg == nil or msg.name == nil or type(msg) ~= "table" then return end

    self:DEBUG("self.ktPlayerInfoDB", self.ktPlayerInfoDB)

    if self.MSG_CODES["REQUEST_INFO"] == msg.MSG_CODE then
        --if msg.onlineTime ~= nil then
        --dont send anything if he already has some update from you
        --	if msg.onlineTime < self.knMyLastUpdate then
        --	return end
        --end buggy, DOESNT WORK AS INTENDET

        self:DEBUG("OBR REQUEST_INFO from " .. msg.name)
        self:DEBUG("OnBroadcastReceived() " .. msg.MSG_CODE, msg)
        self:DEBUG("OnBroadcastReceived() chanell", chanell)
        self:DEBUG("self.ktPlayerInfoDB", self.ktPlayerInfoDB)

        self:BroadcastToTarget(chanell, msg.name)
        return
    end
    if self.tSettings.bDisableNetwork then return end

    if not self:isUpToDateVersion(msg) then return end

    local bNeedUpdateGrid = false

    if self.MSG_CODES["UPDATE_FOR_TARGET"] == msg.MSG_CODE then
        bNeedUpdateGrid = msg.target == self.kMyID

        self:DEBUG("OBR UPDATE_FOR_TARGET " .. msg.target .. " from " .. msg.name)
        self:DEBUG("OnBroadcastReceived() " .. msg.MSG_CODE, msg)
        self:DEBUG("OnBroadcastReceived() chanell", chanell)
        self:DEBUG("self.ktPlayerInfoDB", self.ktPlayerInfoDB)
    elseif self.MSG_CODES["UPDATE_FOR_ALL"] == msg.MSG_CODE then
        bNeedUpdateGrid = true

        self:DEBUG("OBR UPDATE_FOR_ALL from " .. msg.name)
        self:DEBUG("OnBroadcastReceived() " .. msg.MSG_CODE, msg)
        self:DEBUG("OnBroadcastReceived() chanell", chanell)
        self:DEBUG("self.ktPlayerInfoDB", self.ktPlayerInfoDB)
    end

    if bNeedUpdateGrid and self:ValidateBroadcast(msg) then
        self.ktPlayerInfoDB[msg.name] = msg
        self:UpdateGrid(false, false)
    end
end

function ViragsSocial:HelperServerTime()
    local tTime = GameLib.GetServerTime()
    tTime.year = tTime.nYear
    tTime.month = tTime.nMonth
    tTime.day = tTime.nDay
    tTime.hour = tTime.nhour
    tTime.min = tTime.nMinute
    tTime.sec = tTime.nSecond
    tTime.isdst = false
    return os.time(tTime)
end


--VALIDATE (version check)
function ViragsSocial:isUpToDateVersion(msg)
    --protocol changed, so dont try to do anything
    if msg.version and msg.version > self.ICCommLib_PROTOCOL_VERSION then
        self.bNeedUpdateAddon = true
        self:ShowUpdateAddonInfoWnd()
        return false
    end

    --addon changed, so can still use data, just report that you need to update
    if msg.addonVersion and msg.addonVersion > self.ADDON_VERSION then
        self.bNeedUpdateAddon = true
        self:ShowUpdateAddonInfoWnd()
    end

    return true
end

--VALIDATE
function ViragsSocial:ValidateBroadcast(msg)
    return msg and type(msg) == "table" and msg.name ~= nil -- todo validation
end



-- QUEUE from http://stackoverflow.com/questions/18843610/fast-implementation-of-queues-in-lua or  Programming in Lua
function List.new()
    return { first = 0, last = -1 }
end

function List.hasmore(list)
    return list.first <= list.last
end

function List.pushleft(list, value)
    local first = list.first - 1
    list.first = first
    list[first] = value
end

function List.pushright(list, value)
    local last = list.last + 1
    list.last = last
    list[last] = value
end

function List.popleft(list)
    local first = list.first
    if first > list.last then return nil end -- error("list is empty")
    local value = list[first]
    list[first] = nil -- to allow garbage collection
    list.first = first + 1
    return value
end

function List.popright(list)
    local last = list.last
    if list.first > last then return nil end -- error("list is empty")
    local value = list[last]
    list[last] = nil -- to allow garbage collection
    list.last = last - 1
    return value
end
