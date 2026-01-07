--[[
    Jebiga Multi-Gamemode - Enhanced User Panel GUI
    Comprehensive player profile interface with many features
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- State
local isVisible = false
local profileData = {}
local currentTab = "overview"
local fadeIn = 0
local scrollOffset = 0
local maxScroll = 0
local clickCooldown = false
local hoverTab = nil
local animatedProgress = 0
local glowPulse = 0

-- Settings state
local settings = {
    soundEnabled = true,
    musicEnabled = true,
    notificationsEnabled = true,
    showFPS = false,
    showPing = true,
    chatTimestamps = false,
    hudScale = 1.0,
    crosshairStyle = 1,
    language = "English"
}

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
    panelHover = {35, 40, 50},
    text = {255, 255, 255},
    textMuted = {120, 130, 140},
    border = {45, 50, 60}
}

-- Panel dimensions
local panelW = 900 * scale
local panelH = 650 * scale
local panelX = (screenW - panelW) / 2
local panelY = (screenH - panelH) / 2

-- Tabs configuration
local tabs = {
    { id = "overview", name = "Overview", icon = "O" },
    { id = "stats", name = "Statistics", icon = "S" },
    { id = "gamemode_stats", name = "Gamemodes", icon = "G" },
    { id = "achievements", name = "Achievements", icon = "A" },
    { id = "inventory", name = "Inventory", icon = "I" },
    { id = "friends", name = "Friends", icon = "F" },
    { id = "settings", name = "Settings", icon = "C" }
}

-- ============================================
-- SHOW/HIDE
-- ============================================

function showUserPanel()
    isVisible = true
    fadeIn = 0
    showCursor(true)
    scrollOffset = 0
    triggerServerEvent("jebiga:userpanel:requestData", localPlayer)
end

function hideUserPanel()
    isVisible = false
    showCursor(false)
end

function toggleUserPanel()
    if isVisible then
        hideUserPanel()
    else
        showUserPanel()
    end
end

-- Keybind - U to open user panel
bindKey("u", "down", function()
    toggleUserPanel()
end)

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function isMouseOver(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * screenW, cy * screenH
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

function formatNumber(num)
    num = num or 0
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(math.floor(num))
end

function formatTime(seconds)
    seconds = seconds or 0
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return string.format("%dh %dm", hours, mins)
    end
    return string.format("%dm", mins)
end

function formatPlaytime(seconds)
    seconds = seconds or 0
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, mins)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, mins)
    end
    return string.format("%dm", mins)
end

function getRankColor(level)
    local colors = {
        { level = 0, color = {149, 165, 166} },      -- Unranked
        { level = 100, color = {46, 204, 113} },     -- Bronze
        { level = 500, color = {52, 152, 219} },     -- Silver
        { level = 1000, color = {155, 89, 182} },    -- Gold
        { level = 5000, color = {241, 196, 15} },    -- Platinum
        { level = 10000, color = {231, 76, 60} },    -- Diamond
        { level = 50000, color = {255, 0, 128} }     -- Master
    }

    local result = colors[1].color
    for _, rank in ipairs(colors) do
        if level >= rank.level then
            result = rank.color
        end
    end
    return result
end

function getRankName(level)
    level = level or 0
    if level >= 50000 then return "Master"
    elseif level >= 10000 then return "Diamond"
    elseif level >= 5000 then return "Platinum"
    elseif level >= 1000 then return "Gold"
    elseif level >= 500 then return "Silver"
    elseif level >= 100 then return "Bronze"
    else return "Unranked" end
end

-- ============================================
-- RENDER
-- ============================================

addEventHandler("onClientRender", root, function()
    if not isVisible then return end

    -- Animate fade in
    fadeIn = math.min(fadeIn + 0.08, 1)
    local alpha = fadeIn * 255

    -- Animate glow pulse (for accents)
    glowPulse = glowPulse + 0.03
    if glowPulse > math.pi * 2 then glowPulse = 0 end
    local glowIntensity = 0.7 + math.sin(glowPulse) * 0.3

    -- Dark overlay with blur effect simulation
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(0, 0, 0, 200 * fadeIn), false)

    -- Outer glow effect
    local glowSize = 15 * scale
    for i = 1, 5 do
        local glowAlpha = (15 / i) * fadeIn * glowIntensity
        dxDrawRectangle(panelX - i * 3, panelY - i * 3, panelW + i * 6, panelH + i * 6,
            tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], glowAlpha), false)
    end

    -- Main panel
    drawMainPanel(panelX, panelY, panelW, panelH, alpha)

    -- Header
    drawHeader(panelX, panelY, panelW, 70 * scale, alpha, glowIntensity)

    -- Sidebar with tabs
    local sidebarW = 180 * scale
    drawSidebar(panelX, panelY + 70 * scale, sidebarW, panelH - 70 * scale, alpha)

    -- Content area
    local contentX = panelX + sidebarW
    local contentY = panelY + 70 * scale
    local contentW = panelW - sidebarW
    local contentH = panelH - 70 * scale

    drawContent(contentX, contentY, contentW, contentH, alpha)
end)

