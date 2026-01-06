--[[
    Jebiga Multi-Gamemode - Custom UI Library
    Beautiful, modern UI components with animations
]]

JebigaUI = {}

local screenW, screenH = guiGetScreenSize()
local scale = (screenH / 1080)

-- Animation state storage
local animations = {}
local hoverStates = {}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

function JebigaUI.getScale()
    return scale
end

function JebigaUI.getScreenSize()
    return screenW, screenH
end

function JebigaUI.color(colorTable, alpha)
    alpha = alpha or 255
    if type(colorTable) == "table" then
        return tocolor(colorTable[1], colorTable[2], colorTable[3], alpha)
    end
    return colorTable
end

function JebigaUI.hexToRGB(hex)
    hex = hex:gsub("#", "")
    return {
        tonumber("0x" .. hex:sub(1, 2)),
        tonumber("0x" .. hex:sub(3, 4)),
        tonumber("0x" .. hex:sub(5, 6))
    }
end

function JebigaUI.lerpColor(c1, c2, t)
    return {
        c1[1] + (c2[1] - c1[1]) * t,
        c1[2] + (c2[2] - c1[2]) * t,
        c1[3] + (c2[3] - c1[3]) * t
    }
end

function JebigaUI.lerp(a, b, t)
    return a + (b - a) * t
end

-- Easing functions
JebigaUI.easing = {
    linear = function(t) return t end,
    inQuad = function(t) return t * t end,
    outQuad = function(t) return t * (2 - t) end,
    inOutQuad = function(t) return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t end,
    outBack = function(t) local c = 1.70158; return 1 + (c + 1) * math.pow(t - 1, 3) + c * math.pow(t - 1, 2) end,
    outElastic = function(t) return t == 0 and 0 or t == 1 and 1 or math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * (2 * math.pi) / 3) + 1 end
}

-- ============================================
-- ANIMATION SYSTEM
-- ============================================

function JebigaUI.animate(id, targetValue, duration, easing)
    duration = duration or 300
    easing = easing or "outQuad"

    if not animations[id] then
        animations[id] = { value = 0, target = targetValue, startValue = 0, startTime = getTickCount(), duration = duration, easing = easing }
    else
        animations[id].startValue = animations[id].value
        animations[id].target = targetValue
        animations[id].startTime = getTickCount()
        animations[id].duration = duration
        animations[id].easing = easing
    end
end

function JebigaUI.getAnimValue(id, defaultValue)
    defaultValue = defaultValue or 0
    if not animations[id] then return defaultValue end

    local anim = animations[id]
    local elapsed = getTickCount() - anim.startTime
    local progress = math.min(elapsed / anim.duration, 1)

    local easingFunc = JebigaUI.easing[anim.easing] or JebigaUI.easing.linear
    local easedProgress = easingFunc(progress)

    anim.value = JebigaUI.lerp(anim.startValue, anim.target, easedProgress)
    return anim.value
end

-- ============================================
-- HOVER DETECTION
-- ============================================

