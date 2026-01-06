--[[
    Weevil Multi-Gamemode - TopTimes GUI
    Client-side top times display
]]

local screenW, screenH = guiGetScreenSize()
local isVisible = false
local toptimesData = {}
local currentMap = ""
local currentGamemode = ""

-- GUI dimensions
local panelW = 400
local panelH = 350
local panelX = 20
local panelY = screenH / 2 - panelH / 2

-- Render top times panel
function renderTopTimes()
    if not isVisible or not toptimesData.times then return end

    local alpha = 220

    -- Background
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(20, 20, 20, alpha))

    -- Top border
    dxDrawRectangle(panelX, panelY, panelW, 3, tocolor(255, 102, 0, 255))

    -- Title
    dxDrawText(
        "TOP TIMES",
        panelX, panelY + 10,
        panelX + panelW, panelY + 35,
        tocolor(255, 102, 0, 255),
        1.1, "default-bold", "center", "center"
    )

    -- Map name
    dxDrawText(
        toptimesData.map or "Unknown Map",
        panelX, panelY + 35,
        panelX + panelW, panelY + 55,
        tocolor(200, 200, 200, 255),
        0.9, "default", "center", "center"
    )

    -- Header
    local headerY = panelY + 60
    dxDrawRectangle(panelX + 10, headerY, panelW - 20, 25, tocolor(40, 40, 40, 200))

    dxDrawText("#", panelX + 15, headerY, panelX + 45, headerY + 25, tocolor(255, 102, 0, 255), 0.85, "default-bold", "center", "center")
    dxDrawText("Player", panelX + 50, headerY, panelX + 200, headerY + 25, tocolor(255, 102, 0, 255), 0.85, "default-bold", "left", "center")
    dxDrawText("Time", panelX + 280, headerY, panelX + panelW - 15, headerY + 25, tocolor(255, 102, 0, 255), 0.85, "default-bold", "right", "center")

    -- Times list
    local startY = headerY + 30
    local rowH = 24

    for i, tt in ipairs(toptimesData.times or {}) do
        if i <= 10 then
            local rowY = startY + (i - 1) * rowH
            local isLocal = tt.username == getPlayerName(localPlayer)

            -- Highlight local player
            if isLocal then
                dxDrawRectangle(panelX + 10, rowY, panelW - 20, rowH - 2, tocolor(255, 102, 0, 30))
            end

            -- Position with medal colors
            local posColor
            if i == 1 then
                posColor = tocolor(255, 215, 0, 255) -- Gold
            elseif i == 2 then
                posColor = tocolor(192, 192, 192, 255) -- Silver
            elseif i == 3 then
                posColor = tocolor(205, 127, 50, 255) -- Bronze
            else
                posColor = tocolor(150, 150, 150, 255)
            end

            dxDrawText(tostring(i), panelX + 15, rowY, panelX + 45, rowY + rowH, posColor, 0.9, "default-bold", "center", "center")

            -- Player name
            local nameColor = isLocal and tocolor(255, 200, 100, 255) or tocolor(255, 255, 255, 255)
            dxDrawText(tt.username, panelX + 50, rowY, panelX + 270, rowY + rowH, nameColor, 0.85, "default", "left", "center")

            -- Time
            local timeStr = Utils.formatTime(tt.time)
            dxDrawText(timeStr, panelX + 280, rowY, panelX + panelW - 15, rowY + rowH, tocolor(100, 255, 100, 255), 0.85, "default", "right", "center")
        end
    end

    -- Player's own time (if not in top 10)
    if toptimesData.playerTime and toptimesData.playerRank and toptimesData.playerRank > 10 then
        local bottomY = panelY + panelH - 50

        dxDrawRectangle(panelX + 10, bottomY, panelW - 20, 1, tocolor(100, 100, 100, 200))

        dxDrawText(
            "Your best: #" .. toptimesData.playerRank .. " - " .. Utils.formatTime(toptimesData.playerTime.time),
            panelX, bottomY + 10,
            panelX + panelW, bottomY + 35,
            tocolor(200, 200, 100, 255),
            0.9, "default", "center", "center"
        )
    elseif not toptimesData.playerTime then
        local bottomY = panelY + panelH - 35

        dxDrawText(
            "You haven't set a time yet",
            panelX, bottomY,
            panelX + panelW, bottomY + 25,
            tocolor(150, 150, 150, 255),
            0.85, "default", "center", "center"
        )
    end
end

addEventHandler("onClientRender", root, renderTopTimes)

-- Show top times
function showTopTimes(mapName, gamemode)
    currentMap = mapName
    currentGamemode = gamemode
    isVisible = true

    triggerServerEvent(Events.TopTimes.REQUEST_TOPTIMES, localPlayer, mapName, gamemode)
end

-- Hide top times
function hideTopTimes()
    isVisible = false
    toptimesData = {}
end

-- Handle data update
addEvent(Events.TopTimes.UPDATE_LIST, true)
addEventHandler(Events.TopTimes.UPDATE_LIST, root, function(data)
    toptimesData = data or {}
end)

-- Handle new top time notification
addEvent(Events.TopTimes.NEW_TOPTIME, true)
addEventHandler(Events.TopTimes.NEW_TOPTIME, root, function(data)
    local posText = Utils.getOrdinal(data.position)
    local timeText = Utils.formatTime(data.time)

    if data.isNew then
        exports.weevil_core:showNotification("achievement", "New record! " .. posText .. " place: " .. timeText, 5000)
    else
        exports.weevil_core:showNotification("success", "Improved to " .. posText .. " place: " .. timeText, 4000)
    end

    exports.weevil_core:playSound("finish")
end)

-- Toggle with key
bindKey("F6", "down", function()
    if isVisible then
        hideTopTimes()
    else
        local gamemode = exports.weevil_core:getCurrentGamemode()
        if gamemode then
            -- Would need current map name from arena manager
            showTopTimes("Current Map", gamemode)
        end
    end
end)

-- Export
function isTopTimesVisible()
    return isVisible
end
