--[[
    Jebiga Multi-Gamemode - Hunter (Helicopter Combat)
    Client-side Hunter gamemode
]]

local GAMEMODE = "hunter"
local isEliminated = false

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[Jebiga Hunter] Hunter client initialized")
end)

-- Render Hunter HUD
addEventHandler("onClientRender", root, function()
    local gamemode = exports.jebiga_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end

    local screenW, screenH = guiGetScreenSize()

    -- Status
    local statusText = isEliminated and "DESTROYED - Spectating" or "FLYING"
    local statusColor = isEliminated and tocolor(255, 100, 100, 255) or tocolor(100, 200, 255, 255)

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
            dxDrawText("Hull: " .. math.floor(health / 10) .. "%", barX, barY, barX + barW, barY + barH, tocolor(255, 255, 255, 255), 0.8, "default", "center", "center")

            -- Altitude indicator
            local x, y, z = getElementPosition(vehicle)
            dxDrawText(
                "ALT: " .. math.floor(z) .. "m",
                screenW - 150, 20,
                screenW - 20, 40,
                tocolor(100, 200, 255, 255),
                0.9, "default", "right", "center"
            )
        end
    end
end)

-- Reset on new round
addEvent(Events.Arena.ROUND_START, true)
addEventHandler(Events.Arena.ROUND_START, root, function(data)
    if data.gamemode ~= GAMEMODE then return end
    isEliminated = false
end)

-- Eliminated
addEventHandler("onClientVehicleExplode", root, function()
    local vehicle = source
    if getElementDimension(vehicle) ~= Config.Gamemodes.hunter.dimension then return end

    if getPedOccupiedVehicle(localPlayer) == vehicle then
        isEliminated = true
        exports.jebiga_core:showNotification("error", "Your helicopter was destroyed!", 3000)
    end
end)

-- Cleanup
addEvent(Events.Lobby.PLAYER_LEAVE, true)
addEventHandler(Events.Lobby.PLAYER_LEAVE, root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    isEliminated = false
end)
