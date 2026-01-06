--[[
    Weevil Multi-Gamemode - Currency System
    Handles money and points transactions
]]

-- Currency types
local CURRENCY_MONEY = "money"
local CURRENCY_POINTS = "points"

-- Transaction reasons
local REASONS = {
    WIN = "Round Win",
    KILL = "Player Kill",
    FINISH = "Race Finish",
    STUNT = "Stunt Complete",
    GOAL = "Carball Goal",
    CATCH = "Hot Pursuit Catch",
    ESCAPE = "Hot Pursuit Escape",
    ACHIEVEMENT = "Achievement Reward",
    DAILY = "Daily Bonus",
    ADMIN = "Admin Grant",
    PURCHASE = "Shop Purchase",
    TRANSFER = "Player Transfer",
    CLAN = "Clan Transaction"
}

-- Give money to player with validation
function giveMoney(player, amount, reason)
    if not isElement(player) then return false, "Invalid player" end
    if type(amount) ~= "number" or amount <= 0 then return false, "Invalid amount" end

    local success = addPlayerMoney(player, math.floor(amount), reason or REASONS.ADMIN)

    if success then
        -- Show notification
        triggerClientEvent(player, Events.Currency.REWARD_RECEIVED, player, {
            type = CURRENCY_MONEY,
            amount = amount,
            reason = reason
        })
    end

    return success
end

-- Take money from player with validation
function takeMoney(player, amount, reason)
    if not isElement(player) then return false, "Invalid player" end
    if type(amount) ~= "number" or amount <= 0 then return false, "Invalid amount" end

    local currentMoney = getPlayerMoney(player)
    if currentMoney < amount then
        return false, "Insufficient funds"
    end

    return removePlayerMoney(player, math.floor(amount), reason or REASONS.PURCHASE)
end

-- Give points to player
function givePoints(player, amount, gamemode, reason)
    if not isElement(player) then return false, "Invalid player" end
    if type(amount) ~= "number" or amount <= 0 then return false, "Invalid amount" end

    local success = addPlayerPoints(player, math.floor(amount), gamemode)

    if success then
        -- Show notification
        triggerClientEvent(player, Events.Currency.REWARD_RECEIVED, player, {
            type = CURRENCY_POINTS,
            amount = amount,
            gamemode = gamemode,
            reason = reason
        })
    end

    return success
end

-- Transfer money between players
function transferMoney(fromPlayer, toPlayer, amount)
    if not isElement(fromPlayer) or not isElement(toPlayer) then
        return false, "Invalid player"
    end

    if fromPlayer == toPlayer then
        return false, "Cannot transfer to yourself"
    end

    if type(amount) ~= "number" or amount <= 0 then
        return false, "Invalid amount"
    end

    local fromMoney = getPlayerMoney(fromPlayer)
    if fromMoney < amount then
        return false, "Insufficient funds"
    end

    -- Take from sender
    local taken = removePlayerMoney(fromPlayer, amount, REASONS.TRANSFER .. " to " .. getPlayerName(toPlayer))
    if not taken then
        return false, "Transfer failed"
    end

    -- Give to receiver
    local given = addPlayerMoney(toPlayer, amount, REASONS.TRANSFER .. " from " .. getPlayerName(fromPlayer))
    if not given then
        -- Refund if failed
        addPlayerMoney(fromPlayer, amount, "Refund - failed transfer")
        return false, "Transfer failed"
    end

    outputChatBox("#00FF00[Transfer] #FFFFFFYou sent $" .. Utils.formatNumber(amount) .. " to " .. getPlayerName(toPlayer), fromPlayer, 255, 255, 255, true)
    outputChatBox("#00FF00[Transfer] #FFFFFFYou received $" .. Utils.formatNumber(amount) .. " from " .. getPlayerName(fromPlayer), toPlayer, 255, 255, 255, true)

    return true
end

-- Award daily bonus
function awardDailyBonus(player)
    local data = getCachedPlayerData(player)
    if not data then return false end

    local lastDaily = getElementData(player, "lastDailyBonus") or 0
    local now = getRealTime().timestamp
    local dayInSeconds = 86400

    if now - lastDaily < dayInSeconds then
        local remaining = dayInSeconds - (now - lastDaily)
        local hours = math.floor(remaining / 3600)
        local minutes = math.floor((remaining % 3600) / 60)
        return false, string.format("Next daily bonus in %dh %dm", hours, minutes)
    end

    -- Calculate streak bonus
    local streak = (getElementData(player, "dailyStreak") or 0) + 1
    if now - lastDaily > dayInSeconds * 2 then
        streak = 1 -- Reset streak if missed a day
    end

    local baseBonus = 100
    local streakBonus = math.min(streak * 25, 250) -- Max +250 from streak
    local totalBonus = baseBonus + streakBonus

    -- VIP bonus
    if isPlayerVIP(player) then
        totalBonus = math.floor(totalBonus * Config.VIP.bonusMultiplier)
    end

    giveMoney(player, totalBonus, REASONS.DAILY)
    givePoints(player, math.floor(totalBonus / 10), nil, REASONS.DAILY)

    setElementData(player, "lastDailyBonus", now)
    setElementData(player, "dailyStreak", streak)

    outputChatBox("#FFFF00[Daily Bonus] #FFFFFFYou received $" .. Utils.formatNumber(totalBonus) .. "! (Streak: " .. streak .. " days)", player, 255, 255, 255, true)

    return true, totalBonus
