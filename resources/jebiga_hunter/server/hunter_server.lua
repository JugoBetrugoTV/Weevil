--[[
    Jebiga Multi-Gamemode - Hunter (Helicopter Combat)
    Server-side Hunter gamemode - Combat helicopter battles
]]

local GAMEMODE = "hunter"
local hunterData = {
    players = {},
    state = "waiting"
}

local SPAWN_HEIGHT = 200
local ARENA_CENTER = { x = 0, y = 0, z = SPAWN_HEIGHT }
local ARENA_RADIUS = 500

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[Jebiga Hunter] Hunter gamemode initialized")
end)

-- Player joins Hunter
addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local player = source
    hunterData.players[player] = {
        alive = true,
        kills = 0,
        deaths = 0,
        vehicle = nil
    }

    outputChatBox("#4488FF[Hunter] #FFFFFFWelcome to Hunter! Destroy all enemy helicopters.", player, 255, 255, 255, true)
end)

-- Player leaves Hunter
addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local data = hunterData.players[source]
    if data and data.vehicle and isElement(data.vehicle) then
        destroyElement(data.vehicle)
    end

    hunterData.players[source] = nil
    checkWinner()
end)

-- Spawn player in Hunter helicopter
function spawnHunterPlayer(player)
    if not hunterData.players[player] then return end

    -- Random spawn position around arena
    local angle = math.rad(math.random(0, 360))
    local distance = math.random(100, ARENA_RADIUS - 100)
    local x = ARENA_CENTER.x + math.cos(angle) * distance
    local y = ARENA_CENTER.y + math.sin(angle) * distance
    local z = SPAWN_HEIGHT + math.random(-20, 20)

    -- Create Hunter helicopter
    local vehicle = createVehicle(425, x, y, z, 0, 0, math.deg(angle) + 180)
    setElementDimension(vehicle, Config.Gamemodes.hunter.dimension)

    -- Spawn player
    spawnPlayer(player, x, y, z + 2)
    setElementDimension(player, Config.Gamemodes.hunter.dimension)
    warpPedIntoVehicle(player, vehicle)

    hunterData.players[player].vehicle = vehicle
    hunterData.players[player].alive = true
end

-- Handle vehicle explosion
addEventHandler("onVehicleExplode", root, function()
    local vehicle = source
    if getElementDimension(vehicle) ~= Config.Gamemodes.hunter.dimension then return end

    local occupant = getVehicleOccupant(vehicle)
    if occupant and hunterData.players[occupant] then
        eliminatePlayer(occupant, getElementData(vehicle, "lastAttacker"))
    end
end)

-- Eliminate player
function eliminatePlayer(player, killer)
    if not hunterData.players[player] then return end

    hunterData.players[player].alive = false
    hunterData.players[player].deaths = hunterData.players[player].deaths + 1

    exports.jebiga_core:addPlayerDeath(player, GAMEMODE)

    -- Award killer
    if killer and isElement(killer) and killer ~= player and hunterData.players[killer] then
        hunterData.players[killer].kills = hunterData.players[killer].kills + 1
        exports.jebiga_core:addPlayerKill(killer, GAMEMODE)

        for p, _ in pairs(hunterData.players) do
            outputChatBox("#4488FF[Hunter] #FFFFFF" .. getPlayerName(killer) .. " shot down " .. getPlayerName(player) .. "!", p, 255, 255, 255, true)
        end
    else
        for p, _ in pairs(hunterData.players) do
            outputChatBox("#4488FF[Hunter] #FFFFFF" .. getPlayerName(player) .. " was destroyed!", p, 255, 255, 255, true)
        end
    end

    setElementData(player, "eliminated", true)

    checkWinner()
end

-- Check for winner
function checkWinner()
    local alivePlayers = {}

    for player, data in pairs(hunterData.players) do
        if isElement(player) and data.alive then
            table.insert(alivePlayers, player)
        end
    end

    if #alivePlayers <= 1 then
        local winner = alivePlayers[1]
        if winner then
            exports.jebiga_core:addPlayerWin(winner, GAMEMODE)

            for p, _ in pairs(hunterData.players) do
                outputChatBox("#4488FF[Hunter] #00FF00" .. getPlayerName(winner) .. " #FFFFFFwins the Hunter battle!", p, 255, 255, 255, true)
            end

            -- Check achievement
            local data = hunterData.players[winner]
            if data and data.deaths == 0 then
                exports.jebiga_achievements:unlockAchievement(winner, "hunter_ace")
            end
        end

        triggerEvent("weevil:roundEnded", root, GAMEMODE, nil)
    end
end

-- Track projectile hits
addEventHandler("onPlayerWeaponFire", root, function(weapon, ammo, ammoInClip, hitX, hitY, hitZ, hitElement)
    if not hunterData.players[source] then return end

    if hitElement and getElementType(hitElement) == "vehicle" then
        setElementData(hitElement, "lastAttacker", source)
    end
end)

-- Round started
addEventHandler("weevil:roundStarted", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    hunterData.state = "playing"

    for player, data in pairs(hunterData.players) do
        spawnHunterPlayer(player)
        removeElementData(player, "eliminated")
    end
end)

-- Round ended - cleanup
addEventHandler("weevil:roundEnded", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    hunterData.state = "waiting"

    for player, data in pairs(hunterData.players) do
        if data.vehicle and isElement(data.vehicle) then
            destroyElement(data.vehicle)
            data.vehicle = nil
        end
    end
end)
