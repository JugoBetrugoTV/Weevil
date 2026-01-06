--[[
    Jebiga Multi-Gamemode - User Panel Server
    Server-side user panel data management
]]

-- Config loaded on resource start
local Config = nil

-- Simple rank calculation fallback
local function calculateRank(points)
    points = points or 0
    if points >= 100000 then return "Legend"
    elseif points >= 50000 then return "Master"
    elseif points >= 25000 then return "Expert"
    elseif points >= 10000 then return "Veteran"
    elseif points >= 5000 then return "Pro"
    elseif points >= 1000 then return "Regular"
    elseif points >= 100 then return "Rookie"
    else return "Newcomer"
    end
end

-- Get comprehensive player profile data
function getPlayerProfileData(player)
    local cachedData = exports.jebiga_core:getCachedPlayerData(player)
    if not cachedData then return nil end

    local profile = {
        username = cachedData.username,
        rank = calculateRank(cachedData.totalPoints),
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
            local cfg = Config and Config.Gamemodes and Config.Gamemodes[gamemode]
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
        local result = exports.jebiga_core:db_fetchAll([[
            SELECT pa.*, a.name, a.description, a.points, a.category
            FROM player_achievements pa
            JOIN achievements a ON pa.achievement_id = a.achievement_id
            WHERE pa.account_id = ?
            ORDER BY pa.unlocked_at DESC
            LIMIT 10
        ]], accountId)

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

    return profile
end

-- Initialize
addEventHandler("onResourceStart", resourceRoot, function()
    Config = exports.jebiga_core:getConfig()
    outputDebugString("[Jebiga UserPanel] User panel initialized")
end)

-- Request handler
addEvent("weevil:userpanel:requestOpen", true)
addEventHandler("weevil:userpanel:requestOpen", root, function()
    local profile = getPlayerProfileData(client)
    if profile then
        triggerClientEvent(client, "weevil:userpanel:open", client, profile)
    end
end)

-- Update settings handler
addEvent("weevil:userpanel:updateSettings", true)
addEventHandler("weevil:userpanel:updateSettings", root, function(settings)
    if not settings then return end

    local success = exports.jebiga_core:updatePlayerSettings(client, settings)
    if success then
        triggerClientEvent(client, "weevil:notification:showSuccess", client, "Settings saved!", 3000)
    end
end)
