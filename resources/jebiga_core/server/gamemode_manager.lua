--[[
    Jebiga Multi-Gamemode - Gamemode Manager
    Manages gamemode states, rounds, and transitions
]]

local gamemodeTimers = {}
local roundData = {}

-- Initialize gamemode
function initializeGamemode(gamemode)
    if not Jebiga.arenas[gamemode] then return false end

    roundData[gamemode] = {
        state = "waiting",
        currentMap = nil,
        mapStartTime = nil,
        rankings = {},
        votes = {},
        votingMaps = {}
    }

    return true
end

-- Start countdown for gamemode
function startGamemodeCountdown(gamemode)
    local arena = Jebiga.arenas[gamemode]
    if not arena then return false end

    local cfg = Config.Gamemodes[gamemode]
    if #arena.players < cfg.minPlayers then
        broadcastToGamemode(gamemode, "#FFFF00[Arena] #FFFFFFWaiting for more players... (" .. #arena.players .. "/" .. cfg.minPlayers .. ")")
        return false
    end

    arena.state = "countdown"
    roundData[gamemode].state = "countdown"

    local countdown = Config.Arena.countdownTime

    -- Countdown timer
    gamemodeTimers[gamemode .. "_countdown"] = setTimer(function()
        countdown = countdown - 1

        if countdown > 0 then
            -- Send countdown to clients
            for _, player in ipairs(arena.players) do
                triggerClientEvent(player, Events.Arena.COUNTDOWN, player, countdown)
            end

            if countdown <= 5 then
                broadcastToGamemode(gamemode, "#FFFF00[Arena] #FFFFFFStarting in " .. countdown .. "...")
            end
        else
            -- Kill countdown timer
            if isTimer(gamemodeTimers[gamemode .. "_countdown"]) then
                killTimer(gamemodeTimers[gamemode .. "_countdown"])
            end

            -- Start the round
            startGamemodeRound(gamemode)
        end
    end, 1000, countdown + 1)

    return true
end

-- Start gamemode round
function startGamemodeRound(gamemode)
    local arena = Jebiga.arenas[gamemode]
    if not arena then return false end

    arena.state = "playing"
    roundData[gamemode].state = "playing"
    roundData[gamemode].mapStartTime = getTickCount()
    roundData[gamemode].rankings = {}

    -- Spawn all players
    local spawnPoints = getMapSpawnPoints(gamemode)
    for i, player in ipairs(arena.players) do
        local spawn = spawnPoints[i] or spawnPoints[1]
        spawnPlayerInArena(player, gamemode, spawn)
    end

    -- Notify clients
    for _, player in ipairs(arena.players) do
        triggerClientEvent(player, Events.Arena.ROUND_START, player, {
            gamemode = gamemode,
            map = roundData[gamemode].currentMap,
            players = #arena.players
        })
    end

    broadcastToGamemode(gamemode, "#00FF00[Arena] #FFFFFFRound started! Good luck!")

    triggerEvent("weevil:roundStarted", root, gamemode)

    -- Set round timeout
    gamemodeTimers[gamemode .. "_timeout"] = setTimer(function()
        endGamemodeRound(gamemode, "timeout")
    end, Config.Arena.maxRoundTime * 1000, 1)

    return true
end

-- End gamemode round
function endGamemodeRound(gamemode, reason)
    local arena = Jebiga.arenas[gamemode]
    if not arena then return false end

    arena.state = "voting"
    roundData[gamemode].state = "voting"

    -- Kill timeout timer
    if gamemodeTimers[gamemode .. "_timeout"] and isTimer(gamemodeTimers[gamemode .. "_timeout"]) then
        killTimer(gamemodeTimers[gamemode .. "_timeout"])
    end

    -- Calculate final rankings
    local rankings = calculateRankings(gamemode)

    -- Award prizes
    awardRoundPrizes(gamemode, rankings)

    -- Notify clients
    for _, player in ipairs(arena.players) do
        triggerClientEvent(player, Events.Arena.ROUND_END, player, {
            gamemode = gamemode,
            reason = reason,
            rankings = rankings
        })
    end

    local winner = rankings[1]
    if winner then
        broadcastToGamemode(gamemode, "#00FF00[Arena] #FFFF00" .. getPlayerName(winner.player) .. " #FFFFFFwins!")
    end

    triggerEvent("weevil:roundEnded", root, gamemode, rankings)

    -- Start map voting
    startMapVoting(gamemode)

    return true
end

-- Calculate rankings for round
function calculateRankings(gamemode)
    local arena = Jebiga.arenas[gamemode]
    if not arena then return {} end

    local rankings = {}

    for i, entry in ipairs(roundData[gamemode].rankings or {}) do
        table.insert(rankings, {
            position = i,
            player = entry.player,
            name = getPlayerName(entry.player),
            time = entry.time,
            kills = entry.kills or 0,
            deaths = entry.deaths or 0
        })
    end

    return rankings
end

-- Award prizes for round
function awardRoundPrizes(gamemode, rankings)
    local cfg = Config.Gamemodes[gamemode]
    if not cfg then return end

    for i, entry in ipairs(rankings) do
        local player = entry.player
        if not isElement(player) then goto continue end

        if i == 1 then
            -- Winner
            addPlayerWin(player, gamemode)
        else
            -- Participation
            if cfg.pointsPerFinish then
                addPlayerPoints(player, cfg.pointsPerFinish, gamemode)
            end
            if cfg.moneyPerFinish then
                addPlayerMoney(player, cfg.moneyPerFinish, gamemode .. " finish")
            end
        end

        -- Update stats
        updatePlayerStats(player, gamemode, "racesFinished", 1)
        if i < (getPlayerStats(player, gamemode)?.bestPosition or 999) then
            local stats = getPlayerStats(player, gamemode)
            if stats then
                stats.bestPosition = i
            end
        end

        ::continue::
    end
end

-- Start map voting
function startMapVoting(gamemode)
    local arena = Jebiga.arenas[gamemode]
    if not arena then return false end

    -- Get random maps for voting
    local maps = getRandomMaps(gamemode, 5)
    roundData[gamemode].votingMaps = maps
    roundData[gamemode].votes = {}

    -- Notify clients
    for _, player in ipairs(arena.players) do
        triggerClientEvent(player, Events.Arena.MAP_VOTE_START, player, maps)
    end

    broadcastToGamemode(gamemode, "#FFFF00[Arena] #FFFFFFVote for the next map!")

    -- Voting timer
    gamemodeTimers[gamemode .. "_vote"] = setTimer(function()
        endMapVoting(gamemode)
    end, Config.Arena.voteTime * 1000, 1)

    return true
end

-- Handle map vote
function handleMapVote(player, gamemode, mapIndex)
    if not roundData[gamemode] or roundData[gamemode].state ~= "voting" then return end

    roundData[gamemode].votes[player] = mapIndex

    outputChatBox("#00FF00[Arena] #FFFFFFYour vote has been counted!", player, 255, 255, 255, true)
end

addEvent(Events.Arena.VOTE_MAP, true)
addEventHandler(Events.Arena.VOTE_MAP, root, function(mapIndex)
    local gamemode = getCurrentGamemode(client)
    if gamemode then
        handleMapVote(client, gamemode, mapIndex)
    end
end)

-- End map voting
function endMapVoting(gamemode)
    local arena = Jebiga.arenas[gamemode]
    if not arena then return false end

    -- Kill vote timer
    if gamemodeTimers[gamemode .. "_vote"] and isTimer(gamemodeTimers[gamemode .. "_vote"]) then
        killTimer(gamemodeTimers[gamemode .. "_vote"])
    end

    -- Count votes
    local voteCounts = {}
    for _, mapIndex in pairs(roundData[gamemode].votes or {}) do
        voteCounts[mapIndex] = (voteCounts[mapIndex] or 0) + 1
    end

    -- Find winner
    local winningMap = 1
    local maxVotes = 0
    for mapIndex, count in pairs(voteCounts) do
        if count > maxVotes then
            maxVotes = count
            winningMap = mapIndex
        end
    end

    -- Set next map
    local maps = roundData[gamemode].votingMaps
    if maps and maps[winningMap] then
        roundData[gamemode].currentMap = maps[winningMap]
        broadcastToGamemode(gamemode, "#00FF00[Arena] #FFFFFFNext map: " .. maps[winningMap].name)
    end

    -- Notify clients
    for _, player in ipairs(arena.players) do
        triggerClientEvent(player, Events.Arena.MAP_VOTE_END, player, winningMap)
    end

    -- Wait a moment then start next round
    arena.state = "waiting"
    roundData[gamemode].state = "waiting"

    setTimer(function()
        if #arena.players >= Config.Gamemodes[gamemode].minPlayers then
            startGamemodeCountdown(gamemode)
        end
    end, 5000, 1)

    return true
end

-- Get map spawn points
function getMapSpawnPoints(gamemode)
    -- Default spawn points (should be loaded from map resource)
    local defaultSpawns = {
        { x = 0, y = 0, z = 5, rot = 0 },
        { x = 5, y = 0, z = 5, rot = 0 },
        { x = -5, y = 0, z = 5, rot = 0 },
        { x = 0, y = 5, z = 5, rot = 0 },
        { x = 0, y = -5, z = 5, rot = 0 }
    }

    return defaultSpawns
end

-- Get random maps for voting
function getRandomMaps(gamemode, count)
    local maps = {}

    -- Query database for maps
    local queryHandle = dbQuery(connection, [[
        SELECT * FROM maps WHERE gamemode = ? ORDER BY RAND() LIMIT ?
    ]], gamemode, count)

    if queryHandle then
        local result = dbPoll(queryHandle, -1)
        dbFree(queryHandle)

        if result then
            for _, row in ipairs(result) do
                table.insert(maps, {
                    id = row.id,
                    name = row.name,
                    resource = row.resource_name,
                    author = row.author,
                    difficulty = row.difficulty
                })
            end
        end
    end

    -- If no maps in database, create placeholder maps
    if #maps == 0 then
        for i = 1, count do
            table.insert(maps, {
                id = i,
                name = gamemode .. " Map " .. i,
                resource = gamemode .. "_map_" .. i,
                author = "Jebiga",
                difficulty = math.random(1, 5)
            })
        end
    end

    return maps
end

-- Spawn player in arena
function spawnPlayerInArena(player, gamemode, spawn)
    local cfg = Config.Gamemodes[gamemode]
    if not cfg then return false end

    setElementDimension(player, cfg.dimension)

    -- Spawn based on gamemode type
    if gamemode == "hunter" then
        -- Spawn in Hunter helicopter
        local vehicle = createVehicle(425, spawn.x, spawn.y, spawn.z, 0, 0, spawn.rot or 0)
        setElementDimension(vehicle, cfg.dimension)
        spawnPlayer(player, spawn.x, spawn.y, spawn.z + 2)
        warpPedIntoVehicle(player, vehicle)
    elseif gamemode == "shooter" or gamemode == "runarena" then
        -- Spawn on foot with weapons
        spawnPlayer(player, spawn.x, spawn.y, spawn.z, spawn.rot or 0)
        giveWeapon(player, 24, 100) -- Desert Eagle
        giveWeapon(player, 31, 200) -- M4
    elseif gamemode == "trials" then
        -- Spawn on motorbike
        local vehicle = createVehicle(522, spawn.x, spawn.y, spawn.z, 0, 0, spawn.rot or 0) -- NRG-500
        setElementDimension(vehicle, cfg.dimension)
        spawnPlayer(player, spawn.x, spawn.y, spawn.z + 2)
        warpPedIntoVehicle(player, vehicle)
    else
        -- Default vehicle spawn (for DM, Race, DD, etc.)
        local vehicleId = 411 -- Infernus default
        local vehicle = createVehicle(vehicleId, spawn.x, spawn.y, spawn.z, 0, 0, spawn.rot or 0)
        setElementDimension(vehicle, cfg.dimension)
        spawnPlayer(player, spawn.x, spawn.y, spawn.z + 2)
        warpPedIntoVehicle(player, vehicle)

        -- Give weapons for DM
        if gamemode == "dm" then
            giveWeapon(player, 31, 500) -- M4
            giveWeapon(player, 25, 50)  -- Shotgun
        end
    end

    setElementHealth(player, 100)
    setCameraTarget(player, player)
    fadeCamera(player, true, 0.5)

    return true
end

-- Add player finish to rankings
function addPlayerFinish(player, gamemode, time)
    if not roundData[gamemode] then return false end

    -- Check if player already finished
    for _, entry in ipairs(roundData[gamemode].rankings) do
        if entry.player == player then return false end
    end

    table.insert(roundData[gamemode].rankings, {
        player = player,
        time = time,
        position = #roundData[gamemode].rankings + 1
    })

    -- Check if all players finished
    local arena = Jebiga.arenas[gamemode]
    if arena and #roundData[gamemode].rankings >= #arena.players then
        endGamemodeRound(gamemode, "all_finished")
    end

    return true
end

-- Add player elimination (for DD, Hunter, etc.)
function addPlayerElimination(player, gamemode, killer)
    if not roundData[gamemode] then return false end

    -- Add death to rankings (in reverse order for elimination games)
    local arena = Jebiga.arenas[gamemode]
    if arena then
        local position = #arena.players - #roundData[gamemode].rankings

        table.insert(roundData[gamemode].rankings, 1, {
            player = player,
            position = position,
            killedBy = killer
        })

        -- Award killer
        if killer and isElement(killer) then
            addPlayerKill(killer, gamemode)
        end

        -- Add death
        addPlayerDeath(player, gamemode)

        -- Check if only one player left
        local alivePlayers = 0
        local lastAlive = nil
        for _, p in ipairs(arena.players) do
            local isAlive = true
            for _, entry in ipairs(roundData[gamemode].rankings) do
                if entry.player == p then
                    isAlive = false
                    break
                end
            end
            if isAlive and isElement(p) then
                alivePlayers = alivePlayers + 1
                lastAlive = p
            end
        end

        if alivePlayers <= 1 then
            if lastAlive then
                table.insert(roundData[gamemode].rankings, {
                    player = lastAlive,
                    position = 1
                })
            end
            endGamemodeRound(gamemode, "last_standing")
        end
    end

    return true
end

-- Check player count and manage round state
function checkGamemodeState(gamemode)
    local arena = Jebiga.arenas[gamemode]
    if not arena then return end

    local cfg = Config.Gamemodes[gamemode]
    local state = arena.state

    if state == "waiting" then
        if #arena.players >= cfg.minPlayers then
            startGamemodeCountdown(gamemode)
        end
    elseif state == "countdown" or state == "playing" then
        if #arena.players < cfg.minPlayers then
            -- Cancel round due to insufficient players
            if gamemodeTimers[gamemode .. "_countdown"] and isTimer(gamemodeTimers[gamemode .. "_countdown"]) then
                killTimer(gamemodeTimers[gamemode .. "_countdown"])
            end
            if gamemodeTimers[gamemode .. "_timeout"] and isTimer(gamemodeTimers[gamemode .. "_timeout"]) then
                killTimer(gamemodeTimers[gamemode .. "_timeout"])
            end

            arena.state = "waiting"
            if roundData[gamemode] then
                roundData[gamemode].state = "waiting"
            end

            broadcastToGamemode(gamemode, "#FF0000[Arena] #FFFFFFRound cancelled - not enough players.")
        end
    end
end

-- Event: Player joins arena
addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    checkGamemodeState(gamemode)
end)

-- Event: Player leaves arena
addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    -- If in playing state, count as elimination
    if roundData[gamemode] and roundData[gamemode].state == "playing" then
        addPlayerElimination(source, gamemode, nil)
    end

    checkGamemodeState(gamemode)
end)

-- Initialize all gamemodes on resource start
addEventHandler("onResourceStart", resourceRoot, function()
    for gamemode, cfg in pairs(Config.Gamemodes) do
        if cfg.enabled then
            initializeGamemode(gamemode)
        end
    end
end)
