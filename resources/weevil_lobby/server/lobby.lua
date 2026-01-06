--[[
    Weevil Multi-Gamemode - Lobby System
    Server-side lobby management
]]

local lobbyPlayers = {}
local gamemodeStatus = {}

-- Initialize lobby
addEventHandler("onResourceStart", resourceRoot, function()
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

    outputDebugString("[Weevil Lobby] Lobby system initialized")
end)

-- Get gamemode status
function getGamemodeStatus()
    local status = {}

    for gamemode, cfg in pairs(Config.Gamemodes) do
        if cfg.enabled then
            local arena = Weevil.arenas[gamemode]
            local playerCount = arena and #arena.players or 0

            status[gamemode] = {
                name = cfg.name,
                shortName = cfg.shortName,
                description = cfg.description,
                color = cfg.color,
                playerCount = playerCount,
                maxPlayers = cfg.maxPlayers,
                minPlayers = cfg.minPlayers,
                state = arena and arena.state or "waiting",
                currentMap = arena and arena.currentMap or nil,
                enabled = cfg.enabled
            }
        end
    end

    return status
end

-- Send lobby status to player
function sendLobbyStatus(player)
    local status = getGamemodeStatus()
    triggerClientEvent(player, Events.Lobby.UPDATE_GAMEMODE_STATUS, player, status)
end

-- Send lobby status to all lobby players
function broadcastLobbyStatus()
    local status = getGamemodeStatus()

    for player, _ in pairs(lobbyPlayers) do
        if isElement(player) then
            triggerClientEvent(player, Events.Lobby.UPDATE_GAMEMODE_STATUS, player, status)
        end
    end
end

-- Player enters lobby
function playerEnterLobby(player)
    if not isElement(player) then return end

    lobbyPlayers[player] = true

    -- Set player position
    spawnPlayer(
        player,
        Config.Lobby.spawnPosition.x,
        Config.Lobby.spawnPosition.y,
        Config.Lobby.spawnPosition.z,
        Config.Lobby.spawnRotation,
        Config.Lobby.skinId
    )

    setElementDimension(player, Config.Lobby.dimension)
    setElementInterior(player, Config.Lobby.interior)

    fadeCamera(player, true, 1.0)
    setCameraTarget(player, player)

    -- Send current status
    sendLobbyStatus(player)

    outputDebugString("[Weevil Lobby] Player entered lobby: " .. getPlayerName(player))
end

-- Player leaves lobby
function playerLeaveLobby(player)
    lobbyPlayers[player] = nil
end

-- Handle join gamemode request
addEvent(Events.Lobby.REQUEST_JOIN_GAMEMODE, true)
addEventHandler(Events.Lobby.REQUEST_JOIN_GAMEMODE, root, function(gamemode)
    local player = client
    if not player or not isElement(player) then return end

    -- Check if logged in
    if not exports.weevil_accounts:isLoggedIn(player) then
        triggerClientEvent(player, Events.Notification.SHOW_ERROR, player, "You must be logged in to join a gamemode")
        return
    end

    -- Check if gamemode exists
    if not Config.Gamemodes[gamemode] or not Config.Gamemodes[gamemode].enabled then
        triggerClientEvent(player, Events.Notification.SHOW_ERROR, player, "Invalid gamemode")
        return
    end

    -- Try to add player to arena
    local success = exports.weevil_core:addPlayerToArena(player, gamemode)

    if success then
        playerLeaveLobby(player)
        broadcastLobbyStatus()
    end
end)

-- Handle leave gamemode request
addEvent(Events.Lobby.REQUEST_LEAVE_GAMEMODE, true)
addEventHandler(Events.Lobby.REQUEST_LEAVE_GAMEMODE, root, function()
    local player = client
    if not player or not isElement(player) then return end

    local currentGM = exports.weevil_core:getCurrentGamemode(player)
    if currentGM then
        exports.weevil_core:removePlayerFromArena(player, currentGM)
        playerEnterLobby(player)
        broadcastLobbyStatus()
    end
end)

-- Update status when arena changes
addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    broadcastLobbyStatus()
end)

addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    broadcastLobbyStatus()
end)

addEventHandler("weevil:roundStarted", root, function(gamemode)
    broadcastLobbyStatus()
end)

addEventHandler("weevil:roundEnded", root, function(gamemode)
    broadcastLobbyStatus()
end)

-- Handle player join server
addEventHandler("onPlayerJoin", root, function()
    setTimer(function()
        if isElement(source) then
            playerEnterLobby(source)
        end
    end, 1000, 1)
end)

-- Handle player quit
addEventHandler("onPlayerQuit", root, function()
    lobbyPlayers[source] = nil
end)

-- Periodic status update
setTimer(function()
    broadcastLobbyStatus()
end, 5000, 0)

-- Get lobby player count
function getLobbyPlayerCount()
    local count = 0
    for player, _ in pairs(lobbyPlayers) do
        if isElement(player) then
            count = count + 1
        end
    end
    return count
end

-- Command to return to lobby
addCommandHandler("lobbyinfo", function(player)
    local status = getGamemodeStatus()

    outputChatBox("#FF6600=== Gamemode Status ===", player, 255, 255, 255, true)

    for gamemode, info in pairs(status) do
        local stateColor = info.state == "playing" and "#00FF00" or (info.state == "countdown" and "#FFFF00" or "#AAAAAA")
        outputChatBox(
            string.format("%s%s #FFFFFF- %d/%d players (%s%s#FFFFFF)",
                info.color, info.name,
                info.playerCount, info.maxPlayers,
                stateColor, info.state
            ),
            player, 255, 255, 255, true
        )
    end
end)
