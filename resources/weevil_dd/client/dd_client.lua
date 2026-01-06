--[[
    Weevil Multi-Gamemode - DD (Destruction Derby)
    Client-side DD gamemode
]]

local GAMEMODE = "dd"
local isEliminated = false
local spectateTarget = nil
local alivePlayers = 0

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[Weevil DD] DD client initialized")
end)

-- Check if fallen below map
local fallCheckZ = -50

addEventHandler("onClientPreRender", root, function()
    local gamemode = exports.weevil_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end
    if isEliminated then return end

    local x, y, z = getElementPosition(localPlayer)
    if z < fallCheckZ then
        triggerServerEvent("weevil:dd:playerFell", localPlayer)
    end
end)

-- Eliminated event
addEvent("weevil:dd:eliminated", true)
addEventHandler("weevil:dd:eliminated", root, function()
    isEliminated = true
    exports.weevil_core:showNotification("error", "You have been eliminated!", 3000)

    -- Start spectating
    setTimer(function()
        if isEliminated then
            triggerServerEvent(Events.Arena.REQUEST_SPECTATE, localPlayer)
        end
    end, 2000, 1)
end)

-- Render DD HUD
addEventHandler("onClientRender", root, function()
    local gamemode = exports.weevil_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end

    local screenW, screenH = guiGetScreenSize()

    -- Status
    local statusText = isEliminated and "ELIMINATED - Spectating" or "ALIVE"
    local statusColor = isEliminated and tocolor(255, 100, 100, 255) or tocolor(100, 255, 100, 255)

    dxDrawText(
        statusText,
        screenW / 2 - 100, 20,
        screenW / 2 + 100, 50,
        statusColor,
        1.2, "default-bold", "center", "center"
    )

    -- Vehicle health
    if not isEliminated then
        local vehicle = getPedOccupiedVehicle(localPlayer)
        if vehicle then
            local health = getElementHealth(vehicle)
            local healthPercent = health / 1000

            local barW = 200
            local barH = 20
            local barX = screenW / 2 - barW / 2
            local barY = 55

            dxDrawRectangle(barX, barY, barW, barH, tocolor(50, 50, 50, 200))
            dxDrawRectangle(barX, barY, barW * healthPercent, barH, tocolor(255 * (1 - healthPercent), 255 * healthPercent, 0, 255))
            dxDrawText("Vehicle: " .. math.floor(health / 10) .. "%", barX, barY, barX + barW, barY + barH, tocolor(255, 255, 255, 255), 0.8, "default", "center", "center")
        end
    end
end)

-- Reset on new round
addEvent(Events.Arena.ROUND_START, true)
addEventHandler(Events.Arena.ROUND_START, root, function(data)
    if data.gamemode ~= GAMEMODE then return end
    isEliminated = false
    spectateTarget = nil
end)

-- Cleanup
addEvent(Events.Lobby.PLAYER_LEAVE, true)
addEventHandler(Events.Lobby.PLAYER_LEAVE, root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    isEliminated = false
    spectateTarget = nil
end)
