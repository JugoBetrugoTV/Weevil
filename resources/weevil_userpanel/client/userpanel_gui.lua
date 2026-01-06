--[[
    Weevil Multi-Gamemode - User Panel GUI
    Comprehensive player profile interface
]]

local screenW, screenH = guiGetScreenSize()
local isVisible = false
local profileData = {}
local currentTab = "overview"

local panelW = 750
local panelH = 550
local panelX = (screenW - panelW) / 2
local panelY = (screenH - panelH) / 2

local tabs = { "overview", "stats", "achievements", "settings" }

function showUserPanel()
    isVisible = true
    showCursor(true)
    triggerServerEvent(Events.UserPanel.REQUEST_OPEN, localPlayer)
end

function hideUserPanel()
    isVisible = false
    showCursor(false)
end

function renderUserPanel()
    if not isVisible then return end

    -- Background
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(0, 0, 0, 180))
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(25, 25, 25, 250))
    dxDrawRectangle(panelX, panelY, panelW, 4, tocolor(255, 102, 0, 255))

    -- Title
    dxDrawText("USER PANEL", panelX, panelY + 15, panelX + panelW, panelY + 45, tocolor(255, 255, 255, 255), 1.4, "default-bold", "center", "center")

    -- Close button
    local closeX, closeY = panelX + panelW - 35, panelY + 10
    dxDrawRectangle(closeX, closeY, 25, 25, tocolor(200, 50, 50, 255))
    dxDrawText("X", closeX, closeY, closeX + 25, closeY + 25, tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center")

    -- Tabs
    local tabW = (panelW - 40) / #tabs
    local tabY = panelY + 55

    for i, tab in ipairs(tabs) do
        local tabX = panelX + 20 + (i - 1) * tabW
        local isActive = currentTab == tab
        local bgColor = isActive and tocolor(255, 102, 0, 255) or tocolor(50, 50, 50, 255)

        dxDrawRectangle(tabX, tabY, tabW - 5, 35, bgColor)
        dxDrawText(tab:upper(), tabX, tabY, tabX + tabW - 5, tabY + 35, tocolor(255, 255, 255, 255), 0.95, "default-bold", "center", "center")
    end

    -- Content area
    local contentY = tabY + 50
    local contentH = panelH - 120

    if currentTab == "overview" then
        renderOverviewTab(contentY, contentH)
    elseif currentTab == "stats" then
        renderStatsTab(contentY, contentH)
    elseif currentTab == "achievements" then
        renderAchievementsTab(contentY, contentH)
    elseif currentTab == "settings" then
        renderSettingsTab(contentY, contentH)
    end
end

function renderOverviewTab(startY, height)
    if not profileData.username then return end

    -- Profile card
    dxDrawRectangle(panelX + 20, startY, 250, 150, tocolor(40, 40, 40, 255))

    -- Username
    dxDrawText(profileData.username, panelX + 30, startY + 10, panelX + 260, startY + 40, tocolor(255, 255, 255, 255), 1.2, "default-bold", "left", "center")

    -- Rank
    if profileData.rank then
        local rankColor = Utils.hexToRGB(profileData.rank.color)
        dxDrawText(profileData.rank.name, panelX + 30, startY + 40, panelX + 260, startY + 60, tocolor(rankColor.r, rankColor.g, rankColor.b, 255), 0.9, "default", "left", "center")
    end

    -- Stats summary
    dxDrawText("Points: " .. Utils.formatNumber(profileData.totalPoints or 0), panelX + 30, startY + 70, panelX + 260, startY + 90, tocolor(255, 255, 100, 255), 0.9, "default", "left", "center")
    dxDrawText("Money: $" .. Utils.formatNumber(profileData.money or 0), panelX + 30, startY + 90, panelX + 260, startY + 110, tocolor(100, 255, 100, 255), 0.9, "default", "left", "center")
    dxDrawText("Playtime: " .. Utils.formatTimeLong((profileData.playtime or 0) * 1000), panelX + 30, startY + 110, panelX + 260, startY + 130, tocolor(200, 200, 200, 255), 0.9, "default", "left", "center")

    -- Recent achievements
    dxDrawText("Recent Achievements", panelX + 290, startY + 10, panelX + panelW - 20, startY + 30, tocolor(255, 102, 0, 255), 1.0, "default-bold", "left", "center")

    local achievementY = startY + 40
    for i, ach in ipairs(profileData.achievements or {}) do
        if i <= 5 then
            dxDrawText("★ " .. ach.name, panelX + 290, achievementY, panelX + panelW - 20, achievementY + 20, tocolor(255, 215, 0, 255), 0.85, "default", "left", "center")
            achievementY = achievementY + 25
        end
    end
end

function renderStatsTab(startY, height)
    local col1X = panelX + 20
    local col2X = panelX + panelW / 2

    local y = startY
    local colWidth = (panelW - 60) / 2

    for gamemode, stats in pairs(profileData.stats or {}) do
        if y + 80 < startY + height then
            dxDrawRectangle(col1X, y, colWidth, 70, tocolor(40, 40, 40, 255))

            dxDrawText(stats.name, col1X + 10, y + 5, col1X + colWidth, y + 25, tocolor(255, 102, 0, 255), 0.95, "default-bold", "left", "center")
            dxDrawText("Pts: " .. Utils.formatNumber(stats.points), col1X + 10, y + 25, col1X + colWidth / 2, y + 45, tocolor(255, 255, 100, 255), 0.8, "default", "left", "center")
            dxDrawText("W/L: " .. stats.wins .. "/" .. stats.losses, col1X + colWidth / 2, y + 25, col1X + colWidth - 10, y + 45, tocolor(200, 200, 200, 255), 0.8, "default", "left", "center")
            dxDrawText("K/D: " .. stats.kills .. "/" .. stats.deaths, col1X + 10, y + 45, col1X + colWidth - 10, y + 65, tocolor(200, 200, 200, 255), 0.8, "default", "left", "center")

            col1X = col1X == panelX + 20 and col2X or panelX + 20
            if col1X == panelX + 20 then y = y + 80 end
        end
    end
end

function renderAchievementsTab(startY, height)
    dxDrawText("Your Achievements (" .. #(profileData.achievements or {}) .. ")", panelX + 20, startY, panelX + panelW - 20, startY + 25, tocolor(255, 255, 255, 255), 1.0, "default-bold", "left", "center")

    local y = startY + 35
    for i, ach in ipairs(profileData.achievements or {}) do
        if y + 50 < startY + height then
            dxDrawRectangle(panelX + 20, y, panelW - 40, 45, tocolor(40, 40, 40, 255))
            dxDrawText("★ " .. ach.name, panelX + 30, y + 5, panelX + panelW - 100, y + 25, tocolor(255, 215, 0, 255), 0.95, "default-bold", "left", "center")
            dxDrawText(ach.description, panelX + 30, y + 22, panelX + panelW - 100, y + 40, tocolor(180, 180, 180, 255), 0.8, "default", "left", "center")
            dxDrawText("+" .. ach.points .. " pts", panelX + panelW - 80, y + 5, panelX + panelW - 30, y + 45, tocolor(100, 255, 100, 255), 0.85, "default", "center", "center")
            y = y + 50
        end
    end
end

function renderSettingsTab(startY, height)
    dxDrawText("Settings", panelX + 20, startY, panelX + panelW - 20, startY + 25, tocolor(255, 255, 255, 255), 1.0, "default-bold", "left", "center")
    dxDrawText("Coming soon...", panelX + 20, startY + 40, panelX + panelW - 20, startY + 60, tocolor(150, 150, 150, 255), 0.9, "default", "left", "center")
end

addEventHandler("onClientRender", root, renderUserPanel)

-- Handle click
addEventHandler("onClientClick", root, function(button, state, mx, my)
    if button ~= "left" or state ~= "down" or not isVisible then return end

    -- Close button
    if mx >= panelX + panelW - 35 and mx <= panelX + panelW - 10 and my >= panelY + 10 and my <= panelY + 35 then
        hideUserPanel()
        return
    end

    -- Tab clicks
    local tabW = (panelW - 40) / #tabs
    local tabY = panelY + 55

    for i, tab in ipairs(tabs) do
        local tabX = panelX + 20 + (i - 1) * tabW
        if mx >= tabX and mx <= tabX + tabW - 5 and my >= tabY and my <= tabY + 35 then
            currentTab = tab
            return
        end
    end
end)

-- Handle key
addEventHandler("onClientKey", root, function(button, press)
    if button == "escape" and press and isVisible then
        hideUserPanel()
    end
end)

-- Handle data
addEvent(Events.UserPanel.OPEN, true)
addEventHandler(Events.UserPanel.OPEN, root, function(data)
    profileData = data or {}
end)
