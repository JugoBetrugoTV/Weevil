--[[
    Jebiga Multi-Gamemode - Map Manager Client
    Handles map voting GUI and notifications
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- Voting state
local votingOpen = false
local voteMaps = {}
local selectedMap = nil
local voteEndTime = 0
local panelAlpha = 0

-- ============================================
-- VOTING GUI
-- ============================================

function renderVoting()
    if not votingOpen then
        if panelAlpha > 0 then panelAlpha = panelAlpha - 15 end
        if panelAlpha <= 0 then return end
    else
        if panelAlpha < 255 then panelAlpha = panelAlpha + 15 end
    end

    local panelW = 500 * scale
    local panelH = 400 * scale
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Background
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(15, 17, 23, panelAlpha * 0.95))

    -- Header
    dxDrawRectangle(panelX, panelY, panelW, 60 * scale, tocolor(25, 28, 35, panelAlpha))
    dxDrawRectangle(panelX, panelY + 57 * scale, panelW, 3, tocolor(41, 128, 185, panelAlpha))

    -- Timer
    local remaining = math.max(0, math.ceil((voteEndTime - getTickCount()) / 1000))
    local timerColor = remaining <= 10 and tocolor(231, 76, 60, panelAlpha) or tocolor(46, 204, 113, panelAlpha)

    dxDrawText("MAP VOTE", panelX + 20, panelY, panelX + panelW - 80, panelY + 60 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.3 * scale, "default-bold", "left", "center")

    dxDrawText(remaining .. "s", panelX + panelW - 70, panelY, panelX + panelW - 20, panelY + 60 * scale,
        timerColor, 1.5 * scale, "default-bold", "right", "center")

    -- Map buttons
    local buttonH = 50 * scale
    local startY = panelY + 75 * scale
    local padding = 15 * scale

    for i, mapName in ipairs(voteMaps) do
        local y = startY + (i - 1) * (buttonH + 8)
        local isSelected = selectedMap == mapName

        local bgColor = isSelected and tocolor(41, 128, 185, panelAlpha * 0.8) or tocolor(30, 35, 45, panelAlpha * 0.7)
        dxDrawRectangle(panelX + padding, y, panelW - padding * 2, buttonH, bgColor)

        -- Number
        dxDrawText(tostring(i), panelX + padding + 10, y, panelX + padding + 40, y + buttonH,
            tocolor(100, 110, 120, panelAlpha), 1.2 * scale, "default-bold", "center", "center")

        -- Map name
        dxDrawText(mapName, panelX + padding + 50, y, panelX + panelW - padding - 10, y + buttonH,
            tocolor(255, 255, 255, panelAlpha), 1.0 * scale, "default-bold", "left", "center")

        -- Selection indicator
        if isSelected then
            dxDrawRectangle(panelX + padding, y, 4, buttonH, tocolor(46, 204, 113, panelAlpha))
            dxDrawText("VOTED", panelX + panelW - padding - 80, y, panelX + panelW - padding - 10, y + buttonH,
                tocolor(46, 204, 113, panelAlpha), 0.85 * scale, "default-bold", "right", "center")
        end
    end

    -- Instructions
    local instrY = panelY + panelH - 40 * scale
    dxDrawText("Click a map or press 1-" .. #voteMaps .. " to vote | ESC to close", panelX, instrY, panelX + panelW, instrY + 30 * scale,
        tocolor(120, 130, 140, panelAlpha * 0.8), 0.8 * scale, "default", "center", "center")
end

function handleVoteClick(button, state, absX, absY)
    if button ~= "left" or state ~= "down" or not votingOpen then return end

    local panelW = 500 * scale
    local panelH = 400 * scale
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2
    local buttonH = 50 * scale
    local startY = panelY + 75 * scale
    local padding = 15 * scale

    for i, mapName in ipairs(voteMaps) do
        local y = startY + (i - 1) * (buttonH + 8)

        if absX >= panelX + padding and absX <= panelX + panelW - padding and
           absY >= y and absY <= y + buttonH then
            selectMap(mapName)
            return
        end
    end
end

function handleVoteKey(button, press)
    if not press then return end

    if votingOpen then
        if button == "escape" then
            votingOpen = false
            showCursor(false)
            return
        end

        -- Number keys
        local num = tonumber(button)
        if num and num >= 1 and num <= #voteMaps then
            selectMap(voteMaps[num])
        end
    end

    -- F2 to toggle vote panel
    if button == "F2" and #voteMaps > 0 then
        votingOpen = not votingOpen
        showCursor(votingOpen)
    end
end

function selectMap(mapName)
    selectedMap = mapName
    triggerServerEvent("jebiga:map:vote", localPlayer, mapName)
    playSoundFrontEnd(40)
end

-- ============================================
-- EVENTS
-- ============================================

addEventHandler("onClientRender", root, renderVoting)
addEventHandler("onClientClick", root, handleVoteClick)
addEventHandler("onClientKey", root, handleVoteKey)

addEvent("jebiga:map:voteStart", true)
addEventHandler("jebiga:map:voteStart", root, function(maps, duration)
    voteMaps = maps
    selectedMap = nil
    voteEndTime = getTickCount() + duration * 1000
    votingOpen = true
    showCursor(true)
    playSoundFrontEnd(44)
end)

addEvent("jebiga:map:voteEnd", true)
addEventHandler("jebiga:map:voteEnd", root, function(winner, votes)
    votingOpen = false
    voteMaps = {}
    showCursor(false)

    if winner then
        exports.jebiga_core:showNotification(winner .. " won with " .. votes .. " votes!", "success")
    end
end)

addEvent("jebiga:map:loaded", true)
addEventHandler("jebiga:map:loaded", root, function(mapData)
    exports.jebiga_core:showNotification("Now playing: " .. (mapData.displayName or mapData.name), "info")
end)

addEvent("jebiga:map:list", true)
addEventHandler("jebiga:map:list", root, function(maps)
    outputChatBox("#2980B9[MAPS] #FFFFFFFound " .. #maps .. " maps:", 255, 255, 255, true)
    for i, map in ipairs(maps) do
        if i <= 20 then
            outputChatBox("#95A5A6  " .. map.name .. " #FFFFFF(" .. map.gamemode .. ")", 255, 255, 255, true)
        end
    end
    if #maps > 20 then
        outputChatBox("#95A5A6  ... and " .. (#maps - 20) .. " more", 255, 255, 255, true)
    end
end)

-- ============================================
-- COMMANDS
-- ============================================

addCommandHandler("vote", function()
    if #voteMaps > 0 then
        votingOpen = not votingOpen
        showCursor(votingOpen)
    else
        outputChatBox("#E74C3C[VOTE] #FFFFFFNo vote in progress!", 255, 255, 255, true)
    end
end)
