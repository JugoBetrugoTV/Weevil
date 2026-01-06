--[[
    Weevil Multi-Gamemode - Stuntage
    Server-side - Complete stunts around San Andreas
]]

local GAMEMODE = "stuntage"
local stuntageData = {
    players = {},
    stunts = {},
    state = "waiting"
}

-- Example stunts (positions around San Andreas)
local STUNTS = {
    { name = "Chiliad Jump", x = -2327, y = -1602, z = 484, radius = 5, points = 50 },
    { name = "LS Airport Gap", x = 1943, y = -2307, z = 14, radius = 5, points = 30 },
    { name = "Vinewood Sign", x = 1524, y = -892, z = 50, radius = 5, points = 40 },
    { name = "LV Strip Jump", x = 2193, y = 1677, z = 12, radius = 5, points = 25 },
    { name = "SF Bridge Dive", x = -2669, y = 1530, z = 220, radius = 10, points = 75 }
}

addEventHandler("onResourceStart", resourceRoot, function()
    stuntageData.stunts = STUNTS
    outputDebugString("[Weevil Stuntage] Stuntage gamemode initialized with " .. #STUNTS .. " stunts")
end)

-- Player joins Stuntage
addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local player = source
    stuntageData.players[player] = {
        completedStunts = {},
        score = 0
    }

    -- Send stunt data
    triggerClientEvent(player, "weevil:stuntage:loadStunts", player, STUNTS)

    outputChatBox("#FFFF44[Stuntage] #FFFFFFWelcome to Stuntage! Find and complete stunts around San Andreas.", player, 255, 255, 255, true)
    outputChatBox("#FFFF44[Stuntage] #FFFFFFTotal stunts available: " .. #STUNTS, player, 255, 255, 255, true)
end)

-- Player leaves Stuntage
addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    stuntageData.players[source] = nil
end)

-- Handle stunt completion
addEvent("weevil:stuntage:complete", true)
addEventHandler("weevil:stuntage:complete", root, function(stuntIndex)
    local player = client
    if not stuntageData.players[player] then return end

    local stunt = STUNTS[stuntIndex]
    if not stunt then return end

    -- Check if already completed
    if stuntageData.players[player].completedStunts[stuntIndex] then
        outputChatBox("#FFFF44[Stuntage] #FFFFFFYou already completed this stunt!", player, 255, 255, 255, true)
        return
    end

    stuntageData.players[player].completedStunts[stuntIndex] = true
    stuntageData.players[player].score = stuntageData.players[player].score + stunt.points

    exports.weevil_core:addPlayerPoints(player, stunt.points, GAMEMODE)
    exports.weevil_core:addPlayerMoney(player, stunt.points * 2, "Stunt: " .. stunt.name)

    outputChatBox("#FFFF44[Stuntage] #00FF00" .. stunt.name .. " completed! #FFFFFF+" .. stunt.points .. " points", player, 255, 255, 255, true)

    -- Announce to others
    for p, _ in pairs(stuntageData.players) do
        if p ~= player then
            outputChatBox("#FFFF44[Stuntage] #FFFFFF" .. getPlayerName(player) .. " completed " .. stunt.name .. "!", p, 255, 255, 255, true)
        end
    end

    -- Check achievements
    local completedCount = 0
    for _ in pairs(stuntageData.players[player].completedStunts) do
        completedCount = completedCount + 1
    end

    if completedCount >= 100 then
        exports.weevil_achievements:unlockAchievement(player, "stunt_100")
    end
end)

-- Spawn player
function spawnStuntagePlayer(player)
    if not stuntageData.players[player] then return end

    -- Spawn at random location
    local spawn = { x = 0, y = 0, z = 10 }

    spawnPlayer(player, spawn.x, spawn.y, spawn.z)
    setElementDimension(player, Config.Gamemodes.stuntage.dimension)

    -- Give vehicle
    local vehicle = createVehicle(411, spawn.x, spawn.y, spawn.z + 2) -- Infernus
    setElementDimension(vehicle, Config.Gamemodes.stuntage.dimension)
    warpPedIntoVehicle(player, vehicle)
end

addEventHandler("weevil:roundStarted", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    stuntageData.state = "playing"

    for player, data in pairs(stuntageData.players) do
        spawnStuntagePlayer(player)
    end
end)