function drawMainPanel(x, y, w, h, alpha)
    -- Shadow
    for i = 6, 1, -1 do
        dxDrawRectangle(x + i*3, y + i*3, w, h, tocolor(0, 0, 0, (25/i) * (alpha/255)), false)
    end

    -- Background
    dxDrawRectangle(x, y, w, h, tocolor(18, 18, 24, alpha * 0.98), false)

    -- Border glow
    dxDrawRectangle(x, y, w, 3, tocolor(41, 128, 185, alpha), false)
    dxDrawRectangle(x, y, 2, h, tocolor(41, 128, 185, alpha * 0.3), false)
    dxDrawRectangle(x + w - 2, y, 2, h, tocolor(155, 89, 182, alpha * 0.3), false)
end

function drawHeader(x, y, w, h, alpha, glowIntensity)
    glowIntensity = glowIntensity or 1

    -- Header background with gradient effect
    dxDrawRectangle(x, y, w, h, tocolor(22, 25, 32, alpha), false)

    -- Gradient overlay at top
    for i = 0, 10 do
        local gradAlpha = (10 - i) * 2 * (alpha / 255)
        dxDrawRectangle(x, y + i, w, 1, tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], gradAlpha), false)
    end

    -- Animated accent line at bottom
    local accentWidth = w * 0.6
    local accentX = x + (w - accentWidth) / 2
    dxDrawRectangle(x, y + h - 3, w, 3, tocolor(Colors.border[1], Colors.border[2], Colors.border[3], alpha * 0.5), false)
    dxDrawRectangle(accentX, y + h - 3, accentWidth, 3, tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], alpha * glowIntensity), false)

    -- Title with glow
    local titleGlow = 30 * glowIntensity
    dxDrawText("USER PANEL", x + 27, y + 2, x + 202, y + h + 2, tocolor(0, 0, 0, alpha * 0.5), 1.8 * scale, "bankgothic", "left", "center", false, false, false)
    dxDrawText("USER PANEL", x + 25, y, x + 200, y + h, tocolor(255, 255, 255, alpha), 1.8 * scale, "bankgothic", "left", "center", false, false, false)

    -- Player info in header
    if profileData.username then
        local nameX = x + 220 * scale
        local points = profileData.totalPoints or 0
        local rankColor = getRankColor(points)
        local rankName = getRankName(points)

        -- Player name
        dxDrawText(profileData.username, nameX, y + 10, nameX + 200, y + h * 0.5, tocolor(255, 255, 255, alpha), 1.1 * scale, "default-bold", "left", "center", false, false, false)

        -- Rank badge
        dxDrawRectangle(nameX, y + h * 0.55, 80 * scale, 20 * scale, tocolor(rankColor[1], rankColor[2], rankColor[3], alpha * 0.3), false)
        dxDrawRectangle(nameX, y + h * 0.55, 3, 20 * scale, tocolor(rankColor[1], rankColor[2], rankColor[3], alpha), false)
        dxDrawText(rankName, nameX + 10, y + h * 0.55, nameX + 80 * scale, y + h * 0.55 + 20 * scale, tocolor(rankColor[1], rankColor[2], rankColor[3], alpha), 0.85 * scale, "default-bold", "left", "center", false, false, false)
    end

    -- Currency display
    local money = profileData.money or 0
    local moneyX = x + w - 250 * scale
    dxDrawRectangle(moneyX, y + 15, 120 * scale, 40 * scale, tocolor(241, 196, 15, alpha * 0.15), false)
    dxDrawRectangle(moneyX, y + 15, 3, 40 * scale, tocolor(241, 196, 15, alpha), false)
    dxDrawText("$ " .. formatNumber(money), moneyX + 15, y + 15, moneyX + 120 * scale, y + 55, tocolor(241, 196, 15, alpha), 1.1 * scale, "default-bold", "left", "center", false, false, false)

    -- Close button
    local closeSize = 40 * scale
    local closeX = x + w - closeSize - 15
    local closeY = y + (h - closeSize) / 2

    local closeHover = isMouseOver(closeX, closeY, closeSize, closeSize)
    local closeBg = closeHover and {231, 76, 60} or {60, 65, 75}

    dxDrawRectangle(closeX, closeY, closeSize, closeSize, tocolor(closeBg[1], closeBg[2], closeBg[3], alpha), false)
    dxDrawText("✕", closeX, closeY, closeX + closeSize, closeY + closeSize, tocolor(255, 255, 255, alpha), 1.3 * scale, "default-bold", "center", "center", false, false, false)

    if closeHover and getKeyState("mouse1") and not clickCooldown then
        clickCooldown = true
        setTimer(function() clickCooldown = false end, 200, 1)
        hideUserPanel()
    end

    -- Bottom border
    dxDrawRectangle(x, y + h - 1, w, 1, tocolor(40, 45, 55, alpha * 0.5), false)
end