end

-- Get leaderboard (top players by points)
function getPointsLeaderboard(limit, gamemode)
    limit = limit or 10

    local query
    if gamemode then
        query = [[
            SELECT a.username, ps.points
            FROM player_stats ps
            JOIN accounts a ON ps.account_id = a.id
            WHERE ps.gamemode = ?
            ORDER BY ps.points DESC
            LIMIT ?
        ]]
    else
        query = [[
            SELECT username, total_points as points
            FROM accounts
            ORDER BY total_points DESC
            LIMIT ?
        ]]
    end

    local queryHandle
    if gamemode then
        queryHandle = dbQuery(connection, query, gamemode, limit)
    else
        queryHandle = dbQuery(connection, query, limit)
    end

    if not queryHandle then return {} end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    return result or {}
end

-- Get money leaderboard
function getMoneyLeaderboard(limit)
    limit = limit or 10

    local queryHandle = dbQuery(connection, [[
        SELECT username, money
        FROM accounts
        ORDER BY money DESC
        LIMIT ?
    ]], limit)

    if not queryHandle then return {} end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    return result or {}
end

-- Commands
addCommandHandler("pay", function(player, cmd, targetName, amountStr)
    if not targetName or not amountStr then
        outputChatBox("Usage: /pay [player] [amount]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("Player not found.", player, 255, 0, 0)
        return
    end

    local amount = tonumber(amountStr)
    if not amount or amount <= 0 then
        outputChatBox("Invalid amount.", player, 255, 0, 0)
        return
    end

    local success, err = transferMoney(player, target, amount)
    if not success then
        outputChatBox("Transfer failed: " .. (err or "Unknown error"), player, 255, 0, 0)
    end
end)

addCommandHandler("daily", function(player)
    local success, result = awardDailyBonus(player)
    if not success then
        outputChatBox("#FF0000[Daily] #FFFFFF" .. (result or "You already claimed your daily bonus."), player, 255, 255, 255, true)
    end
end)

addCommandHandler("balance", function(player)
    local money = getPlayerMoney(player)
    local points = getPlayerPoints(player)
    outputChatBox("#FFFF00[Balance] #FFFFFFMoney: $" .. Utils.formatNumber(money) .. " | Points: " .. Utils.formatNumber(points), player, 255, 255, 255, true)
end)

addCommandHandler("top", function(player, cmd, typeArg)
    local leaderboard

    if typeArg == "money" then
        leaderboard = getMoneyLeaderboard(10)
        outputChatBox("#FFFF00=== Top 10 Richest Players ===", player, 255, 255, 255, true)
        for i, entry in ipairs(leaderboard) do
            outputChatBox("#FFFFFF" .. i .. ". " .. entry.username .. " - $" .. Utils.formatNumber(entry.money), player, 255, 255, 255, true)
        end
    else
        leaderboard = getPointsLeaderboard(10, typeArg)
        outputChatBox("#FFFF00=== Top 10 Players" .. (typeArg and (" (" .. typeArg .. ")") or "") .. " ===", player, 255, 255, 255, true)
        for i, entry in ipairs(leaderboard) do
            outputChatBox("#FFFFFF" .. i .. ". " .. entry.username .. " - " .. Utils.formatNumber(entry.points) .. " pts", player, 255, 255, 255, true)
        end
    end
end)

-- Helper function to get player from partial name
function getPlayerFromPartialName(name)
    name = name:lower()
    for _, player in ipairs(getElementsByType("player")) do
        if getPlayerName(player):lower():find(name, 1, true) then
            return player
        end
    end
    return nil
end

-- Export functions
_G.giveMoney = giveMoney
_G.takeMoney = takeMoney
_G.givePoints = givePoints
_G.transferMoney = transferMoney
_G.awardDailyBonus = awardDailyBonus
_G.getPointsLeaderboard = getPointsLeaderboard
_G.getMoneyLeaderboard = getMoneyLeaderboard
