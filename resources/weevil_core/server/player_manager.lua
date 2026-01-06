--[[
    Weevil Multi-Gamemode - Player Manager
    Handles player data, stats, and persistence
]]

local playerCache = {}

-- Load player data from database
function loadPlayerData(player, accountId)
    local queryHandle = dbQuery(connection, [[
        SELECT * FROM accounts WHERE id = ?
    ]], accountId)

    if not queryHandle then return nil end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    if result and #result > 0 then
        local data = result[1]

        playerCache[player] = {
            accountId = data.id,
            username = data.username,
            email = data.email,
            adminLevel = data.admin_level or 0,
            vipLevel = data.vip_level or 0,
            vipExpires = data.vip_expires,
            money = data.money or Config.Currency.startMoney,
            totalPoints = data.total_points or 0,
            playtime = data.playtime or 0,
            lastLogin = data.last_login,
            createdAt = data.created_at,
            banned = data.banned == 1,
            banReason = data.ban_reason,
            muted = data.muted == 1,
            muteExpires = data.mute_expires,
            settings = Utils.jsonDecode(data.settings) or {}
        }

        -- Load gamemode-specific stats
        loadPlayerStats(player, accountId)

        return playerCache[player]
    end

    return nil
end

-- Load player stats for all gamemodes
function loadPlayerStats(player, accountId)
    local queryHandle = dbQuery(connection, [[
        SELECT * FROM player_stats WHERE account_id = ?
    ]], accountId)

    if not queryHandle then return end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    if not playerCache[player] then return end

    playerCache[player].stats = {}

    if result then
        for _, row in ipairs(result) do
            playerCache[player].stats[row.gamemode] = {
                points = row.points or 0,
                wins = row.wins or 0,
                losses = row.losses or 0,
                kills = row.kills or 0,
                deaths = row.deaths or 0,
                racesFinished = row.races_finished or 0,
                bestPosition = row.best_position or 0,
                playtime = row.playtime or 0
            }
        end
    end

    -- Initialize missing gamemode stats
    for gamemode, _ in pairs(Config.Gamemodes) do
        if not playerCache[player].stats[gamemode] then
            playerCache[player].stats[gamemode] = {
                points = 0,
                wins = 0,
                losses = 0,
                kills = 0,
                deaths = 0,
                racesFinished = 0,
                bestPosition = 0,
                playtime = 0
            }

            -- Insert initial stats into database
            dbExec(connection, [[
                INSERT INTO player_stats (account_id, gamemode)
                VALUES (?, ?)
            ]], accountId, gamemode)
        end
    end
end

-- Save player data to database
function savePlayerData(player)
    local data = playerCache[player]
    if not data then return false end

    dbExec(connection, [[
        UPDATE accounts SET
            money = ?,
            total_points = ?,
            playtime = ?,
            settings = ?,
            last_login = NOW()
        WHERE id = ?
    ]], data.money, data.totalPoints, data.playtime, Utils.jsonEncode(data.settings), data.accountId)

    -- Save gamemode stats
    for gamemode, stats in pairs(data.stats or {}) do
        dbExec(connection, [[
            UPDATE player_stats SET
                points = ?,
                wins = ?,
                losses = ?,
                kills = ?,
                deaths = ?,
                races_finished = ?,
                best_position = ?,
                playtime = ?
            WHERE account_id = ? AND gamemode = ?
        ]], stats.points, stats.wins, stats.losses, stats.kills, stats.deaths,
            stats.racesFinished, stats.bestPosition, stats.playtime,
            data.accountId, gamemode)
    end

    return true
end

-- Get cached player data
function getCachedPlayerData(player)
    return playerCache[player]
end

-- Update player money
function getPlayerMoney(player)
    local data = playerCache[player]
    return data and data.money or 0
end

function addPlayerMoney(player, amount, reason)
    local data = playerCache[player]
    if not data then return false end

    data.money = data.money + amount

    -- Log transaction
    dbExec(connection, [[
        INSERT INTO transaction_log (account_id, type, amount, reason, balance_after)
        VALUES (?, 'credit', ?, ?, ?)
    ]], data.accountId, amount, reason or "Unknown", data.money)

    -- Update client
    triggerClientEvent(player, Events.Currency.UPDATE_MONEY, player, data.money, amount)

    return true
end

function removePlayerMoney(player, amount, reason)
    local data = playerCache[player]
    if not data then return false end

    if data.money < amount then return false end

    data.money = data.money - amount

    -- Log transaction
    dbExec(connection, [[
        INSERT INTO transaction_log (account_id, type, amount, reason, balance_after)
        VALUES (?, 'debit', ?, ?, ?)
    ]], data.accountId, -amount, reason or "Unknown", data.money)

    -- Update client
    triggerClientEvent(player, Events.Currency.UPDATE_MONEY, player, data.money, -amount)

    return true
end

-- Update player points
function getPlayerPoints(player, gamemode)
    local data = playerCache[player]
    if not data then return 0 end

    if gamemode then
        return data.stats and data.stats[gamemode] and data.stats[gamemode].points or 0
    end

    return data.totalPoints or 0
end

function addPlayerPoints(player, amount, gamemode)
    local data = playerCache[player]
    if not data then return false end

    -- Add to total points
    data.totalPoints = data.totalPoints + amount

    -- Add to gamemode-specific points if specified
    if gamemode and data.stats and data.stats[gamemode] then
        data.stats[gamemode].points = data.stats[gamemode].points + amount
    end

    -- Check for VIP bonus
    if data.vipLevel > 0 and data.vipExpires then
        local vipExpires = data.vipExpires
        local now = getRealTime().timestamp
        if vipExpires > now then
            local bonus = math.floor(amount * (Config.VIP.bonusMultiplier - 1))
            data.totalPoints = data.totalPoints + bonus
            if gamemode and data.stats[gamemode] then
                data.stats[gamemode].points = data.stats[gamemode].points + bonus
            end
        end
    end

    -- Update client
    triggerClientEvent(player, Events.Currency.UPDATE_POINTS, player, data.totalPoints, amount, gamemode)

    -- Check achievements
    checkPointsAchievements(player)

    return true