function drawSidebar(x, y, w, h, alpha)
    -- Sidebar background with subtle gradient
    dxDrawRectangle(x, y, w, h, tocolor(22, 25, 32, alpha), false)

    -- Subtle right border glow
    for i = 1, 3 do
        dxDrawRectangle(x + w - i, y, 1, h, tocolor(Colors.border[1], Colors.border[2], Colors.border[3], alpha * (0.3 / i)), false)
    end

    local tabHeight = 50 * scale
    local tabY = y + 15

    for i, tab in ipairs(tabs) do
        local isActive = currentTab == tab.id
        local isHover = isMouseOver(x, tabY, w - 5, tabHeight - 5)

        -- Smooth background transition
        local bgR, bgG, bgB, bgA
        if isActive then
            bgR, bgG, bgB = Colors.primary[1], Colors.primary[2], Colors.primary[3]
            bgA = alpha * 0.8
        elseif isHover then
            bgR, bgG, bgB = Colors.panelHover[1], Colors.panelHover[2], Colors.panelHover[3]
            bgA = alpha * 0.9
        else
            bgR, bgG, bgB = Colors.panel[1], Colors.panel[2], Colors.panel[3]
            bgA = alpha * 0.3
        end

        -- Tab background with rounded corners effect
        dxDrawRectangle(x + 8, tabY + 2, w - 16, tabHeight - 9, tocolor(bgR, bgG, bgB, bgA), false)

        -- Active indicator with glow
        if isActive then
            for j = 1, 3 do
                dxDrawRectangle(x + j - 1, tabY + 2, 4 - j + 1, tabHeight - 9,
                    tocolor(Colors.accent[1], Colors.accent[2], Colors.accent[3], alpha * (1 - j * 0.2)), false)
            end
        end

        -- Hover highlight effect
        if isHover and not isActive then
            dxDrawRectangle(x + 8, tabY + 2, 3, tabHeight - 9,
                tocolor(Colors.secondary[1], Colors.secondary[2], Colors.secondary[3], alpha * 0.6), false)
        end

        -- Icon with shadow
        local textColor = isActive and {255, 255, 255} or (isHover and {220, 225, 230} or {100, 110, 120})
        if isActive or isHover then
            dxDrawText(tab.icon, x + 22, tabY + 2, x + 47, tabY + tabHeight - 3,
                tocolor(0, 0, 0, alpha * 0.3), 1.2 * scale, "default-bold", "center", "center", false, false, false)
        end
        dxDrawText(tab.icon, x + 20, tabY, x + 45, tabY + tabHeight - 5,
            tocolor(textColor[1], textColor[2], textColor[3], alpha), 1.2 * scale, "default-bold", "center", "center", false, false, false)

        -- Tab name with shadow for active
        if isActive then
            dxDrawText(tab.name, x + 52, tabY + 2, x + w - 8, tabY + tabHeight - 3,
                tocolor(0, 0, 0, alpha * 0.3), 0.95 * scale, "default-bold", "left", "center", false, false, false)
        end
        dxDrawText(tab.name, x + 50, tabY, x + w - 10, tabY + tabHeight - 5,
            tocolor(textColor[1], textColor[2], textColor[3], alpha), 0.95 * scale, "default-bold", "left", "center", false, false, false)

        -- Handle click
        if isHover and getKeyState("mouse1") and not clickCooldown then
            clickCooldown = true
            setTimer(function() clickCooldown = false end, 200, 1)
            currentTab = tab.id
            scrollOffset = 0
            playSoundFrontEnd(37)
        end

        tabY = tabY + tabHeight
    end

    -- Footer with gradient separator
    local footerY = y + h - 70 * scale
    for i = 0, 5 do
        dxDrawRectangle(x + 10, footerY + i, w - 20, 1,
            tocolor(Colors.border[1], Colors.border[2], Colors.border[3], alpha * (0.5 - i * 0.08)), false)
    end

    -- Footer text with better styling
    dxDrawText("Press U to close", x, footerY + 15, x + w, footerY + 35,
        tocolor(Colors.textMuted[1], Colors.textMuted[2], Colors.textMuted[3], alpha * 0.6), 0.8 * scale, "default", "center", "top", false, false, false)

    -- Jebiga Gaming branding with gradient text effect
    dxDrawText("JEBIGA GAMING", x, footerY + 38, x + w, footerY + 58,
        tocolor(Colors.primary[1], Colors.primary[2], Colors.primary[3], alpha * 0.8), 0.85 * scale, "default-bold", "center", "top", false, false, false)
end

function drawContent(x, y, w, h, alpha)
    -- Content background
    dxDrawRectangle(x, y, w, h, tocolor(15, 15, 20, alpha), false)

    -- Render current tab content
    if currentTab == "overview" then
        renderOverviewTab(x, y, w, h, alpha)
    elseif currentTab == "stats" then
        renderStatsTab(x, y, w, h, alpha)
    elseif currentTab == "gamemode_stats" then
        renderGamemodeStatsTab(x, y, w, h, alpha)
    elseif currentTab == "achievements" then
        renderAchievementsTab(x, y, w, h, alpha)
    elseif currentTab == "inventory" then
        renderInventoryTab(x, y, w, h, alpha)
    elseif currentTab == "friends" then
        renderFriendsTab(x, y, w, h, alpha)
    elseif currentTab == "settings" then
        renderSettingsTab(x, y, w, h, alpha)
    end
end

-- ============================================
-- TAB: OVERVIEW
-- ============================================

function renderOverviewTab(x, y, w, h, alpha)
    local padding = 20 * scale

    -- Profile Card
    local cardW = (w - padding * 3) / 2
    local cardH = 200 * scale
    local cardX = x + padding
    local cardY = y + padding

    drawProfileCard(cardX, cardY, cardW, cardH, alpha)

    -- Quick Stats Card
    drawQuickStats(cardX + cardW + padding, cardY, cardW, cardH, alpha)

    -- Recent Activity
    local activityY = cardY + cardH + padding
    local activityH = h - cardH - padding * 3
    drawRecentActivity(cardX, activityY, w - padding * 2, activityH, alpha)
