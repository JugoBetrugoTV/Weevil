--[[
    Jebiga Multi-Gamemode - Scoreboard System
    Server-side scoreboard data management
]]

-- Config and Events from jebiga_core
local Config = nil
local Events = nil

-- Get scoreboard data
function getScoreboardData()
    local data = {}

    for _, player in ipairs(getElementsByType("player")) do
        local playerData = exports.jebiga_core:getPlayerData(player)
        local cachedData = exports.jebiga_core:getCachedPlayerData(player)

        if playerData then
            local entry = {
                name = getPlayerName(player),
                ping = getPlayerPing(player),
                loggedIn = playerData.loggedIn or false,
                gamemode = playerData.currentGamemode,
                inLobby = playerData.inLobby,
                money = cachedData and cachedData.money or 0,
                points = cachedData and cachedData.totalPoints or 0,
                kills = 0,
                deaths = 0,
                adminLevel = cachedData and cachedData.adminLevel or 0,
                vipLevel = cachedData and cachedData.vipLevel or 0
            }

            -- Calculate kills/deaths from stats
            if cachedData and cachedData.stats then
                for _, stats in pairs(cachedData.stats) do
                    entry.kills = entry.kills + (stats.kills or 0)
                    entry.deaths = entry.deaths + (stats.deaths or 0)
                end
            end

            table.insert(data, entry)
        end
    end

    -- Sort by points
    table.sort(data, function(a, b)
        return a.points > b.points
    end)

    return data
end

-- Send scoreboard data to player
function sendScoreboardData(player)
    if not Events then return end
    local data = getScoreboardData()
    triggerClientEvent(player, "weevil:scoreboard:update", player, data)
end

-- Broadcast scoreboard update
function broadcastScoreboardUpdate()
    local data = getScoreboardData()

    for _, player in ipairs(getElementsByType("player")) do
        triggerClientEvent(player, "weevil:scoreboard:update", player, data)
    end
end

-- Initialize on resource start
addEventHandler("onResourceStart", resourceRoot, function()
    Config = exports.jebiga_core:getConfig()
    Events = exports.jebiga_core:getEvents()

    -- Periodic scoreboard update
    local updateInterval = (Config and Config.Scoreboard and Config.Scoreboard.updateInterval) or 5000
    setTimer(broadcastScoreboardUpdate, updateInterval, 0)

    outputDebugString("[Jebiga Scoreboard] Scoreboard system initialized")
end)

-- Request handler
addEvent("weevil:requestScoreboard", true)
addEventHandler("weevil:requestScoreboard", root, function()
    sendScoreboardData(client)
end)
