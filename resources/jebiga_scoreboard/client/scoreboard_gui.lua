--[[
    Jebiga Multi-Gamemode - Modern Scoreboard GUI
    Client-side scoreboard display with enhanced visual design
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- State
local isVisible = false
local scoreboardData = {}
local scrollOffset = 0
local maxVisibleRows = 15
local fadeIn = 0
local glowPulse = 0
local hoverRow = nil

-- Modern color palette
local Colors = {
    primary = {41, 128, 185},
    secondary = {155, 89, 182},
    accent = {46, 204, 113},
    gold = {241, 196, 15},
    danger = {231, 76, 60},
    dark = {18, 18, 24},
    darker = {12, 12, 16},
    panel = {25, 28, 36},
    panelLight = {35, 40, 50},
    text = {255, 255, 255},
    textMuted = {120, 130, 140},
    border = {45, 50, 60},
    online = {46, 204, 113},
    offline = {149, 165, 166}
}

-- GUI dimensions (responsive)
local boardW = 900 * scale
local boardH = 580 * scale
local boardX = (screenW - boardW) / 2
local boardY = (screenH - boardH) / 2

local rowH = 38 * scale
local headerH = 45 * scale

-- Column definitions with better widths
local columns = {
    { name = "#", width = 45 * scale, align = "center", icon = "" },
    { name = "Player", width = 220 * scale, align = "left", icon = "" },
    { name = "Points", width = 110 * scale, align = "right", icon = "" },
    { name = "K/D", width = 90 * scale, align = "center", icon = "" },
    { name = "Money", width = 120 * scale, align = "right", icon = "$" },
    { name = "Mode", width = 110 * scale, align = "center", icon = "" },
    { name = "Ping", width = 70 * scale, align = "center", icon = "" }
}

-- Calculate total column width
local function getTotalColumnWidth()
    local total = 0
    for _, col in ipairs(columns) do
        total = total + col.width
    end
    return total + (#columns - 1) * 15 * scale + 30 * scale
end

-- Show/hide scoreboard
function toggleScoreboard(show)
    if show == nil then
        isVisible = not isVisible
    else
        isVisible = show
    end

    if isVisible then
        fadeIn = 0
        triggerServerEvent("weevil:requestScoreboard", localPlayer)
    end
end

-- Helper: Check mouse over
local function isMouseOver(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * screenW, cy * screenH
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

-- Helper: Get rank color based on points
local function getRankColor(points)
    points = points or 0
    if points >= 50000 then return {255, 0, 128}      -- Master (Pink)
    elseif points >= 10000 then return {231, 76, 60}  -- Diamond (Red)
    elseif points >= 5000 then return {241, 196, 15}  -- Platinum (Gold)
    elseif points >= 1000 then return {155, 89, 182}  -- Gold (Purple)
    elseif points >= 500 then return {52, 152, 219}   -- Silver (Blue)
    elseif points >= 100 then return {46, 204, 113}   -- Bronze (Green)
    else return {149, 165, 166} end                   -- Unranked (Gray)
end

-- Helper: Format number with K/M suffix
local function formatNumber(num)
    num = num or 0
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(math.floor(num))
end

-- Render scoreboard
function renderScoreboard()
    if not isVisible then
        if fadeIn > 0 then
            fadeIn = fadeIn - 0.1
        end
        if fadeIn <= 0 then return end
    else
        fadeIn = math.min(fadeIn + 0.08, 1)
    end

    local alpha = fadeIn * 255

    -- Animate glow pulse
    glowPulse = glowPulse + 0.04
    if glowPulse > math.pi * 2 then glowPulse = 0 end
    local glowIntensity = 0.7 + math.sin(glowPulse) * 0.3

    -- Dark overlay
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(0, 0, 0, 180 * fadeIn), false)

    -- Outer glow effect
    for i = 1, 6 do
        local glowAlpha = (12 / i) * fadeIn * glowIntensity
        dxDrawRectangle(boardX - i * 3, boardY - i * 3, boardW + i * 6, boardH + i * 6,
            tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], glowAlpha), false)
    end

    -- Main background with shadow
    for i = 8, 1, -1 do
        dxDrawRectangle(boardX + i * 2, boardY + i * 2, boardW, boardH, tocolor(0, 0, 0, (20 / i) * fadeIn), false)
    end
    dxDrawRectangle(boardX, boardY, boardW, boardH, tocolor(Colors.dark[1], Colors.dark[2], Colors.dark[3], alpha * 0.98), false)

    -- Top gradient accent
    for i = 0, 4 do
        local gradAlpha = (4 - i) * 50 * (alpha / 255)
        dxDrawRectangle(boardX, boardY + i, boardW, 1, tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], gradAlpha), false)
    end

    -- Animated top border
    local accentWidth = boardW * 0.5
    local accentX = boardX + (boardW - accentWidth) / 2
    dxDrawRectangle(boardX, boardY, boardW, 4, tocolor(Colors.border[1], Colors.border[2], Colors.border[3], alpha * 0.5), false)
    dxDrawRectangle(accentX, boardY, accentWidth, 4, tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], alpha * glowIntensity), false)

    -- Header area background
    local titleAreaH = 60 * scale
    dxDrawRectangle(boardX, boardY, boardW, titleAreaH, tocolor(Colors.panel[1], Colors.panel[2], Colors.panel[3], alpha * 0.8), false)

    -- Title with shadow
    local titleY = boardY + titleAreaH / 2
    dxDrawText("SCOREBOARD", boardX + 2, titleY - 12 * scale + 2, boardX + boardW, titleY + 12 * scale + 2,
        tocolor(0, 0, 0, alpha * 0.5), 1.8 * scale, "bankgothic", "center", "center", false, false, false)
    dxDrawText("SCOREBOARD", boardX, titleY - 12 * scale, boardX + boardW, titleY + 12 * scale,
        tocolor(255, 255, 255, alpha), 1.8 * scale, "bankgothic", "center", "center", false, false, false)

    -- Player count (left side)
    local playerCountBg = boardX + 20 * scale
    dxDrawRectangle(playerCountBg, boardY + 15 * scale, 120 * scale, 30 * scale, tocolor(Colors.accent[1], Colors.accent[2], Colors.accent[3], alpha * 0.2), false)
    dxDrawRectangle(playerCountBg, boardY + 15 * scale, 3, 30 * scale, tocolor(Colors.accent[1], Colors.accent[2], Colors.accent[3], alpha), false)
    dxDrawText(#scoreboardData .. " Online", playerCountBg + 12, boardY + 15 * scale, playerCountBg + 120 * scale, boardY + 45 * scale,
        tocolor(Colors.accent[1], Colors.accent[2], Colors.accent[3], alpha), 0.9 * scale, "default-bold", "left", "center", false, false, false)

    -- Server name (right side)
    local serverName = "Jebiga Gaming"
    if Config and Config.ServerName then
        serverName = Config.ServerName
    end
    dxDrawText(serverName, boardX + boardW - 200 * scale, boardY + 15 * scale, boardX + boardW - 20 * scale, boardY + 45 * scale,
        tocolor(Colors.textMuted[1], Colors.textMuted[2], Colors.textMuted[3], alpha * 0.8), 0.85 * scale, "default-bold", "right", "center", false, false, false)

    -- Header row
    local headerY = boardY + titleAreaH + 5 * scale
    dxDrawRectangle(boardX + 10 * scale, headerY, boardW - 20 * scale, headerH, tocolor(Colors.panelLight[1], Colors.panelLight[2], Colors.panelLight[3], alpha * 0.9), false)

    -- Header bottom line
    dxDrawRectangle(boardX + 10 * scale, headerY + headerH - 2, boardW - 20 * scale, 2, tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], alpha * 0.5), false)

    local colX = boardX + 20 * scale
    for _, col in ipairs(columns) do
        dxDrawText(col.name, colX, headerY, colX + col.width, headerY + headerH,
            tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], alpha), 0.9 * scale, "default-bold", col.align, "center", false, false, false)
        colX = colX + col.width + 15 * scale
    end

    -- Player rows
    local startY = headerY + headerH + 8 * scale
    local visibleCount = 0
    local contentHeight = boardH - titleAreaH - headerH - 60 * scale
    maxVisibleRows = math.floor(contentHeight / rowH)

    hoverRow = nil

    for i, player in ipairs(scoreboardData) do
        if i > scrollOffset and visibleCount < maxVisibleRows then
            visibleCount = visibleCount + 1
            local rowY = startY + (visibleCount - 1) * rowH

            -- Check hover
            local isHover = isMouseOver(boardX + 10 * scale, rowY, boardW - 40 * scale, rowH - 4)
            if isHover then
                hoverRow = i
            end

            -- Row background
            local bgColor
            local isLocalPlayer = player.name == getPlayerName(localPlayer)

            if isLocalPlayer then
                -- Local player highlight with glow
                bgColor = tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], alpha * 0.25)
            elseif isHover then
                bgColor = tocolor(Colors.panelLight[1], Colors.panelLight[2], Colors.panelLight[3], alpha * 0.8)
            elseif i % 2 == 0 then
                bgColor = tocolor(Colors.panel[1], Colors.panel[2], Colors.panel[3], alpha * 0.5)
            else
                bgColor = tocolor(Colors.dark[1], Colors.dark[2], Colors.dark[3], alpha * 0.3)
            end

            dxDrawRectangle(boardX + 10 * scale, rowY, boardW - 40 * scale, rowH - 4, bgColor, false)

            -- Local player left indicator
            if isLocalPlayer then
                dxDrawRectangle(boardX + 10 * scale, rowY, 4, rowH - 4, tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], alpha), false)
            end

            -- Draw columns
            colX = boardX + 20 * scale

            -- Rank number with badge effect
            local rankBadgeColor = getRankColor(player.points or 0)
            dxDrawText(tostring(i), colX, rowY, colX + columns[1].width, rowY + rowH - 4,
                tocolor(rankBadgeColor[1], rankBadgeColor[2], rankBadgeColor[3], alpha), 1.0 * scale, "default-bold", "center", "center", false, false, false)
            colX = colX + columns[1].width + 15 * scale

            -- Name with admin/VIP styling
            local nameColor = {255, 255, 255}
            local prefix = ""
            local prefixColor = nameColor

            if player.adminLevel and player.adminLevel > 0 then
                if Config and Config.AdminLevels and Config.AdminLevels[player.adminLevel] then
                    local adminCfg = Config.AdminLevels[player.adminLevel]
                    if Utils and Utils.hexToRGB then
                        local rgb = Utils.hexToRGB(adminCfg.color)
                        nameColor = {rgb.r, rgb.g, rgb.b}
                    else
                        nameColor = {255, 100, 100}
                    end
                    prefix = "[" .. adminCfg.name:sub(1, 1) .. "] "
                end
            elseif player.vipLevel and player.vipLevel > 0 then
                nameColor = {Colors.gold[1], Colors.gold[2], Colors.gold[3]}
                prefix = "[VIP] "
            end

            -- Draw prefix if exists
            if prefix ~= "" then
                dxDrawText(prefix, colX, rowY, colX + 50 * scale, rowY + rowH - 4,
                    tocolor(nameColor[1], nameColor[2], nameColor[3], alpha * 0.8), 0.85 * scale, "default-bold", "left", "center", false, false, false)
            end

            -- Draw name
            local nameOffsetX = prefix ~= "" and 45 * scale or 0
            dxDrawText(player.name or "Unknown", colX + nameOffsetX, rowY, colX + columns[2].width, rowY + rowH - 4,
                tocolor(nameColor[1], nameColor[2], nameColor[3], alpha), 0.95 * scale, "default-bold", "left", "center", false, false, false)
            colX = colX + columns[2].width + 15 * scale

            -- Points with rank color
            local pointsColor = getRankColor(player.points or 0)
            local pointsText = formatNumber(player.points or 0)
            dxDrawText(pointsText, colX, rowY, colX + columns[3].width, rowY + rowH - 4,
                tocolor(pointsColor[1], pointsColor[2], pointsColor[3], alpha), 0.95 * scale, "default-bold", "right", "center", false, false, false)
            colX = colX + columns[3].width + 15 * scale

            -- K/D with color coding
            local kills = player.kills or 0
            local deaths = player.deaths or 0
            local kd = kills .. "/" .. deaths
            local kdRatio = deaths > 0 and (kills / deaths) or kills
            local kdColor
            if kdRatio >= 2 then
                kdColor = {Colors.accent[1], Colors.accent[2], Colors.accent[3]}
            elseif kdRatio >= 1 then
                kdColor = {255, 255, 255}
            else
                kdColor = {Colors.danger[1], Colors.danger[2], Colors.danger[3]}
            end
            dxDrawText(kd, colX, rowY, colX + columns[4].width, rowY + rowH - 4,
                tocolor(kdColor[1], kdColor[2], kdColor[3], alpha * 0.9), 0.9 * scale, "default", "center", "center", false, false, false)
            colX = colX + columns[4].width + 15 * scale

            -- Money with green color
            local moneyText = "$" .. formatNumber(player.money or 0)
            dxDrawText(moneyText, colX, rowY, colX + columns[5].width, rowY + rowH - 4,
                tocolor(Colors.accent[1], Colors.accent[2], Colors.accent[3], alpha), 0.9 * scale, "default-bold", "right", "center", false, false, false)
            colX = colX + columns[5].width + 15 * scale

            -- Gamemode with color
            local gmText = "Lobby"
            local gmColor = Colors.textMuted
            if not player.inLobby and player.gamemode then
                if Config and Config.Gamemodes and Config.Gamemodes[player.gamemode] then
                    local gm = Config.Gamemodes[player.gamemode]
                    gmText = gm.shortName or gm.name or player.gamemode
                    gmColor = gm.color or Colors.primary
                else
                    gmText = player.gamemode
                    gmColor = Colors.primary
                end
            end

            -- Gamemode badge background
            local gmBadgeW = columns[6].width - 10 * scale
            local gmBadgeH = 22 * scale
            local gmBadgeX = colX + 5 * scale
            local gmBadgeY = rowY + (rowH - 4 - gmBadgeH) / 2
            dxDrawRectangle(gmBadgeX, gmBadgeY, gmBadgeW, gmBadgeH, tocolor(gmColor[1], gmColor[2], gmColor[3], alpha * 0.2), false)
            dxDrawRectangle(gmBadgeX, gmBadgeY, 3, gmBadgeH, tocolor(gmColor[1], gmColor[2], gmColor[3], alpha * 0.8), false)

            dxDrawText(gmText, colX, rowY, colX + columns[6].width, rowY + rowH - 4,
                tocolor(gmColor[1], gmColor[2], gmColor[3], alpha), 0.8 * scale, "default-bold", "center", "center", false, false, false)
            colX = colX + columns[6].width + 15 * scale

            -- Ping with color coding
            local ping = player.ping or 0
            local pingColor
            if ping < 50 then
                pingColor = {Colors.accent[1], Colors.accent[2], Colors.accent[3]}
            elseif ping < 100 then
                pingColor = {Colors.gold[1], Colors.gold[2], Colors.gold[3]}
            elseif ping < 150 then
                pingColor = {255, 150, 50}
            else
                pingColor = {Colors.danger[1], Colors.danger[2], Colors.danger[3]}
            end

            -- Ping indicator dot
            local dotSize = 8 * scale
            local dotX = colX + columns[7].width / 2 - 25 * scale
            local dotY = rowY + (rowH - 4) / 2 - dotSize / 2
            dxDrawRectangle(dotX, dotY, dotSize, dotSize, tocolor(pingColor[1], pingColor[2], pingColor[3], alpha), false)

            dxDrawText(tostring(ping), colX, rowY, colX + columns[7].width, rowY + rowH - 4,
                tocolor(pingColor[1], pingColor[2], pingColor[3], alpha), 0.9 * scale, "default", "center", "center", false, false, false)
        end
    end

    -- Scrollbar
    if #scoreboardData > maxVisibleRows then
        local scrollBarW = 6 * scale
        local scrollBarX = boardX + boardW - 25 * scale
        local scrollAreaH = contentHeight - 20 * scale
        local scrollBarH = math.max(30 * scale, (maxVisibleRows / #scoreboardData) * scrollAreaH)
        local scrollBarY = startY + (scrollOffset / math.max(1, #scoreboardData - maxVisibleRows)) * (scrollAreaH - scrollBarH)

        -- Scrollbar track
        dxDrawRectangle(scrollBarX, startY, scrollBarW, scrollAreaH, tocolor(Colors.border[1], Colors.border[2], Colors.border[3], alpha * 0.5), false)

        -- Scrollbar thumb with glow
        dxDrawRectangle(scrollBarX - 1, scrollBarY - 1, scrollBarW + 2, scrollBarH + 2, tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], alpha * 0.3), false)
        dxDrawRectangle(scrollBarX, scrollBarY, scrollBarW, scrollBarH, tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], alpha * 0.9), false)
    end

    -- Footer
    local footerY = boardY + boardH - 35 * scale
    dxDrawRectangle(boardX, footerY - 5 * scale, boardW, 1, tocolor(Colors.border[1], Colors.border[2], Colors.border[3], alpha * 0.3), false)

    dxDrawText("Press TAB to close", boardX, footerY, boardX + boardW / 2, boardY + boardH,
        tocolor(Colors.textMuted[1], Colors.textMuted[2], Colors.textMuted[3], alpha * 0.6), 0.8 * scale, "default", "center", "center", false, false, false)

    dxDrawText("Scroll with mouse wheel", boardX + boardW / 2, footerY, boardX + boardW, boardY + boardH,
        tocolor(Colors.textMuted[1], Colors.textMuted[2], Colors.textMuted[3], alpha * 0.6), 0.8 * scale, "default", "center", "center", false, false, false)

    -- Border glow on sides
    dxDrawRectangle(boardX, boardY, 2, boardH, tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], alpha * 0.3), false)
    dxDrawRectangle(boardX + boardW - 2, boardY, 2, boardH, tocolor(Colors.secondary[1], Colors.secondary[2], Colors.secondary[3], alpha * 0.3), false)
