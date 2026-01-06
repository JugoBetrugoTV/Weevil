--[[
    Weevil Multi-Gamemode - Race (Oldschool)
    Server-side Race gamemode logic - Classic racing without weapons
]]

local GAMEMODE = "race"
local raceData = {
    players = {},
    checkpoints = {},
    currentMap = nil,
    state = "waiting",
    roundStartTime = nil
}

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[Weevil Race] Oldschool Race gamemode initialized")
end)

-- Player joins Race
addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local player = source
    raceData.players[player] = {
        checkpoint = 0,
        lapTime = 0,
        finished = false,
        position = 0
    }

    outputChatBox("#44FF44[Race] #FFFFFFWelcome to Oldschool Racing! Be the first to finish.", player, 255, 255, 255, true)
end)

-- Player leaves Race
addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    raceData.players[source] = nil
end)

-- Handle checkpoint hit
addEvent("weevil:race:checkpointHit", true)
addEventHandler("weevil:race:checkpointHit", root, function(checkpointIndex)
    local player = client
    if not raceData.players[player] then return end

    local currentCP = raceData.players[player].checkpoint

    if checkpointIndex == currentCP + 1 then
        raceData.players[player].checkpoint = checkpointIndex

        local totalCheckpoints = #raceData.checkpoints
        if checkpointIndex >= totalCheckpoints then
            playerFinished(player)
        else
            triggerClientEvent(player, "weevil:race:nextCheckpoint", player, checkpointIndex + 1)
        end
    end
end)

-- Player finished
function playerFinished(player)
    if not raceData.players[player] or raceData.players[player].finished then return end

    raceData.players[player].finished = true

    local finishTime = getTickCount() - (raceData.roundStartTime or getTickCount())
    raceData.players[player].lapTime = finishTime

    -- Calculate position
    local position = 1
    for p, data in pairs(raceData.players) do
        if data.finished and data.lapTime < finishTime then
            position = position + 1
        end
    end
    raceData.players[player].position = position

    exports.weevil_core:addPlayerFinish(player, GAMEMODE, finishTime)

    -- Try to add top time
    if raceData.currentMap then
        exports.weevil_toptimes:addTopTime(player, raceData.currentMap, GAMEMODE, finishTime, nil)
    end

    local posStr = Utils.getOrdinal(position)
    for p, _ in pairs(raceData.players) do
        outputChatBox("#44FF44[Race] #00FF00" .. getPlayerName(player) .. " #FFFFFFfinished " .. posStr .. "! Time: " .. Utils.formatTime(finishTime), p, 255, 255, 255, true)
    end
end

-- Round handlers
addEventHandler("weevil:roundStarted", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    raceData.roundStartTime = getTickCount()
    raceData.state = "playing"

    for player, data in pairs(raceData.players) do
        data.checkpoint = 0
        data.lapTime = 0
        data.finished = false
        data.position = 0
    end
end)

addEventHandler("weevil:roundEnded", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    raceData.state = "waiting"
end)
