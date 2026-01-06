--[[
    Weevil Multi-Gamemode - Admin Panel GUI
]]

local screenW, screenH = guiGetScreenSize()
local isVisible = false
local adminData = {}
local currentTab = "players"
local selectedPlayer = nil

local panelW = 850
local panelH = 600
local panelX = (screenW - panelW) / 2
local panelY = (screenH - panelH) / 2

local tabs = { "players", "server", "logs" }

function showAdminPanel()
    isVisible = true
    showCursor(true)
end

function hideAdminPanel()
    isVisible = false
    showCursor(false)
end

function renderAdminPanel()
    if not isVisible then return end

    -- Background
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(0, 0, 0, 180))
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(25, 25, 25, 250))
    dxDrawRectangle(panelX, panelY, panelW, 4, tocolor(255, 0, 0, 255))

    -- Title
    dxDrawText("ADMIN PANEL", panelX, panelY + 15, panelX + panelW, panelY + 45, tocolor(255, 50, 50, 255), 1.4, "default-bold", "center", "center")

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
        local bgColor = isActive and tocolor(255, 50, 50, 255) or tocolor(50, 50, 50, 255)

        dxDrawRectangle(tabX, tabY, tabW - 5, 35, bgColor)
        dxDrawText(tab:upper(), tabX, tabY, tabX + tabW - 5, tabY + 35, tocolor(255, 255, 255, 255), 0.95, "default-bold", "center", "center")
    end

    -- Content
    local contentY = tabY + 50

    if currentTab == "players" then
        renderPlayersTab(contentY)
    elseif currentTab == "server" then
        renderServerTab(contentY)
    elseif currentTab == "logs" then
        renderLogsTab(contentY)
    end
end

function renderPlayersTab(startY)
    local players = adminData.players or {}

    -- Header
    dxDrawRectangle(panelX + 20, startY, panelW - 40, 25, tocolor(40, 40, 40, 255))
    dxDrawText("Name", panelX + 30, startY, panelX + 200, startY + 25, tocolor(255, 100, 100, 255), 0.85, "default-bold", "left", "center")
    dxDrawText("Points", panelX + 200, startY, panelX + 280, startY + 25, tocolor(255, 100, 100, 255), 0.85, "default-bold", "left", "center")
    dxDrawText("Money", panelX + 280, startY, panelX + 380, startY + 25, tocolor(255, 100, 100, 255), 0.85, "default-bold", "left", "center")
    dxDrawText("Gamemode", panelX + 380, startY, panelX + 480, startY + 25, tocolor(255, 100, 100, 255), 0.85, "default-bold", "left", "center")
    dxDrawText("Ping", panelX + 480, startY, panelX + 530, startY + 25, tocolor(255, 100, 100, 255), 0.85, "default-bold", "center", "center")
    dxDrawText("Actions", panelX + 550, startY, panelX + panelW - 30, startY + 25, tocolor(255, 100, 100, 255), 0.85, "default-bold", "center", "center")

    local y = startY + 30
    for i, p in ipairs(players) do
        if y + 28 < panelY + panelH - 50 then
            local bgColor = i % 2 == 0 and tocolor(35, 35, 35, 255) or tocolor(30, 30, 30, 255)
            dxDrawRectangle(panelX + 20, y, panelW - 40, 26, bgColor)

            dxDrawText(p.name, panelX + 30, y, panelX + 200, y + 26, tocolor(255, 255, 255, 255), 0.8, "default", "left", "center")
            dxDrawText(Utils.formatNumber(p.points), panelX + 200, y, panelX + 280, y + 26, tocolor(255, 255, 100, 255), 0.8, "default", "left", "center")
            dxDrawText("$" .. Utils.formatNumber(p.money), panelX + 280, y, panelX + 380, y + 26, tocolor(100, 255, 100, 255), 0.8, "default", "left", "center")
            dxDrawText(p.gamemode or "Lobby", panelX + 380, y, panelX + 480, y + 26, tocolor(200, 200, 200, 255), 0.8, "default", "left", "center")
            dxDrawText(tostring(p.ping), panelX + 480, y, panelX + 530, y + 26, tocolor(200, 200, 200, 255), 0.8, "default", "center", "center")

            -- Action buttons
            dxDrawRectangle(panelX + 560, y + 3, 50, 20, tocolor(255, 150, 50, 255))
            dxDrawText("Kick", panelX + 560, y + 3, panelX + 610, y + 23, tocolor(255, 255, 255, 255), 0.7, "default", "center", "center")

            dxDrawRectangle(panelX + 620, y + 3, 50, 20, tocolor(255, 50, 50, 255))
            dxDrawText("Ban", panelX + 620, y + 3, panelX + 670, y + 23, tocolor(255, 255, 255, 255), 0.7, "default", "center", "center")

            y = y + 28
        end
    end
