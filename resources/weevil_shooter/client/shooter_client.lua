--[[
    Weevil Multi-Gamemode - Shooter (FPS Combat)
    Client-side Shooter gamemode
]]

local GAMEMODE = "shooter"
local kills = 0
local deaths = 0
local roundTimeRemaining = 0

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[Weevil Shooter] Shooter client initialized")
end)

-- Render Shooter HUD
addEventHandler("onClientRender", root, function()
    local gamemode = exports.weevil_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end

    local screenW, screenH = guiGetScreenSize()

    -- K/D Display
    dxDrawRectangle(screenW / 2 - 80, 15, 160, 50, tocolor(0, 0, 0, 150))

    dxDrawText(
        "KILLS: " .. kills,
        screenW / 2 - 70, 20,
        screenW / 2, 45,
        tocolor(100, 255, 100, 255),
        1.0, "default-bold", "left", "center"
    )

    dxDrawText(
        "DEATHS: " .. deaths,
        screenW / 2, 20,
        screenW / 2 + 70, 45,
        tocolor(255, 100, 100, 255),
        1.0, "default-bold", "right", "center"
    )

    -- Health & Armor
    local health = getElementHealth(localPlayer)
    local armor = getPedArmor(localPlayer)

    -- Health bar
    dxDrawRectangle(20, screenH - 60, 200, 20, tocolor(50, 50, 50, 200))
    dxDrawRectangle(20, screenH - 60, 200 * (health / 100), 20, tocolor(255, 50, 50, 255))
    dxDrawText("HP: " .. math.floor(health), 25, screenH - 60, 215, screenH - 40, tocolor(255, 255, 255, 255), 0.8, "default", "left", "center")

    -- Armor bar
    dxDrawRectangle(20, screenH - 35, 200, 20, tocolor(50, 50, 50, 200))
    dxDrawRectangle(20, screenH - 35, 200 * (armor / 100), 20, tocolor(50, 150, 255, 255))
    dxDrawText("ARMOR: " .. math.floor(armor), 25, screenH - 35, 215, screenH - 15, tocolor(255, 255, 255, 255), 0.8, "default", "left", "center")

    -- Crosshair
    local cx, cy = screenW / 2, screenH / 2
    dxDrawLine(cx - 10, cy, cx + 10, cy, tocolor(255, 255, 255, 200), 2)
    dxDrawLine(cx, cy - 10, cx, cy + 10, tocolor(255, 255, 255, 200), 2)
end)

-- Update stats (would be synced from server in full implementation)
addEvent("weevil:shooter:updateStats", true)
addEventHandler("weevil:shooter:updateStats", root, function(k, d)
    kills = k
    deaths = d
end)

-- Reset on new round
addEvent(Events.Arena.ROUND_START, true)
addEventHandler(Events.Arena.ROUND_START, root, function(data)
    if data.gamemode ~= GAMEMODE then return end
    kills = 0
    deaths = 0
end)

-- Cleanup
addEvent(Events.Lobby.PLAYER_LEAVE, true)
addEventHandler(Events.Lobby.PLAYER_LEAVE, root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    kills = 0
    deaths = 0
end)