end

addEventHandler("onClientRender", root, renderScoreboard)

-- Handle scoreboard data update
addEvent("weevil:scoreboardUpdate", true)
addEventHandler("weevil:scoreboardUpdate", root, function(data)
    scoreboardData = data or {}
    scrollOffset = 0
end)

-- Fallback event name
if Events and Events.Scoreboard and Events.Scoreboard.UPDATE then
    addEvent(Events.Scoreboard.UPDATE, true)
    addEventHandler(Events.Scoreboard.UPDATE, root, function(data)
        scoreboardData = data or {}
        scrollOffset = 0
    end)
end

-- Key bindings
bindKey("tab", "down", function()
    toggleScoreboard(true)
end)

bindKey("tab", "up", function()
    toggleScoreboard(false)
end)

bindKey("F4", "down", function()
    toggleScoreboard()
end)

-- Mouse scroll
addEventHandler("onClientKey", root, function(button, press)
    if not isVisible then return end

    if button == "mouse_wheel_up" and press then
        scrollOffset = math.max(0, scrollOffset - 2)
    elseif button == "mouse_wheel_down" and press then
        scrollOffset = math.min(math.max(0, #scoreboardData - maxVisibleRows), scrollOffset + 2)
    end
end)

-- Exports
function isScoreboardVisible()
    return isVisible
end

-- Initialize
addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[Jebiga Scoreboard] Modern scoreboard initialized")
end)
