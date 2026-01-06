--[[
    Weevil Multi-Gamemode - Training
    Practice your skills without pressure
]]

local GAMEMODE = "training"
local trainingData = {
    players = {}
}

local SPAWN_LOCATION = { x = 0, y = 0, z = 5 }
local AVAILABLE_VEHICLES = { 411, 451, 522, 541, 506, 477, 560, 562, 415, 429 }

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[Weevil Training] Training gamemode initialized")
end)

addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    trainingData.players[source] = {
        vehicle = nil,
        invincible = true
    }

    spawnTrainingPlayer(source)

    outputChatBox("#888888[Training] #FFFFFFWelcome to Training! Practice your skills here.", source, 255, 255, 255, true)
    outputChatBox("#888888[Training] #FFFFFFCommands: /vehicle [id], /repair, /flip, /invincible", source, 255, 255, 255, true)
end)

addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local data = trainingData.players[source]
    if data and data.vehicle and isElement(data.vehicle) then
        destroyElement(data.vehicle)
    end

    trainingData.players[source] = nil
end)

function spawnTrainingPlayer(player)
    local data = trainingData.players[player]
    if not data then return end

    -- Destroy old vehicle
    if data.vehicle and isElement(data.vehicle) then
        destroyElement(data.vehicle)
    end

    local spawn = { x = SPAWN_LOCATION.x + math.random(-20, 20), y = SPAWN_LOCATION.y + math.random(-20, 20), z = SPAWN_LOCATION.z }

    local vehicle = createVehicle(411, spawn.x, spawn.y, spawn.z)
    setElementDimension(vehicle, Config.Gamemodes.training.dimension)

    if data.invincible then
        setVehicleDamageProof(vehicle, true)
    end

    spawnPlayer(player, spawn.x, spawn.y, spawn.z + 2)
    setElementDimension(player, Config.Gamemodes.training.dimension)
    warpPedIntoVehicle(player, vehicle)

    data.vehicle = vehicle
end

-- Training commands
addCommandHandler("vehicle", function(player, cmd, vehicleId)
    if not trainingData.players[player] then return end

    vehicleId = tonumber(vehicleId)
    if not vehicleId or vehicleId < 400 or vehicleId > 611 then
        outputChatBox("Invalid vehicle ID (400-611)", player, 255, 0, 0)
        return
    end

    local data = trainingData.players[player]
    local x, y, z = getElementPosition(player)

    if data.vehicle and isElement(data.vehicle) then
        destroyElement(data.vehicle)
    end

    local vehicle = createVehicle(vehicleId, x, y, z + 2)
    setElementDimension(vehicle, Config.Gamemodes.training.dimension)

    if data.invincible then
        setVehicleDamageProof(vehicle, true)
    end

    warpPedIntoVehicle(player, vehicle)
    data.vehicle = vehicle

    outputChatBox("#888888[Training] #FFFFFFVehicle changed!", player, 255, 255, 255, true)
end)

addCommandHandler("repair", function(player)
    if not trainingData.players[player] then return end

    local vehicle = getPedOccupiedVehicle(player)
    if vehicle then
        fixVehicle(vehicle)
        outputChatBox("#888888[Training] #FFFFFFVehicle repaired!", player, 255, 255, 255, true)
    end
end)

addCommandHandler("flip", function(player)
    if not trainingData.players[player] then return end

    local vehicle = getPedOccupiedVehicle(player)
    if vehicle then
        local x, y, z = getElementPosition(vehicle)
        setElementPosition(vehicle, x, y, z + 2)
        setElementRotation(vehicle, 0, 0, 0)
        outputChatBox("#888888[Training] #FFFFFFVehicle flipped!", player, 255, 255, 255, true)
    end
end)

addCommandHandler("invincible", function(player)
    local data = trainingData.players[player]
    if not data then return end

    data.invincible = not data.invincible

    local vehicle = getPedOccupiedVehicle(player)
    if vehicle then
        setVehicleDamageProof(vehicle, data.invincible)
    end

    outputChatBox("#888888[Training] #FFFFFFInvincibility " .. (data.invincible and "enabled" or "disabled"), player, 255, 255, 255, true)
end)