end

function drawProfileCard(x, y, w, h, alpha)
    -- Card background
    dxDrawRectangle(x, y, w, h, tocolor(25, 28, 36, alpha), false)
    dxDrawRectangle(x, y, w, 4, tocolor(41, 128, 185, alpha), false)

    -- Title
    dxDrawText("PROFILE", x + 15, y + 15, x + w, y + 35, tocolor(100, 110, 120, alpha), 0.8 * scale, "default-bold", "left", "top", false, false, false)

    -- Avatar placeholder
    local avatarSize = 80 * scale
    local avatarX = x + 20
    local avatarY = y + 50

    dxDrawRectangle(avatarX, avatarY, avatarSize, avatarSize, tocolor(60, 65, 75, alpha), false)

    local points = profileData.totalPoints or 0
    local rankColor = getRankColor(points)
    dxDrawText(getRankName(points):sub(1, 1), avatarX, avatarY, avatarX + avatarSize, avatarY + avatarSize, tocolor(rankColor[1], rankColor[2], rankColor[3], alpha), 2.5 * scale, "pricedown", "center", "center", false, false, false)

    -- Player details
    local detailsX = avatarX + avatarSize + 15
    local detailsY = avatarY

    -- Username
    dxDrawText(profileData.username or "Unknown", detailsX, detailsY, x + w - 15, detailsY + 25, tocolor(255, 255, 255, alpha), 1.2 * scale, "default-bold", "left", "center", false, false, false)

    -- Rank
    local rankName = getRankName(points)
    dxDrawText(rankName, detailsX, detailsY + 28, x + w - 15, detailsY + 48, tocolor(rankColor[1], rankColor[2], rankColor[3], alpha), 0.95 * scale, "default-bold", "left", "center", false, false, false)

    -- Stats
    dxDrawText("Total Points: " .. formatNumber(points), detailsX, detailsY + 55, x + w - 15, detailsY + 72, tocolor(160, 170, 180, alpha), 0.85 * scale, "default", "left", "center", false, false, false)

    local playtime = profileData.playtime or 0
    dxDrawText("Playtime: " .. formatPlaytime(playtime), detailsX, detailsY + 75, x + w - 15, detailsY + 92, tocolor(160, 170, 180, alpha), 0.85 * scale, "default", "left", "center", false, false, false)

    -- VIP badge if applicable
    if profileData.isVIP then
        local vipY = y + h - 35
        dxDrawRectangle(x + 15, vipY, 60 * scale, 25 * scale, tocolor(241, 196, 15, alpha * 0.2), false)
        dxDrawRectangle(x + 15, vipY, 3, 25 * scale, tocolor(241, 196, 15, alpha), false)
        dxDrawText("VIP", x + 25, vipY, x + 75 * scale, vipY + 25 * scale, tocolor(241, 196, 15, alpha), 0.9 * scale, "default-bold", "left", "center", false, false, false)
    end
end

function drawQuickStats(x, y, w, h, alpha)
    -- Card background
    dxDrawRectangle(x, y, w, h, tocolor(25, 28, 36, alpha), false)
    dxDrawRectangle(x, y, w, 4, tocolor(155, 89, 182, alpha), false)

    -- Title
    dxDrawText("QUICK STATS", x + 15, y + 15, x + w, y + 35, tocolor(100, 110, 120, alpha), 0.8 * scale, "default-bold", "left", "top", false, false, false)

    -- Stats grid
    local stats = {
        { label = "Total Kills", value = profileData.totalKills or 0, color = {231, 76, 60} },
        { label = "Total Deaths", value = profileData.totalDeaths or 0, color = {149, 165, 166} },
        { label = "Wins", value = profileData.totalWins or 0, color = {46, 204, 113} },
        { label = "Losses", value = profileData.totalLosses or 0, color = {231, 76, 60} },
        { label = "K/D Ratio", value = string.format("%.2f", (profileData.totalKills or 0) / math.max(1, profileData.totalDeaths or 1)), color = {52, 152, 219} },
        { label = "Win Rate", value = string.format("%.1f%%", ((profileData.totalWins or 0) / math.max(1, (profileData.totalWins or 0) + (profileData.totalLosses or 0))) * 100), color = {46, 204, 113} }
    }

    local statH = 25 * scale
    local statY = y + 50
    local col1X = x + 15
    local col2X = x + w / 2

    for i, stat in ipairs(stats) do
        local statX = i % 2 == 1 and col1X or col2X
        if i % 2 == 1 and i > 1 then statY = statY + statH + 5 end

        dxDrawText(stat.label, statX, statY, statX + w/2 - 20, statY + statH, tocolor(100, 110, 120, alpha), 0.8 * scale, "default", "left", "center", false, false, false)
        dxDrawText(tostring(stat.value), statX + w/2 - 80, statY, statX + w/2 - 20, statY + statH, tocolor(stat.color[1], stat.color[2], stat.color[3], alpha), 1.0 * scale, "default-bold", "right", "center", false, false, false)
    end
end

