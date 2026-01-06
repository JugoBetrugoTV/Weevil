--[[
    Jebiga Multi-Gamemode - Client Main Script
    Core client-side functionality
]]

-- Local variables
local screenW, screenH = guiGetScreenSize()
local localPlayerData = {}
local currentGamemode = nil
local isInLobby = true

-- Initialize client
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Set up render target
    showChat(true)
    showPlayerHudComponent("radar", true)

    -- Request initial data
    triggerServerEvent(Events.Stats.REQUEST_STATS, localPlayer)

    outputChatBox("#FF6600[Jebiga] #FFFFFFClient initialized. Press F1 for help.", 255, 255, 255, true)
end)

-- Handle player data update
addEvent(Events.Account.DATA_UPDATE, true)
addEventHandler(Events.Account.DATA_UPDATE, root, function(data)
    localPlayerData = data or {}
end)

-- Handle currency updates
addEvent(Events.Currency.UPDATE_MONEY, true)
addEventHandler(Events.Currency.UPDATE_MONEY, root, function(newBalance, change)
    localPlayerData.money = newBalance

    if change and change ~= 0 then
        local color = change > 0 and "#00FF00+" or "#FF0000"
        exports.jebiga_core:showNotification("info", color .. "$" .. Utils.formatNumber(math.abs(change)), 3000)
    end
end)

addEvent(Events.Currency.UPDATE_POINTS, true)
addEventHandler(Events.Currency.UPDATE_POINTS, root, function(newPoints, change, gamemode)
    localPlayerData.totalPoints = newPoints

    if change and change ~= 0 then
        local color = change > 0 and "#00FF00+" or "#FF0000"
        local gmText = gamemode and (" (" .. gamemode .. ")") or ""
        exports.jebiga_core:showNotification("info", color .. Utils.formatNumber(math.abs(change)) .. " pts" .. gmText, 3000)
    end
end)

addEvent(Events.Currency.REWARD_RECEIVED, true)
addEventHandler(Events.Currency.REWARD_RECEIVED, root, function(data)
    if data.type == "money" then
        exports.jebiga_core:showNotification("success", "+$" .. Utils.formatNumber(data.amount) .. (data.reason and (" - " .. data.reason) or ""), 4000)
    elseif data.type == "points" then
        exports.jebiga_core:showNotification("success", "+" .. Utils.formatNumber(data.amount) .. " pts" .. (data.reason and (" - " .. data.reason) or ""), 4000)
    end
end)

-- Handle lobby events
addEvent(Events.Lobby.PLAYER_JOIN, true)
addEventHandler(Events.Lobby.PLAYER_JOIN, root, function(gamemode)
    currentGamemode = gamemode
    isInLobby = false
end)

addEvent(Events.Lobby.PLAYER_LEAVE, true)
addEventHandler(Events.Lobby.PLAYER_LEAVE, root, function(gamemode)
    currentGamemode = nil
    isInLobby = true
end)

-- Handle arena events
addEvent(Events.Arena.COUNTDOWN, true)
addEventHandler(Events.Arena.COUNTDOWN, root, function(seconds)
    if seconds <= 5 then
        exports.jebiga_core:showNotification("warning", tostring(seconds), 1000)
        exports.jebiga_core:playSound("countdown")
    end
end)

addEvent(Events.Arena.ROUND_START, true)
addEventHandler(Events.Arena.ROUND_START, root, function(data)
    exports.jebiga_core:showNotification("success", "GO!", 2000)
    exports.jebiga_core:playSound("start")
end)

addEvent(Events.Arena.ROUND_END, true)
addEventHandler(Events.Arena.ROUND_END, root, function(data)
    exports.jebiga_core:showNotification("info", "Round Over!", 3000)

    -- Show rankings
    if data.rankings then
        for i, entry in ipairs(data.rankings) do
            if i <= 3 then
                local pos = Utils.getOrdinal(i)
                outputChatBox("#FFFF00" .. pos .. " #FFFFFF" .. entry.name .. (entry.time and (" - " .. Utils.formatTime(entry.time)) or ""), 255, 255, 255, true)
            end
        end
    end
end)

-- HUD rendering
local hudVisible = true
local hudAlpha = 255

