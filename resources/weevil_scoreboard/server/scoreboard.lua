--[[
    Weevil Multi-Gamemode - Scoreboard System
    Server-side scoreboard data management
]]

-- Get scoreboard data
function getScoreboardData()
    local data = {}

    for _, player in ipairs(getElementsByType("player")) do
        local playerData = exports.weevil_core:getPlayerData(player)
        local cachedData = exports.weevil_core:getCachedPlayerData and exports.weevil_core:getCachedPlayerData(player)

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
    local data = getScoreboardData()
    triggerClientEvent(player, Events.Scoreboard.UPDATE, player, data)
end

-- Broadcast scoreboard update
function broadcastScoreboardUpdate()
    local data = getScoreboardData()

    for _, player in ipairs(getElementsByType("player")) do
        triggerClientEvent(player, Events.Scoreboard.UPDATE, player, data)
    end
end

-- Periodic scoreboard update
setTimer(broadcastScoreboardUpdate, Config.Scoreboard.updateInterval, 0)

-- Request handler
addEvent("weevil:requestScoreboard", true)
addEventHandler("weevil:requestScoreboard", root, function()
    sendScoreboardData(client)
end)
