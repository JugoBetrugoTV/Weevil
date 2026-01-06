--[[
    Jebiga Multi-Gamemode - Shooter (FPS Combat)
    Server-side Shooter gamemode - Team or FFA deathmatch
]]

local GAMEMODE = "shooter"
local shooterData = {
    players = {},
    state = "waiting",
    roundTime = 300, -- 5 minutes
    roundStartTime = nil
}

local WEAPONS = {
    { id = 31, ammo = 200 }, -- M4
    { id = 24, ammo = 100 }, -- Desert Eagle
    { id = 25, ammo = 50 },  -- Shotgun
    { id = 34, ammo = 10 },  -- Sniper
    { id = 16, ammo = 5 }    -- Grenade
}

local SPAWN_POINTS = {
    { x = 2495, y = -1670, z = 14 },
    { x = 2505, y = -1680, z = 14 },
    { x = 2485, y = -1660, z = 14 },
    { x = 2515, y = -1670, z = 14 }
}

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[Jebiga Shooter] Shooter gamemode initialized")
end)

-- Player joins Shooter
addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local player = source
    shooterData.players[player] = {
        kills = 0,
        deaths = 0,
        headshots = 0
    }

    outputChatBox("#FF44FF[Shooter] #FFFFFFWelcome to Shooter! Eliminate opponents to score points.", player, 255, 255, 255, true)
end)

-- Player leaves Shooter
addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    shooterData.players[source] = nil
end)

-- Spawn player with weapons
function spawnShooterPlayer(player)
    if not shooterData.players[player] then return end

    local spawn = SPAWN_POINTS[math.random(1, #SPAWN_POINTS)]

    spawnPlayer(player, spawn.x, spawn.y, spawn.z, math.random(0, 360))
    setElementDimension(player, Config.Gamemodes.shooter.dimension)
    setElementHealth(player, 100)
    setPedArmor(player, 100)

    -- Give weapons
    for _, weapon in ipairs(WEAPONS) do
        giveWeapon(player, weapon.id, weapon.ammo)
    end
end

-- Handle player death
addEventHandler("onPlayerWasted", root, function(ammo, killer, weapon, bodypart)
    local player = source
    if not shooterData.players[player] then return end

    shooterData.players[player].deaths = shooterData.players[player].deaths + 1
    exports.jebiga_core:addPlayerDeath(player, GAMEMODE)

    -- Award killer
    if killer and isElement(killer) and killer ~= player and shooterData.players[killer] then
        shooterData.players[killer].kills = shooterData.players[killer].kills + 1
        exports.jebiga_core:addPlayerKill(killer, GAMEMODE)

        local killMsg = getPlayerName(killer) .. " killed " .. getPlayerName(player)

        -- Headshot bonus
        if bodypart == 9 then
            shooterData.players[killer].headshots = shooterData.players[killer].headshots + 1
            killMsg = killMsg .. " (HEADSHOT!)"
            exports.jebiga_core:addPlayerPoints(killer, 2, GAMEMODE) -- Bonus points

            triggerClientEvent(killer, Events.Notification.SHOW_SUCCESS, killer, "Headshot! +2 bonus points", 2000)
        end

        for p, _ in pairs(shooterData.players) do
            outputChatBox("#FF44FF[Shooter] #FFFFFF" .. killMsg, p, 255, 255, 255, true)
        end
    end

    -- Respawn after delay
    setTimer(function()
        if isElement(player) and shooterData.players[player] and shooterData.state == "playing" then
            spawnShooterPlayer(player)
        end
    end, 3000, 1)
end)

-- Round started
addEventHandler("weevil:roundStarted", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    shooterData.state = "playing"
    shooterData.roundStartTime = getTickCount()

    for player, data in pairs(shooterData.players) do
        data.kills = 0
        data.deaths = 0
        data.headshots = 0
        spawnShooterPlayer(player)
    end

    -- Round timer
    setTimer(function()
        if shooterData.state == "playing" then
            endShooterRound()
        end
    end, shooterData.roundTime * 1000, 1)
end)

-- End round and determine winner
function endShooterRound()
    shooterData.state = "ending"

    -- Find winner (most kills)
    local winner = nil
    local maxKills = -1

    for player, data in pairs(shooterData.players) do
        if data.kills > maxKills then
            maxKills = data.kills
            winner = player
        end
    end

    if winner then
        exports.jebiga_core:addPlayerWin(winner, GAMEMODE)

        for p, _ in pairs(shooterData.players) do
            outputChatBox("#FF44FF[Shooter] #00FF00" .. getPlayerName(winner) .. " #FFFFFFwins with " .. maxKills .. " kills!", p, 255, 255, 255, true)
        end
    end

    triggerEvent("weevil:roundEnded", root, GAMEMODE, nil)
end

addEventHandler("weevil:roundEnded", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    shooterData.state = "waiting"
end)
