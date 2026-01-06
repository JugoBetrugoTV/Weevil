--[[
    Jebiga Multi-Gamemode - Main Server Script
    Core initialization and management
]]

-- Global variables
Jebiga = {
    version = Config.ServerVersion,
    startTime = nil,
    players = {},
    arenas = {},
    currentMaps = {}
}

-- Resource initialization
addEventHandler("onResourceStart", resourceRoot, function()
    Jebiga.startTime = getTickCount()

    -- Set server name
    setServerPassword("")
    setGameType("Jebiga MGM")
    setMapName("Lobby")

    -- Set global weather and time for lobby
    setWeather(Config.Lobby.weather)
    setTime(Config.Lobby.time.hour, Config.Lobby.time.minute)

    -- Initialize arenas for each gamemode
    for gamemode, cfg in pairs(Config.Gamemodes) do
        if cfg.enabled then
            Jebiga.arenas[gamemode] = {
                players = {},
                state = "waiting", -- waiting, countdown, playing, voting
                currentMap = nil,
                roundStartTime = nil,
                rankings = {}
            }
        end
    end

    outputDebugString("[Jebiga] Server started - Version " .. Jebiga.version)
    outputServerLog("[Jebiga] Multi-Gamemode server initialized")
end)

-- Player connect handler
addEventHandler("onPlayerJoin", root, function()
    local player = source

    -- Initialize player data structure
    Jebiga.players[player] = {
        accountId = nil,
        loggedIn = false,
        currentGamemode = nil,
        inLobby = true,
        joinTime = getTickCount(),
        sessionStats = {
            kills = 0,
            deaths = 0,
            wins = 0,
            points = 0,
            money = 0
        }
    }

    -- Set player to lobby
    setElementDimension(player, Config.Lobby.dimension)
    setElementInterior(player, Config.Lobby.interior)

    -- Spawn at lobby
    spawnPlayer(
        player,
        Config.Lobby.spawnPosition.x,
        Config.Lobby.spawnPosition.y,
        Config.Lobby.spawnPosition.z,
        Config.Lobby.spawnRotation,
        Config.Lobby.skinId
    )

    fadeCamera(player, true, 1.0)
    setCameraTarget(player, player)

    -- Show welcome message
    outputChatBox("#FF6600[Jebiga] #FFFFFFWelcome to " .. Config.ServerName .. "!", player, 255, 255, 255, true)
    outputChatBox("#FF6600[Jebiga] #FFFFFFPlease login or register to play.", player, 255, 255, 255, true)

    outputDebugString("[Jebiga] Player joined: " .. getPlayerName(player))
end)

-- Player disconnect handler
addEventHandler("onPlayerQuit", root, function(quitType, reason)
    local player = source

    if Jebiga.players[player] then
        -- Save session stats if logged in
        if Jebiga.players[player].loggedIn then
            savePlayerSession(player)
        end

        -- Remove from current gamemode
        local gamemode = Jebiga.players[player].currentGamemode
        if gamemode and Jebiga.arenas[gamemode] then
            removePlayerFromArena(player, gamemode)
        end

        -- Cleanup
        Jebiga.players[player] = nil
    end

    outputDebugString("[Jebiga] Player left: " .. getPlayerName(player) .. " (" .. quitType .. ")")
end)

-- Save player session data
function savePlayerSession(player)
    local data = Jebiga.players[player]
    if not data or not data.accountId then return end

    local session = data.sessionStats

    -- Update playtime
    local playTime = math.floor((getTickCount() - data.joinTime) / 1000)

    -- Update database
    dbExec([[
        UPDATE accounts SET
            playtime = playtime + ?,
            last_login = NOW()
        WHERE id = ?
    ]], playTime, data.accountId)
end

-- Get player server data
function getPlayerData(player)
    return Jebiga.players[player]
end

-- Set player server data
function setPlayerData(player, key, value)
    if Jebiga.players[player] then
        Jebiga.players[player][key] = value
        return true
    end
    return false
end

-- Check if player is logged in
function isPlayerLoggedIn(player)
    local data = Jebiga.players[player]
    return data and data.loggedIn
end

-- Get player account ID
function getPlayerAccountId(player)
    local data = Jebiga.players[player]
    return data and data.accountId
end

-- Get current gamemode for player
function getCurrentGamemode(player)
    local data = Jebiga.players[player]
    return data and data.currentGamemode
end

-- Get all online players
function getOnlinePlayers()
    local players = {}
    for player, data in pairs(Jebiga.players) do
        if isElement(player) then
            table.insert(players, {
                player = player,
                name = getPlayerName(player),
                loggedIn = data.loggedIn,
                gamemode = data.currentGamemode
            })
        end
    end
    return players
end

-- Get players in specific gamemode
function getArenaPlayers(gamemode)
    if not Jebiga.arenas[gamemode] then return {} end
    return Jebiga.arenas[gamemode].players
end

-- Check if player is in arena
function isPlayerInArena(player, gamemode)
    if not gamemode then
        local data = Jebiga.players[player]
        return data and data.currentGamemode ~= nil
    end

    if not Jebiga.arenas[gamemode] then return false end

    for _, p in ipairs(Jebiga.arenas[gamemode].players) do
        if p == player then return true end
    end
    return false
