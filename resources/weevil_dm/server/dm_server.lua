--[[
    Weevil Multi-Gamemode - DM (Deathmatch Race)
    Server-side DM gamemode logic
]]

local GAMEMODE = "dm"
local dmData = {
    players = {},
    checkpoints = {},
    currentMap = nil,
    state = "waiting"
}

-- Initialize DM
addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[Weevil DM] Deathmatch gamemode initialized")
end)

-- Player joins DM
addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local player = source
    dmData.players[player] = {
        checkpoint = 0,
        kills = 0,
        deaths = 0,
        finished = false
    }

    -- Give weapons
    giveWeapon(player, 31, 500) -- M4
    giveWeapon(player, 25, 50)  -- Shotgun
    giveWeapon(player, 24, 100) -- Desert Eagle

    outputChatBox("#FF4444[DM] #FFFFFFWelcome to Deathmatch! Race to the finish while eliminating opponents.", player, 255, 255, 255, true)
end)

-- Player leaves DM
addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    dmData.players[source] = nil
end)

-- Handle player death
addEventHandler("onPlayerWasted", root, function(ammo, killer, weapon, bodypart)
    local player = source
    if not dmData.players[player] then return end

    dmData.players[player].deaths = dmData.players[player].deaths + 1
    exports.weevil_core:addPlayerDeath(player, GAMEMODE)

    -- Award killer
    if killer and isElement(killer) and killer ~= player and dmData.players[killer] then
        dmData.players[killer].kills = dmData.players[killer].kills + 1
        exports.weevil_core:addPlayerKill(killer, GAMEMODE)

        local killMsg = getPlayerName(killer) .. " killed " .. getPlayerName(player)
        if bodypart == 9 then killMsg = killMsg .. " (Headshot!)" end

        for p, _ in pairs(dmData.players) do
            outputChatBox("#FF4444[DM] #FFFFFF" .. killMsg, p, 255, 255, 255, true)
        end
    end

    -- Respawn after delay
    setTimer(function()
        if isElement(player) and dmData.players[player] then
            respawnPlayer(player)
        end
    end, 3000, 1)
end)

-- Respawn player
function respawnPlayer(player)
    if not dmData.players[player] then return end

    local arena = Weevil.arenas[GAMEMODE]
    if not arena or arena.state ~= "playing" then return end

    local spawn = { x = 0, y = 0, z = 10 } -- Default spawn
    exports.weevil_core:spawnPlayerInArena(player, GAMEMODE, spawn)
end

-- Handle checkpoint hit
addEvent("weevil:dm:checkpointHit", true)
addEventHandler("weevil:dm:checkpointHit", root, function(checkpointIndex)
    local player = client
    if not dmData.players[player] then return end

    local currentCP = dmData.players[player].checkpoint

    if checkpointIndex == currentCP + 1 then
        dmData.players[player].checkpoint = checkpointIndex

        -- Check if finished
        local totalCheckpoints = #dmData.checkpoints
        if checkpointIndex >= totalCheckpoints then
            playerFinished(player)
        else
            -- Update next checkpoint
            triggerClientEvent(player, "weevil:dm:nextCheckpoint", player, checkpointIndex + 1)
        end
    end
end)

-- Player finished
function playerFinished(player)
    if not dmData.players[player] or dmData.players[player].finished then return end

    dmData.players[player].finished = true

    local finishTime = getTickCount() - (dmData.roundStartTime or getTickCount())

    exports.weevil_core:addPlayerFinish(player, GAMEMODE, finishTime)

    for p, _ in pairs(dmData.players) do
        outputChatBox("#FF4444[DM] #00FF00" .. getPlayerName(player) .. " #FFFFFFfinished! Time: " .. Utils.formatTime(finishTime), p, 255, 255, 255, true)
    end
end

-- Round started
addEventHandler("weevil:roundStarted", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    dmData.roundStartTime = getTickCount()
    dmData.state = "playing"

    -- Reset player states
    for player, data in pairs(dmData.players) do
        data.checkpoint = 0
        data.kills = 0
        data.deaths = 0
        data.finished = false

        -- Give weapons again
        giveWeapon(player, 31, 500)
        giveWeapon(player, 25, 50)
        giveWeapon(player, 24, 100)
    end
end)

-- Round ended
addEventHandler("weevil:roundEnded", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    dmData.state = "waiting"
end)
