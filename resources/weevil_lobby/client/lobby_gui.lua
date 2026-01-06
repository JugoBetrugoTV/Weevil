--[[
    Weevil Multi-Gamemode - Lobby GUI
    Gamemode selection interface
]]

local screenW, screenH = guiGetScreenSize()
local isGUIVisible = false
local gamemodeStatus = {}
local selectedGamemode = nil

-- GUI dimensions
local panelW = 900
local panelH = 600
local panelX = (screenW - panelW) / 2
local panelY = (screenH - panelH) / 2

-- Animation
local fadeAlpha = 0
local targetAlpha = 0
local animationSpeed = 0.15

-- Gamemode grid layout
local gridCols = 4
local gridRows = 3
local cardW = 200
local cardH = 150
local cardPadding = 15

-- Gamemode order for display
local gamemodeOrder = {
    "dm", "race", "dd", "hunter",
    "shooter", "stuntage", "trials", "carball",
    "hotpursuit", "runarena", "training"
}

-- Gamemode icons (emoji placeholders)
local gamemodeIcons = {
    dm = "💀",
    race = "🏎️",
    dd = "💥",
    hunter = "🚁",
    shooter = "🔫",
    stuntage = "🎯",
    trials = "🏍️",
    carball = "⚽",
    hotpursuit = "🚔",
    runarena = "🏃",
    training = "📚"
}

-- Show lobby GUI
function showLobbyGUI()
    if isGUIVisible then
        hideLobbyGUI()
        return
    end

    isGUIVisible = true
    targetAlpha = 255
    showCursor(true)
    selectedGamemode = nil
end

-- Hide lobby GUI
function hideLobbyGUI()
    targetAlpha = 0
    showCursor(false)
end

-- Event to open GUI
addEvent("weevil:openLobbyGUI", false)
addEventHandler("weevil:openLobbyGUI", localPlayer, showLobbyGUI)

-- Render the GUI
function renderLobbyGUI()
    -- Animate alpha
    fadeAlpha = fadeAlpha + (targetAlpha - fadeAlpha) * animationSpeed

    if fadeAlpha < 1 and targetAlpha == 0 then
        isGUIVisible = false
        return
    end

    if not isGUIVisible then return end

    local alpha = math.floor(fadeAlpha)

    -- Background overlay
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(0, 0, 0, math.floor(alpha * 0.8)))

    -- Main panel
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(25, 25, 25, alpha))

    -- Top border
    dxDrawRectangle(panelX, panelY, panelW, 4, tocolor(255, 102, 0, alpha))

    -- Title
    dxDrawText(
        "SELECT GAMEMODE",
        panelX, panelY + 15,
        panelX + panelW, panelY + 50,
        tocolor(255, 255, 255, alpha),
        1.5, "default-bold", "center", "center"
    )

    -- Close button
    local closeX = panelX + panelW - 40
    local closeY = panelY + 10
    local closeSize = 30

    dxDrawRectangle(closeX, closeY, closeSize, closeSize, tocolor(200, 50, 50, alpha))
    dxDrawText("X", closeX, closeY, closeX + closeSize, closeY + closeSize, tocolor(255, 255, 255, alpha), 1.2, "default-bold", "center", "center")

    -- Gamemode cards
    local startX = panelX + (panelW - (gridCols * (cardW + cardPadding) - cardPadding)) / 2
    local startY = panelY + 70

    local mx, my = getCursorPosition()
    if mx and my then
        mx, my = mx * screenW, my * screenH
    end

    for i, gamemode in ipairs(gamemodeOrder) do
        local info = gamemodeStatus[gamemode]
        if info and info.enabled then
            local col = ((i - 1) % gridCols)
            local row = math.floor((i - 1) / gridCols)

            local cardX = startX + col * (cardW + cardPadding)
            local cardY = startY + row * (cardH + cardPadding)

            -- Check hover
            local isHovered = mx and my and mx >= cardX and mx <= cardX + cardW and my >= cardY and my <= cardY + cardH
            local isSelected = selectedGamemode == gamemode

            -- Card background
            local bgColor
            if isSelected then
                bgColor = tocolor(255, 102, 0, alpha)
            elseif isHovered then
                bgColor = tocolor(60, 60, 60, alpha)
            else
                bgColor = tocolor(40, 40, 40, alpha)
            end

            dxDrawRectangle(cardX, cardY, cardW, cardH, bgColor)

            -- Color indicator
            local gmColor = Utils.hexToRGB(info.color or "#FFFFFF")
            dxDrawRectangle(cardX, cardY, 5, cardH, tocolor(gmColor.r, gmColor.g, gmColor.b, alpha))

            -- Icon
            dxDrawText(
                gamemodeIcons[gamemode] or "?",
                cardX, cardY + 10,
                cardX + cardW, cardY + 50,
                tocolor(255, 255, 255, alpha),
                2.0, "default", "center", "center"
            )

            -- Name
            dxDrawText(
                info.shortName or gamemode:upper(),
                cardX, cardY + 55,
                cardX + cardW, cardY + 80,
                tocolor(255, 255, 255, alpha),
                1.1, "default-bold", "center", "center"
            )

            -- Player count
            local playerText = info.playerCount .. "/" .. info.maxPlayers
            local playerColor = info.playerCount >= info.minPlayers and tocolor(100, 255, 100, alpha) or tocolor(255, 200, 100, alpha)
            dxDrawText(
                playerText .. " players",
                cardX, cardY + 85,
                cardX + cardW, cardY + 105,
                playerColor,
                0.85, "default", "center", "center"
            )

            -- State indicator
            local stateText = info.state:upper()
            local stateColor
            if info.state == "playing" then
                stateColor = tocolor(100, 255, 100, alpha)
            elseif info.state == "countdown" then
                stateColor = tocolor(255, 255, 100, alpha)
            elseif info.state == "voting" then
                stateColor = tocolor(100, 200, 255, alpha)
            else
                stateColor = tocolor(150, 150, 150, alpha)
            end

            dxDrawText(
                stateText,
                cardX, cardY + cardH - 30,
                cardX + cardW, cardY + cardH - 10,
                stateColor,
                0.8, "default", "center", "center"
            )
        end
    end

    -- Selected gamemode info panel
    if selectedGamemode and gamemodeStatus[selectedGamemode] then
        local info = gamemodeStatus[selectedGamemode]

        local infoX = panelX + 20
        local infoY = panelY + panelH - 120
        local infoW = panelW - 200
        local infoH = 100

        dxDrawRectangle(infoX, infoY, infoW, infoH, tocolor(35, 35, 35, alpha))

        -- Name and description
        dxDrawText(
            info.name,
            infoX + 15, infoY + 10,
            infoX + infoW, infoY + 35,
            tocolor(255, 102, 0, alpha),
            1.2, "default-bold", "left", "center"
        )

        dxDrawText(
            info.description or "No description available",
            infoX + 15, infoY + 40,
            infoX + infoW - 15, infoY + 70,
            tocolor(200, 200, 200, alpha),
            0.9, "default", "left", "center"
        )

        -- Current map
        if info.currentMap then
            dxDrawText(
                "Current map: " .. info.currentMap,
                infoX + 15, infoY + 70,
                infoX + infoW, infoY + 90,
                tocolor(150, 150, 150, alpha),
                0.85, "default", "left", "center"
            )
        end

        -- Join button
        local btnX = panelX + panelW - 160
        local btnY = infoY + 25
        local btnW = 130
        local btnH = 50

        local btnHover = mx and my and mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH
        local btnColor = btnHover and tocolor(255, 130, 50, alpha) or tocolor(255, 102, 0, alpha)

        dxDrawRectangle(btnX, btnY, btnW, btnH, btnColor)
        dxDrawText(
            "JOIN",
            btnX, btnY,
            btnX + btnW, btnY + btnH,
            tocolor(255, 255, 255, alpha),
            1.3, "default-bold", "center", "center"
        )
    end

    -- Footer
    dxDrawText(
        "Press F2 or click to select a gamemode | ESC to close",
        panelX, panelY + panelH - 25,
        panelX + panelW, panelY + panelH,
        tocolor(120, 120, 120, alpha),
        0.8, "default", "center", "center"
    )
