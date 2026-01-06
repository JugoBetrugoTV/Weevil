--[[
    Jebiga Multi-Gamemode - Run Arena
    On-foot racing with combat - Race while fighting!
]]

local GAMEMODE = "runarena"
local runData = {
    players = {},
    checkpoints = {},
    state = "waiting"
}

local WEAPONS = {
    { id = 24, ammo = 50 }, -- Desert Eagle
    { id = 22, ammo = 100 } -- Pistol
}

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[Jebiga Run] Run Arena gamemode initialized")
end)

addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    runData.players[source] = {
        checkpoint = 0,
        kills = 0,
        deaths = 0,
        finished = false
    }

    outputChatBox("#FF8888[Run] #FFFFFFWelcome to Run Arena! Race on foot while fighting opponents.", source, 255, 255, 255, true)
end)

addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    runData.players[source] = nil
end)

function spawnRunPlayer(player)
    local spawn = { x = math.random(-10, 10), y = math.random(-10, 10), z = 5 }

    spawnPlayer(player, spawn.x, spawn.y, spawn.z)
    setElementDimension(player, Config.Gamemodes.runarena.dimension)
    setElementHealth(player, 100)
    setPedArmor(player, 50)

    for _, weapon in ipairs(WEAPONS) do
        giveWeapon(player, weapon.id, weapon.ammo)
    end
end

addEventHandler("onPlayerWasted", root, function(ammo, killer, weapon, bodypart)
    local player = source
    if not runData.players[player] then return end

    runData.players[player].deaths = runData.players[player].deaths + 1
    exports.jebiga_core:addPlayerDeath(player, GAMEMODE)

    if killer and isElement(killer) and killer ~= player and runData.players[killer] then
        runData.players[killer].kills = runData.players[killer].kills + 1
        exports.jebiga_core:addPlayerKill(killer, GAMEMODE)
    end

    setTimer(function()
        if isElement(player) and runData.players[player] and runData.state == "playing" then
            spawnRunPlayer(player)
        end
    end, 3000, 1)
end)

addEvent("weevil:run:checkpoint", true)
addEventHandler("weevil:run:checkpoint", root, function(index)
    local player = client
    if not runData.players[player] then return end

    if index == runData.players[player].checkpoint + 1 then
        runData.players[player].checkpoint = index

        if index >= #runData.checkpoints then
            runData.players[player].finished = true
            exports.jebiga_core:addPlayerFinish(player, GAMEMODE, getTickCount() - (runData.roundStartTime or 0))

            for p, _ in pairs(runData.players) do
                outputChatBox("#FF8888[Run] #00FF00" .. getPlayerName(player) .. " #FFFFFFfinished!", p, 255, 255, 255, true)
            end
        end
    end
end)

addEventHandler("weevil:roundStarted", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    runData.state = "playing"
    runData.roundStartTime = getTickCount()

    for player, data in pairs(runData.players) do
        data.checkpoint = 0
        data.kills = 0
        data.deaths = 0
        data.finished = false
        spawnRunPlayer(player)
    end
end)
