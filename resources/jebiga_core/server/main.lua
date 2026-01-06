--[[
    Jebiga Multi-Gamemode - Main Server Script
    Core initialization and management

    Flow: Join -> Login Screen -> Lobby Panel -> Select Gamemode -> Spawn in Arena
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

    -- Set server info
    setGameType("Jebiga MGM")
    setMapName("Lobby")

    -- Set global weather and time
    setWeather(Config.Lobby.weather or 0)
    setTime(Config.Lobby.time and Config.Lobby.time.hour or 12, Config.Lobby.time and Config.Lobby.time.minute or 0)

    -- Initialize arenas for each gamemode
    for gamemode, cfg in pairs(Config.Gamemodes) do
        if cfg.enabled then
            Jebiga.arenas[gamemode] = {
                players = {},
                state = "waiting", -- waiting, countdown, playing, intermission
                currentMap = nil,
                currentMapResource = nil,
                roundStartTime = nil,
                roundNumber = 0,
                rankings = {},
                spawnpoints = {},
                vehicles = {}
            }
        end
    end

    outputDebugString("[Jebiga] Server started - Version " .. Jebiga.version)
    outputServerLog("[Jebiga] Multi-Gamemode server initialized")
end)

-- ============================================
-- PLAYER JOIN - NO SPAWN, JUST LOGIN SCREEN
-- ============================================

addEventHandler("onPlayerJoin", root, function()
    local player = source

    -- Initialize player data
    Jebiga.players[player] = {
        accountId = nil,
        loggedIn = false,
        currentGamemode = nil,
        inLobby = false,
        spawned = false,
        joinTime = getTickCount(),
        sessionStats = {
            kills = 0,
            deaths = 0,
            wins = 0,
            points = 0,
            money = 0
        }
    }

    -- DON'T spawn the player - just set dimension
    setElementDimension(player, 0)
    setElementInterior(player, 0)

    -- Fade camera in but DON'T set target to player (they're not spawned)
    fadeCamera(player, true, 1.0)

    -- The client will show login screen automatically
    -- Camera is handled client-side

    outputDebugString("[Jebiga] Player connected: " .. getPlayerName(player) .. " (awaiting login)")
end)

-- ============================================
-- AFTER LOGIN - SHOW LOBBY (STILL NO SPAWN)
-- ============================================

addEvent("jebiga:onPlayerLoggedIn", true)
addEventHandler("jebiga:onPlayerLoggedIn", root, function(accountId)
    local player = source
    if not Jebiga.players[player] then return end

    Jebiga.players[player].accountId = accountId
    Jebiga.players[player].loggedIn = true
    Jebiga.players[player].inLobby = true

    -- Set element data
    setElementData(player, "jebiga:loggedIn", true)
    setElementData(player, "jebiga:accountId", accountId)

    -- Player is still NOT spawned - lobby is a UI panel
    -- Client will show lobby panel

    outputChatBox("#2ECC71[Jebiga] #FFFFFFWelcome! Select a gamemode to start playing.", player, 255, 255, 255, true)
    outputDebugString("[Jebiga] Player logged in: " .. getPlayerName(player))

    -- Trigger client to show lobby
    triggerClientEvent(player, "jebiga:lobby:show", player)
end)

-- ============================================
-- JOIN GAMEMODE - NOW SPAWN PLAYER
-- ============================================

