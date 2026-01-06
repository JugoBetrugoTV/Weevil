--[[
    Jebiga Multi-Gamemode - Achievements System
]]

local playerAchievements = {}

-- Helper to get account ID
local function getAccountId(player)
    return getElementData(player, "jebiga:accountId")
end

function loadPlayerAchievements(player)
    local accountId = getAccountId(player)
    if not accountId then return end

    playerAchievements[player] = {}

    local result = exports.jebiga_core:db_fetchAll([[
        SELECT achievement_id FROM player_achievements WHERE account_id = ?
    ]], accountId)

    if result then
        for _, row in ipairs(result) do
            playerAchievements[player][row.achievement_id] = true
        end
    end
end

function hasAchievement(player, achievementId)
    if not playerAchievements[player] then
        loadPlayerAchievements(player)
    end
    return playerAchievements[player] and playerAchievements[player][achievementId] or false
end

function unlockAchievement(player, achievementId)
    if not isElement(player) then return false end
    if hasAchievement(player, achievementId) then return false end

    local accountId = getAccountId(player)
    if not accountId then return false end

    -- Get achievement info
    local achievement = exports.jebiga_core:db_fetchOne([[
        SELECT * FROM achievements WHERE achievement_id = ?
    ]], achievementId)

    if not achievement then return false end

    -- Insert player achievement
    local success = exports.jebiga_core:db_execute([[
        INSERT IGNORE INTO player_achievements (account_id, achievement_id, unlocked, unlocked_at)
        VALUES (?, ?, 1, NOW())
    ]], accountId, achievementId)

    if success then
        if not playerAchievements[player] then
            playerAchievements[player] = {}
        end
        playerAchievements[player][achievementId] = true

        -- Award points
        if achievement.points then
            exports.jebiga_core:addPlayerPoints(player, achievement.points, nil)
        end

        -- Award money
        if achievement.reward_money and achievement.reward_money > 0 then
            exports.jebiga_core:addPlayerMoney(player, achievement.reward_money, "Achievement: " .. achievement.name)
        end

        -- Notify player
        if Events and Events.Achievements and Events.Achievements.UNLOCKED then
            triggerClientEvent(player, Events.Achievements.UNLOCKED, player, {
                id = achievementId,
                name = achievement.name,
                description = achievement.description,
                points = achievement.points,
                category = achievement.category
            })
        end

        -- Announce
        outputChatBox("#FFFF00[Achievement] #FFFFFF" .. getPlayerName(player) .. " unlocked: #FFD700" .. achievement.name, root, 255, 255, 255, true)

        return true
    end

    return false
end

function getPlayerAchievementList(player)
    local accountId = getAccountId(player)
    if not accountId then return {} end

    local result = exports.jebiga_core:db_fetchAll([[
        SELECT pa.*, a.name, a.description, a.points, a.category
        FROM player_achievements pa
        JOIN achievements a ON pa.achievement_id = a.achievement_id
        WHERE pa.account_id = ?
    ]], accountId)

    return result or {}
end

-- Check achievement conditions
function checkWinAchievements(player, gamemode)
    local data = exports.jebiga_core:getCachedPlayerData(player)
    if not data or not data.stats or not data.stats[gamemode] then return end

    local wins = data.stats[gamemode].wins or 0

    if wins >= 1 then unlockAchievement(player, "first_win") end
    if wins >= 10 then unlockAchievement(player, "win_10") end
    if wins >= 50 then unlockAchievement(player, "win_50") end
    if wins >= 100 then unlockAchievement(player, "win_100") end
    if wins >= 500 then unlockAchievement(player, "win_500") end

    -- Gamemode specific
    if gamemode == "dd" and wins >= 10 then unlockAchievement(player, "dd_win_10") end
    if gamemode == "hunter" and wins >= 10 then unlockAchievement(player, "hunter_win_10") end
end

function checkKillAchievements(player)
    local totalKills = 0
    local data = exports.jebiga_core:getCachedPlayerData(player)
    if data and data.stats then
        for _, stats in pairs(data.stats) do
            totalKills = totalKills + (stats.kills or 0)
        end
    end

    if totalKills >= 1 then unlockAchievement(player, "first_kill") end
    if totalKills >= 100 then unlockAchievement(player, "kill_100") end
    if totalKills >= 500 then unlockAchievement(player, "kill_500") end
    if totalKills >= 1000 then unlockAchievement(player, "kill_1000") end
end

function checkPointsAchievements(player)
    local data = exports.jebiga_core:getCachedPlayerData(player)
    if not data then return end

    local money = data.money or 0

    if money >= 10000 then unlockAchievement(player, "money_10k") end
    if money >= 100000 then unlockAchievement(player, "money_100k") end
    if money >= 1000000 then unlockAchievement(player, "money_1m") end
end

-- Cleanup
addEventHandler("onPlayerQuit", root, function()
    playerAchievements[source] = nil
end)

-- Make functions available for other resources
_G.unlockAchievement = unlockAchievement
_G.hasAchievement = hasAchievement
_G.getPlayerAchievementList = getPlayerAchievementList
_G.checkWinAchievements = checkWinAchievements
_G.checkKillAchievements = checkKillAchievements
_G.checkPointsAchievements = checkPointsAchievements
