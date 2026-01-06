--[[
    Weevil Multi-Gamemode - DD (Destruction Derby)
    Server-side DD gamemode - Last vehicle standing wins
]]

local GAMEMODE = "dd"
local ddData = {
    players = {},
    alivePlayers = {},
    state = "waiting"
}

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[Weevil DD] Destruction Derby gamemode initialized")
end)

-- Player joins DD
addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local player = source
    ddData.players[player] = {
        alive = true,
        kills = 0,
        eliminated = false
    }

    outputChatBox("#FF8844[DD] #FFFFFFWelcome to Destruction Derby! Be the last one standing.", player, 255, 255, 255, true)
end)

-- Player leaves DD
addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    ddData.players[source] = nil
    checkWinner()
end)

-- Handle vehicle explosion
addEventHandler("onVehicleExplode", root, function()
    local vehicle = source
    if getElementDimension(vehicle) ~= Config.Gamemodes.dd.dimension then return end

    local occupant = getVehicleOccupant(vehicle)
    if occupant and ddData.players[occupant] then
        eliminatePlayer(occupant, getElementData(vehicle, "lastDamager"))
    end
end)

-- Handle player falling (out of map)
addEvent("weevil:dd:playerFell", true)
addEventHandler("weevil:dd:playerFell", root, function()
    local player = client
    if ddData.players[player] and ddData.players[player].alive then
        eliminatePlayer(player, nil)
    end
end)

-- Eliminate player
function eliminatePlayer(player, killer)
    if not ddData.players[player] or ddData.players[player].eliminated then return end

    ddData.players[player].alive = false
    ddData.players[player].eliminated = true

    exports.weevil_core:addPlayerElimination(player, GAMEMODE, killer)

    -- Award killer
    if killer and isElement(killer) and killer ~= player and ddData.players[killer] then
        ddData.players[killer].kills = ddData.players[killer].kills + 1
        exports.weevil_core:addPlayerKill(killer, GAMEMODE)

        for p, _ in pairs(ddData.players) do
            outputChatBox("#FF8844[DD] #FFFFFF" .. getPlayerName(killer) .. " eliminated " .. getPlayerName(player) .. "!", p, 255, 255, 255, true)
        end
    else
        for p, _ in pairs(ddData.players) do
            outputChatBox("#FF8844[DD] #FFFFFF" .. getPlayerName(player) .. " was eliminated!", p, 255, 255, 255, true)
        end
    end

    -- Set spectating
    setElementData(player, "eliminated", true)
    triggerClientEvent(player, "weevil:dd:eliminated", player)

    checkWinner()
end

-- Check for winner
function checkWinner()
    local alivePlayers = {}

    for player, data in pairs(ddData.players) do
        if isElement(player) and data.alive and not data.eliminated then
            table.insert(alivePlayers, player)
        end
    end

    if #alivePlayers <= 1 then
        local winner = alivePlayers[1]
        if winner then
            exports.weevil_core:addPlayerWin(winner, GAMEMODE)

            for p, _ in pairs(ddData.players) do
                outputChatBox("#FF8844[DD] #00FF00" .. getPlayerName(winner) .. " #FFFFFFwins the Destruction Derby!", p, 255, 255, 255, true)
            end
        end

        -- End round
        triggerEvent("weevil:roundEnded", root, GAMEMODE, nil)
    end
end

-- Round started
addEventHandler("weevil:roundStarted", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    ddData.state = "playing"

    for player, data in pairs(ddData.players) do
        data.alive = true
        data.kills = 0
        data.eliminated = false
        removeElementData(player, "eliminated")
    end
end)

-- Track vehicle damage for kill credit
addEventHandler("onVehicleDamage", root, function(loss)
    local vehicle = source
    if getElementDimension(vehicle) ~= Config.Gamemodes.dd.dimension then return end

    -- Find attacker (nearest vehicle)
    local x, y, z = getElementPosition(vehicle)
    local nearestPlayer = nil
    local nearestDist = 20

    for player, _ in pairs(ddData.players) do
        if isElement(player) and player ~= getVehicleOccupant(vehicle) then
            local pVeh = getPedOccupiedVehicle(player)
            if pVeh then
                local px, py, pz = getElementPosition(pVeh)
                local dist = getDistanceBetweenPoints3D(x, y, z, px, py, pz)
                if dist < nearestDist then
                    nearestDist = dist
                    nearestPlayer = player
                end
            end
        end
    end

    if nearestPlayer then
        setElementData(vehicle, "lastDamager", nearestPlayer)
    end
end)
