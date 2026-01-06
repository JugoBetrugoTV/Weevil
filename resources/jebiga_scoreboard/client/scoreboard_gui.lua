--[[
    Jebiga Multi-Gamemode - Scoreboard GUI
    Client-side scoreboard display
]]

local screenW, screenH = guiGetScreenSize()
local isVisible = false
local scoreboardData = {}
local scrollOffset = 0
local maxVisibleRows = 15

-- GUI dimensions
local boardW = 800
local boardH = 500
local boardX = (screenW - boardW) / 2
local boardY = (screenH - boardH) / 2

local rowH = 28
local headerH = 40

-- Column definitions
local columns = {
    { name = "#", width = 40, align = "center" },
    { name = "Name", width = 200, align = "left" },
    { name = "Points", width = 100, align = "right" },
    { name = "K/D", width = 80, align = "center" },
    { name = "Money", width = 100, align = "right" },
    { name = "Gamemode", width = 100, align = "center" },
    { name = "Ping", width = 60, align = "center" }
}

-- Show/hide scoreboard
function toggleScoreboard(show)
    if show == nil then
        isVisible = not isVisible
    else
        isVisible = show
    end

    if isVisible then
        triggerServerEvent("weevil:requestScoreboard", localPlayer)
    end
end

-- Render scoreboard
function renderScoreboard()
    if not isVisible then return end

    -- Background
    dxDrawRectangle(boardX, boardY, boardW, boardH, tocolor(20, 20, 20, 240))

    -- Top border
    dxDrawRectangle(boardX, boardY, boardW, 4, tocolor(255, 102, 0, 255))

    -- Title
    dxDrawText(
        "SCOREBOARD",
        boardX, boardY + 10,
        boardX + boardW, boardY + 35,
        tocolor(255, 255, 255, 255),
        1.3, "default-bold", "center", "center"
    )

    -- Player count
    dxDrawText(
        #scoreboardData .. " players online",
        boardX + 15, boardY + 10,
        boardX + 200, boardY + 35,
        tocolor(150, 150, 150, 255),
        0.9, "default", "left", "center"
    )

    -- Server info
    dxDrawText(
        Config.ServerName,
        boardX + boardW - 200, boardY + 10,
        boardX + boardW - 15, boardY + 35,
        tocolor(150, 150, 150, 255),
        0.9, "default", "right", "center"
    )

    -- Header row
    local headerY = boardY + 45
    dxDrawRectangle(boardX, headerY, boardW, headerH, tocolor(40, 40, 40, 255))

    local colX = boardX + 10
    for _, col in ipairs(columns) do
        dxDrawText(
            col.name,
            colX, headerY,
            colX + col.width, headerY + headerH,
            tocolor(255, 102, 0, 255),
            0.95, "default-bold", col.align, "center"
        )
        colX = colX + col.width + 10
    end

    -- Player rows
    local startY = headerY + headerH + 5
    local visibleCount = 0

    for i, player in ipairs(scoreboardData) do
        if i > scrollOffset and visibleCount < maxVisibleRows then
            visibleCount = visibleCount + 1
            local rowY = startY + (visibleCount - 1) * rowH

            -- Alternate row colors
            local bgColor = i % 2 == 0 and tocolor(35, 35, 35, 200) or tocolor(30, 30, 30, 200)

            -- Highlight local player
            if player.name == getPlayerName(localPlayer) then
                bgColor = tocolor(255, 102, 0, 50)
            end

            dxDrawRectangle(boardX + 5, rowY, boardW - 10, rowH - 2, bgColor)

            -- Draw columns
            colX = boardX + 10

            -- Rank
            dxDrawText(
                tostring(i),
                colX, rowY,
                colX + columns[1].width, rowY + rowH,
                tocolor(150, 150, 150, 255),
                0.9, "default", "center", "center"
            )
            colX = colX + columns[1].width + 10

            -- Name with admin/VIP colors
            local nameColor = tocolor(255, 255, 255, 255)
            local prefix = ""

            if player.adminLevel > 0 then
                local adminCfg = Config.AdminLevels[player.adminLevel]
                if adminCfg then
                    local rgb = Utils.hexToRGB(adminCfg.color)
                    nameColor = tocolor(rgb.r, rgb.g, rgb.b, 255)
                    prefix = "[" .. adminCfg.name:sub(1, 1) .. "] "
                end
            elseif player.vipLevel > 0 then
                nameColor = tocolor(255, 215, 0, 255)
                prefix = "[VIP] "
            end

            dxDrawText(
                prefix .. player.name,
                colX, rowY,
                colX + columns[2].width, rowY + rowH,
                nameColor,
                0.9, "default", "left", "center"
            )
            colX = colX + columns[2].width + 10

            -- Points
            local rank = Utils.calculateRank(player.points)
            local rankColor = Utils.hexToRGB(rank.color)
            dxDrawText(
                Utils.formatNumber(player.points),
                colX, rowY,
                colX + columns[3].width, rowY + rowH,
                tocolor(rankColor.r, rankColor.g, rankColor.b, 255),
                0.9, "default", "right", "center"
            )
            colX = colX + columns[3].width + 10

            -- K/D
            local kd = player.kills .. "/" .. player.deaths
            dxDrawText(
                kd,
                colX, rowY,
                colX + columns[4].width, rowY + rowH,
                tocolor(200, 200, 200, 255),
                0.9, "default", "center", "center"
            )
            colX = colX + columns[4].width + 10

            -- Money
            dxDrawText(
                "$" .. Utils.formatNumber(player.money),
                colX, rowY,
                colX + columns[5].width, rowY + rowH,
                tocolor(100, 255, 100, 255),
                0.9, "default", "right", "center"
            )
            colX = colX + columns[5].width + 10

            -- Gamemode
            local gmText = player.inLobby and "Lobby" or (player.gamemode and Config.Gamemodes[player.gamemode] and Config.Gamemodes[player.gamemode].shortName or "---")
            local gmColor = player.inLobby and tocolor(150, 150, 150, 255) or tocolor(100, 200, 255, 255)
            dxDrawText(
                gmText,
                colX, rowY,
                colX + columns[6].width, rowY + rowH,
                gmColor,
                0.9, "default", "center", "center"
            )
            colX = colX + columns[6].width + 10

            -- Ping
            local pingColor
            if player.ping < 50 then
                pingColor = tocolor(100, 255, 100, 255)
            elseif player.ping < 100 then
                pingColor = tocolor(255, 255, 100, 255)
            elseif player.ping < 200 then
                pingColor = tocolor(255, 150, 50, 255)
            else
                pingColor = tocolor(255, 50, 50, 255)
            end

            dxDrawText(
                tostring(player.ping),
                colX, rowY,
                colX + columns[7].width, rowY + rowH,
                pingColor,
                0.9, "default", "center", "center"
            )
        end
    end

    -- Scroll indicator
    if #scoreboardData > maxVisibleRows then
        local scrollBarH = (maxVisibleRows / #scoreboardData) * (boardH - headerH - 60)
        local scrollBarY = startY + (scrollOffset / (#scoreboardData - maxVisibleRows)) * ((boardH - headerH - 80) - scrollBarH)

        dxDrawRectangle(boardX + boardW - 12, startY, 6, boardH - headerH - 80, tocolor(40, 40, 40, 200))
        dxDrawRectangle(boardX + boardW - 12, scrollBarY, 6, scrollBarH, tocolor(255, 102, 0, 200))
    end

    -- Footer
    dxDrawText(
        "Press TAB to close | Scroll with mouse wheel",
        boardX, boardY + boardH - 25,
        boardX + boardW, boardY + boardH,
        tocolor(100, 100, 100, 255),
        0.8, "default", "center", "center"
    )
end

addEventHandler("onClientRender", root, renderScoreboard)

-- Handle scoreboard data update
addEvent(Events.Scoreboard.UPDATE, true)
addEventHandler(Events.Scoreboard.UPDATE, root, function(data)
    scoreboardData = data or {}
    scrollOffset = 0
end)

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
        scrollOffset = math.max(0, scrollOffset - 1)
    elseif button == "mouse_wheel_down" and press then
        scrollOffset = math.min(math.max(0, #scoreboardData - maxVisibleRows), scrollOffset + 1)
    end
end)

-- Initialize
addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[Jebiga Scoreboard] Scoreboard initialized")
end)