function drawRecentActivity(x, y, w, h, alpha)
    -- Card background
    dxDrawRectangle(x, y, w, h, tocolor(25, 28, 36, alpha), false)
    dxDrawRectangle(x, y, w, 4, tocolor(46, 204, 113, alpha), false)

    -- Title
    dxDrawText("RECENT ACTIVITY", x + 15, y + 15, x + w, y + 35, tocolor(100, 110, 120, alpha), 0.8 * scale, "default-bold", "left", "top", false, false, false)

    -- Activity list (placeholder)
    local activities = profileData.recentActivity or {
        { type = "join", text = "Joined Jebiga Gaming", time = "Just now" },
        { type = "gamemode", text = "Ready to play!", time = "" }
    }

    local actY = y + 50
    for i, activity in ipairs(activities) do
        if actY + 35 < y + h - 10 then
            -- Activity icon
            local iconColor = activity.type == "win" and {46, 204, 113} or (activity.type == "kill" and {231, 76, 60} or {100, 110, 120})
            dxDrawRectangle(x + 15, actY, 8, 8, tocolor(iconColor[1], iconColor[2], iconColor[3], alpha), false)

            -- Activity text
            dxDrawText(activity.text, x + 35, actY - 5, x + w - 100, actY + 20, tocolor(200, 210, 220, alpha), 0.85 * scale, "default", "left", "center", false, false, false)

            -- Time
            dxDrawText(activity.time, x + w - 100, actY - 5, x + w - 15, actY + 20, tocolor(80, 90, 100, alpha), 0.75 * scale, "default", "right", "center", false, false, false)

            actY = actY + 35
        end
    end
end

-- ============================================
-- TAB: STATISTICS
-- ============================================

function renderStatsTab(x, y, w, h, alpha)
    local padding = 20 * scale

    -- Title
    dxDrawText("DETAILED STATISTICS", x + padding, y + padding, x + w, y + padding + 30, tocolor(255, 255, 255, alpha), 1.1 * scale, "default-bold", "left", "center", false, false, false)

    -- Stats cards
    local cardW = (w - padding * 4) / 3
    local cardH = 100 * scale
    local cardY = y + padding + 45

    -- Total Points
    drawStatCard(x + padding, cardY, cardW, cardH, "TOTAL POINTS", formatNumber(profileData.totalPoints or 0), {241, 196, 15}, alpha)

    -- Total Money
    drawStatCard(x + padding * 2 + cardW, cardY, cardW, cardH, "TOTAL MONEY", "$ " .. formatNumber(profileData.money or 0), {46, 204, 113}, alpha)

    -- Playtime
    drawStatCard(x + padding * 3 + cardW * 2, cardY, cardW, cardH, "PLAYTIME", formatPlaytime(profileData.playtime or 0), {52, 152, 219}, alpha)

    -- Second row
    cardY = cardY + cardH + padding

    -- Total Kills
    drawStatCard(x + padding, cardY, cardW, cardH, "TOTAL KILLS", formatNumber(profileData.totalKills or 0), {231, 76, 60}, alpha)

    -- Total Deaths
    drawStatCard(x + padding * 2 + cardW, cardY, cardW, cardH, "TOTAL DEATHS", formatNumber(profileData.totalDeaths or 0), {149, 165, 166}, alpha)

    -- K/D Ratio
    local kd = (profileData.totalKills or 0) / math.max(1, profileData.totalDeaths or 1)
    drawStatCard(x + padding * 3 + cardW * 2, cardY, cardW, cardH, "K/D RATIO", string.format("%.2f", kd), kd >= 1 and {46, 204, 113} or {231, 76, 60}, alpha)

    -- Third row
    cardY = cardY + cardH + padding

    -- Wins
    drawStatCard(x + padding, cardY, cardW, cardH, "TOTAL WINS", formatNumber(profileData.totalWins or 0), {46, 204, 113}, alpha)

    -- Losses
    drawStatCard(x + padding * 2 + cardW, cardY, cardW, cardH, "TOTAL LOSSES", formatNumber(profileData.totalLosses or 0), {231, 76, 60}, alpha)

    -- Win Rate
    local winRate = ((profileData.totalWins or 0) / math.max(1, (profileData.totalWins or 0) + (profileData.totalLosses or 0))) * 100
    drawStatCard(x + padding * 3 + cardW * 2, cardY, cardW, cardH, "WIN RATE", string.format("%.1f%%", winRate), winRate >= 50 and {46, 204, 113} or {231, 76, 60}, alpha)
end

function drawStatCard(x, y, w, h, label, value, color, alpha)
    -- Card background with subtle gradient
    dxDrawRectangle(x, y, w, h, tocolor(25, 28, 36, alpha), false)

    -- Top accent bar with glow effect
    dxDrawRectangle(x, y, w, 4, tocolor(color[1], color[2], color[3], alpha), false)
    for i = 1, 3 do
        dxDrawRectangle(x, y + 4 + i, w, 1, tocolor(color[1], color[2], color[3], alpha * (0.15 / i)), false)
    end

    -- Subtle border
    dxDrawRectangle(x, y, 1, h, tocolor(Colors.border[1], Colors.border[2], Colors.border[3], alpha * 0.3), false)
    dxDrawRectangle(x + w - 1, y, 1, h, tocolor(Colors.border[1], Colors.border[2], Colors.border[3], alpha * 0.3), false)
    dxDrawRectangle(x, y + h - 1, w, 1, tocolor(Colors.border[1], Colors.border[2], Colors.border[3], alpha * 0.3), false)

    -- Label with icon effect
    dxDrawText(label, x + 15, y + 18, x + w - 15, y + 35, tocolor(Colors.textMuted[1], Colors.textMuted[2], Colors.textMuted[3], alpha), 0.75 * scale, "default-bold", "left", "center", false, false, false)

    -- Value with shadow
    dxDrawText(value, x + 17, y + 42, x + w - 13, y + h - 8, tocolor(0, 0, 0, alpha * 0.4), 1.5 * scale, "default-bold", "left", "center", false, false, false)
    dxDrawText(value, x + 15, y + 40, x + w - 15, y + h - 10, tocolor(color[1], color[2], color[3], alpha), 1.5 * scale, "default-bold", "left", "center", false, false, false)

    -- Hover effect
    if isMouseOver(x, y, w, h) then
        dxDrawRectangle(x, y, w, h, tocolor(255, 255, 255, alpha * 0.03), false)
    end