function addPlayerToArena(player, gamemode)
    if not Jebiga.arenas[gamemode] then return false end
    if not Jebiga.players[player] or not Jebiga.players[player].loggedIn then
        outputChatBox("#E74C3C[Jebiga] #FFFFFFYou must be logged in to join.", player, 255, 255, 255, true)
        return false
    end

    local cfg = Config.Gamemodes[gamemode]
    if not cfg or not cfg.enabled then return false end

    -- Check max players
    if #Jebiga.arenas[gamemode].players >= cfg.maxPlayers then
        outputChatBox("#E74C3C[Jebiga] #FFFFFFThis arena is full.", player, 255, 255, 255, true)
        return false
    end

    -- Remove from current gamemode if any
    local currentGM = Jebiga.players[player].currentGamemode
    if currentGM then
        removePlayerFromArena(player, currentGM)
    end

    -- Add to arena
    table.insert(Jebiga.arenas[gamemode].players, player)
    Jebiga.players[player].currentGamemode = gamemode
    Jebiga.players[player].inLobby = false
    Jebiga.players[player].spawned = true

    -- Set element data
    setElementData(player, "jebiga:currentGamemode", gamemode)
    setElementData(player, "jebiga:inLobby", false)

    -- Set dimension
    setElementDimension(player, cfg.dimension)
    setElementInterior(player, 0)

    -- NOW spawn the player
    local spawnPos = getArenaSpawnpoint(gamemode)
    spawnPlayer(player, spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.rot or 0, cfg.skinId or 0)

    fadeCamera(player, true, 0.5)
    setCameraTarget(player, player)

    -- Give starting weapons if configured
    if cfg.weapons then
        for _, weapon in ipairs(cfg.weapons) do
            giveWeapon(player, weapon.id, weapon.ammo or 100)
        end
    end

    -- Trigger events
    triggerEvent("weevil:playerJoinedArena", player, gamemode)
    triggerClientEvent(player, "weevil:lobby:playerJoin", player, gamemode)

    outputChatBox("#2ECC71[Jebiga] #FFFFFFYou joined #2980B9" .. cfg.name .. "#FFFFFF!", player, 255, 255, 255, true)
    outputDebugString("[Jebiga] " .. getPlayerName(player) .. " joined " .. gamemode)

    -- Check if we need to start/load a map
    checkArenaState(gamemode)

    return true
end

-- ============================================
-- ARENA SPAWNPOINT
-- ============================================

