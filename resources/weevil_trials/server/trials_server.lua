--[[
    Weevil Multi-Gamemode - Trials
    Server-side - Motorbike obstacle courses
]]

local GAMEMODE = "trials"
local trialsData = {
    players = {},
    checkpoints = {},
    state = "waiting",
    roundStartTime = nil
}

local MOTORBIKE_ID = 522 -- NRG-500

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[Weevil Trials] Trials gamemode initialized")
end)

-- Player joins Trials
addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local player = source
    trialsData.players[player] = {
        checkpoint = 0,
        falls = 0,
        finished = false,
        vehicle = nil
    }

    outputChatBox("#44FFFF[Trials] #FFFFFFWelcome to Trials! Navigate the obstacle course on your bike.", player, 255, 255, 255, true)
end)

-- Player leaves Trials
addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local data = trialsData.players[source]
    if data and data.vehicle and isElement(data.vehicle) then
        destroyElement(data.vehicle)
    end

    trialsData.players[source] = nil
end)

-- Spawn player on motorbike
function spawnTrialsPlayer(player)
    if not trialsData.players[player] then return end

    local spawn = { x = 0, y = 0, z = 10 }

    -- Create motorbike
    local vehicle = createVehicle(MOTORBIKE_ID, spawn.x, spawn.y, spawn.z)
    setElementDimension(vehicle, Config.Gamemodes.trials.dimension)

    spawnPlayer(player, spawn.x, spawn.y, spawn.z + 2)
    setElementDimension(player, Config.Gamemodes.trials.dimension)
    warpPedIntoVehicle(player, vehicle)

    trialsData.players[player].vehicle = vehicle
end

-- Handle checkpoint
addEvent("weevil:trials:checkpointHit", true)
addEventHandler("weevil:trials:checkpointHit", root, function(checkpointIndex)
    local player = client
    if not trialsData.players[player] then return end

    local currentCP = trialsData.players[player].checkpoint

    if checkpointIndex == currentCP + 1 then
        trialsData.players[player].checkpoint = checkpointIndex

        local totalCheckpoints = #trialsData.checkpoints
        if checkpointIndex >= totalCheckpoints then
            playerFinished(player)
        else
            triggerClientEvent(player, "weevil:trials:nextCheckpoint", player, checkpointIndex + 1)
        end
    end
end)

-- Handle player fall/reset
addEvent("weevil:trials:fell", true)
addEventHandler("weevil:trials:fell", root, function()
    local player = client
    if not trialsData.players[player] then return end

    trialsData.players[player].falls = trialsData.players[player].falls + 1

    -- Respawn at last checkpoint
    local cpIndex = trialsData.players[player].checkpoint
    local respawnPos = cpIndex > 0 and trialsData.checkpoints[cpIndex] or { x = 0, y = 0, z = 10 }

    -- Destroy old vehicle
    if trialsData.players[player].vehicle and isElement(trialsData.players[player].vehicle) then
        destroyElement(trialsData.players[player].vehicle)
    end

    -- Create new vehicle
    local vehicle = createVehicle(MOTORBIKE_ID, respawnPos.x, respawnPos.y, respawnPos.z + 2)
    setElementDimension(vehicle, Config.Gamemodes.trials.dimension)
    warpPedIntoVehicle(player, vehicle)

    trialsData.players[player].vehicle = vehicle

    outputChatBox("#44FFFF[Trials] #FFFFFFRespawned at checkpoint " .. cpIndex .. " (Falls: " .. trialsData.players[player].falls .. ")", player, 255, 255, 255, true)
end)

-- Player finished
function playerFinished(player)
    if not trialsData.players[player] or trialsData.players[player].finished then return end

    trialsData.players[player].finished = true

    local finishTime = getTickCount() - (trialsData.roundStartTime or getTickCount())
    local falls = trialsData.players[player].falls

    exports.weevil_core:addPlayerFinish(player, GAMEMODE, finishTime)

    for p, _ in pairs(trialsData.players) do
        outputChatBox("#44FFFF[Trials] #00FF00" .. getPlayerName(player) .. " #FFFFFFfinished! Time: " .. Utils.formatTime(finishTime) .. " (Falls: " .. falls .. ")", p, 255, 255, 255, true)
    end
end

-- Round started
addEventHandler("weevil:roundStarted", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    trialsData.state = "playing"
    trialsData.roundStartTime = getTickCount()

    for player, data in pairs(trialsData.players) do
        data.checkpoint = 0
        data.falls = 0
        data.finished = false
        spawnTrialsPlayer(player)
    end
end)

-- Round ended
addEventHandler("weevil:roundEnded", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    trialsData.state = "waiting"

    for player, data in pairs(trialsData.players) do
        if data.vehicle and isElement(data.vehicle) then
            destroyElement(data.vehicle)
            data.vehicle = nil
        end
    end
end)