end

-- ============================================
-- TAB: GAMEMODE STATS
-- ============================================

function renderGamemodeStatsTab(x, y, w, h, alpha)
    local padding = 20 * scale

    -- Title
    dxDrawText("GAMEMODE STATISTICS", x + padding, y + padding, x + w, y + padding + 30, tocolor(255, 255, 255, alpha), 1.1 * scale, "default-bold", "left", "center", false, false, false)

    local cardW = (w - padding * 3) / 2
    local cardH = 120 * scale
    local col = 0
    local cardY = y + padding + 45

    local gamemodeStats = profileData.gamemodeStats or {}

    for gmKey, gm in pairs(Config.Gamemodes or {}) do
        if gm.enabled then
            local stats = gamemodeStats[gmKey] or {}
            local cardX = x + padding + col * (cardW + padding)

            drawGamemodeStatCard(cardX, cardY, cardW, cardH, gm, stats, alpha)

            col = col + 1
            if col >= 2 then
                col = 0
                cardY = cardY + cardH + padding
            end
        end
    end
end

function drawGamemodeStatCard(x, y, w, h, gm, stats, alpha)
    local gmColor = gm.color or {100, 100, 100}

    -- Background
    dxDrawRectangle(x, y, w, h, tocolor(25, 28, 36, alpha), false)
    dxDrawRectangle(x, y, w, 4, tocolor(gmColor[1], gmColor[2], gmColor[3], alpha), false)

    -- Gamemode name
    dxDrawText(gm.name:upper(), x + 15, y + 15, x + w - 15, y + 35, tocolor(gmColor[1], gmColor[2], gmColor[3], alpha), 1.0 * scale, "default-bold", "left", "center", false, false, false)

    -- Stats
    local statsY = y + 45
    local col1 = x + 15
    local col2 = x + w / 2

    dxDrawText("Points: " .. formatNumber(stats.points or 0), col1, statsY, col2, statsY + 20, tocolor(241, 196, 15, alpha), 0.85 * scale, "default", "left", "center", false, false, false)
    dxDrawText("Wins: " .. formatNumber(stats.wins or 0), col2, statsY, x + w - 15, statsY + 20, tocolor(46, 204, 113, alpha), 0.85 * scale, "default", "left", "center", false, false, false)

    dxDrawText("Kills: " .. formatNumber(stats.kills or 0), col1, statsY + 25, col2, statsY + 45, tocolor(231, 76, 60, alpha), 0.85 * scale, "default", "left", "center", false, false, false)
    dxDrawText("Deaths: " .. formatNumber(stats.deaths or 0), col2, statsY + 25, x + w - 15, statsY + 45, tocolor(149, 165, 166, alpha), 0.85 * scale, "default", "left", "center", false, false, false)

    dxDrawText("Time: " .. formatTime(stats.playTime or 0), col1, statsY + 50, x + w - 15, statsY + 70, tocolor(100, 110, 120, alpha), 0.8 * scale, "default", "left", "center", false, false, false)
end

-- ============================================
-- TAB: ACHIEVEMENTS
-- ============================================

function renderAchievementsTab(x, y, w, h, alpha)
    local padding = 20 * scale

    local totalAchievements = #(Config.Achievements and Config.Achievements.list or {})
    local unlockedAchievements = #(profileData.achievements or {})

    -- Header
    dxDrawText("ACHIEVEMENTS (" .. unlockedAchievements .. "/" .. totalAchievements .. ")", x + padding, y + padding, x + w - padding, y + padding + 30, tocolor(255, 255, 255, alpha), 1.1 * scale, "default-bold", "left", "center", false, false, false)

    -- Progress bar
    local progress = unlockedAchievements / math.max(1, totalAchievements)
    local barY = y + padding + 40
    dxDrawRectangle(x + padding, barY, w - padding * 2, 8, tocolor(40, 45, 55, alpha), false)
    dxDrawRectangle(x + padding, barY, (w - padding * 2) * progress, 8, tocolor(46, 204, 113, alpha), false)

    -- Achievement list
    local listY = barY + 25
    local achievements = Config.Achievements and Config.Achievements.list or {}
    local unlockedIds = {}
    for _, ach in ipairs(profileData.achievements or {}) do
        unlockedIds[ach.id] = true
    end

    for i, ach in ipairs(achievements) do
        if listY + 60 < y + h - padding then
            local isUnlocked = unlockedIds[ach.id]

            -- Achievement card
            local cardAlpha = isUnlocked and alpha or alpha * 0.5
            dxDrawRectangle(x + padding, listY, w - padding * 2, 55, tocolor(25, 28, 36, cardAlpha), false)

            -- Left color bar
            local achColor = isUnlocked and {241, 196, 15} or {60, 65, 75}
            dxDrawRectangle(x + padding, listY, 4, 55, tocolor(achColor[1], achColor[2], achColor[3], cardAlpha), false)

            -- Icon
            local iconText = isUnlocked and "★" or "☆"
            dxDrawText(iconText, x + padding + 15, listY, x + padding + 50, listY + 55, tocolor(achColor[1], achColor[2], achColor[3], cardAlpha), 1.5 * scale, "default", "center", "center", false, false, false)

            -- Name and description
            dxDrawText(ach.name, x + padding + 55, listY + 8, x + w - 120, listY + 28, tocolor(255, 255, 255, cardAlpha), 1.0 * scale, "default-bold", "left", "center", false, false, false)
            dxDrawText(ach.desc, x + padding + 55, listY + 30, x + w - 120, listY + 50, tocolor(140, 150, 160, cardAlpha * 0.8), 0.8 * scale, "default", "left", "center", false, false, false)

            -- Reward
            dxDrawText("+" .. formatNumber(ach.reward) .. " JCoins", x + w - 110, listY, x + w - padding - 10, listY + 55, tocolor(46, 204, 113, cardAlpha), 0.85 * scale, "default-bold", "right", "center", false, false, false)

            listY = listY + 60
        end
    end
