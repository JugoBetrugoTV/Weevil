--[[
    Jebiga Multi-Gamemode - Player Manager
    Handles player data, stats, and persistence
    Uses centralized database from database.lua
]]

local playerCache = {}

-- ============================================
-- PLAYER DATA LOADING
-- ============================================

-- Load player data from database
function loadPlayerData(player, accountId)
    if not accountId then return nil end

    local data = fetchOne([[
        SELECT * FROM accounts WHERE id = ?
    ]], accountId)

    if not data then return nil end

    playerCache[player] = {
        accountId = data.id,
        username = data.username,
        email = data.email,
        adminLevel = data.admin_level or 0,
        vipLevel = data.vip_level or 0,
        vipExpires = data.vip_expires,
        money = data.money or (Config and Config.Currency and Config.Currency.startMoney or 5000),
        totalPoints = data.total_points or 0,
        playtime = data.playtime or 0,
        lastLogin = data.last_login,
        createdAt = data.created_at,
        banned = data.banned == 1,
        banReason = data.ban_reason,
        muted = data.muted == 1,
        muteExpires = data.mute_expires,
        settings = data.settings and Utils and Utils.jsonDecode and Utils.jsonDecode(data.settings) or {}
    }

    -- Set element data for other resources
    setElementData(player, "jebiga:accountId", accountId)
    setElementData(player, "jebiga:money", playerCache[player].money)
    setElementData(player, "jebiga:points", playerCache[player].totalPoints)
    setElementData(player, "jebiga:adminLevel", playerCache[player].adminLevel)
    setElementData(player, "jebiga:vipLevel", playerCache[player].vipLevel)

    -- Load gamemode-specific stats
    loadPlayerStats(player, accountId)

    outputDebugString("[Jebiga] Loaded player data for account " .. accountId)
    return playerCache[player]
end

-- Load player stats for all gamemodes
function loadPlayerStats(player, accountId)
    local result = fetchAll([[
        SELECT * FROM player_stats WHERE account_id = ?
    ]], accountId)

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
    local gamemodes = Config and Config.Gamemodes or {dm = true, race = true, dd = true, hunter = true}
    for gamemode, _ in pairs(gamemodes) do
        if not playerCache[player].stats[gamemode] then
            playerCache[player].stats[gamemode] = {
                points = 0, wins = 0, losses = 0, kills = 0,
                deaths = 0, racesFinished = 0, bestPosition = 0, playtime = 0
            }

            -- Insert initial stats into database
            execute([[
                INSERT IGNORE INTO player_stats (account_id, gamemode)
                VALUES (?, ?)
            ]], accountId, gamemode)
        end
    end
end

-- ============================================
-- PLAYER DATA SAVING
-- ============================================

-- Save player data to database
function savePlayerData(player)
    local data = playerCache[player]
    if not data or not data.accountId then return false end

    -- Save main account data
    execute([[
        UPDATE accounts SET
            money = ?,
            total_points = ?,
            playtime = ?,
            settings = ?,
            last_login = NOW()
        WHERE id = ?
    ]], data.money, data.totalPoints, data.playtime,
        Utils and Utils.jsonEncode and Utils.jsonEncode(data.settings) or "{}",
        data.accountId)

    -- Save gamemode stats
    if data.stats then
        for gamemode, stats in pairs(data.stats) do
            execute([[
                UPDATE player_stats SET
                    points = ?,
                    wins = ?,
                    losses = ?,
                    kills = ?,
                    deaths = ?,
                    races_finished = ?,
                    best_position = ?,
                    playtime = ?,
                    last_played = NOW()
                WHERE account_id = ? AND gamemode = ?
            ]], stats.points, stats.wins, stats.losses, stats.kills, stats.deaths,
                stats.racesFinished, stats.bestPosition, stats.playtime,
                data.accountId, gamemode)
        end
    end

    outputDebugString("[Jebiga] Saved player data for account " .. data.accountId)
    return true
end

-- ============================================
-- PLAYER DATA ACCESS
-- ============================================

-- Get cached player data
function getCachedPlayerData(player)
    return playerCache[player]
end

-- Check if player has data loaded
function isPlayerDataLoaded(player)
    return playerCache[player] ~= nil
end

-- ============================================
-- MONEY FUNCTIONS
-- ============================================

function getPlayerMoney(player)
    local data = playerCache[player]
    if data then
        return data.money or 0
    end
    return getElementData(player, "jebiga:money") or 0
end

