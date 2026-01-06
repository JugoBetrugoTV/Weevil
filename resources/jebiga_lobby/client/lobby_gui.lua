--[[
    Jebiga Multi-Gamemode - Lobby GUI
    Beautiful, modern lobby with clickable gamemode selection and teleportation
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- State
local isLobbyOpen = false
local selectedGamemode = nil
local scrollOffset = 0
local maxScroll = 0
local mapCounts = {}
local playerCounts = {}
local clickCooldown = false
local lastClickTime = 0

-- Animation states
local fadeIn = 0
local cardAnimations = {}

-- Gamemode order for display
local gamemodeOrder = {"dm", "race", "dd", "hunter", "shooter", "stuntage", "trials", "carball", "hotpursuit", "runarena", "training"}

-- ============================================
-- INITIALIZATION
-- ============================================

addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Request initial data
    triggerServerEvent("jebiga:lobby:requestData", localPlayer)
    outputDebugString("[Jebiga Lobby] Lobby GUI initialized")
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
    isLobbyOpen = true
    showCursor(true)
    fadeIn = 0

    -- Initialize card animations
    for i, gm in ipairs(gamemodeOrder) do
        cardAnimations[gm] = { offset = 100, alpha = 0, delay = i * 50, startTime = nil }
    end

    -- Request fresh data
    triggerServerEvent("jebiga:lobby:requestData", localPlayer)
end

function hideLobby()
    isLobbyOpen = false
    showCursor(false)
    selectedGamemode = nil
end

function toggleLobby()
    if isLobbyOpen then
        hideLobby()
    else
        showLobby()
    end
end

-- Keybind for lobby
bindKey("F1", "down", function()
    toggleLobby()
end)

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function getGamemodeSymbol(shortName)
    local symbols = {
        DM = "DM",
        Race = "RC",
        DD = "DD",
        Hunter = "HT",
        FPS = "FPS",
        Stunt = "ST",
        Trials = "TR",
        CB = "CB",
        HP = "HP",
        Run = "RN",
        Train = "TN"
    }
    return symbols[shortName] or shortName:sub(1, 2):upper()
end

function isMouseOver(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * screenW, cy * screenH
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

function lerpColor(c1, c2, t)
    return {
        c1[1] + (c2[1] - c1[1]) * t,
        c1[2] + (c2[2] - c1[2]) * t,
        c1[3] + (c2[3] - c1[3]) * t
    }
end

function joinGamemode(gmKey)
    -- Prevent double clicks
    local now = getTickCount()
    if now - lastClickTime < 500 then return end
    lastClickTime = now

    -- Play sound effect
    playSoundFrontEnd(40)

    -- Show feedback
    outputChatBox("#2980B9[JEBIGA] #FFFFFFTeleporting to " .. (Config.Gamemodes[gmKey] and Config.Gamemodes[gmKey].name or gmKey) .. "...", 255, 255, 255, true)

    -- Trigger server teleport
    triggerServerEvent("jebiga:lobby:joinGamemode", localPlayer, gmKey)

    -- Close lobby with delay for visual feedback
    setTimer(function()
        hideLobby()
    end, 300, 1)
end

-- ============================================
-- DRAWING
-- ============================================

addEventHandler("onClientRender", root, function()
    if not isLobbyOpen then return end

    -- Animate fade in
    fadeIn = math.min(fadeIn + 0.08, 1)
    local globalAlpha = fadeIn * 255

    -- Animate card entrance
    local currentTime = getTickCount()
    for gm, anim in pairs(cardAnimations) do
        if anim.startTime then
            local elapsed = currentTime - anim.startTime
            if elapsed > anim.delay then
                local progress = math.min((elapsed - anim.delay) / 300, 1)
                -- Ease out cubic
                progress = 1 - math.pow(1 - progress, 3)
                anim.offset = 100 * (1 - progress)
                anim.alpha = 255 * progress
            end
        else
            anim.startTime = currentTime
        end
    end

    -- Dark overlay with blur simulation
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(0, 0, 0, 200 * fadeIn), false)

    -- Main container
    local panelW = screenW * 0.92
    local panelH = screenH * 0.88
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Draw main panel
    drawMainPanel(panelX, panelY, panelW, panelH, globalAlpha)

    -- Draw header
    drawHeader(panelX, panelY, panelW, 90 * scale, globalAlpha)

    -- Draw gamemode grid
    local contentY = panelY + 110 * scale
    local contentH = panelH - 160 * scale
    drawGamemodeGrid(panelX + 30, contentY, panelW - 60, contentH, globalAlpha)

    -- Draw footer
    drawFooter(panelX, panelY + panelH - 45 * scale, panelW, 45 * scale, globalAlpha)
end)

function drawMainPanel(x, y, w, h, alpha)
    -- Multiple shadow layers for depth
    for i = 6, 1, -1 do
        dxDrawRectangle(x + i*4, y + i*4, w, h, tocolor(0, 0, 0, (25/i) * (alpha/255)), false)
    end

    -- Main background - dark with slight transparency
    dxDrawRectangle(x, y, w, h, tocolor(15, 15, 20, alpha * 0.98), false)

    -- Animated gradient top border
    local gradientHeight = 4
    for i = 0, gradientHeight do
        local progress = i / gradientHeight
        local r = math.floor(41 + (155 - 41) * progress)
        local g = math.floor(128 + (89 - 128) * progress)
        local b = math.floor(185 + (182 - 185) * progress)
        dxDrawRectangle(x, y + i, w, 1, tocolor(r, g, b, alpha), false)
    end

    -- Subtle inner glow from top
    for i = 0, 30 do
        local glowAlpha = (30 - i) * 1.5 * (alpha/255)
        dxDrawRectangle(x + 1, y + gradientHeight + i, w - 2, 1, tocolor(41, 128, 185, glowAlpha), false)
    end

    -- Side borders
    dxDrawRectangle(x, y, 2, h, tocolor(41, 128, 185, alpha * 0.4), false)
    dxDrawRectangle(x + w - 2, y, 2, h, tocolor(155, 89, 182, alpha * 0.4), false)
    dxDrawRectangle(x, y + h - 2, w, 2, tocolor(40, 40, 50, alpha * 0.8), false)
end

function drawHeader(x, y, w, h, alpha)
    -- Header background with gradient
    for i = 0, h do
        local progress = i / h
        local r = math.floor(25 + progress * 5)
        local g = math.floor(28 + progress * 5)
        local b = math.floor(36 + progress * 5)
        dxDrawRectangle(x, y + i, w, 1, tocolor(r, g, b, alpha * 0.95), false)
    end

    -- Accent line
    for i = 0, 3 do
        local progress = i / 3
        local a = (1 - progress) * alpha
        dxDrawRectangle(x, y + h - 4 + i, w, 1, tocolor(41, 128, 185, a * 0.5), false)
    end

    -- Server logo/name with glow effect
    local titleX = x + 35
    local titleY = y + h * 0.35

    -- Glow behind text
    dxDrawText("JEBIGA", titleX + 2, titleY + 2, titleX + 400, titleY + 50, tocolor(41, 128, 185, alpha * 0.3), 3.0 * scale, "bankgothic", "left", "center", false, false, false)
    dxDrawText("JEBIGA", titleX, titleY, titleX + 400, titleY + 50, tocolor(255, 255, 255, alpha), 3.0 * scale, "bankgothic", "left", "center", false, false, false)

    -- GAMING text with purple accent
    dxDrawText("GAMING", titleX + 195 * scale, titleY, titleX + 500, titleY + 50, tocolor(155, 89, 182, alpha), 3.0 * scale, "bankgothic", "left", "center", false, false, false)

    -- Subtitle
    dxDrawText("SELECT YOUR GAMEMODE", titleX, y + h * 0.7, titleX + 500, y + h, tocolor(160, 170, 180, alpha * 0.8), 1.0 * scale, "default", "left", "center", false, false, false)

    -- Online players counter with icon
    local totalPlayers = 0
    for _, count in pairs(playerCounts) do
        totalPlayers = totalPlayers + count
    end

    local onlineX = x + w - 280
    dxDrawRectangle(onlineX, y + 25, 180, 40 * scale, tocolor(46, 204, 113, alpha * 0.15), false)
    dxDrawRectangle(onlineX, y + 25, 3, 40 * scale, tocolor(46, 204, 113, alpha), false)
    dxDrawText("● " .. totalPlayers .. " ONLINE", onlineX + 15, y + 25, onlineX + 180, y + 25 + 40 * scale, tocolor(46, 204, 113, alpha), 1.0 * scale, "default-bold", "left", "center", false, false, false)

    -- Close button
    local closeSize = 45 * scale
    local closeX = x + w - closeSize - 20
    local closeY = y + (h - closeSize) / 2

    local closeHover = isMouseOver(closeX, closeY, closeSize, closeSize)
    local closeBgColor = closeHover and {231, 76, 60} or {60, 65, 75}

    -- Close button background
    dxDrawRectangle(closeX, closeY, closeSize, closeSize, tocolor(closeBgColor[1], closeBgColor[2], closeBgColor[3], alpha), false)
    dxDrawRectangle(closeX, closeY, closeSize, 2, tocolor(255, 255, 255, alpha * 0.1), false)

    -- X icon
    local iconAlpha = closeHover and alpha or (alpha * 0.8)
    dxDrawText("✕", closeX, closeY, closeX + closeSize, closeY + closeSize, tocolor(255, 255, 255, iconAlpha), 1.4 * scale, "default-bold", "center", "center", false, false, false)

    if closeHover and getKeyState("mouse1") and not clickCooldown then
        clickCooldown = true
        setTimer(function() clickCooldown = false end, 200, 1)
        hideLobby()
    end
end

function drawGamemodeGrid(x, y, w, h, alpha)
    local cardW = 280 * scale
    local cardH = 340 * scale
    local padding = 25 * scale
    local cardsPerRow = math.floor((w + padding) / (cardW + padding))

    -- Recalculate card width to fill space nicely
    if cardsPerRow > 0 then
        cardW = (w - (cardsPerRow - 1) * padding) / cardsPerRow
    end

    local col = 0
    local row = 0

    for i, gmKey in ipairs(gamemodeOrder) do
        local gm = Config.Gamemodes[gmKey]
        if gm and gm.enabled then
            local cardX = x + col * (cardW + padding)
            local cardY = y + row * (cardH + padding) - scrollOffset

            -- Only draw if visible
            if cardY + cardH > y - 50 and cardY < y + h + 50 then
                local anim = cardAnimations[gmKey] or { offset = 0, alpha = 255 }
                drawGamemodeCard(gmKey, gm, cardX, cardY + anim.offset, cardW, cardH, anim.alpha * (alpha/255))
            end

            col = col + 1
            if col >= cardsPerRow then
                col = 0
                row = row + 1
            end
        end
    end

    -- Calculate max scroll
    local totalRows = math.ceil(#gamemodeOrder / cardsPerRow)
    maxScroll = math.max(0, totalRows * (cardH + padding) - h + 50)
end

function drawGamemodeCard(gmKey, gm, x, y, w, h, alpha)
    if alpha <= 0 then return end

    local isHover = isMouseOver(x, y, w, h)

    -- Get gamemode color
    local gmColor = gm.color or {100, 100, 100}
    local gmGradient = gm.gradient or gmColor

    -- Hover effects
    local hoverOffset = isHover and -8 or 0
    local elevation = isHover and 12 or 4
    y = y + hoverOffset

    -- Drop shadow
    for i = elevation, 1, -1 do
        local shadowAlpha = (40 / i) * (alpha/255)
        if isHover then
            -- Colored shadow on hover
            dxDrawRectangle(x + i*2, y + i*2, w, h, tocolor(gmColor[1], gmColor[2], gmColor[3], shadowAlpha * 0.5), false)
        else
            dxDrawRectangle(x + i*2, y + i*2, w, h, tocolor(0, 0, 0, shadowAlpha), false)
        end
    end

    -- Glow effect on hover
    if isHover then
        for i = 4, 1, -1 do
            dxDrawRectangle(x - i, y - i, w + i*2, h + i*2, tocolor(gmColor[1], gmColor[2], gmColor[3], (30/i) * (alpha/255)), false)
        end
    end

    -- Card background
    local bgColor = isHover and {30, 33, 42} or {22, 25, 32}
    dxDrawRectangle(x, y, w, h, tocolor(bgColor[1], bgColor[2], bgColor[3], alpha), false)

    -- Top colored accent bar with gradient
    local accentHeight = 5
    for i = 0, w do
        local progress = i / w
        local r = math.floor(gmColor[1] + (gmGradient[1] - gmColor[1]) * progress)
        local g = math.floor(gmColor[2] + (gmGradient[2] - gmColor[2]) * progress)
        local b = math.floor(gmColor[3] + (gmGradient[3] - gmColor[3]) * progress)
        dxDrawRectangle(x + i, y, 1, accentHeight, tocolor(r, g, b, alpha), false)
    end

    -- Glow under accent
    for i = 0, 20 do
        local glowAlpha = (20 - i) * 3 * (alpha/255)
        dxDrawRectangle(x, y + accentHeight + i, w, 1, tocolor(gmColor[1], gmColor[2], gmColor[3], glowAlpha), false)
    end

    -- Icon area
    local iconSize = 90 * scale
    local iconX = x + (w - iconSize) / 2
    local iconY = y + 35 * scale

    -- Icon background with gradient
    for i = 0, iconSize do
        local progress = i / iconSize
        local iconBgAlpha = (40 - progress * 25) * (alpha/255)
        dxDrawRectangle(iconX, iconY + i, iconSize, 1, tocolor(gmColor[1], gmColor[2], gmColor[3], iconBgAlpha), false)
    end

    -- Icon border
    dxDrawRectangle(iconX, iconY, iconSize, 1, tocolor(gmColor[1], gmColor[2], gmColor[3], alpha * 0.3), false)
    dxDrawRectangle(iconX, iconY + iconSize - 1, iconSize, 1, tocolor(gmColor[1], gmColor[2], gmColor[3], alpha * 0.1), false)

    -- Gamemode symbol
    local symbol = getGamemodeSymbol(gm.shortName)
    -- Shadow
    dxDrawText(symbol, iconX + 2, iconY + 2, iconX + iconSize, iconY + iconSize, tocolor(0, 0, 0, alpha * 0.5), 3.0 * scale, "pricedown", "center", "center", false, false, false)
    -- Main
    dxDrawText(symbol, iconX, iconY, iconX + iconSize, iconY + iconSize, tocolor(gmColor[1], gmColor[2], gmColor[3], alpha), 3.0 * scale, "pricedown", "center", "center", false, false, false)

    -- Gamemode name
    local nameY = iconY + iconSize + 20 * scale
    dxDrawText(gm.name:upper(), x, nameY, x + w, nameY + 30 * scale, tocolor(255, 255, 255, alpha), 1.35 * scale, "default-bold", "center", "center", false, false, false)

    -- Description
    local descY = nameY + 35 * scale
    dxDrawText(gm.description, x + 15, descY, x + w - 15, descY + 55 * scale, tocolor(140, 150, 160, alpha * 0.85), 0.9 * scale, "default", "center", "top", true, true, false)

    -- Stats section at bottom
    local statsHeight = 85 * scale
    local statsY = y + h - statsHeight

    -- Stats background
    dxDrawRectangle(x, statsY, w, statsHeight, tocolor(15, 17, 22, alpha * 0.95), false)
    dxDrawRectangle(x, statsY, w, 1, tocolor(50, 55, 65, alpha * 0.5), false)

    -- Players stat
    local players = playerCounts[gmKey] or 0
    local playerColor = players > 0 and {46, 204, 113} or {100, 110, 120}
    dxDrawText("PLAYERS", x + 20, statsY + 12, x + w/2 - 10, statsY + 30 * scale, tocolor(80, 90, 100, alpha), 0.75 * scale, "default", "left", "center", false, false, false)
    dxDrawText(tostring(players), x + 20, statsY + 32 * scale, x + w/2 - 10, statsY + 55 * scale, tocolor(playerColor[1], playerColor[2], playerColor[3], alpha), 1.4 * scale, "default-bold", "left", "center", false, false, false)

    -- Maps stat
    local maps = mapCounts[gmKey] or 0
    dxDrawText("MAPS", x + w/2 + 10, statsY + 12, x + w - 20, statsY + 30 * scale, tocolor(80, 90, 100, alpha), 0.75 * scale, "default", "right", "center", false, false, false)
    dxDrawText(tostring(maps), x + w/2 + 10, statsY + 32 * scale, x + w - 20, statsY + 55 * scale, tocolor(255, 255, 255, alpha), 1.4 * scale, "default-bold", "right", "center", false, false, false)

    -- Join button (visible on hover)
    local btnY = statsY + 55 * scale
    local btnH = 28 * scale
    local btnAlpha = isHover and alpha or (alpha * 0.4)

    -- Button gradient
    for i = 0, btnH do
        local progress = i / btnH
        local r = math.floor(gmColor[1] * (1 - progress * 0.25))
        local g = math.floor(gmColor[2] * (1 - progress * 0.25))
        local b = math.floor(gmColor[3] * (1 - progress * 0.25))
        dxDrawRectangle(x + 15, btnY + i, w - 30, 1, tocolor(r, g, b, btnAlpha), false)
    end

    local btnText = isHover and "► CLICK TO JOIN" or "JOIN"
    dxDrawText(btnText, x + 15, btnY, x + w - 15, btnY + btnH, tocolor(255, 255, 255, btnAlpha), 0.95 * scale, "default-bold", "center", "center", false, false, false)

    -- Handle click
    if isHover and getKeyState("mouse1") and not clickCooldown then
        clickCooldown = true
        setTimer(function() clickCooldown = false end, 400, 1)
        joinGamemode(gmKey)
    end
end

function drawFooter(x, y, w, h, alpha)
    -- Footer background
    dxDrawRectangle(x, y, w, h, tocolor(12, 12, 16, alpha), false)
    dxDrawRectangle(x, y, w, 1, tocolor(40, 45, 55, alpha * 0.5), false)

    -- Help text
    dxDrawText("F1 - Toggle Lobby  │  Click on a gamemode to teleport  │  Mouse Wheel - Scroll", x + 25, y, x + w - 150, y + h, tocolor(80, 90, 100, alpha * 0.8), 0.9 * scale, "default", "left", "center", false, false, false)

    -- Version and branding
    dxDrawText("JEBIGA v" .. (Config.ServerVersion or "2.0.0"), x + w - 150, y, x + w - 25, y + h, tocolor(60, 70, 80, alpha * 0.6), 0.85 * scale, "default", "right", "center", false, false, false)
end

-- ============================================
-- SCROLL HANDLING
-- ============================================

addEventHandler("onClientKey", root, function(key, state)
    if not isLobbyOpen then return end

    if key == "mouse_wheel_up" and state then
        scrollOffset = math.max(0, scrollOffset - 60)
    elseif key == "mouse_wheel_down" and state then
        scrollOffset = math.min(maxScroll, scrollOffset + 60)
    elseif key == "escape" and state then
        hideLobby()
        cancelEvent()
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

function isLobbyGUIVisible()
    return isLobbyOpen
end

function showLobbyGUI()
    showLobby()
end

function hideLobbyGUI()
    hideLobby()
end
