--[[
    Jebiga Multi-Gamemode - Private Messages System
]]

local pmHistory = {} -- player serial -> {messages}
local lastReply = {} -- player serial -> last PM sender serial

addCommandHandler("pm", function(player, cmd, targetName, ...)
    if not targetName then
        outputChatBox("#E74C3C[PM] #FFFFFFUsage: /pm [player] [message]", player, 255, 255, 255, true)
        return
    end

    local message = table.concat({...}, " ")
    if message == "" then
        outputChatBox("#E74C3C[PM] #FFFFFFPlease enter a message!", player, 255, 255, 255, true)
        return
    end

    local target = getPlayerFromName(targetName)
    if not target then
        -- Try partial match
        for _, p in ipairs(getElementsByType("player")) do
            if getPlayerName(p):lower():find(targetName:lower(), 1, true) then
                target = p
                break
            end
        end
    end

    if not target then
        outputChatBox("#E74C3C[PM] #FFFFFFPlayer not found!", player, 255, 255, 255, true)
        return
    end

    if target == player then
        outputChatBox("#E74C3C[PM] #FFFFFFYou can't PM yourself!", player, 255, 255, 255, true)
        return
    end

    -- Send PM
    sendPM(player, target, message)
end)

addCommandHandler("r", function(player, cmd, ...)
    local message = table.concat({...}, " ")
    if message == "" then
        outputChatBox("#E74C3C[PM] #FFFFFFUsage: /r [message]", player, 255, 255, 255, true)
        return
    end

    local mySerial = getPlayerSerial(player)
    local targetSerial = lastReply[mySerial]

    if not targetSerial then
        outputChatBox("#E74C3C[PM] #FFFFFFNo one to reply to!", player, 255, 255, 255, true)
        return
    end

    -- Find player by serial
    local target = nil
    for _, p in ipairs(getElementsByType("player")) do
        if getPlayerSerial(p) == targetSerial then
            target = p
            break
        end
    end

    if not target then
        outputChatBox("#E74C3C[PM] #FFFFFFPlayer is no longer online!", player, 255, 255, 255, true)
        return
    end

    sendPM(player, target, message)
end)

function sendPM(sender, receiver, message)
    local senderName = getPlayerName(sender)
    local receiverName = getPlayerName(receiver)

    -- Send to receiver
    outputChatBox("#9B59B6[PM] #FFFFFFFrom #2980B9" .. senderName .. "#FFFFFF: " .. message, receiver, 255, 255, 255, true)
    triggerClientEvent(receiver, "jebiga:pm:received", resourceRoot, senderName, message)

    -- Confirm to sender
    outputChatBox("#9B59B6[PM] #FFFFFFTo #2980B9" .. receiverName .. "#FFFFFF: " .. message, sender, 255, 255, 255, true)

    -- Save for reply
    local senderSerial = getPlayerSerial(sender)
    local receiverSerial = getPlayerSerial(receiver)
    lastReply[receiverSerial] = senderSerial

    -- Log
    outputDebugString("[Jebiga PM] " .. senderName .. " -> " .. receiverName .. ": " .. message)
end

-- Cleanup
addEventHandler("onPlayerQuit", root, function()
    local serial = getPlayerSerial(source)
    lastReply[serial] = nil
end)
