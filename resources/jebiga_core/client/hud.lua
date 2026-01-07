--[[
    Jebiga Multi-Gamemode - Enhanced HUD
    Inspired by Vultaic MGM
    Features: Speedometer, Health/Armor bars, Money display, Minimap enhancements
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- HUD State
local hudEnabled = true
local speedoEnabled = true
local radarEnabled = true
local statsEnabled = true

-- Animation values
local currentSpeed = 0
local targetSpeed = 0
local currentHealth = 100
local currentArmor = 0
local displayMoney = 0
local targetMoney = 0

-- Speedometer settings
local speedo = {
    x = screenW - 280 * scale,
    y = screenH - 280 * scale,
    size = 240 * scale,
    maxSpeed = 300,
    unit = "km/h"
}

-- Colors
local colors = {
    background = {15, 15, 20},
    panel = {25, 28, 36},
    primary = {41, 128, 185},
    secondary = {155, 89, 182},
    accent = {46, 204, 113},
    danger = {231, 76, 60},
    warning = {241, 196, 15},
    text = {255, 255, 255},
    textMuted = {120, 130, 140}
}

-- ============================================
-- SPEEDOMETER
-- ============================================

function drawSpeedometer()
    if not speedoEnabled then return end

    local player = localPlayer
    local vehicle = getPedOccupiedVehicle(player)

    if not vehicle then
        targetSpeed = 0
    else
        -- Get speed in km/h
        local vx, vy, vz = getElementVelocity(vehicle)
        targetSpeed = math.sqrt(vx*vx + vy*vy + vz*vz) * 180
    end

    -- Smooth speed animation
    currentSpeed = currentSpeed + (targetSpeed - currentSpeed) * 0.15

    local cx = speedo.x + speedo.size / 2
    local cy = speedo.y + speedo.size / 2
    local radius = speedo.size / 2 - 20 * scale

    -- Background circle with glow
    for i = 5, 1, -1 do
        local glowAlpha = 30 / i
        drawCircle(cx, cy, radius + i * 3, 50, tocolor(colors.primary[1], colors.primary[2], colors.primary[3], glowAlpha))
    end

    -- Main background
    drawCircle(cx, cy, radius, 50, tocolor(colors.background[1], colors.background[2], colors.background[3], 230))

    -- Inner ring
    drawCircle(cx, cy, radius - 5, 50, tocolor(colors.panel[1], colors.panel[2], colors.panel[3], 200))

    -- Speed arc background
    local arcRadius = radius - 25 * scale
    drawArc(cx, cy, arcRadius, 15 * scale, 135, 405, tocolor(40, 45, 55, 200))

    -- Speed arc (colored based on speed)
    local speedPercent = math.min(currentSpeed / speedo.maxSpeed, 1)
    local speedAngle = 135 + speedPercent * 270

    -- Gradient color based on speed
    local arcColor
    if speedPercent < 0.5 then
        arcColor = lerpColor(colors.accent, colors.warning, speedPercent * 2)
    else
        arcColor = lerpColor(colors.warning, colors.danger, (speedPercent - 0.5) * 2)
    end

    if speedAngle > 135 then
        drawArc(cx, cy, arcRadius, 15 * scale, 135, speedAngle, tocolor(arcColor[1], arcColor[2], arcColor[3], 255))
    end

    -- Speed text
    local speedText = math.floor(currentSpeed)
    dxDrawText(speedText, cx - 60 * scale, cy - 30 * scale, cx + 60 * scale, cy + 10 * scale,
        tocolor(255, 255, 255, 255), 3.0 * scale, "pricedown", "center", "center", false, false, false)

    -- Unit text
    dxDrawText(speedo.unit, cx - 40 * scale, cy + 15 * scale, cx + 40 * scale, cy + 40 * scale,
        tocolor(colors.textMuted[1], colors.textMuted[2], colors.textMuted[3], 200), 1.0 * scale, "default-bold", "center", "center", false, false, false)

    -- Gear indicator (if in vehicle)
    if vehicle then
        local gear = getVehicleCurrentGear(vehicle)
        local gearText = gear == 0 and "R" or tostring(gear)
        dxDrawText(gearText, cx + 50 * scale, cy + 30 * scale, cx + 80 * scale, cy + 60 * scale,
            tocolor(colors.primary[1], colors.primary[2], colors.primary[3], 255), 1.5 * scale, "default-bold", "center", "center", false, false, false)
    end

    -- Speed markers
    for i = 0, 10 do
        local angle = math.rad(135 + i * 27)
        local markerRadius = radius - 45 * scale
        local mx = cx + math.cos(angle) * markerRadius
        local my = cy + math.sin(angle) * markerRadius
        local speed = i * 30

        -- Marker line
        local lineStart = radius - 50 * scale
        local lineEnd = radius - 58 * scale
        local lx1 = cx + math.cos(angle) * lineStart
        local ly1 = cy + math.sin(angle) * lineStart
        local lx2 = cx + math.cos(angle) * lineEnd
        local ly2 = cy + math.sin(angle) * lineEnd

        dxDrawLine(lx1, ly1, lx2, ly2, tocolor(100, 110, 120, 150), 2)

        -- Speed number (every 60)
        if i % 2 == 0 then
            local textRadius = radius - 70 * scale
            local tx = cx + math.cos(angle) * textRadius
            local ty = cy + math.sin(angle) * textRadius
            dxDrawText(tostring(speed), tx - 20, ty - 10, tx + 20, ty + 10,
                tocolor(colors.textMuted[1], colors.textMuted[2], colors.textMuted[3], 180), 0.7 * scale, "default", "center", "center", false, false, false)
        end
    end

    -- Nitro bar (if available)
    if vehicle then
        local nitro = getVehicleNitroLevel(vehicle)
        if nitro then
            local nitroY = speedo.y + speedo.size + 10 * scale
            local nitroW = speedo.size
            local nitroH = 8 * scale

            -- Background
            dxDrawRectangle(speedo.x, nitroY, nitroW, nitroH, tocolor(40, 45, 55, 200))

            -- Fill
            local nitroColor = nitro > 0.3 and colors.primary or colors.danger
            dxDrawRectangle(speedo.x, nitroY, nitroW * nitro, nitroH, tocolor(nitroColor[1], nitroColor[2], nitroColor[3], 255))

            -- Label
            dxDrawText("NOS", speedo.x, nitroY - 18 * scale, speedo.x + nitroW, nitroY,
                tocolor(colors.textMuted[1], colors.textMuted[2], colors.textMuted[3], 180), 0.7 * scale, "default-bold", "left", "center", false, false, false)
        end
    end
end

-- ============================================
-- HEALTH & ARMOR BARS
-- ============================================

function drawHealthArmor()
    if not statsEnabled then return end

    local player = localPlayer
    local health = getElementHealth(player)
    local armor = getPedArmor(player)

    -- Smooth animations
    currentHealth = currentHealth + (health - currentHealth) * 0.1
    currentArmor = currentArmor + (armor - currentArmor) * 0.1

    local barX = 20 * scale
    local barY = screenH - 100 * scale
    local barW = 200 * scale
    local barH = 25 * scale
    local spacing = 35 * scale

    -- Health bar
    drawStatBar(barX, barY, barW, barH, currentHealth / 100, "HEALTH", colors.danger)

    -- Armor bar
    drawStatBar(barX, barY - spacing, barW, barH, currentArmor / 100, "ARMOR", colors.primary)
end

function drawStatBar(x, y, w, h, percent, label, color)
    percent = math.max(0, math.min(1, percent))

    -- Background with shadow
    dxDrawRectangle(x + 2, y + 2, w, h, tocolor(0, 0, 0, 100))
    dxDrawRectangle(x, y, w, h, tocolor(colors.panel[1], colors.panel[2], colors.panel[3], 220))

    -- Fill gradient
    if percent > 0 then
        local fillW = w * percent
        for i = 0, fillW do
            local progress = i / w
            local alpha = 200 + progress * 55
            dxDrawRectangle(x + i, y, 1, h, tocolor(color[1], color[2], color[3], alpha))
        end
    end

    -- Border
    dxDrawRectangle(x, y, w, 1, tocolor(255, 255, 255, 30))
    dxDrawRectangle(x, y + h - 1, w, 1, tocolor(0, 0, 0, 50))

    -- Label
    dxDrawText(label, x + 8, y, x + w, y + h,
        tocolor(255, 255, 255, 220), 0.75 * scale, "default-bold", "left", "center", false, false, false)

    -- Percentage
    local percentText = math.floor(percent * 100) .. "%"
    dxDrawText(percentText, x, y, x + w - 8, y + h,
        tocolor(255, 255, 255, 200), 0.8 * scale, "default-bold", "right", "center", false, false, false)
end

-- ============================================
-- MONEY DISPLAY
-- ============================================

function drawMoneyDisplay()
    if not statsEnabled then return end

    local money = getElementData(localPlayer, "jebiga:money") or 0
    targetMoney = money

    -- Smooth animation for money changes
    displayMoney = displayMoney + (targetMoney - displayMoney) * 0.1

    local x = screenW - 250 * scale
    local y = 20 * scale
    local w = 230 * scale
    local h = 45 * scale

    -- Background
    dxDrawRectangle(x + 2, y + 2, w, h, tocolor(0, 0, 0, 100))
    dxDrawRectangle(x, y, w, h, tocolor(colors.panel[1], colors.panel[2], colors.panel[3], 220))

    -- Left accent
    dxDrawRectangle(x, y, 4, h, tocolor(colors.warning[1], colors.warning[2], colors.warning[3], 255))

    -- Money icon
    dxDrawText("$", x + 15, y, x + 45, y + h,
        tocolor(colors.warning[1], colors.warning[2], colors.warning[3], 255), 1.8 * scale, "default-bold", "center", "center", false, false, false)

    -- Money amount
    local moneyText = formatMoney(math.floor(displayMoney))
    dxDrawText(moneyText, x + 50, y, x + w - 10, y + h,
        tocolor(255, 255, 255, 255), 1.3 * scale, "default-bold", "left", "center", false, false, false)

    -- Points display below
    local points = getElementData(localPlayer, "jebiga:points") or 0
    local pointsY = y + h + 5

    dxDrawRectangle(x + 2, pointsY + 2, w, h - 10, tocolor(0, 0, 0, 100))
    dxDrawRectangle(x, pointsY, w, h - 10, tocolor(colors.panel[1], colors.panel[2], colors.panel[3], 200))
    dxDrawRectangle(x, pointsY, 4, h - 10, tocolor(colors.secondary[1], colors.secondary[2], colors.secondary[3], 255))

    dxDrawText("JP", x + 15, pointsY, x + 45, pointsY + h - 10,
        tocolor(colors.secondary[1], colors.secondary[2], colors.secondary[3], 255), 1.0 * scale, "default-bold", "center", "center", false, false, false)

    dxDrawText(formatMoney(points), x + 50, pointsY, x + w - 10, pointsY + h - 10,
        tocolor(255, 255, 255, 230), 1.1 * scale, "default-bold", "left", "center", false, false, false)
end

-- ============================================
-- GAMEMODE INFO
-- ============================================

function drawGamemodeInfo()
    local gamemode = getElementData(localPlayer, "jebiga:currentGamemode")
    if not gamemode then return end

    local gm = Config.Gamemodes[gamemode]
    if not gm then return end

    local x = 20 * scale
    local y = 20 * scale
    local w = 200 * scale
    local h = 50 * scale

    -- Background
    dxDrawRectangle(x, y, w, h, tocolor(colors.panel[1], colors.panel[2], colors.panel[3], 200))

    -- Colored left bar
    local gmColor = gm.color or {100, 100, 100}
    dxDrawRectangle(x, y, 5, h, tocolor(gmColor[1], gmColor[2], gmColor[3], 255))

    -- Gamemode name
    dxDrawText(gm.name:upper(), x + 15, y + 5, x + w - 10, y + 30,
        tocolor(255, 255, 255, 255), 1.1 * scale, "default-bold", "left", "center", false, false, false)

    -- Player count - get players in same gamemode
    local playerCount = 0
    local myArena = getElementData(localPlayer, "jebiga:arena")
    for _, player in ipairs(getElementsByType("player")) do
        local theirGamemode = getElementData(player, "jebiga:currentGamemode")
        local theirArena = getElementData(player, "jebiga:arena")
        if theirGamemode == gamemode and (not myArena or theirArena == myArena) then
            playerCount = playerCount + 1
        end
    end
    dxDrawText(playerCount .. " players", x + 15, y + 28, x + w - 10, y + h - 5,
        tocolor(colors.textMuted[1], colors.textMuted[2], colors.textMuted[3], 200), 0.8 * scale, "default", "left", "center", false, false, false)
end

-- ============================================
-- FPS & PING DISPLAY
-- ============================================

local fps = 0
local fpsCounter = 0
local fpsTimer = getTickCount()

function drawPerformance()
    -- Calculate FPS
    fpsCounter = fpsCounter + 1
    local now = getTickCount()
    if now - fpsTimer >= 1000 then
        fps = fpsCounter
        fpsCounter = 0
        fpsTimer = now
    end

    local ping = getPlayerPing(localPlayer)

    local x = screenW - 100 * scale
    local y = screenH - 50 * scale

    -- FPS
    local fpsColor = fps >= 60 and colors.accent or (fps >= 30 and colors.warning or colors.danger)
    dxDrawText("FPS: " .. fps, x, y, x + 80, y + 20,
        tocolor(fpsColor[1], fpsColor[2], fpsColor[3], 200), 0.8 * scale, "default-bold", "left", "center", false, false, false)

    -- Ping
    local pingColor = ping <= 50 and colors.accent or (ping <= 150 and colors.warning or colors.danger)
    dxDrawText("PING: " .. ping, x, y + 20, x + 80, y + 40,
        tocolor(pingColor[1], pingColor[2], pingColor[3], 200), 0.8 * scale, "default-bold", "left", "center", false, false, false)
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Cache for circle points to avoid recalculating every frame
local circleCache = {}

function drawCircle(x, y, radius, segments, color)
    -- Create cache key
    local cacheKey = string.format("%d_%d", radius, segments)

    -- Generate points only once per radius/segments combo
    if not circleCache[cacheKey] then
        local points = {}
        for i = 0, segments do
            local angle = math.rad(i * 360 / segments)
            table.insert(points, {math.cos(angle), math.sin(angle)})
        end
        circleCache[cacheKey] = points
    end

    -- Draw using cached points
    local points = circleCache[cacheKey]
    for i = 1, #points - 1 do
        local x1 = x + points[i][1] * radius
        local y1 = y + points[i][2] * radius
        local x2 = x + points[i+1][1] * radius
        local y2 = y + points[i+1][2] * radius
        dxDrawLine(x1, y1, x2, y2, color, 2)
    end
end

function drawArc(cx, cy, radius, thickness, startAngle, endAngle, color)
    local segments = math.ceil((endAngle - startAngle) / 3)
    for i = 0, segments do
        local angle = math.rad(startAngle + i * (endAngle - startAngle) / segments)
        local x1 = cx + math.cos(angle) * (radius - thickness/2)
        local y1 = cy + math.sin(angle) * (radius - thickness/2)
        local x2 = cx + math.cos(angle) * (radius + thickness/2)
        local y2 = cy + math.sin(angle) * (radius + thickness/2)

        if i > 0 then
            local prevAngle = math.rad(startAngle + (i-1) * (endAngle - startAngle) / segments)
            local px1 = cx + math.cos(prevAngle) * (radius - thickness/2)
            local py1 = cy + math.sin(prevAngle) * (radius - thickness/2)
            local px2 = cx + math.cos(prevAngle) * (radius + thickness/2)
            local py2 = cy + math.sin(prevAngle) * (radius + thickness/2)

            dxDrawLine(px1, py1, x1, y1, color, 2)
            dxDrawLine(px2, py2, x2, y2, color, 2)
        end
    end
end

function lerpColor(c1, c2, t)
    return {
        c1[1] + (c2[1] - c1[1]) * t,
        c1[2] + (c2[2] - c1[2]) * t,
        c1[3] + (c2[3] - c1[3]) * t
    }
end

-- Cache for formatted money values
local moneyFormatCache = {}
local moneyFormatCacheTime = 0

function formatMoney(amount)
    -- Clear cache every 5 seconds to prevent memory buildup
    local now = getTickCount()
    if now - moneyFormatCacheTime > 5000 then
        moneyFormatCache = {}
        moneyFormatCacheTime = now
    end

    -- Check cache first
    if moneyFormatCache[amount] then
        return moneyFormatCache[amount]
    end

    -- Format and cache
    local formatted = tostring(amount)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end

    moneyFormatCache[amount] = formatted
    return formatted
end

-- ============================================
-- MAIN RENDER
-- ============================================

addEventHandler("onClientRender", root, function()
    if not hudEnabled then return end

    drawSpeedometer()
    drawHealthArmor()
    drawMoneyDisplay()
    drawGamemodeInfo()
    drawPerformance()
end)

-- ============================================
-- TOGGLE COMMANDS
-- ============================================

bindKey("F7", "down", function()
    hudEnabled = not hudEnabled
    outputChatBox("#2980B9[JEBIGA] #FFFFFFHUD " .. (hudEnabled and "enabled" or "disabled"), 255, 255, 255, true)
end)

addCommandHandler("hud", function()
    hudEnabled = not hudEnabled
    outputChatBox("#2980B9[JEBIGA] #FFFFFFHUD " .. (hudEnabled and "enabled" or "disabled"), 255, 255, 255, true)
end)

addCommandHandler("speedo", function()
    speedoEnabled = not speedoEnabled
    outputChatBox("#2980B9[JEBIGA] #FFFFFFSpeedometer " .. (speedoEnabled and "enabled" or "disabled"), 255, 255, 255, true)
end)

-- Hide default HUD elements
setPlayerHudComponentVisible("armour", false)
setPlayerHudComponentVisible("breath", false)
setPlayerHudComponentVisible("clock", false)
setPlayerHudComponentVisible("health", false)
setPlayerHudComponentVisible("money", false)
setPlayerHudComponentVisible("weapon", false)
setPlayerHudComponentVisible("wanted", false)

-- ============================================
-- EXPORTS
-- ============================================

function setHudEnabled(enabled)
    hudEnabled = enabled
end

function isHudEnabled()
    return hudEnabled
end