end

addEventHandler("onClientRender", root, renderLobbyGUI)

-- Handle mouse clicks
function handleLobbyClick(button, state, mx, my)
    if button ~= "left" or state ~= "down" then return end
    if not isGUIVisible then return end

    -- Close button
    local closeX = panelX + panelW - 40
    local closeY = panelY + 10
    local closeSize = 30

    if mx >= closeX and mx <= closeX + closeSize and my >= closeY and my <= closeY + closeSize then
        hideLobbyGUI()
        return
    end

    -- Gamemode cards
    local startX = panelX + (panelW - (gridCols * (cardW + cardPadding) - cardPadding)) / 2
    local startY = panelY + 70

    for i, gamemode in ipairs(gamemodeOrder) do
        local info = gamemodeStatus[gamemode]
        if info and info.enabled then
            local col = ((i - 1) % gridCols)
            local row = math.floor((i - 1) / gridCols)

            local cardX = startX + col * (cardW + cardPadding)
            local cardY = startY + row * (cardH + cardPadding)

            if mx >= cardX and mx <= cardX + cardW and my >= cardY and my <= cardY + cardH then
                if selectedGamemode == gamemode then
                    -- Double click to join
                    joinSelectedGamemode()
                else
                    selectedGamemode = gamemode
                    exports.weevil_core:playSound("click")
                end
                return
            end
        end
    end

    -- Join button
    if selectedGamemode then
        local btnX = panelX + panelW - 160
        local btnY = panelY + panelH - 120 + 25
        local btnW = 130
        local btnH = 50

        if mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH then
            joinSelectedGamemode()
            return
        end
    end
end

addEventHandler("onClientClick", root, handleLobbyClick)

-- Join selected gamemode
function joinSelectedGamemode()
    if not selectedGamemode then return end

    triggerServerEvent(Events.Lobby.REQUEST_JOIN_GAMEMODE, localPlayer, selectedGamemode)
    hideLobbyGUI()
end

-- Handle key press
function handleLobbyKey(button, press)
    if not press then return end

    if button == "escape" and isGUIVisible then
        hideLobbyGUI()
    elseif button == "enter" and isGUIVisible and selectedGamemode then
        joinSelectedGamemode()
    end
end

addEventHandler("onClientKey", root, handleLobbyKey)

-- Handle status update from server
addEvent(Events.Lobby.UPDATE_GAMEMODE_STATUS, true)
addEventHandler(Events.Lobby.UPDATE_GAMEMODE_STATUS, root, function(status)
    gamemodeStatus = status or {}
end)

-- Initialize
addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[Weevil Lobby] Lobby GUI initialized")
end)

-- Export
function isLobbyGUIVisible()
    return isGUIVisible
end
