--[[
    Jebiga Multi-Gamemode - Currency System
    Handles money and points transactions
    Uses database functions from database.lua
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

-- ============================================
-- MONEY FUNCTIONS
-- ============================================

-- Give money to player with validation
function giveMoney(player, amount, reason)
    if not isElement(player) then return false, "Invalid player" end
    if type(amount) ~= "number" or amount <= 0 then return false, "Invalid amount" end

    -- Check if player is logged in
    local accountId = getElementData(player, "jebiga:accountId")
    if not accountId then
        return false, "Player not logged in"
    end

    local success = addPlayerMoney(player, math.floor(amount), reason or REASONS.ADMIN)

    if success then
        -- Show notification
        triggerClientEvent(player, "jebiga:currency:reward", player, {
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

-- ============================================
-- POINTS FUNCTIONS
-- ============================================

-- Give points to player
function givePoints(player, amount, gamemode, reason)
    if not isElement(player) then return false, "Invalid player" end
    if type(amount) ~= "number" or amount <= 0 then return false, "Invalid amount" end

    local success = addPlayerPoints(player, math.floor(amount), gamemode)

    if success then
        -- Show notification
        triggerClientEvent(player, "jebiga:currency:reward", player, {
            type = CURRENCY_POINTS,
            amount = amount,
            gamemode = gamemode,
            reason = reason
        })
    end

    return success
end

-- ============================================
-- TRANSFER FUNCTIONS
-- ============================================

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

    -- Check if both are logged in
    local fromAccount = getElementData(fromPlayer, "jebiga:accountId")
    local toAccount = getElementData(toPlayer, "jebiga:accountId")

    if not fromAccount then
        return false, "You must be logged in"
    end

    if not toAccount then
        return false, "Target player must be logged in"
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

    -- Format number helper
    local function formatNumber(num)
        if Utils and Utils.formatNumber then
            return Utils.formatNumber(num)
        end
        local formatted = tostring(num)
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if k == 0 then break end
        end
        return formatted
    end

    outputChatBox("#00FF00[Transfer] #FFFFFFYou sent $" .. formatNumber(amount) .. " to " .. getPlayerName(toPlayer), fromPlayer, 255, 255, 255, true)
    outputChatBox("#00FF00[Transfer] #FFFFFFYou received $" .. formatNumber(amount) .. " from " .. getPlayerName(fromPlayer), toPlayer, 255, 255, 255, true)

    return true
end

-- ============================================
-- DAILY BONUS
-- ============================================

function awardDailyBonus(player)
    local data = getCachedPlayerData(player)
    if not data then
        return false, "You must be logged in"
    end

    local lastDaily = getElementData(player, "jebiga:lastDailyBonus") or 0
    local now = getRealTime().timestamp
    local dayInSeconds = 86400

    if now - lastDaily < dayInSeconds then
        local remaining = dayInSeconds - (now - lastDaily)
        local hours = math.floor(remaining / 3600)
        local minutes = math.floor((remaining % 3600) / 60)
        return false, string.format("Next daily bonus in %dh %dm", hours, minutes)
    end

    -- Calculate streak bonus
    local streak = (getElementData(player, "jebiga:dailyStreak") or 0) + 1
    if now - lastDaily > dayInSeconds * 2 then
        streak = 1 -- Reset streak if missed a day
    end

    local baseBonus = 100
    local streakBonus = math.min(streak * 25, 250) -- Max +250 from streak
    local totalBonus = baseBonus + streakBonus

    -- VIP bonus
    if isPlayerVIP and isPlayerVIP(player) then
        local multiplier = Config and Config.VIP and Config.VIP.bonusMultiplier or 1.5
        totalBonus = math.floor(totalBonus * multiplier)
    end

    giveMoney(player, totalBonus, REASONS.DAILY)
    givePoints(player, math.floor(totalBonus / 10), nil, REASONS.DAILY)

    setElementData(player, "jebiga:lastDailyBonus", now)
    setElementData(player, "jebiga:dailyStreak", streak)

    -- Format number helper
    local function formatNumber(num)
        if Utils and Utils.formatNumber then
            return Utils.formatNumber(num)
        end
        return tostring(num)
    end

    outputChatBox("#FFFF00[Daily Bonus] #FFFFFFYou received $" .. formatNumber(totalBonus) .. "! (Streak: " .. streak .. " days)", player, 255, 255, 255, true)

    return true, totalBonus
end

-- ============================================
-- LEADERBOARDS
-- ============================================

function getPointsLeaderboard(limit, gamemode)
    limit = limit or 10

    local result
    if gamemode then
        result = fetchAll([[
            SELECT a.username, ps.points
            FROM player_stats ps
            JOIN accounts a ON ps.account_id = a.id
            WHERE ps.gamemode = ?
            ORDER BY ps.points DESC
            LIMIT ?
        ]], gamemode, limit)
    else
        result = fetchAll([[
            SELECT username, total_points as points
            FROM accounts
            ORDER BY total_points DESC
            LIMIT ?
        ]], limit)
    end

    return result or {}
end

function getMoneyLeaderboard(limit)
    limit = limit or 10

    local result = fetchAll([[
        SELECT username, money
        FROM accounts
        ORDER BY money DESC
        LIMIT ?
    ]], limit)

    return result or {}
end

-- ============================================
-- COMMANDS
-- ============================================

addCommandHandler("pay", function(player, cmd, targetName, amountStr)
    if not targetName or not amountStr then
        outputChatBox("#FFFF00[Jebiga] #FFFFFFUsage: /pay [player] [amount]", player, 255, 255, 255, true)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("#FF0000[Jebiga] #FFFFFFPlayer not found.", player, 255, 255, 255, true)
        return
    end

    local amount = tonumber(amountStr)
    if not amount or amount <= 0 then
        outputChatBox("#FF0000[Jebiga] #FFFFFFInvalid amount.", player, 255, 255, 255, true)
        return
    end

    if amount > 1000000 then
        outputChatBox("#FF0000[Jebiga] #FFFFFFMaximum transfer is $1,000,000.", player, 255, 255, 255, true)
        return
    end

    local success, err = transferMoney(player, target, amount)
    if not success then
        outputChatBox("#FF0000[Jebiga] #FFFFFF" .. (err or "Transfer failed"), player, 255, 255, 255, true)
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

    local function formatNumber(num)
        if Utils and Utils.formatNumber then
            return Utils.formatNumber(num)
        end
        local formatted = tostring(num)
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if k == 0 then break end
        end
        return formatted
    end

    outputChatBox("#FFFF00[Balance] #FFFFFFMoney: $" .. formatNumber(money) .. " | Points: " .. formatNumber(points), player, 255, 255, 255, true)
end)

addCommandHandler("top", function(player, cmd, typeArg)
    local function formatNumber(num)
        if Utils and Utils.formatNumber then
            return Utils.formatNumber(num)
        end
        local formatted = tostring(num)
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if k == 0 then break end
        end
        return formatted
    end

    if typeArg == "money" then
        local leaderboard = getMoneyLeaderboard(10)
        outputChatBox("#FFFF00═══ Top 10 Richest Players ═══", player, 255, 255, 255, true)
        for i, entry in ipairs(leaderboard) do
            local color = i <= 3 and "#FFD700" or "#FFFFFF"
            outputChatBox(color .. i .. ". " .. entry.username .. " - $" .. formatNumber(entry.money), player, 255, 255, 255, true)
        end
    else
        local leaderboard = getPointsLeaderboard(10, typeArg)
        local title = typeArg and ("Top 10 - " .. typeArg:upper()) or "Top 10 Overall"
        outputChatBox("#FFFF00═══ " .. title .. " ═══", player, 255, 255, 255, true)
        for i, entry in ipairs(leaderboard) do
            local color = i <= 3 and "#FFD700" or "#FFFFFF"
            outputChatBox(color .. i .. ". " .. entry.username .. " - " .. formatNumber(entry.points) .. " pts", player, 255, 255, 255, true)
        end
    end
end)

-- Helper function to get player from partial name
function getPlayerFromPartialName(name)
    if not name then return nil end
    name = name:lower()
    for _, player in ipairs(getElementsByType("player")) do
        if getPlayerName(player):lower():find(name, 1, true) then
            return player
        end
    end
    return nil
end

-- ============================================
-- EXPORTS
-- ============================================

_G.giveMoney = giveMoney
_G.takeMoney = takeMoney
_G.givePoints = givePoints
_G.transferMoney = transferMoney
_G.awardDailyBonus = awardDailyBonus
_G.getPointsLeaderboard = getPointsLeaderboard
_G.getMoneyLeaderboard = getMoneyLeaderboard
_G.getPlayerFromPartialName = getPlayerFromPartialName
_G.TRANSACTION_REASONS = REASONS