end

function renderServerTab(startY)
    local stats = adminData.serverStats or {}

    dxDrawText("Server Statistics", panelX + 20, startY, panelX + panelW - 20, startY + 30, tocolor(255, 100, 100, 255), 1.1, "default-bold", "left", "center")

    local y = startY + 40
    dxDrawText("Online Players: " .. (stats.totalPlayers or 0), panelX + 30, y, panelX + panelW - 30, y + 25, tocolor(255, 255, 255, 255), 0.95, "default", "left", "center")
    y = y + 30
    dxDrawText("Registered Accounts: " .. (stats.registeredAccounts or 0), panelX + 30, y, panelX + panelW - 30, y + 25, tocolor(255, 255, 255, 255), 0.95, "default", "left", "center")
    y = y + 30
    dxDrawText("Uptime: " .. Utils.formatTimeLong(stats.uptime or 0), panelX + 30, y, panelX + panelW - 30, y + 25, tocolor(255, 255, 255, 255), 0.95, "default", "left", "center")
end

function renderLogsTab(startY)
    local logs = adminData.recentLogs or {}

    dxDrawText("Recent Admin Actions", panelX + 20, startY, panelX + panelW - 20, startY + 30, tocolor(255, 100, 100, 255), 1.1, "default-bold", "left", "center")

    local y = startY + 40
    for i, log in ipairs(logs) do
        if y + 25 < panelY + panelH - 50 then
            local text = (log.admin_name or "Unknown") .. " - " .. log.action .. ": " .. (log.details or "")
            dxDrawText(text, panelX + 30, y, panelX + panelW - 30, y + 20, tocolor(200, 200, 200, 255), 0.8, "default", "left", "center")
            y = y + 25
        end
    end
end

addEventHandler("onClientRender", root, renderAdminPanel)

-- Handle click
addEventHandler("onClientClick", root, function(button, state, mx, my)
    if button ~= "left" or state ~= "down" or not isVisible then return end

    -- Close
    if mx >= panelX + panelW - 35 and mx <= panelX + panelW - 10 and my >= panelY + 10 and my <= panelY + 35 then
        hideAdminPanel()
        return
    end

    -- Tabs
    local tabW = (panelW - 40) / #tabs
    local tabY = panelY + 55

    for i, tab in ipairs(tabs) do
        local tabX = panelX + 20 + (i - 1) * tabW
        if mx >= tabX and mx <= tabX + tabW - 5 and my >= tabY and my <= tabY + 35 then
            currentTab = tab
            return
        end
    end

    -- Player actions
    if currentTab == "players" then
        local startY = tabY + 80
        for i, p in ipairs(adminData.players or {}) do
            local y = startY + (i - 1) * 28
            if y + 28 < panelY + panelH - 50 then
                -- Kick button
                if mx >= panelX + 560 and mx <= panelX + 610 and my >= y + 3 and my <= y + 23 then
                    triggerServerEvent(Events.Admin.KICK_PLAYER, localPlayer, p.name, "Kicked by admin")
                    return
                end
                -- Ban button
                if mx >= panelX + 620 and mx <= panelX + 670 and my >= y + 3 and my <= y + 23 then
                    triggerServerEvent(Events.Admin.BAN_PLAYER, localPlayer, p.name, nil, "Banned by admin")
                    return
                end
            end
        end
    end
end)

-- Handle key
addEventHandler("onClientKey", root, function(button, press)
    if button == "escape" and press and isVisible then
        hideAdminPanel()
    end
end)

-- Handle data
addEvent(Events.Admin.PANEL_OPEN, true)
addEventHandler(Events.Admin.PANEL_OPEN, root, function(data)
    adminData = data or {}
    showAdminPanel()
end)
