--[[
    Jebiga Multi-Gamemode - Private Messages System
    Uses centralized MySQL database from jebiga_core
]]

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

    -- Check if target allows PMs
    local targetSettings = getElementData(target, "jebiga:settings")
    if targetSettings and targetSettings.allowPM == false then
        outputChatBox("#E74C3C[PM] #FFFFFFThis player has disabled private messages!", player, 255, 255, 255, true)
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

    -- Save to database
    savePMToDatabase(sender, receiver, message)

    -- Log
    outputDebugString("[Jebiga PM] " .. senderName .. " -> " .. receiverName .. ": " .. message)
end

function savePMToDatabase(sender, receiver, message)
    local senderAccountId = getElementData(sender, "jebiga:accountId")
    local receiverAccountId = getElementData(receiver, "jebiga:accountId")

    if senderAccountId and receiverAccountId then
        exports.jebiga_core:db_execute(
            "INSERT INTO private_messages (sender_id, receiver_id, message) VALUES (?, ?, ?)",
            senderAccountId, receiverAccountId, message
        )
    end
end

-- Get PM history (for future panel use)
function getPlayerPMHistory(player, limit)
    local accountId = getElementData(player, "jebiga:accountId")
    if not accountId then return {} end

    limit = limit or 50

    return exports.jebiga_core:db_fetchAll(
        "SELECT pm.*, " ..
        "s.username as sender_name, r.username as receiver_name " ..
        "FROM private_messages pm " ..
        "JOIN accounts s ON pm.sender_id = s.id " ..
        "JOIN accounts r ON pm.receiver_id = r.id " ..
        "WHERE pm.sender_id = ? OR pm.receiver_id = ? " ..
        "ORDER BY pm.created_at DESC LIMIT ?",
        accountId, accountId, limit
    ) or {}
end

-- Mark messages as read
function markMessagesAsRead(player, senderId)
    local accountId = getElementData(player, "jebiga:accountId")
    if not accountId then return end

    exports.jebiga_core:db_execute(
        "UPDATE private_messages SET read_at = NOW() WHERE receiver_id = ? AND sender_id = ? AND read_at IS NULL",
        accountId, senderId
    )
end

-- Get unread message count
function getUnreadMessageCount(player)
    local accountId = getElementData(player, "jebiga:accountId")
    if not accountId then return 0 end

    local result = exports.jebiga_core:db_fetchOne(
        "SELECT COUNT(*) as count FROM private_messages WHERE receiver_id = ? AND read_at IS NULL",
        accountId
    )

    return result and result.count or 0
end

-- Cleanup
addEventHandler("onPlayerQuit", root, function()
    local serial = getPlayerSerial(source)
    lastReply[serial] = nil
end)

-- ============================================
-- EXPORTS
-- ============================================

_G.getPlayerPMHistory = getPlayerPMHistory
_G.getUnreadMessageCount = getUnreadMessageCount
