--[[
    Weevil Multi-Gamemode - User Panel Server
    Server-side user panel data management
]]

-- Get comprehensive player profile data
function getPlayerProfileData(player)
    local cachedData = exports.weevil_core:getCachedPlayerData and exports.weevil_core:getCachedPlayerData(player)
    if not cachedData then return nil end

    local profile = {
        username = cachedData.username,
        rank = Utils.calculateRank(cachedData.totalPoints),
        money = cachedData.money,
        totalPoints = cachedData.totalPoints,
        playtime = cachedData.playtime,
        adminLevel = cachedData.adminLevel,
        vipLevel = cachedData.vipLevel,
        createdAt = cachedData.createdAt,
        lastLogin = cachedData.lastLogin,
        stats = {},
        recentMatches = {},
        achievements = {}
    }

    -- Compile gamemode stats
    if cachedData.stats then
        for gamemode, stats in pairs(cachedData.stats) do
            local cfg = Config.Gamemodes[gamemode]
            profile.stats[gamemode] = {
                name = cfg and cfg.name or gamemode,
                points = stats.points,
                wins = stats.wins,
                losses = stats.losses,
                kills = stats.kills,
                deaths = stats.deaths,
                racesFinished = stats.racesFinished,
                bestPosition = stats.bestPosition,
                playtime = stats.playtime
            }
        end
    end

    -- Get recent achievements
    local accountId = cachedData.accountId
    if accountId then
        local queryHandle = dbQuery(exports.weevil_core:dbQuery, [[
            SELECT pa.*, a.name, a.description, a.points, a.category
            FROM player_achievements pa
            JOIN achievements a ON pa.achievement_id = a.achievement_id
            WHERE pa.account_id = ?
            ORDER BY pa.unlocked_at DESC
            LIMIT 10
        ]], accountId)

        if queryHandle then
            local result = dbPoll(queryHandle, -1)
            dbFree(queryHandle)

            if result then
                for _, row in ipairs(result) do
                    table.insert(profile.achievements, {
                        id = row.achievement_id,
                        name = row.name,
                        description = row.description,
                        points = row.points,
                        category = row.category,
                        unlockedAt = row.unlocked_at
                    })
                end
            end
        end
    end

    return profile
end

-- Request handler
addEvent(Events.UserPanel.REQUEST_OPEN, true)
addEventHandler(Events.UserPanel.REQUEST_OPEN, root, function()
    local profile = getPlayerProfileData(client)
    if profile then
        triggerClientEvent(client, Events.UserPanel.OPEN, client, profile)
    end
end)

-- Update settings handler
addEvent(Events.UserPanel.UPDATE_SETTINGS, true)
addEventHandler(Events.UserPanel.UPDATE_SETTINGS, root, function(settings)
    if not settings then return end

    local success = exports.weevil_core:updatePlayerSettings(client, settings)
    if success then
        triggerClientEvent(client, Events.Notification.SHOW_SUCCESS, client, "Settings saved!", 3000)
    end
end)
