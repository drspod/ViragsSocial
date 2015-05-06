--
-- Created by IntelliJ IDEA.
-- User: Vestl_000
-- Date: 8/19/2014
-- Time: 5:36 PM
-- To change this template use File | Settings | File Templates.
--

local ViragsSocial = Apollo.GetAddon("ViragsSocial")

local kBarrensChatChannelName = "VSocialChat"

function ViragsSocial:SetBarrensChatState()
    --[[ -- todo uncoment and test with every chat addon
    if self.tSettings.bBarenceChatInactive then
        for k, v in pairs(ChatSystemLib.GetChannels()) do
            if v:GetName() == kBarrensChatChannelName then
                self:ChannelPRINT("You Left " .. kBarrensChatChannelName .. ".", v)
                v:Leave()
                Apollo.RemoveEventHandler("ChatJoin", self)
                return
            end
        end
    else
        local bAlreadyAMember = false
        for k, v in pairs(ChatSystemLib.GetChannels()) do
            if v:GetName() == kBarrensChatChannelName then
                bAlreadyAMember = true

                self:OnChatJoin(v)
            end
        end

        if not bAlreadyAMember then
            Apollo.RegisterEventHandler("ChatJoin", "OnChatJoin", self)
            ChatSystemLib.JoinChannel(kBarrensChatChannelName)
        end

    end
    ]]
end



function ViragsSocial:DisableBarrensChatFiltering()
    -- Hide this Channel from Chat Addons
    local chanType
    for k, v in pairs(ChatSystemLib.GetChannels()) do
        if v:GetName() == kBarrensChatChannelName then
            chanType = v:GetType()
            break
        end
    end

    local chatAddons = {
        "ChatLog",
        "BetterChatLog",
        "ChatFixed"
    }
    for k, v in pairs(chatAddons) do
        local chatAddon = Apollo.GetAddon(v)
        if chatAddon and chatAddon.tChatWindows then
            chatAddon.tAllViewedChannels[chanType] = true
            for key, wndChat in pairs(chatAddon.tChatWindows) do
                self:DEBUG("wndChat:GetData()", wndChat:GetData())
                if not wndChat:GetData().tViewedChannels[chanType] then -- check flags for filtering
                    wndChat:GetData().tViewedChannels[chanType] = true
                end
            end
            chatAddon = nil
        end
    end
end


function ViragsSocial:OnChatJoin(channelJoined)
    self:DEBUG("channelJoined", channelJoined)
    if channelJoined:GetName() == kBarrensChatChannelName then

        self:DisableBarrensChatFiltering()
        local commandTxt = " /" .. channelJoined:GetCommand() or ""
        self:ChannelPRINT("You Joined " .. kBarrensChatChannelName .. "! Global single-faction channel. Use" .. commandTxt .. " to type here. Can disable auto-join in settings. ", channelJoined)
    end
end