function addPlayerMoney(player, amount, reason)
    local data = playerCache[player]
    if not data then
        -- Fallback to element data for non-cached players
        local current = getElementData(player, "jebiga:money") or 0
        setElementData(player, "jebiga:money", current + amount)
        return true
    end

    data.money = (data.money or 0) + amount
    setElementData(player, "jebiga:money", data.money)

    -- Log transaction
    if data.accountId then
        execute([[
            INSERT INTO transactions (account_id, type, amount, reason, balance_after)
            VALUES (?, 'earn', ?, ?, ?)
        ]], data.accountId, amount, reason or "Unknown", data.money)
    end

    -- Update client
    if Events and Events.Currency and Events.Currency.UPDATE_MONEY then
        triggerClientEvent(player, Events.Currency.UPDATE_MONEY, player, data.money, amount)
    end

    return true
end

function removePlayerMoney(player, amount, reason)
    local data = playerCache[player]
    if not data then return false end

    if (data.money or 0) < amount then return false end

    data.money = data.money - amount
    setElementData(player, "jebiga:money", data.money)

    -- Log transaction
    if data.accountId then
        execute([[
            INSERT INTO transactions (account_id, type, amount, reason, balance_after)
            VALUES (?, 'spend', ?, ?, ?)
        ]], data.accountId, -amount, reason or "Unknown", data.money)
    end

    -- Update client
    if Events and Events.Currency and Events.Currency.UPDATE_MONEY then
        triggerClientEvent(player, Events.Currency.UPDATE_MONEY, player, data.money, -amount)
    end

    return true
end

-- ============================================
-- POINTS FUNCTIONS
-- ============================================

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
    data.totalPoints = (data.totalPoints or 0) + amount
    setElementData(player, "jebiga:points", data.totalPoints)

    -- Add to gamemode-specific points if specified
    if gamemode and data.stats and data.stats[gamemode] then
        data.stats[gamemode].points = (data.stats[gamemode].points or 0) + amount
    end

    -- Check for VIP bonus
    if data.vipLevel and data.vipLevel > 0 then
        local vipMultiplier = Config and Config.VIP and Config.VIP.bonusMultiplier or 1.5
        local bonus = math.floor(amount * (vipMultiplier - 1))
        data.totalPoints = data.totalPoints + bonus
        if gamemode and data.stats and data.stats[gamemode] then
            data.stats[gamemode].points = data.stats[gamemode].points + bonus
        end
    end

    -- Update client
    if Events and Events.Currency and Events.Currency.UPDATE_POINTS then
        triggerClientEvent(player, Events.Currency.UPDATE_POINTS, player, data.totalPoints, amount, gamemode)
    end

    -- Check achievements
    safeCallAchievements(player, "checkPointsAchievements")

    return true
end

-- ============================================
-- STATS FUNCTIONS
-- ============================================

function getPlayerStats(player, gamemode)
    local data = playerCache[player]
    if not data or not data.stats then return nil end

    if gamemode then
        return data.stats[gamemode]
    end

    return data.stats
end

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
    if not data or not data.stats then return false end

    if not data.stats[gamemode] then
        data.stats[gamemode] = {points = 0, wins = 0, losses = 0, kills = 0, deaths = 0, racesFinished = 0, bestPosition = 0, playtime = 0}
    end

    data.stats[gamemode].wins = (data.stats[gamemode].wins or 0) + 1

    -- Award points and money
    local cfg = Config and Config.Gamemodes and Config.Gamemodes[gamemode]
    if cfg then
        if cfg.pointsPerWin then
            addPlayerPoints(player, cfg.pointsPerWin, gamemode)
        end
        if cfg.moneyPerWin then
            addPlayerMoney(player, cfg.moneyPerWin, gamemode .. " win")
        end
    else
        -- Default rewards
        addPlayerPoints(player, 50, gamemode)
        addPlayerMoney(player, 100, gamemode .. " win")
    end

    -- Check achievements
    safeCallAchievements(player, "checkWinAchievements", gamemode)

    return true
end

-- Add kill to player
function addPlayerKill(player, gamemode)
    local data = playerCache[player]
    if not data or not data.stats then return false end

    if not data.stats[gamemode] then
        data.stats[gamemode] = {points = 0, wins = 0, losses = 0, kills = 0, deaths = 0, racesFinished = 0, bestPosition = 0, playtime = 0}
    end

    data.stats[gamemode].kills = (data.stats[gamemode].kills or 0) + 1

    -- Award points and money
    local cfg = Config and Config.Gamemodes and Config.Gamemodes[gamemode]
    if cfg then
        if cfg.pointsPerKill then
            addPlayerPoints(player, cfg.pointsPerKill, gamemode)
        end
        if cfg.moneyPerKill then
            addPlayerMoney(player, cfg.moneyPerKill, gamemode .. " kill")
        end
    else
        -- Default rewards
        addPlayerPoints(player, 10, gamemode)
        addPlayerMoney(player, 25, gamemode .. " kill")
    end

    -- Check achievements
    safeCallAchievements(player, "checkKillAchievements")

    return true
