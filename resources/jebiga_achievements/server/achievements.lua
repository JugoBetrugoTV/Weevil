--[[
    Jebiga Multi-Gamemode - Achievements System
]]

local playerAchievements = {}

function loadPlayerAchievements(player)
    local accountId = exports.jebiga_core:getPlayerAccountId(player)
    if not accountId then return end

    playerAchievements[player] = {}

    local queryHandle = dbQuery(exports.jebiga_core:dbQuery, [[
        SELECT achievement_id FROM player_achievements WHERE account_id = ?
    ]], accountId)

    if queryHandle then
        local result = dbPoll(queryHandle, -1)
        dbFree(queryHandle)

        if result then
            for _, row in ipairs(result) do
                playerAchievements[player][row.achievement_id] = true
            end
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

    local accountId = exports.jebiga_core:getPlayerAccountId(player)
    if not accountId then return false end

    -- Get achievement info
    local queryHandle = dbQuery(exports.jebiga_core:dbQuery, [[
        SELECT * FROM achievements WHERE achievement_id = ?
    ]], achievementId)

    if not queryHandle then return false end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    if not result or #result == 0 then return false end

    local achievement = result[1]

    -- Insert player achievement
    local success = dbExec(exports.jebiga_core:dbExec, [[
        INSERT IGNORE INTO player_achievements (account_id, achievement_id) VALUES (?, ?)
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

        -- Notify player
        triggerClientEvent(player, Events.Achievements.UNLOCKED, player, {
            id = achievementId,
            name = achievement.name,
            description = achievement.description,
            points = achievement.points,
            category = achievement.category
        })

        -- Announce
        outputChatBox("#FFFF00[Achievement] #FFFFFF" .. getPlayerName(player) .. " unlocked: #FFD700" .. achievement.name, root, 255, 255, 255, true)

        return true
    end

    return false
end

function getPlayerAchievements(player)
    local accountId = exports.jebiga_core:getPlayerAccountId(player)
    if not accountId then return {} end

    local queryHandle = dbQuery(exports.jebiga_core:dbQuery, [[
        SELECT pa.*, a.name, a.description, a.points, a.category
        FROM player_achievements pa
        JOIN achievements a ON pa.achievement_id = a.achievement_id
        WHERE pa.account_id = ?
    ]], accountId)

    if not queryHandle then return {} end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    return result or {}
end

-- Cleanup
addEventHandler("onPlayerQuit", root, function()
    playerAchievements[source] = nil
end)

-- Exports
exports.jebiga_achievements = exports.jebiga_achievements or {}
exports.jebiga_achievements.unlockAchievement = unlockAchievement
exports.jebiga_achievements.hasAchievement = hasAchievement
exports.jebiga_achievements.getPlayerAchievements = getPlayerAchievements