end

-- Get player stats
function getPlayerStats(player, gamemode)
    local data = playerCache[player]
    if not data or not data.stats then return nil end

    if gamemode then
        return data.stats[gamemode]
    end

    return data.stats
end

-- Update player stats
function updatePlayerStats(player, gamemode, statType, value)
    local data = playerCache[player]
    if not data or not data.stats or not data.stats[gamemode] then return false end

    if data.stats[gamemode][statType] ~= nil then
        data.stats[gamemode][statType] = data.stats[gamemode][statType] + (value or 1)
        return true
    end

    return false
end

-- Add win to player
function addPlayerWin(player, gamemode)
    local data = playerCache[player]
    if not data or not data.stats or not data.stats[gamemode] then return false end

    data.stats[gamemode].wins = data.stats[gamemode].wins + 1

    -- Award points and money
    local cfg = Config.Gamemodes[gamemode]
    if cfg then
        if cfg.pointsPerWin then
            addPlayerPoints(player, cfg.pointsPerWin, gamemode)
        end
        if cfg.moneyPerWin then
            addPlayerMoney(player, cfg.moneyPerWin, gamemode .. " win")
        end
    end

    -- Check achievements
    checkWinAchievements(player, gamemode)

    return true
end

-- Add kill to player
function addPlayerKill(player, gamemode)
    local data = playerCache[player]
    if not data or not data.stats or not data.stats[gamemode] then return false end

    data.stats[gamemode].kills = data.stats[gamemode].kills + 1

    -- Award points and money
    local cfg = Config.Gamemodes[gamemode]
    if cfg then
        if cfg.pointsPerKill then
            addPlayerPoints(player, cfg.pointsPerKill, gamemode)
        end
        if cfg.moneyPerKill then
            addPlayerMoney(player, cfg.moneyPerKill, gamemode .. " kill")
        end
    end

    -- Check achievements
    checkKillAchievements(player)

    return true
end

-- Add death to player
function addPlayerDeath(player, gamemode)
    local data = playerCache[player]
    if not data or not data.stats or not data.stats[gamemode] then return false end

    data.stats[gamemode].deaths = data.stats[gamemode].deaths + 1

    return true
end

-- Check points-related achievements
function checkPointsAchievements(player)
    local data = playerCache[player]
    if not data then return end

    if data.totalPoints >= 10000 then
        exports.weevil_achievements:unlockAchievement(player, "points_10k")
    end
    if data.totalPoints >= 100000 then
        exports.weevil_achievements:unlockAchievement(player, "points_100k")
    end
end

-- Check win-related achievements
function checkWinAchievements(player, gamemode)
    local data = playerCache[player]
    if not data or not data.stats then return end

    local totalWins = 0
    for _, stats in pairs(data.stats) do
        totalWins = totalWins + (stats.wins or 0)
    end

    if totalWins >= 1 then
        exports.weevil_achievements:unlockAchievement(player, "first_win")
    end
    if totalWins >= 10 then
        exports.weevil_achievements:unlockAchievement(player, "win_10")
    end
    if totalWins >= 100 then
        exports.weevil_achievements:unlockAchievement(player, "win_100")
    end
    if totalWins >= 1000 then
        exports.weevil_achievements:unlockAchievement(player, "win_1000")
    end
end

-- Check kill-related achievements
function checkKillAchievements(player)
    local data = playerCache[player]
    if not data or not data.stats then return end

    local totalKills = 0
    for _, stats in pairs(data.stats) do
        totalKills = totalKills + (stats.kills or 0)
    end

    if totalKills >= 1 then
        exports.weevil_achievements:unlockAchievement(player, "first_kill")
    end
    if totalKills >= 100 then
        exports.weevil_achievements:unlockAchievement(player, "kill_100")
    end
    if totalKills >= 1000 then
        exports.weevil_achievements:unlockAchievement(player, "kill_1000")
    end
end

-- Get player rank
function getPlayerRank(player)
    local data = playerCache[player]
    if not data then return nil end

    return Utils.calculateRank(data.totalPoints)
end

-- Check if player is VIP
function isPlayerVIP(player)
    local data = playerCache[player]
    if not data or data.vipLevel == 0 then return false end

    if data.vipExpires then
        local now = getRealTime().timestamp
        return data.vipExpires > now
    end

    return data.vipLevel > 0
end

-- Check if player is admin
function isPlayerAdmin(player, minLevel)
    local data = playerCache[player]
    if not data then return false end

    minLevel = minLevel or 1
    return data.adminLevel >= minLevel
end

-- Get player admin level
function getPlayerAdminLevel(player)
    local data = playerCache[player]
    return data and data.adminLevel or 0
end

-- Update player settings
function updatePlayerSettings(player, settings)
    local data = playerCache[player]
    if not data then return false end

    data.settings = Utils.mergeTables(data.settings or {}, settings)

    return true
end

-- Get player settings
function getPlayerSettings(player)
    local data = playerCache[player]
    return data and data.settings or {}
end

-- Clear player cache on disconnect
addEventHandler("onPlayerQuit", root, function()
    if playerCache[source] then
        savePlayerData(source)
        playerCache[source] = nil
    end
end)

-- Periodic save (every 5 minutes)
setTimer(function()
    for player, _ in pairs(playerCache) do
        if isElement(player) then
            savePlayerData(player)
        end
    end
end, 300000, 0)
