--[[
    Jebiga Multi-Gamemode - Fullscreen Lobby Panel
    Panel-based lobby - NO walking around, just click to select gamemode
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- State
local isLobbyVisible = false
local mapCounts = {}
local playerCounts = {}
local hoverGamemode = nil
local clickCooldown = false

-- Animation
local fadeAlpha = 0
local targetAlpha = 0

-- Gamemode definitions with colors
local gamemodes = {
    { id = "dm", name = "DEATHMATCH", color = {255, 68, 68}, maxPlayers = 560 },
    { id = "race", name = "RACE", color = {68, 255, 68}, maxPlayers = 128 },
    { id = "dd", name = "DERBY", color = {255, 136, 68}, maxPlayers = 120 },
    { id = "hunter", name = "HUNTER", color = {68, 136, 255}, maxPlayers = 56 },
    { id = "shooter", name = "SHOOTER", color = {255, 68, 255}, maxPlayers = 64 },
    { id = "stuntage", name = "STUNTAGE", color = {255, 255, 68}, maxPlayers = 64 },
    { id = "trials", name = "TRIALS", color = {68, 255, 255}, maxPlayers = 32 },
    { id = "hotpursuit", name = "HOT PURSUIT", color = {136, 68, 255}, maxPlayers = 50 },
    { id = "runarena", name = "RUN", color = {255, 136, 136}, maxPlayers = 64 },
    { id = "clanwars", name = "CLAN WARS", color = {255, 200, 68}, maxPlayers = 32 },
    { id = "ptp", name = "PTP", color = {68, 200, 136}, maxPlayers = 128 },
    { id = "carball", name = "CARBALL", color = {136, 255, 136}, maxPlayers = 20 },
    { id = "training", name = "TRAINING", color = {136, 136, 136}, maxPlayers = 32 },
    { id = "minigames", name = "MINIGAMES", color = {200, 136, 255}, maxPlayers = 96 },
    { id = "garage", name = "GARAGE", color = {100, 150, 200}, maxPlayers = 0, isGarage = true },
    { id = "geoguesser", name = "GEOGUESSER", color = {68, 200, 200}, maxPlayers = 64 },
    { id = "coming1", name = "COMING SOON", color = {80, 80, 80}, comingSoon = true },
    { id = "coming2", name = "COMING SOON", color = {80, 80, 80}, comingSoon = true },
    { id = "coming3", name = "COMING SOON", color = {80, 80, 80}, comingSoon = true },
    { id = "coming4", name = "COMING SOON", color = {80, 80, 80}, comingSoon = true },
}

-- Grid settings
local cols = 5
local rows = 4
local cardPadding = 8 * scale
local gridStartX = 80 * scale
local gridStartY = 120 * scale

-- ============================================
-- INITIALIZATION
-- ============================================

addEventHandler("onClientResourceStart", resourceRoot, function()
    setTimer(function()
        triggerServerEvent("jebiga:lobby:requestData", localPlayer)
    end, 1000, 1)
end)

-- ============================================
-- DATA EVENTS
-- ============================================

addEvent("jebiga:lobby:updateData", true)
addEventHandler("jebiga:lobby:updateData", root, function(maps, players)
    mapCounts = maps or {}
    playerCounts = players or {}
end)

addEvent("jebiga:lobby:show", true)
addEventHandler("jebiga:lobby:show", root, function()
    showLobby()
end)

addEvent("jebiga:lobby:hide", true)
addEventHandler("jebiga:lobby:hide", root, function()
    hideLobby()
end)

-- ============================================
-- LOBBY CONTROL
-- ============================================

function showLobby()
    isLobbyVisible = true
    targetAlpha = 255
    showCursor(true)
    showChat(false)

    -- Freeze player completely
    setElementFrozen(localPlayer, true)
    setElementAlpha(localPlayer, 0)

    -- Hide all HUD
    setPlayerHudComponentVisible("all", false)

    -- Set scenic camera (fixed position)
    setCameraMatrix(1500, -1700, 80, 1481, -1770, 18)

    -- Request data
    triggerServerEvent("jebiga:lobby:requestData", localPlayer)
end

function hideLobby()
    isLobbyVisible = false
    targetAlpha = 0
    showCursor(false)
    showChat(true)

    -- Unfreeze player
    setElementFrozen(localPlayer, false)
    setElementAlpha(localPlayer, 255)

    -- Restore HUD
    setPlayerHudComponentVisible("all", true)

    -- Reset camera to player
    setCameraTarget(localPlayer)
end

function toggleLobby()
    if isLobbyVisible then
        hideLobby()
    else
        showLobby()
    end
end

-- F1 to toggle
bindKey("F1", "down", toggleLobby)

-- ============================================
-- HELPERS
-- ============================================

function isMouseOver(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * screenW, cy * screenH
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

function getTotalOnline()
    local total = 0
    for _, count in pairs(playerCounts) do
        total = total + count
    end
    return math.max(total, #getElementsByType("player"))
end

-- ============================================
-- MAIN RENDERING
-- ============================================

addEventHandler("onClientRender", root, function()
    -- Animate fade
    if fadeAlpha < targetAlpha then
        fadeAlpha = math.min(fadeAlpha + 15, targetAlpha)
    elseif fadeAlpha > targetAlpha then
        fadeAlpha = math.max(fadeAlpha - 15, targetAlpha)
    end

    if fadeAlpha <= 0 then return end

    local alpha = fadeAlpha

    -- Dark background overlay
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(20, 25, 30, alpha * 0.92))

    -- Top gradient
    for i = 0, 60 do
        local a = (60 - i) / 60 * 80 * (alpha/255)
        dxDrawRectangle(0, i, screenW, 1, tocolor(50, 55, 60, a))
    end

    -- Daily challenges (top right)
    drawDailyChallenges(screenW - 280 * scale, 15 * scale, 260 * scale, alpha)

    -- Draw gamemode grid
    drawGamemodeGrid(alpha)

    -- Online counter at bottom
    drawOnlineCounter(alpha)

    hoverGamemode = nil
end)

-- ============================================
-- DAILY CHALLENGES
-- ============================================

function drawDailyChallenges(x, y, w, alpha)
    local h = 90 * scale

    -- Background
    dxDrawRectangle(x, y, w, h, tocolor(30, 30, 35, alpha * 0.95))

    -- Header bar
    dxDrawRectangle(x, y, w, 22 * scale, tocolor(180, 140, 50, alpha))
    dxDrawText("Daily Challenges", x, y, x + w, y + 22 * scale,
        tocolor(255, 255, 255, alpha), 0.85 * scale, "default-bold", "center", "center")

    -- Challenges
    local challenges = {
        { text = "Win 3 DM Hard rounds", progress = "0/3" },
        { text = "Kill 30 players in Shooter Beta Ground", progress = "0/30" },
        { text = "Kill 30 players in DD Alpha", progress = "0/36" },
    }

    local itemY = y + 26 * scale
    for _, ch in ipairs(challenges) do
        dxDrawText(ch.text, x + 8, itemY, x + w - 40, itemY + 18 * scale,
            tocolor(170, 170, 170, alpha), 0.65 * scale, "default", "left", "center")
        dxDrawText(ch.progress, x + w - 38, itemY, x + w - 5, itemY + 18 * scale,
            tocolor(180, 140, 50, alpha), 0.65 * scale, "default", "right", "center")
        itemY = itemY + 20 * scale
    end
end

-- ============================================
-- GAMEMODE GRID
-- ============================================

function drawGamemodeGrid(alpha)
    local totalW = screenW - gridStartX * 2
    local totalH = screenH - gridStartY - 60 * scale

    local cardW = (totalW - (cols - 1) * cardPadding) / cols
    local cardH = (totalH - (rows - 1) * cardPadding) / rows

    for i, gm in ipairs(gamemodes) do
        if i > cols * rows then break end

        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        local x = gridStartX + col * (cardW + cardPadding)
        local y = gridStartY + row * (cardH + cardPadding)

        drawGamemodeCard(gm, x, y, cardW, cardH, alpha)
    end
end

function drawGamemodeCard(gm, x, y, w, h, alpha)
    local isHover = isMouseOver(x, y, w, h) and not gm.comingSoon
    local isComingSoon = gm.comingSoon

    if isHover then
        hoverGamemode = gm.id
    end

    -- Colors
    local bgColor = isComingSoon and {45, 45, 50} or (isHover and {55, 60, 70} or {38, 42, 50})

    -- Hover glow/shadow
    if isHover and not isComingSoon then
        dxDrawRectangle(x + 3, y + 3, w, h, tocolor(gm.color[1], gm.color[2], gm.color[3], alpha * 0.25))
    end

    -- Main background
    dxDrawRectangle(x, y, w, h, tocolor(bgColor[1], bgColor[2], bgColor[3], alpha))

    -- Bottom color bar
    if not isComingSoon then
        local barH = 3
        local barAlpha = isHover and 1 or 0.5
        dxDrawRectangle(x, y + h - barH, w, barH,
            tocolor(gm.color[1], gm.color[2], gm.color[3], alpha * barAlpha))
    end

    -- Image area (gradient simulation)
    local imgH = h * 0.6
    if not isComingSoon then
        for i = 0, imgH do
            local progress = i / imgH
            local intensity = 0.15 + progress * 0.15
            dxDrawRectangle(x, y + i, w, 1,
                tocolor(gm.color[1] * intensity, gm.color[2] * intensity, gm.color[3] * intensity, alpha * 0.8))
        end
    end

    -- Gamemode name
    local nameY = y + imgH + 8 * scale
    local nameColor = isComingSoon and {100, 100, 100} or {255, 255, 255}
    dxDrawText(gm.name, x, nameY, x + w, nameY + 22 * scale,
        tocolor(nameColor[1], nameColor[2], nameColor[3], alpha),
        0.95 * scale, "default-bold", "center", "center")

    -- Player count
    if not isComingSoon and not gm.isGarage then
        local players = playerCounts[gm.id] or 0
        local countText = players .. "/" .. gm.maxPlayers
        local countY = y + h - 25 * scale

        dxDrawText(countText, x, countY, x + w, countY + 18 * scale,
            tocolor(140, 140, 140, alpha), 0.8 * scale, "default", "center", "center")
    end

    -- Map count (corner)
    if not isComingSoon and not gm.isGarage then
        local maps = mapCounts[gm.id] or 0
        if maps > 0 then
            dxDrawText(tostring(maps), x + w - 22, y + 5, x + w - 5, y + 20,
                tocolor(255, 255, 255, alpha * 0.5), 0.75 * scale, "default", "right", "top")
        end
    end

    -- Click
    if isHover and not isComingSoon and getKeyState("mouse1") and not clickCooldown then
        clickCooldown = true
        setTimer(function() clickCooldown = false end, 500, 1)

        if gm.isGarage then
            triggerServerEvent("weevil:garage:requestOpen", localPlayer)
        else
            playSoundFrontEnd(40)
            triggerServerEvent("jebiga:lobby:joinGamemode", localPlayer, gm.id)
            setTimer(hideLobby, 300, 1)
        end
    end
end

-- ============================================
-- ONLINE COUNTER
-- ============================================

function drawOnlineCounter(alpha)
    local total = getTotalOnline()
    local text = total .. " players online"
    local y = screenH - 45 * scale

    dxDrawText(text, 0, y, screenW, y + 25 * scale,
        tocolor(140, 140, 140, alpha), 0.95 * scale, "default", "center", "center")
end

-- ============================================
-- BLOCK INPUT WHEN IN LOBBY
-- ============================================

addEventHandler("onClientKey", root, function(key, state)
    if not isLobbyVisible then return end

    -- Block movement
    local blocked = {
        "w", "a", "s", "d",
        "arrow_u", "arrow_d", "arrow_l", "arrow_r",
        "space", "lshift", "lctrl"
    }

    for _, k in ipairs(blocked) do
        if key == k then
            cancelEvent()
            return
        end
    end

    -- ESC doesn't close lobby (player must select gamemode)
    if key == "escape" and state then
        cancelEvent()
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

function isLobbyGUIVisible()
    return isLobbyVisible
end

function showLobbyGUI()
    showLobby()
end

function hideLobbyGUI()
    hideLobby()
end