end

-- ============================================
-- TAB: INVENTORY
-- ============================================

function renderInventoryTab(x, y, w, h, alpha)
    local padding = 20 * scale

    dxDrawText("INVENTORY", x + padding, y + padding, x + w, y + padding + 30, tocolor(255, 255, 255, alpha), 1.1 * scale, "default-bold", "left", "center", false, false, false)

    -- Categories
    local categories = {"Vehicles", "Skins", "Weapons", "Effects"}
    local catW = (w - padding * 2 - padding * (#categories - 1)) / #categories
    local catY = y + padding + 45

    for i, cat in ipairs(categories) do
        local catX = x + padding + (i - 1) * (catW + padding)
        local isActive = i == 1

        dxDrawRectangle(catX, catY, catW, 35, tocolor(isActive and 41 or 40, isActive and 128 or 45, isActive and 185 or 55, alpha * (isActive and 1 or 0.5)), false)
        dxDrawText(cat, catX, catY, catX + catW, catY + 35, tocolor(255, 255, 255, alpha * (isActive and 1 or 0.7)), 0.9 * scale, "default-bold", "center", "center", false, false, false)
    end

    -- Inventory items (placeholder)
    local itemY = catY + 55
    dxDrawText("Your inventory is empty.", x + padding, itemY, x + w - padding, itemY + 50, tocolor(100, 110, 120, alpha * 0.7), 1.0 * scale, "default", "center", "center", false, false, false)
    dxDrawText("Visit the Garage to purchase vehicles!", x + padding, itemY + 30, x + w - padding, itemY + 80, tocolor(80, 90, 100, alpha * 0.5), 0.85 * scale, "default", "center", "center", false, false, false)
end

-- ============================================
-- TAB: FRIENDS
-- ============================================

function renderFriendsTab(x, y, w, h, alpha)
    local padding = 20 * scale

    dxDrawText("FRIENDS", x + padding, y + padding, x + w, y + padding + 30, tocolor(255, 255, 255, alpha), 1.1 * scale, "default-bold", "left", "center", false, false, false)

    -- Online/Offline toggle
    local toggleY = y + padding + 45
    dxDrawRectangle(x + padding, toggleY, 80 * scale, 30, tocolor(41, 128, 185, alpha), false)
    dxDrawText("Online", x + padding, toggleY, x + padding + 80 * scale, toggleY + 30, tocolor(255, 255, 255, alpha), 0.85 * scale, "default-bold", "center", "center", false, false, false)

    dxDrawRectangle(x + padding + 85 * scale, toggleY, 80 * scale, 30, tocolor(40, 45, 55, alpha * 0.5), false)
    dxDrawText("All", x + padding + 85 * scale, toggleY, x + padding + 165 * scale, toggleY + 30, tocolor(160, 170, 180, alpha), 0.85 * scale, "default-bold", "center", "center", false, false, false)

    -- Friends list (placeholder)
    local listY = toggleY + 50
    local friends = profileData.friends or {}

    if #friends == 0 then
        dxDrawText("No friends yet.", x + padding, listY, x + w - padding, listY + 50, tocolor(100, 110, 120, alpha * 0.7), 1.0 * scale, "default", "center", "center", false, false, false)
        dxDrawText("Use /addfriend <name> to add friends!", x + padding, listY + 30, x + w - padding, listY + 80, tocolor(80, 90, 100, alpha * 0.5), 0.85 * scale, "default", "center", "center", false, false, false)
    else
        for i, friend in ipairs(friends) do
            if listY + 50 < y + h - padding then
                local isOnline = friend.online
                local statusColor = isOnline and {46, 204, 113} or {100, 110, 120}

                dxDrawRectangle(x + padding, listY, w - padding * 2, 45, tocolor(25, 28, 36, alpha), false)
                dxDrawRectangle(x + padding, listY, 4, 45, tocolor(statusColor[1], statusColor[2], statusColor[3], alpha), false)

                dxDrawText(friend.name, x + padding + 20, listY, x + w - 100, listY + 45, tocolor(255, 255, 255, alpha), 1.0 * scale, "default-bold", "left", "center", false, false, false)

                local statusText = isOnline and "Online" or "Offline"
                dxDrawText(statusText, x + w - 100, listY, x + w - padding - 10, listY + 45, tocolor(statusColor[1], statusColor[2], statusColor[3], alpha), 0.85 * scale, "default", "right", "center", false, false, false)

                listY = listY + 50
            end
        end
    end
end

-- ============================================
-- TAB: SETTINGS
-- ============================================

function renderSettingsTab(x, y, w, h, alpha)
    local padding = 20 * scale

    dxDrawText("SETTINGS", x + padding, y + padding, x + w, y + padding + 30, tocolor(255, 255, 255, alpha), 1.1 * scale, "default-bold", "left", "center", false, false, false)

    local settingY = y + padding + 50
    local settingH = 45 * scale

    -- Sound settings
    drawSettingToggle(x + padding, settingY, w - padding * 2, settingH, "Sound Effects", "Enable in-game sound effects", settings.soundEnabled, "soundEnabled", alpha)
    settingY = settingY + settingH + 10

    drawSettingToggle(x + padding, settingY, w - padding * 2, settingH, "Background Music", "Enable lobby and menu music", settings.musicEnabled, "musicEnabled", alpha)
    settingY = settingY + settingH + 10

    drawSettingToggle(x + padding, settingY, w - padding * 2, settingH, "Notifications", "Show achievement and reward popups", settings.notificationsEnabled, "notificationsEnabled", alpha)
    settingY = settingY + settingH + 10

    -- HUD settings
    settingY = settingY + 15
    dxDrawText("HUD SETTINGS", x + padding, settingY, x + w, settingY + 20, tocolor(100, 110, 120, alpha), 0.8 * scale, "default-bold", "left", "center", false, false, false)
    settingY = settingY + 30

    drawSettingToggle(x + padding, settingY, w - padding * 2, settingH, "Show FPS", "Display frames per second counter", settings.showFPS, "showFPS", alpha)
    settingY = settingY + settingH + 10

    drawSettingToggle(x + padding, settingY, w - padding * 2, settingH, "Show Ping", "Display network latency", settings.showPing, "showPing", alpha)
    settingY = settingY + settingH + 10

    drawSettingToggle(x + padding, settingY, w - padding * 2, settingH, "Chat Timestamps", "Show time in chat messages", settings.chatTimestamps, "chatTimestamps", alpha)
end

function drawSettingToggle(x, y, w, h, label, description, value, settingKey, alpha)
    -- Background
    dxDrawRectangle(x, y, w, h, tocolor(25, 28, 36, alpha), false)

    -- Label and description
    dxDrawText(label, x + 15, y + 5, x + w - 80, y + h * 0.5, tocolor(255, 255, 255, alpha), 0.95 * scale, "default-bold", "left", "center", false, false, false)
    dxDrawText(description, x + 15, y + h * 0.5, x + w - 80, y + h - 5, tocolor(100, 110, 120, alpha), 0.75 * scale, "default", "left", "center", false, false, false)

    -- Toggle switch
    local toggleW = 50 * scale
    local toggleH = 24 * scale
    local toggleX = x + w - toggleW - 15
    local toggleY = y + (h - toggleH) / 2

    local toggleBg = value and {46, 204, 113} or {60, 65, 75}
    dxDrawRectangle(toggleX, toggleY, toggleW, toggleH, tocolor(toggleBg[1], toggleBg[2], toggleBg[3], alpha), false)

    -- Toggle knob
    local knobSize = toggleH - 4
    local knobX = value and (toggleX + toggleW - knobSize - 2) or (toggleX + 2)
    dxDrawRectangle(knobX, toggleY + 2, knobSize, knobSize, tocolor(255, 255, 255, alpha), false)

    -- Handle click
    if isMouseOver(toggleX, toggleY, toggleW, toggleH) and getKeyState("mouse1") and not clickCooldown then
        clickCooldown = true
        setTimer(function() clickCooldown = false end, 200, 1)
        settings[settingKey] = not settings[settingKey]
        playSoundFrontEnd(37)
        -- Save setting
        triggerServerEvent("jebiga:userpanel:saveSetting", localPlayer, settingKey, settings[settingKey])
    end
end

-- ============================================
-- SCROLL HANDLING
-- ============================================

addEventHandler("onClientKey", root, function(key, state)
    if not isVisible then return end

    if key == "mouse_wheel_up" and state then
        scrollOffset = math.max(0, scrollOffset - 40)
    elseif key == "mouse_wheel_down" and state then
        scrollOffset = math.min(maxScroll, scrollOffset + 40)
    elseif key == "escape" and state then
        hideUserPanel()
        cancelEvent()
    end
end)

-- ============================================
-- DATA EVENTS
-- ============================================

addEvent("jebiga:userpanel:receiveData", true)
addEventHandler("jebiga:userpanel:receiveData", root, function(data)
    profileData = data or {}
end)

-- Initialize
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Load saved settings
    settings.soundEnabled = true
    settings.musicEnabled = true
    outputDebugString("[Jebiga UserPanel] User Panel initialized")
end)

-- ============================================
-- EXPORTS
-- ============================================

function isUserPanelVisible()
    return isVisible
end