end

-- Add player to arena
function addPlayerToArena(player, gamemode)
    if not Jebiga.arenas[gamemode] then return false end
    if not isPlayerLoggedIn(player) then
        outputChatBox("#FF0000[Jebiga] #FFFFFFYou must be logged in to join a gamemode.", player, 255, 255, 255, true)
        return false
    end

    local cfg = Config.Gamemodes[gamemode]
    if not cfg or not cfg.enabled then return false end

    -- Check max players
    if #Jebiga.arenas[gamemode].players >= cfg.maxPlayers then
        outputChatBox("#FF0000[Jebiga] #FFFFFFThis arena is full.", player, 255, 255, 255, true)
        return false
    end

    -- Remove from current gamemode if any
    local currentGM = Jebiga.players[player].currentGamemode
    if currentGM then
        removePlayerFromArena(player, currentGM)
    end

    -- Add to new arena
    table.insert(Jebiga.arenas[gamemode].players, player)
    Jebiga.players[player].currentGamemode = gamemode
    Jebiga.players[player].inLobby = false

    -- Set dimension
    setElementDimension(player, cfg.dimension)

    -- Trigger event
    triggerEvent("weevil:playerJoinedArena", player, gamemode)
    triggerClientEvent(player, Events.Lobby.PLAYER_JOIN, player, gamemode)

    outputChatBox("#00FF00[Jebiga] #FFFFFFYou joined " .. cfg.name .. "!", player, 255, 255, 255, true)
    outputDebugString("[Jebiga] " .. getPlayerName(player) .. " joined " .. gamemode)

    return true
end

-- Remove player from arena
function removePlayerFromArena(player, gamemode)
    if not Jebiga.arenas[gamemode] then return false end

    -- Find and remove player
    for i, p in ipairs(Jebiga.arenas[gamemode].players) do
        if p == player then
            table.remove(Jebiga.arenas[gamemode].players, i)
            break
        end
    end

    Jebiga.players[player].currentGamemode = nil
    Jebiga.players[player].inLobby = true

    -- Return to lobby
    teleportToLobby(player)

    -- Trigger event
    triggerEvent("weevil:playerLeftArena", player, gamemode)
    triggerClientEvent(player, Events.Lobby.PLAYER_LEAVE, player, gamemode)

    return true
end

-- Teleport player to lobby
function teleportToLobby(player)
    setElementDimension(player, Config.Lobby.dimension)
    setElementInterior(player, Config.Lobby.interior)

    spawnPlayer(
        player,
        Config.Lobby.spawnPosition.x,
        Config.Lobby.spawnPosition.y,
        Config.Lobby.spawnPosition.z,
        Config.Lobby.spawnRotation,
        Config.Lobby.skinId
    )

    fadeCamera(player, true, 0.5)
    setCameraTarget(player, player)

    if Jebiga.players[player] then
        Jebiga.players[player].inLobby = true
        Jebiga.players[player].currentGamemode = nil
    end
end

-- Teleport player to arena
function teleportToArena(player, gamemode, x, y, z, rot)
    local cfg = Config.Gamemodes[gamemode]
    if not cfg then return false end

    setElementDimension(player, cfg.dimension)

    if x and y and z then
        setElementPosition(player, x, y, z)
        if rot then
            setElementRotation(player, 0, 0, rot)
        end
    end

    return true
end

-- Get server uptime
function getServerUptime()
    if not Jebiga.startTime then return 0 end
    return getTickCount() - Jebiga.startTime
end

-- Broadcast message to all players
function broadcastMessage(message, r, g, b)
    r = r or 255
    g = g or 255
    b = b or 255

    for player, _ in pairs(Jebiga.players) do
        if isElement(player) then
            outputChatBox(message, player, r, g, b, true)
        end
    end
end

-- Broadcast to specific gamemode
function broadcastToGamemode(gamemode, message, r, g, b)
    if not Jebiga.arenas[gamemode] then return end

    r = r or 255
    g = g or 255
    b = b or 255

    for _, player in ipairs(Jebiga.arenas[gamemode].players) do
        if isElement(player) then
            outputChatBox(message, player, r, g, b, true)
        end
    end
end

-- Custom events
addEvent("weevil:playerJoinedArena", false)
addEvent("weevil:playerLeftArena", false)
addEvent("weevil:roundStarted", false)
addEvent("weevil:roundEnded", false)

-- Export functions
exports.jebiga_core = {
    getPlayerData = getPlayerData,
    setPlayerData = setPlayerData,
    isPlayerLoggedIn = isPlayerLoggedIn,
    getPlayerAccountId = getPlayerAccountId,
    getCurrentGamemode = getCurrentGamemode,
    getOnlinePlayers = getOnlinePlayers,
    getArenaPlayers = getArenaPlayers,
    isPlayerInArena = isPlayerInArena,
    addPlayerToArena = addPlayerToArena,
    removePlayerFromArena = removePlayerFromArena,
    teleportToLobby = teleportToLobby,
    teleportToArena = teleportToArena,
    broadcastMessage = broadcastMessage,
    broadcastToGamemode = broadcastToGamemode,
    getServerUptime = getServerUptime
}