function JebigaUI.isHovering(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * screenW, cy * screenH
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

function JebigaUI.updateHover(id, x, y, w, h)
    local hovering = JebigaUI.isHovering(x, y, w, h)
    if hovering and not hoverStates[id] then
        hoverStates[id] = true
        JebigaUI.animate(id .. "_hover", 1, 150, "outQuad")
    elseif not hovering and hoverStates[id] then
        hoverStates[id] = false
        JebigaUI.animate(id .. "_hover", 0, 150, "outQuad")
    end
    return hoverStates[id] or false
end

function JebigaUI.getHoverValue(id)
    return JebigaUI.getAnimValue(id .. "_hover", 0)
end

-- ============================================
-- BASIC DRAWING FUNCTIONS
-- ============================================

-- Draw rounded rectangle (using multiple rectangles for approximation)
function JebigaUI.drawRoundedRect(x, y, w, h, color, radius, postGUI)
    radius = radius or 8
    postGUI = postGUI or false

    -- Main body
    dxDrawRectangle(x + radius, y, w - radius * 2, h, color, postGUI)
    dxDrawRectangle(x, y + radius, w, h - radius * 2, color, postGUI)

    -- Corners (circles approximated with rectangles)
    dxDrawRectangle(x + radius/2, y + radius/2, radius/2, radius/2, color, postGUI)
    dxDrawRectangle(x + w - radius, y + radius/2, radius/2, radius/2, color, postGUI)
    dxDrawRectangle(x + radius/2, y + h - radius, radius/2, radius/2, color, postGUI)
    dxDrawRectangle(x + w - radius, y + h - radius, radius/2, radius/2, color, postGUI)
end

-- Draw panel with shadow and glow
function JebigaUI.drawPanel(x, y, w, h, options)
    options = options or {}
    local bgColor = options.color or Config.Theme.backgrounds.panel
    local borderColor = options.borderColor or Config.Theme.borders.default
    local alpha = options.alpha or 240
    local shadow = options.shadow ~= false
    local border = options.border ~= false
    local glow = options.glow
    local radius = options.radius or 8

    -- Shadow
    if shadow then
        for i = 4, 1, -1 do
            local shadowAlpha = math.floor(30 / i)
            dxDrawRectangle(x + i*2, y + i*2, w, h, tocolor(0, 0, 0, shadowAlpha), false)
        end
    end

    -- Glow effect
    if glow then
        local glowColor = glow
        for i = 3, 1, -1 do
            local glowAlpha = math.floor(50 / i)
            dxDrawRectangle(x - i, y - i, w + i*2, h + i*2, JebigaUI.color(glowColor, glowAlpha), false)
        end
    end

    -- Main background
    dxDrawRectangle(x, y, w, h, JebigaUI.color(bgColor, alpha), false)

    -- Border
    if border then
        dxDrawRectangle(x, y, w, 1, JebigaUI.color(borderColor, 150), false) -- Top
        dxDrawRectangle(x, y + h - 1, w, 1, JebigaUI.color(borderColor, 150), false) -- Bottom
        dxDrawRectangle(x, y, 1, h, JebigaUI.color(borderColor, 150), false) -- Left
        dxDrawRectangle(x + w - 1, y, 1, h, JebigaUI.color(borderColor, 150), false) -- Right
    end

    -- Top highlight (glass effect)
    dxDrawRectangle(x + 1, y + 1, w - 2, 1, tocolor(255, 255, 255, 20), false)
end

-- Draw gradient (vertical)
function JebigaUI.drawGradient(x, y, w, h, color1, color2, alpha)
    alpha = alpha or 255
    local steps = math.min(h, 50)
    local stepHeight = h / steps

    for i = 0, steps - 1 do
        local t = i / (steps - 1)
        local color = JebigaUI.lerpColor(color1, color2, t)
        dxDrawRectangle(x, y + i * stepHeight, w, stepHeight + 1, JebigaUI.color(color, alpha), false)
    end
end

-- Draw horizontal gradient
function JebigaUI.drawGradientH(x, y, w, h, color1, color2, alpha)
    alpha = alpha or 255
    local steps = math.min(w, 50)
    local stepWidth = w / steps

    for i = 0, steps - 1 do
        local t = i / (steps - 1)
        local color = JebigaUI.lerpColor(color1, color2, t)
        dxDrawRectangle(x + i * stepWidth, y, stepWidth + 1, h, JebigaUI.color(color, alpha), false)
    end
end

-- ============================================
-- UI COMPONENTS
-- ============================================

-- Button Component
function JebigaUI.drawButton(id, x, y, w, h, text, options)
    options = options or {}
    local color = options.color or Config.Theme.brand.primary
    local textColor = options.textColor or Config.Theme.text.primary
    local font = options.font or "default-bold"
    local fontSize = options.fontSize or 1
    local enabled = options.enabled ~= false
    local icon = options.icon

    local isHover = JebigaUI.updateHover(id, x, y, w, h)
    local hoverVal = JebigaUI.getHoverValue(id)

    -- Adjust colors based on hover
    local bgColor = JebigaUI.lerpColor(color, {math.min(color[1] + 30, 255), math.min(color[2] + 30, 255), math.min(color[3] + 30, 255)}, hoverVal)
    local finalAlpha = enabled and 255 or 150

    -- Scale animation
    local scaleOffset = hoverVal * 2
    local bx, by, bw, bh = x - scaleOffset, y - scaleOffset/2, w + scaleOffset*2, h + scaleOffset

    -- Shadow
    dxDrawRectangle(bx + 2, by + 2, bw, bh, tocolor(0, 0, 0, 80 + hoverVal * 40), false)

    -- Button gradient background
    local gradEnd = {math.max(bgColor[1] - 30, 0), math.max(bgColor[2] - 30, 0), math.max(bgColor[3] - 30, 0)}
    JebigaUI.drawGradient(bx, by, bw, bh, bgColor, gradEnd, finalAlpha)

    -- Border
    dxDrawRectangle(bx, by, bw, 1, tocolor(255, 255, 255, 30 + hoverVal * 30), false)

    -- Text
    local textX = bx + bw/2
    if icon then textX = textX + 10 end
    dxDrawText(text, bx, by, bx + bw, by + bh, JebigaUI.color(textColor, finalAlpha), fontSize * scale, font, "center", "center", false, false, false)

    return isHover and getKeyState("mouse1")
end

-- Card Component (for gamemode selection)
function JebigaUI.drawGamemodeCard(id, x, y, w, h, gamemode, playerCount, mapCount)
    local isHover = JebigaUI.updateHover(id, x, y, w, h)
    local hoverVal = JebigaUI.getHoverValue(id)

    -- Card elevation on hover
    local elevation = hoverVal * 8
    local cx, cy = x - elevation/2, y - elevation/2
    local cw, ch = w + elevation, h + elevation

    -- Get gamemode colors
    local gmColor = gamemode.color or {100, 100, 100}
    local gmGradient = gamemode.gradient or gmColor

    -- Shadow
    for i = 4, 1, -1 do
        local shadowAlpha = math.floor((40 + hoverVal * 30) / i)
        dxDrawRectangle(cx + i*2, cy + i*2, cw, ch, tocolor(0, 0, 0, shadowAlpha), false)
    end

    -- Card background
    JebigaUI.drawPanel(cx, cy, cw, ch, {
        color = Config.Theme.backgrounds.panel,
        alpha = 250,
        border = true,
        glow = isHover and gmColor or nil
    })

    -- Colored top bar
    JebigaUI.drawGradientH(cx, cy, cw, 4, gmColor, gmGradient, 255)

    -- Icon area with colored background
    local iconSize = 60 * scale
    local iconX = cx + (cw - iconSize) / 2
    local iconY = cy + 20 * scale
    dxDrawRectangle(iconX, iconY, iconSize, iconSize, JebigaUI.color(gmColor, 40 + hoverVal * 40), false)

    -- Icon symbol (using text for now)
    local iconSymbol = getGamemodeSymbol(gamemode.shortName)
    dxDrawText(iconSymbol, iconX, iconY, iconX + iconSize, iconY + iconSize, JebigaUI.color(gmColor, 200 + hoverVal * 55), 2.5 * scale, "pricedown", "center", "center", false, false, false)

    -- Gamemode name
    local nameY = iconY + iconSize + 15 * scale
    dxDrawText(gamemode.name, cx, nameY, cx + cw, nameY + 25 * scale, JebigaUI.color(Config.Theme.text.primary, 255), 1.2 * scale, "default-bold", "center", "center", false, false, false)

    -- Description
    local descY = nameY + 25 * scale
    dxDrawText(gamemode.description or "", cx + 10, descY, cx + cw - 10, descY + 35 * scale, JebigaUI.color(Config.Theme.text.secondary, 200), 0.9 * scale, "default", "center", "center", true, false, false)

    -- Stats bar at bottom
    local statsY = cy + ch - 35 * scale
    dxDrawRectangle(cx, statsY, cw, 35 * scale, JebigaUI.color(Config.Theme.backgrounds.darker, 200), false)

    -- Player count
    local playersText = playerCount .. " Players"
    dxDrawText(playersText, cx + 15, statsY, cx + cw/2, statsY + 35 * scale, JebigaUI.color(Config.Theme.text.secondary, 200), 0.85 * scale, "default", "left", "center", false, false, false)

    -- Map count
    local mapsText = mapCount .. " Maps"
    dxDrawText(mapsText, cx + cw/2, statsY, cx + cw - 15, statsY + 35 * scale, JebigaUI.color(Config.Theme.text.secondary, 200), 0.85 * scale, "default", "right", "center", false, false, false)

    -- Click indicator on hover
    if isHover then
        dxDrawText("CLICK TO JOIN", cx, cy + ch - 55 * scale, cx + cw, cy + ch - 35 * scale, JebigaUI.color(gmColor, 150 + hoverVal * 105), 0.8 * scale, "default-bold", "center", "center", false, false, false)
    end

    return isHover and getKeyState("mouse1")
end

-- Progress Bar
function JebigaUI.drawProgressBar(x, y, w, h, progress, options)
    options = options or {}
    local bgColor = options.bgColor or Config.Theme.backgrounds.darker
    local fillColor = options.fillColor or Config.Theme.brand.primary
    local showText = options.showText ~= false
    local text = options.text or math.floor(progress * 100) .. "%"

    progress = math.max(0, math.min(1, progress))

    -- Background
    dxDrawRectangle(x, y, w, h, JebigaUI.color(bgColor, 200), false)

    -- Fill with gradient
    local fillWidth = w * progress
    if fillWidth > 0 then
        local gradEnd = {math.max(fillColor[1] - 40, 0), math.max(fillColor[2] - 40, 0), math.max(fillColor[3] - 40, 0)}
        JebigaUI.drawGradientH(x, y, fillWidth, h, fillColor, gradEnd, 255)
    end

    -- Border
    dxDrawRectangle(x, y, w, 1, tocolor(255, 255, 255, 30), false)
    dxDrawRectangle(x, y + h - 1, w, 1, tocolor(0, 0, 0, 50), false)

    -- Text
    if showText then
        dxDrawText(text, x, y, x + w, y + h, tocolor(255, 255, 255, 255), 0.9 * scale, "default-bold", "center", "center", false, false, false)
    end
end

-- Tab Header
function JebigaUI.drawTabHeader(id, x, y, w, h, tabs, activeTab)
    local tabWidth = w / #tabs
    local clicked = nil

    for i, tab in ipairs(tabs) do
        local tabX = x + (i - 1) * tabWidth
        local tabId = id .. "_tab_" .. i
        local isActive = activeTab == i
        local isHover = JebigaUI.updateHover(tabId, tabX, y, tabWidth, h)
        local hoverVal = JebigaUI.getHoverValue(tabId)

        -- Tab background
        local bgAlpha = isActive and 255 or (100 + hoverVal * 50)
        local bgColor = isActive and Config.Theme.brand.primary or Config.Theme.backgrounds.panelHover
        dxDrawRectangle(tabX, y, tabWidth, h, JebigaUI.color(bgColor, bgAlpha), false)

        -- Active indicator
        if isActive then
            dxDrawRectangle(tabX, y + h - 3, tabWidth, 3, JebigaUI.color(Config.Theme.brand.accent, 255), false)
        end

        -- Tab text
        local textColor = isActive and Config.Theme.text.primary or Config.Theme.text.secondary
        dxDrawText(tab, tabX, y, tabX + tabWidth, y + h, JebigaUI.color(textColor, 255), 1 * scale, "default-bold", "center", "center", false, false, false)

        -- Separator
        if i < #tabs then
            dxDrawRectangle(tabX + tabWidth - 1, y + 5, 1, h - 10, JebigaUI.color(Config.Theme.borders.separator, 100), false)
        end

        if isHover and getKeyState("mouse1") then
            clicked = i
        end
    end

    return clicked
end

-- Stat Display
function JebigaUI.drawStat(x, y, w, h, label, value, icon, color)
    color = color or Config.Theme.brand.primary

    -- Background
    JebigaUI.drawPanel(x, y, w, h, {
        color = Config.Theme.backgrounds.panel,
        alpha = 200,
        border = true
    })

    -- Colored left bar
    dxDrawRectangle(x, y, 4, h, JebigaUI.color(color, 255), false)

    -- Icon/symbol
    if icon then
        dxDrawText(icon, x + 10, y, x + 40, y + h, JebigaUI.color(color, 200), 1.5 * scale, "default", "center", "center", false, false, false)
    end

    -- Label
    local labelX = icon and (x + 45) or (x + 15)
    dxDrawText(label, labelX, y + 5, x + w - 10, y + h/2, JebigaUI.color(Config.Theme.text.secondary, 200), 0.85 * scale, "default", "left", "center", false, false, false)

    -- Value
    dxDrawText(tostring(value), labelX, y + h/2, x + w - 10, y + h - 5, JebigaUI.color(Config.Theme.text.primary, 255), 1.1 * scale, "default-bold", "left", "center", false, false, false)
end

-- Title Bar
function JebigaUI.drawTitleBar(x, y, w, h, title, subtitle)
    -- Background with gradient
    JebigaUI.drawGradient(x, y, w, h, Config.Theme.brand.primary, Config.Theme.brand.secondary, 255)

    -- Title
    dxDrawText(title, x + 20, y, x + w - 20, y + h * 0.6, JebigaUI.color(Config.Theme.text.primary, 255), 1.8 * scale, "bankgothic", "left", "center", false, false, false)

    -- Subtitle
    if subtitle then
        dxDrawText(subtitle, x + 20, y + h * 0.5, x + w - 20, y + h, JebigaUI.color(Config.Theme.text.primary, 200), 0.9 * scale, "default", "left", "center", false, false, false)
    end

    -- Jebiga Logo/Brand
    dxDrawText("JEBIGA", x + w - 120, y, x + w - 20, y + h, JebigaUI.color(Config.Theme.text.primary, 150), 1.2 * scale, "bankgothic", "right", "center", false, false, false)
end

-- Close Button
function JebigaUI.drawCloseButton(id, x, y, size)
    size = size or 30
    local isHover = JebigaUI.updateHover(id, x, y, size, size)
    local hoverVal = JebigaUI.getHoverValue(id)

    local bgColor = JebigaUI.lerpColor(Config.Theme.colors.danger, {255, 100, 100}, hoverVal)

    dxDrawRectangle(x, y, size, size, JebigaUI.color(bgColor, 200 + hoverVal * 55), false)
    dxDrawText("X", x, y, x + size, y + size, tocolor(255, 255, 255, 255), 1.2 * scale, "default-bold", "center", "center", false, false, false)

    return isHover and getKeyState("mouse1")
end

-- Scrollbar
function JebigaUI.drawScrollbar(x, y, h, scrollPos, contentHeight, visibleHeight)
    if contentHeight <= visibleHeight then return end

    local scrollbarHeight = (visibleHeight / contentHeight) * h
    local scrollbarY = y + (scrollPos / (contentHeight - visibleHeight)) * (h - scrollbarHeight)

    -- Track
    dxDrawRectangle(x, y, 8, h, JebigaUI.color(Config.Theme.backgrounds.darker, 150), false)

    -- Thumb
    dxDrawRectangle(x, scrollbarY, 8, scrollbarHeight, JebigaUI.color(Config.Theme.brand.primary, 200), false)
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function getGamemodeSymbol(shortName)
    local symbols = {
        DM = "DM",
        Race = "R",
        DD = "DD",
        Hunter = "H",
        FPS = "FPS",
        Stunt = "ST",
        Trials = "TR",
        CB = "CB",
        HP = "HP",
        Run = "RN",
        Train = "T"
    }
    return symbols[shortName] or shortName:sub(1, 2):upper()
end

-- Export for other resources
_G.JebigaUI = JebigaUI
