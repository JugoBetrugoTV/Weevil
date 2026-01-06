--[[
    Jebiga Multi-Gamemode - Anti-spam & Security System
]]

-- Message tracking
local messageHistory = {} -- serial -> {messages}
local warningCount = {} -- serial -> count
local mutedPlayers = {} -- serial -> expiry time

-- Config
local config = {
    maxMessages = 5,         -- Max messages in time window
    timeWindow = 5000,       -- 5 seconds
    similarityThreshold = 0.8,
    muteTime = 60,           -- 60 seconds mute
    maxWarnings = 3,         -- Warnings before auto-mute
    capsThreshold = 0.7,     -- 70% caps = spam
    minMessageLength = 1,
    maxMessageLength = 200,
    blockedWords = {"hack", "cheat", "exploit"} -- Add more as needed
}

-- ============================================
-- CHAT FILTERING
-- ============================================

addEventHandler("onPlayerChat", root, function(message, type)
    local player = source
    local serial = getPlayerSerial(player)

    -- Check if muted
    if mutedPlayers[serial] and mutedPlayers[serial] > getRealTime().timestamp then
        cancelEvent()
        local remaining = mutedPlayers[serial] - getRealTime().timestamp
        outputChatBox("#E74C3C[MUTED] #FFFFFFYou are muted for " .. remaining .. " seconds.", player, 255, 255, 255, true)
        return
    end

    -- Check message length
    if #message < config.minMessageLength then
        cancelEvent()
        return
    end

    if #message > config.maxMessageLength then
        cancelEvent()
        outputChatBox("#E74C3C[CHAT] #FFFFFFMessage too long!", player, 255, 255, 255, true)
        return
    end

    -- Check for spam
    local spamType = detectSpam(player, message)
    if spamType then
        cancelEvent()
        handleSpam(player, spamType)
        return
    end

    -- Check for blocked words
    local blocked = checkBlockedWords(message)
    if blocked then
        cancelEvent()
        outputChatBox("#E74C3C[CHAT] #FFFFFFYour message contains blocked content.", player, 255, 255, 255, true)
        addWarning(player, "blocked_words")
        return
    end

    -- Store message for spam detection
    addMessageToHistory(player, message)
end)

function detectSpam(player, message)
    local serial = getPlayerSerial(player)
    local history = messageHistory[serial] or {}
    local now = getTickCount()

    -- Remove old messages
    for i = #history, 1, -1 do
        if now - history[i].time > config.timeWindow then
            table.remove(history, i)
        end
    end

    -- Check message count
    if #history >= config.maxMessages then
        return "flood"
    end

    -- Check for duplicate messages
    for _, msg in ipairs(history) do
        if calculateSimilarity(message, msg.text) > config.similarityThreshold then
            return "duplicate"
        end
    end

    -- Check for excessive caps
    local caps = 0
    local letters = 0
    for i = 1, #message do
        local c = message:sub(i, i)
        if c:match("%a") then
            letters = letters + 1
            if c:match("%u") then
                caps = caps + 1
            end
        end
    end

    if letters > 5 and caps / letters > config.capsThreshold then
        return "caps"
    end

    return nil
end

function handleSpam(player, spamType)
    local messages = {
        flood = "You are sending messages too fast!",
        duplicate = "Don't repeat messages!",
        caps = "Please don't use excessive caps!"
    }

    outputChatBox("#E74C3C[SPAM] #FFFFFF" .. messages[spamType], player, 255, 255, 255, true)
    addWarning(player, spamType)
end

function addWarning(player, reason)
    local serial = getPlayerSerial(player)
    warningCount[serial] = (warningCount[serial] or 0) + 1

    if warningCount[serial] >= config.maxWarnings then
        mutePlayer(player, config.muteTime, "Automatic: Too many spam warnings")
        warningCount[serial] = 0
    else
        local remaining = config.maxWarnings - warningCount[serial]
        outputChatBox("#F1C40F[WARNING] #FFFFFF" .. remaining .. " warnings remaining before mute.", player, 255, 255, 255, true)
    end
end