local function renderHUD()
    if not hudVisible then return end
    if not localPlayerData or not localPlayerData.money then return end

    local padding = 10
    local boxWidth = 200
    local boxHeight = 80

    -- Draw background
    dxDrawRectangle(screenW - boxWidth - padding, padding, boxWidth, boxHeight, tocolor(0, 0, 0, 150))

    -- Draw border
    dxDrawLine(screenW - boxWidth - padding, padding, screenW - padding, padding, tocolor(255, 102, 0, 255), 2)

    -- Draw money
    dxDrawText(
        "$" .. Utils.formatNumber(localPlayerData.money or 0),
        screenW - boxWidth - padding + 10,
        padding + 10,
        screenW - padding - 10,
        padding + 35,
        tocolor(0, 255, 0, hudAlpha),
        1.0,
        "default-bold",
        "left",
        "center"
    )

    -- Draw points
    dxDrawText(
        Utils.formatNumber(localPlayerData.totalPoints or 0) .. " pts",
        screenW - boxWidth - padding + 10,
        padding + 35,
        screenW - padding - 10,
        padding + 55,
        tocolor(255, 255, 0, hudAlpha),
        0.9,
        "default",
        "left",
        "center"
    )

    -- Draw rank
    local rank = Utils.calculateRank(localPlayerData.totalPoints or 0)
    local rankColor = Utils.hexToRGB(rank.color)
    dxDrawText(
        rank.name,
        screenW - boxWidth - padding + 10,
        padding + 55,
        screenW - padding - 10,
        padding + 75,
        tocolor(rankColor.r, rankColor.g, rankColor.b, hudAlpha),
        0.8,
        "default",
        "left",
        "center"
    )

    -- Draw gamemode indicator if in arena
    if currentGamemode then
        local cfg = Config.Gamemodes[currentGamemode]
        if cfg then
            dxDrawRectangle(screenW - boxWidth - padding, padding + boxHeight + 5, boxWidth, 25, tocolor(0, 0, 0, 150))
            dxDrawText(
                cfg.name,
                screenW - boxWidth - padding + 10,
                padding + boxHeight + 5,
                screenW - padding - 10,
                padding + boxHeight + 30,
                tocolor(255, 255, 255, hudAlpha),
                0.9,
                "default-bold",
                "center",
                "center"
            )
        end
    end
end

addEventHandler("onClientRender", root, renderHUD)

-- Toggle HUD
bindKey("F7", "down", function()
    hudVisible = not hudVisible
    exports.jebiga_core:showNotification("info", "HUD " .. (hudVisible and "enabled" or "disabled"), 2000)
end)

-- Key bindings
bindKey("F1", "down", function()
    outputChatBox("#FF6600=== Jebiga Gaming Keybinds ===", 255, 255, 255, true)
    outputChatBox("#FFFFFF F1 - Show this help", 255, 255, 255, true)
    outputChatBox("#FFFFFF F2 - Open gamemode selection", 255, 255, 255, true)
    outputChatBox("#FFFFFF F3 - Open profile/stats", 255, 255, 255, true)
    outputChatBox("#FFFFFF F4 - Toggle scoreboard", 255, 255, 255, true)
    outputChatBox("#FFFFFF F5 - Open garage", 255, 255, 255, true)
    outputChatBox("#FFFFFF F7 - Toggle HUD", 255, 255, 255, true)
    outputChatBox("#FFFFFF TAB - Quick scoreboard", 255, 255, 255, true)
end)

bindKey("F2", "down", function()
    triggerEvent("weevil:openLobbyGUI", localPlayer)
end)

bindKey("F3", "down", function()
    triggerServerEvent(Events.UserPanel.REQUEST_OPEN, localPlayer)
end)

bindKey("F5", "down", function()
    triggerServerEvent(Events.Garage.REQUEST_OPEN, localPlayer)
end)

-- Getters for other resources
function getLocalPlayerData()
    return localPlayerData
end

function getCurrentGamemode()
    return currentGamemode
end

function isPlayerInLobby()
    return isInLobby
end

function getPlayerMoney()
    return localPlayerData.money or 0
end

function getPlayerPoints()
    return localPlayerData.totalPoints or 0
end

-- Export functions
exports.jebiga_core = exports.jebiga_core or {}
exports.jebiga_core.getLocalPlayerData = getLocalPlayerData
exports.jebiga_core.getCurrentGamemode = getCurrentGamemode
exports.jebiga_core.isPlayerInLobby = isPlayerInLobby
exports.jebiga_core.getPlayerMoney = getPlayerMoney
exports.jebiga_core.getPlayerPoints = getPlayerPoints
