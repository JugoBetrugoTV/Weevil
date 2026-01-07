--[[
    Jebiga Multi-Gamemode - Lobby System
    Server-side lobby management with map detection and teleportation
]]

-- Config and Events will be loaded from jebiga_core on resource start
local Config = nil
local Events = nil

local lobbyPlayers = {}
local gamemodeStatus = {}
local detectedMaps = {}
local playerCounts = {}

-- ============================================
-- MAP DETECTION SYSTEM
-- ============================================

-- Detect maps based on their name prefix
function scanMapsForGamemodes()
    detectedMaps = {}

    -- Initialize empty tables for each gamemode
    for gmKey, _ in pairs(Config.Gamemodes) do
        detectedMaps[gmKey] = {}
    end

    -- Get all resources
    local resources = getResources()

    for _, res in ipairs(resources) do
        local resName = getResourceName(res)

        -- Check each gamemode's prefixes
        for gmKey, prefixes in pairs(Config.MapPrefixes) do
            for _, prefix in ipairs(prefixes) do
                -- Case-insensitive prefix check
                local lowerName = resName:lower()
                local lowerPrefix = prefix:lower()

                if lowerName:find("^" .. lowerPrefix:gsub("%[", "%%["):gsub("%]", "%%]"):gsub("%-", "%%-"):lower()) then
                    table.insert(detectedMaps[gmKey], {
                        name = resName,
                        resource = res,
                        state = getResourceState(res)
                    })
                    break -- Don't add same map to same gamemode twice
                end
            end
        end
    end

    -- Log detected maps
    outputDebugString("[Jebiga Maps] Map scan complete:")
    for gmKey, maps in pairs(detectedMaps) do
        if #maps > 0 then
            outputDebugString("  " .. gmKey:upper() .. ": " .. #maps .. " maps")
        end
    end

    return detectedMaps
end

-- Get map count for each gamemode
function getMapCounts()
    local counts = {}
    for gmKey, maps in pairs(detectedMaps) do
        counts[gmKey] = #maps
    end
    return counts
end

-- Get maps for a specific gamemode
function getMapsForGamemode(gamemode)
    return detectedMaps[gamemode] or {}
end

-- ============================================
-- PLAYER COUNT TRACKING
-- ============================================

-- Track players in each gamemode
function getPlayerCounts()
    local counts = {}
    for gmKey, _ in pairs(Config.Gamemodes) do
        counts[gmKey] = 0
    end

    -- Count lobby players
    counts["lobby"] = 0
    for player, _ in pairs(lobbyPlayers) do
        if isElement(player) then
            counts["lobby"] = counts["lobby"] + 1
        end
    end

    -- Count players in gamemodes (check by dimension)
    for _, player in ipairs(getElementsByType("player")) do
        if isElement(player) then
            local dim = getElementDimension(player)
            for gmKey, gm in pairs(Config.Gamemodes) do
                if gm.dimension == dim then
                    counts[gmKey] = (counts[gmKey] or 0) + 1
                    break
                end
            end
        end
    end

    playerCounts = counts
    return counts
end

-- ============================================
-- INITIALIZATION
-- ============================================

addEventHandler("onResourceStart", resourceRoot, function()
    -- Get Config and Events from jebiga_core
    Config = exports.jebiga_core:getConfig()
    Events = exports.jebiga_core:getEvents()

    if not Config then
        outputDebugString("[Jebiga Lobby] ERROR: Could not get Config from jebiga_core!", 1)
        return
    end

    -- Scan for maps
    scanMapsForGamemodes()

    -- Initialize gamemode status
    for gamemode, cfg in pairs(Config.Gamemodes) do
        if cfg.enabled then
            gamemodeStatus[gamemode] = {
                playerCount = 0,
                maxPlayers = cfg.maxPlayers,
                state = "waiting",
                currentMap = nil
            }
        end
    end

    -- Rescan maps periodically (in case new maps are added)
    setTimer(function()
        scanMapsForGamemodes()
    end, 60000, 0) -- Every minute

    outputDebugString("[Jebiga Lobby] Lobby system initialized with map detection")
end)

-- ============================================
-- CLIENT DATA REQUESTS
-- ============================================

addEvent("jebiga:lobby:requestData", true)
addEventHandler("jebiga:lobby:requestData", root, function()
    local player = client or source
    if not isElement(player) then return end

    local mapCounts = getMapCounts()
    local playerCounts = getPlayerCounts()

    triggerClientEvent(player, "jebiga:lobby:updateData", player, mapCounts, playerCounts)
end)

-- ============================================
-- TELEPORTATION SYSTEM
-- ============================================

addEvent("jebiga:lobby:joinGamemode", true)
addEventHandler("jebiga:lobby:joinGamemode", root, function(gamemode)
    local player = client or source
    if not isElement(player) then return end

    -- Check if gamemode exists and is enabled
    local gm = Config.Gamemodes[gamemode]
    if not gm or not gm.enabled then
        outputChatBox("#E74C3C[JEBIGA] #FFFFFFInvalid gamemode!", player, 255, 255, 255, true)
        return
    end

    -- Check if player is logged in (optional - remove if not using account system)
    -- if not exports.jebiga_accounts:isLoggedIn(player) then
    --     outputChatBox("#E74C3C[JEBIGA] #FFFFFFYou must be logged in to join a gamemode!", player, 255, 255, 255, true)
    --     return
    -- end

    -- Get teleport position
    local pos = gm.teleportPos
    if not pos then
        -- Fallback to lobby position for this gamemode
        pos = gm.lobbyPos or Config.Lobby.spawnPosition
    end

    -- Remove from lobby
    lobbyPlayers[player] = nil

    -- Teleport player
    setElementDimension(player, gm.dimension)
    setElementInterior(player, 0)

    -- Spawn if dead
    if not isElement(player) or getElementHealth(player) <= 0 then
        spawnPlayer(player, pos.x, pos.y, pos.z, 0, 0)
    else
        setElementPosition(player, pos.x, pos.y, pos.z)
    end

    -- Camera and fade effects
    fadeCamera(player, false, 0.3)
    setTimer(function()
        if isElement(player) then
            setCameraTarget(player, player)
            fadeCamera(player, true, 0.5)
        end
    end, 300, 1)

    -- Store current gamemode on player
    setElementData(player, "jebiga:currentGamemode", gamemode)

    -- Notify
    outputChatBox("#2ECC71[JEBIGA] #FFFFFFYou joined #2980B9" .. gm.name .. "#FFFFFF!", player, 255, 255, 255, true)

    -- Broadcast updated counts
    broadcastLobbyData()

    outputDebugString("[Jebiga Lobby] " .. getPlayerName(player) .. " joined " .. gamemode)
end)

-- ============================================
-- LOBBY MANAGEMENT
-- ============================================

-- Player enters lobby
function playerEnterLobby(player)
    if not isElement(player) then return end

    lobbyPlayers[player] = true

    -- Clear gamemode data
    setElementData(player, "jebiga:currentGamemode", nil)

    -- Set player position
    local pos = Config.Lobby.spawnPosition
    spawnPlayer(player, pos.x, pos.y, pos.z, Config.Lobby.spawnRotation, Config.Lobby.skinId)

    setElementDimension(player, Config.Lobby.dimension)
    setElementInterior(player, Config.Lobby.interior)

    -- Camera effects
    fadeCamera(player, true, 1.0)
    setCameraTarget(player, player)

    -- Set time and weather
    setTime(Config.Lobby.time.hour, Config.Lobby.time.minute)
    setWeather(Config.Lobby.weather)

    -- Send lobby data
    local mapCounts = getMapCounts()
    local playerCounts = getPlayerCounts()
    triggerClientEvent(player, "jebiga:lobby:updateData", player, mapCounts, playerCounts)

    -- Show lobby after short delay
    setTimer(function()
        if isElement(player) then
            triggerClientEvent(player, "jebiga:lobby:show", player)
        end
    end, 1500, 1)

    outputDebugString("[Jebiga Lobby] Player entered lobby: " .. getPlayerName(player))
end

-- Player leaves lobby
function playerLeaveLobby(player)
    lobbyPlayers[player] = nil
end

-- Broadcast lobby data to all lobby players
function broadcastLobbyData()
    local mapCounts = getMapCounts()
    local playerCounts = getPlayerCounts()

    for player, _ in pairs(lobbyPlayers) do
        if isElement(player) then
            triggerClientEvent(player, "jebiga:lobby:updateData", player, mapCounts, playerCounts)
        end
    end
end

-- ============================================
-- PLAYER EVENTS
-- ============================================

-- Handle player spawn (after login)
addEvent("jebiga:playerLoggedIn", true)
addEventHandler("jebiga:playerLoggedIn", root, function()
    local player = source
    if isElement(player) then
        playerEnterLobby(player)
    end
end)

-- Handle player join server (if no login system)
addEventHandler("onPlayerJoin", root, function()
    setTimer(function()
        if isElement(source) then
            -- Show welcome message
            outputChatBox(" ", source)
            outputChatBox("#2980B9╔══════════════════════════════════════╗", source, 255, 255, 255, true)
            outputChatBox("#2980B9║  #FFFFFFWelcome to #2ECC71JEBIGA GAMING#FFFFFF!           #2980B9║", source, 255, 255, 255, true)
            outputChatBox("#2980B9║  #95A5A6Press F1 to open the gamemode menu  #2980B9║", source, 255, 255, 255, true)
            outputChatBox("#2980B9╚══════════════════════════════════════╝", source, 255, 255, 255, true)
            outputChatBox(" ", source)

            playerEnterLobby(source)
        end
    end, 2000, 1)
end)

-- Handle player quit
addEventHandler("onPlayerQuit", root, function()
    lobbyPlayers[source] = nil
    broadcastLobbyData()
end)

-- ============================================
-- RETURN TO LOBBY COMMAND
-- ============================================

addCommandHandler("lobby", function(player)
    -- Check if player is in a gamemode
    local currentGM = getElementData(player, "jebiga:currentGamemode")

    if currentGM then
        outputChatBox("#2980B9[JEBIGA] #FFFFFFReturning to lobby...", player, 255, 255, 255, true)
        playerEnterLobby(player)
    else
        outputChatBox("#E74C3C[JEBIGA] #FFFFFFYou are already in the lobby!", player, 255, 255, 255, true)
    end
end)

-- Alias commands
addCommandHandler("hub", function(player)
    executeCommandHandler("lobby", player)
end)

addCommandHandler("spawn", function(player)
    executeCommandHandler("lobby", player)
end)

-- ============================================
-- MAP INFO COMMAND
-- ============================================

addCommandHandler("maps", function(player, cmd, gamemode)
    if not gamemode then
        outputChatBox("#2980B9[JEBIGA] #FFFFFFUsage: /maps <gamemode>", player, 255, 255, 255, true)
        outputChatBox("#95A5A6Available: dm, race, dd, hunter, shooter, stuntage, trials, carball, hotpursuit, runarena, training", player, 255, 255, 255, true)
        return
    end

    gamemode = gamemode:lower()
    local maps = detectedMaps[gamemode]

    if not maps then
        outputChatBox("#E74C3C[JEBIGA] #FFFFFFUnknown gamemode: " .. gamemode, player, 255, 255, 255, true)
        return
    end

    local gm = Config.Gamemodes[gamemode]
    local gmName = gm and gm.name or gamemode:upper()

    outputChatBox("#2980B9[JEBIGA] #FFFFFF" .. gmName .. " Maps (" .. #maps .. "):", player, 255, 255, 255, true)

    if #maps == 0 then
        outputChatBox("#95A5A6  No maps found for this gamemode.", player, 255, 255, 255, true)
    else
        local maxShow = math.min(#maps, 15)
        for i = 1, maxShow do
            outputChatBox("#95A5A6  " .. i .. ". " .. maps[i].name, player, 255, 255, 255, true)
        end
        if #maps > maxShow then
            outputChatBox("#95A5A6  ... and " .. (#maps - maxShow) .. " more", player, 255, 255, 255, true)
        end
    end
end)

-- ============================================
-- PERIODIC UPDATES (OPTIMIZED)
-- ============================================

-- Cache for change detection
local lastMapCounts = {}
local lastPlayerCounts = {}

-- Check if counts have changed
local function hasDataChanged(newMapCounts, newPlayerCounts)
    -- Check map counts
    for k, v in pairs(newMapCounts) do
        if lastMapCounts[k] ~= v then return true end
    end
    for k, v in pairs(lastMapCounts) do
        if newMapCounts[k] ~= v then return true end
    end
    -- Check player counts
    for k, v in pairs(newPlayerCounts) do
        if lastPlayerCounts[k] ~= v then return true end
    end
    for k, v in pairs(lastPlayerCounts) do
        if newPlayerCounts[k] ~= v then return true end
    end
    return false
end

-- Only broadcast if data changed (reduces network traffic)
setTimer(function()
    local newMapCounts = getMapCounts()
    local newPlayerCounts = getPlayerCounts()

    if hasDataChanged(newMapCounts, newPlayerCounts) then
        -- Update cache
        lastMapCounts = newMapCounts
        lastPlayerCounts = newPlayerCounts
        -- Broadcast to lobby players
        broadcastLobbyData()
    end
end, 10000, 0) -- Check every 10 seconds

-- ============================================
-- EXPORTS
-- ============================================

function getLobbyPlayerCount()
    local count = 0
    for player, _ in pairs(lobbyPlayers) do
        if isElement(player) then
            count = count + 1
        end
    end
    return count
end

function isPlayerInLobby(player)
    return lobbyPlayers[player] == true
end

function getDetectedMaps()
    return detectedMaps
end

function rescanMaps()
    return scanMapsForGamemodes()
end