function addMessageToHistory(player, message)
    local serial = getPlayerSerial(player)
    if not messageHistory[serial] then
        messageHistory[serial] = {}
    end

    table.insert(messageHistory[serial], {
        text = message,
        time = getTickCount()
    })
end

-- ============================================
-- MUTING
-- ============================================

function mutePlayer(player, duration, reason)
    local serial = getPlayerSerial(player)
    local expiry = getRealTime().timestamp + duration
    mutedPlayers[serial] = expiry

    outputChatBox("#E74C3C[MUTED] #FFFFFFYou have been muted for " .. duration .. " seconds.", player, 255, 255, 255, true)
    if reason then
        outputChatBox("#E74C3C[REASON] #FFFFFF" .. reason, player, 255, 255, 255, true)
    end

    -- Announce
    outputChatBox("#E74C3C[MUTE] #FFFFFF" .. getPlayerName(player) .. " has been muted.", root, 255, 255, 255, true)
end

function unmutePlayer(player)
    local serial = getPlayerSerial(player)
    mutedPlayers[serial] = nil
    outputChatBox("#2ECC71[UNMUTED] #FFFFFFYou have been unmuted.", player, 255, 255, 255, true)
end

-- ============================================
-- UTILITY
-- ============================================

function calculateSimilarity(str1, str2)
    str1 = str1:lower()
    str2 = str2:lower()

    if str1 == str2 then return 1.0 end

    local len1, len2 = #str1, #str2
    if len1 == 0 or len2 == 0 then return 0 end

    local matrix = {}
    for i = 0, len1 do
        matrix[i] = {[0] = i}
    end
    for j = 0, len2 do
        matrix[0][j] = j
    end

    for i = 1, len1 do
        for j = 1, len2 do
            local cost = str1:sub(i, i) == str2:sub(j, j) and 0 or 1
            matrix[i][j] = math.min(
                matrix[i-1][j] + 1,
                matrix[i][j-1] + 1,
                matrix[i-1][j-1] + cost
            )
        end
    end

    local distance = matrix[len1][len2]
    return 1 - (distance / math.max(len1, len2))
end

function checkBlockedWords(message)
    local lower = message:lower()
    for _, word in ipairs(config.blockedWords) do
        if lower:find(word, 1, true) then
            return true
        end
    end
    return false
end

-- ============================================
-- COMMANDS
-- ============================================

addCommandHandler("mute", function(player, cmd, targetName, duration, ...)
    if not hasObjectPermissionTo(player, "command.mute") then
        outputChatBox("#E74C3C[MUTE] #FFFFFFYou don't have permission!", player, 255, 255, 255, true)
        return
    end

    local target = getPlayerFromName(targetName)
    if not target then
        outputChatBox("#E74C3C[MUTE] #FFFFFFPlayer not found!", player, 255, 255, 255, true)
        return
    end

    duration = tonumber(duration) or 60
    local reason = table.concat({...}, " ")

    mutePlayer(target, duration, reason ~= "" and reason or "No reason given")
    outputChatBox("#2980B9[MUTE] #FFFFFFMuted " .. getPlayerName(target) .. " for " .. duration .. " seconds.", player, 255, 255, 255, true)
end)

addCommandHandler("unmute", function(player, cmd, targetName)
    if not hasObjectPermissionTo(player, "command.mute") then
        outputChatBox("#E74C3C[UNMUTE] #FFFFFFYou don't have permission!", player, 255, 255, 255, true)
        return
    end

    local target = getPlayerFromName(targetName)
    if not target then
        outputChatBox("#E74C3C[UNMUTE] #FFFFFFPlayer not found!", player, 255, 255, 255, true)
        return
    end

    unmutePlayer(target)
    outputChatBox("#2980B9[UNMUTE] #FFFFFFUnmuted " .. getPlayerName(target), player, 255, 255, 255, true)
end)

-- ============================================
-- CLEANUP
-- ============================================

addEventHandler("onPlayerQuit", root, function()
    local serial = getPlayerSerial(source)
    messageHistory[serial] = nil
    warningCount[serial] = nil
end)