function getArenaSpawnpoint(gamemode)
    local arena = Jebiga.arenas[gamemode]
    local cfg = Config.Gamemodes[gamemode]

    -- If map has spawnpoints, use them
    if arena and arena.spawnpoints and #arena.spawnpoints > 0 then
        local sp = arena.spawnpoints[math.random(#arena.spawnpoints)]
        return { x = sp.x, y = sp.y, z = sp.z, rot = sp.rot or 0 }
    end

    -- Use gamemode default spawn
    if cfg and cfg.spawnPosition then
        return cfg.spawnPosition
    end

    -- Fallback
    return { x = 0, y = 0, z = 5, rot = 0 }
end

-- ============================================
-- ARENA STATE MANAGEMENT
-- ============================================

function checkArenaState(gamemode)
    local arena = Jebiga.arenas[gamemode]
    if not arena then return end

    local playerCount = #arena.players
    local cfg = Config.Gamemodes[gamemode]
    local minPlayers = cfg.minPlayers or 1

    if arena.state == "waiting" then
        if playerCount >= minPlayers then
            -- Start countdown or load map
            if not arena.currentMap then
                -- Load a random map for this gamemode
                loadRandomMapForGamemode(gamemode)
            else
                -- Start countdown
                startArenaCountdown(gamemode)
            end
        end
    end
end

-- ============================================
-- MAP LOADING SYSTEM
-- ============================================

function loadRandomMapForGamemode(gamemode)
    local arena = Jebiga.arenas[gamemode]
    if not arena then return false end

    local cfg = Config.Gamemodes[gamemode]
    local prefixes = Config.MapPrefixes and Config.MapPrefixes[gamemode] or {}

    -- Find maps with matching prefix
    local availableMaps = {}
    local resources = getResources()

    for _, res in ipairs(resources) do
        local resName = getResourceName(res)

        for _, prefix in ipairs(prefixes) do
            if resName:lower():find("^" .. prefix:lower():gsub("[%[%]%-]", "%%%1")) then
                table.insert(availableMaps, res)
                break
            end
        end
    end

    if #availableMaps == 0 then
        outputDebugString("[Jebiga] No maps found for gamemode: " .. gamemode, 2)
        -- Use a default spawn area
        arena.currentMap = "default"
        startArenaCountdown(gamemode)
        return false
    end

    -- Pick random map
    local mapRes = availableMaps[math.random(#availableMaps)]
    local mapName = getResourceName(mapRes)

    outputDebugString("[Jebiga] Loading map: " .. mapName .. " for " .. gamemode)

    -- Start the map resource
    if getResourceState(mapRes) ~= "running" then
        startResource(mapRes)
    end

    -- Store map info
    arena.currentMap = mapName
    arena.currentMapResource = mapRes

    -- Parse map file for spawnpoints
    parseMapResource(gamemode, mapRes)

    -- Broadcast to arena players
    broadcastToGamemode(gamemode, "#2980B9[" .. (cfg.name or gamemode):upper() .. "] #FFFFFFMap: #2ECC71" .. mapName)

    -- Teleport all players to new spawnpoints
    for _, player in ipairs(arena.players) do
        local sp = getArenaSpawnpoint(gamemode)
        spawnPlayer(player, sp.x, sp.y, sp.z, sp.rot or 0, cfg.skinId or 0)
        setCameraTarget(player, player)
    end

    -- Start countdown
    setTimer(function()
        startArenaCountdown(gamemode)
    end, 2000, 1)

    return true
end

function parseMapResource(gamemode, mapRes)
    local arena = Jebiga.arenas[gamemode]
    if not arena then return end

    arena.spawnpoints = {}

    local resName = getResourceName(mapRes)

    -- Try to find .map file
    local files = {"map.map", resName .. ".map", "meta.map"}

    for _, fileName in ipairs(files) do
        local mapFile = ":" .. resName .. "/" .. fileName
        local xml = xmlLoadFile(mapFile)

        if xml then
            local children = xmlNodeGetChildren(xml)

            for _, node in ipairs(children) do
                local nodeName = xmlNodeGetName(node)

                if nodeName == "spawnpoint" then
                    local x = tonumber(xmlNodeGetAttribute(node, "posX") or xmlNodeGetAttribute(node, "x")) or 0
                    local y = tonumber(xmlNodeGetAttribute(node, "posY") or xmlNodeGetAttribute(node, "y")) or 0
                    local z = tonumber(xmlNodeGetAttribute(node, "posZ") or xmlNodeGetAttribute(node, "z")) or 0
                    local rot = tonumber(xmlNodeGetAttribute(node, "rot") or xmlNodeGetAttribute(node, "rotation")) or 0

                    table.insert(arena.spawnpoints, { x = x, y = y, z = z, rot = rot })
                end
            end

            xmlUnloadFile(xml)
            outputDebugString("[Jebiga] Parsed " .. #arena.spawnpoints .. " spawnpoints from " .. fileName)
            break
        end
    end
end

-- ============================================
-- ARENA COUNTDOWN
-- ============================================

function startArenaCountdown(gamemode)
    local arena = Jebiga.arenas[gamemode]
    if not arena then return end

    arena.state = "countdown"

    -- Freeze players during countdown
    for _, player in ipairs(arena.players) do
        setElementFrozen(player, true)
        triggerClientEvent(player, "jebiga:countdown:start", player, 5)
    end

    -- Countdown from 5
    local countdown = 5
    setTimer(function()
        countdown = countdown - 1

        for _, player in ipairs(arena.players) do
            if isElement(player) then
                triggerClientEvent(player, "jebiga:countdown:tick", player, countdown)
            end
        end

        if countdown <= 0 then
            startArenaRound(gamemode)
        end
    end, 1000, 5)
end

function startArenaRound(gamemode)
    local arena = Jebiga.arenas[gamemode]
    if not arena then return end

    arena.state = "playing"
    arena.roundStartTime = getTickCount()
    arena.roundNumber = arena.roundNumber + 1

    -- Unfreeze players
    for _, player in ipairs(arena.players) do
        if isElement(player) then
            setElementFrozen(player, false)
            triggerClientEvent(player, "jebiga:round:start", player)
        end
    end

    local cfg = Config.Gamemodes[gamemode]
    broadcastToGamemode(gamemode, "#2ECC71[" .. (cfg.name or gamemode):upper() .. "] #FFFFFFGO!")

    triggerEvent("weevil:roundStarted", root, gamemode, arena.roundNumber)
end

-- ============================================
-- REMOVE FROM ARENA / RETURN TO LOBBY
-- ============================================

function removePlayerFromArena(player, gamemode)
    if not Jebiga.arenas[gamemode] then return false end

    -- Find and remove player
    for i, p in ipairs(Jebiga.arenas[gamemode].players) do
        if p == player then
            table.remove(Jebiga.arenas[gamemode].players, i)
            break
        end
    end

    -- Update player state
    if Jebiga.players[player] then
        Jebiga.players[player].currentGamemode = nil
        Jebiga.players[player].inLobby = true
        Jebiga.players[player].spawned = false
    end

    -- Clear element data
    setElementData(player, "jebiga:currentGamemode", nil)
    setElementData(player, "jebiga:inLobby", true)

    -- "Despawn" player (make invisible, freeze)
    setElementAlpha(player, 0)
    setElementFrozen(player, true)
    setElementDimension(player, 0)

    -- Trigger events
    triggerEvent("weevil:playerLeftArena", player, gamemode)
    triggerClientEvent(player, "weevil:lobby:playerLeave", player, gamemode)

    -- Show lobby panel again
    triggerClientEvent(player, "jebiga:lobby:show", player)

    return true
end

-- ============================================
-- PLAYER DISCONNECT
-- ============================================

addEventHandler("onPlayerQuit", root, function(quitType, reason)
    local player = source

    if Jebiga.players[player] then
        -- Save if logged in
        if Jebiga.players[player].loggedIn then
            savePlayerSession(player)
        end

        -- Remove from arena
        local gamemode = Jebiga.players[player].currentGamemode
        if gamemode and Jebiga.arenas[gamemode] then
            for i, p in ipairs(Jebiga.arenas[gamemode].players) do
                if p == player then
                    table.remove(Jebiga.arenas[gamemode].players, i)
                    break
                end
            end
        end

        Jebiga.players[player] = nil
    end

    outputDebugString("[Jebiga] Player left: " .. getPlayerName(player))
end)

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function savePlayerSession(player)
    local data = Jebiga.players[player]
    if not data or not data.accountId then return end

    local playTime = math.floor((getTickCount() - data.joinTime) / 1000)

    execute([[
        UPDATE accounts SET
            playtime = playtime + ?,
            last_login = NOW()
        WHERE id = ?
    ]], playTime, data.accountId)
end

function getPlayerData(player)
    return Jebiga.players[player]
end

function setPlayerData(player, key, value)
    if Jebiga.players[player] then
        Jebiga.players[player][key] = value
        return true
    end
    return false
end

function isPlayerLoggedIn(player)
    local data = Jebiga.players[player]
    return data and data.loggedIn
end

function getPlayerAccountId(player)
    local data = Jebiga.players[player]
    return data and data.accountId
end

function getCurrentGamemode(player)
    local data = Jebiga.players[player]
    return data and data.currentGamemode
end

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

function getArenaPlayers(gamemode)
    if not Jebiga.arenas[gamemode] then return {} end
    return Jebiga.arenas[gamemode].players
end

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

function teleportToLobby(player)
    removePlayerFromArena(player, Jebiga.players[player] and Jebiga.players[player].currentGamemode)
end

function teleportToArena(player, gamemode, x, y, z, rot)
    local cfg = Config.Gamemodes[gamemode]
    if not cfg then return false end
    setElementDimension(player, cfg.dimension)
    if x and y and z then
        setElementPosition(player, x, y, z)
        if rot then setElementRotation(player, 0, 0, rot) end
    end
    return true
end

function getServerUptime()
    if not Jebiga.startTime then return 0 end
    return getTickCount() - Jebiga.startTime
end

function broadcastMessage(message, r, g, b)
    r, g, b = r or 255, g or 255, b or 255
    for player, _ in pairs(Jebiga.players) do
        if isElement(player) then
            outputChatBox(message, player, r, g, b, true)
        end
    end
end

function broadcastToGamemode(gamemode, message, r, g, b)
    if not Jebiga.arenas[gamemode] then return end
    r, g, b = r or 255, g or 255, b or 255
    for _, player in ipairs(Jebiga.arenas[gamemode].players) do
        if isElement(player) then
            outputChatBox(message, player, r, g, b, true)
        end
    end
end

-- ============================================
-- EVENTS
-- ============================================

addEvent("weevil:playerJoinedArena", false)
addEvent("weevil:playerLeftArena", false)
addEvent("weevil:roundStarted", false)
addEvent("weevil:roundEnded", false)

-- Make functions global for exports
_G.getPlayerData = getPlayerData
_G.setPlayerData = setPlayerData
_G.isPlayerLoggedIn = isPlayerLoggedIn
_G.getPlayerAccountId = getPlayerAccountId
_G.getCurrentGamemode = getCurrentGamemode
_G.getOnlinePlayers = getOnlinePlayers
_G.getArenaPlayers = getArenaPlayers
_G.isPlayerInArena = isPlayerInArena
_G.addPlayerToArena = addPlayerToArena
_G.removePlayerFromArena = removePlayerFromArena
_G.teleportToLobby = teleportToLobby
_G.teleportToArena = teleportToArena
_G.broadcastMessage = broadcastMessage
_G.broadcastToGamemode = broadcastToGamemode
_G.getServerUptime = getServerUptime
_G.loadRandomMapForGamemode = loadRandomMapForGamemode
_G.checkArenaState = checkArenaState