end

-- Add death to player
function addPlayerDeath(player, gamemode)
    local data = playerCache[player]
    if not data or not data.stats then return false end

    if not data.stats[gamemode] then
        data.stats[gamemode] = {points = 0, wins = 0, losses = 0, kills = 0, deaths = 0, racesFinished = 0, bestPosition = 0, playtime = 0}
    end

    data.stats[gamemode].deaths = (data.stats[gamemode].deaths or 0) + 1

    return true
end

-- ============================================
-- VIP & ADMIN FUNCTIONS
-- ============================================

function isPlayerVIP(player)
    local data = playerCache[player]
    if not data then
        return (getElementData(player, "jebiga:vipLevel") or 0) > 0
    end

    if not data.vipLevel or data.vipLevel == 0 then return false end

    if data.vipExpires then
        local now = getRealTime().timestamp
        if type(data.vipExpires) == "number" then
            return data.vipExpires > now
        end
    end

    return data.vipLevel > 0
end

function isPlayerAdmin(player, minLevel)
    local data = playerCache[player]
    if not data then
        local adminLevel = getElementData(player, "jebiga:adminLevel") or 0
        return adminLevel >= (minLevel or 1)
    end

    minLevel = minLevel or 1
    return (data.adminLevel or 0) >= minLevel
end

function getPlayerAdminLevel(player)
    local data = playerCache[player]
    if data then
        return data.adminLevel or 0
    end
    return getElementData(player, "jebiga:adminLevel") or 0
end

function getPlayerRank(player)
    local data = playerCache[player]
    if not data then return nil end

    if Utils and Utils.calculateRank then
        return Utils.calculateRank(data.totalPoints)
    end

    -- Default rank calculation
    local points = data.totalPoints or 0
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

-- ============================================
-- SETTINGS FUNCTIONS
-- ============================================

function updatePlayerSettings(player, settings)
    local data = playerCache[player]
    if not data then return false end

    if Utils and Utils.mergeTables then
        data.settings = Utils.mergeTables(data.settings or {}, settings)
    else
        data.settings = data.settings or {}
        for k, v in pairs(settings) do
            data.settings[k] = v
        end
    end

    return true
end

function getPlayerSettings(player)
    local data = playerCache[player]
    return data and data.settings or {}
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Safely call achievement functions
function safeCallAchievements(player, funcName, ...)
    local achievementsRes = getResourceFromName("jebiga_achievements")
    if achievementsRes and getResourceState(achievementsRes) == "running" then
        local func = exports.jebiga_achievements[funcName]
        if func then
            pcall(func, exports.jebiga_achievements, player, ...)
        end
    end
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Clear player cache on disconnect
addEventHandler("onPlayerQuit", root, function()
    if playerCache[source] then
        savePlayerData(source)
        playerCache[source] = nil
    end
end)

-- Periodic save (every 5 minutes)
setTimer(function()
    local savedCount = 0
    for player, _ in pairs(playerCache) do
        if isElement(player) then
            savePlayerData(player)
            savedCount = savedCount + 1
        else
            playerCache[player] = nil
        end
    end
    if savedCount > 0 then
        outputDebugString("[Jebiga] Auto-saved " .. savedCount .. " player(s)")
    end
end, 300000, 0)

-- ============================================
-- EXPORTS
-- ============================================

-- Make functions globally accessible for other scripts in same resource
_G.loadPlayerData = loadPlayerData
_G.savePlayerData = savePlayerData
_G.getCachedPlayerData = getCachedPlayerData
_G.isPlayerDataLoaded = isPlayerDataLoaded
_G.getPlayerMoney = getPlayerMoney
_G.addPlayerMoney = addPlayerMoney
_G.removePlayerMoney = removePlayerMoney
_G.getPlayerPoints = getPlayerPoints
_G.addPlayerPoints = addPlayerPoints
_G.getPlayerStats = getPlayerStats
_G.updatePlayerStats = updatePlayerStats
_G.addPlayerWin = addPlayerWin
_G.addPlayerKill = addPlayerKill
_G.addPlayerDeath = addPlayerDeath
_G.isPlayerVIP = isPlayerVIP
_G.isPlayerAdmin = isPlayerAdmin
_G.getPlayerAdminLevel = getPlayerAdminLevel
_G.getPlayerRank = getPlayerRank
_G.updatePlayerSettings = updatePlayerSettings
_G.getPlayerSettings = getPlayerSettings
