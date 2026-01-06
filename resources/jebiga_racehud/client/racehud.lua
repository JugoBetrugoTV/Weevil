--[[
    Jebiga Multi-Gamemode - Race HUD
    Shows checkpoints, lap times, position, and race info
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- Race state
local raceActive = false
local raceData = {
    position = 0,
    totalPlayers = 0,
    checkpoint = 0,
    totalCheckpoints = 0,
    lap = 1,
    totalLaps = 1,
    startTime = 0,
    bestLap = 0,
    lastLap = 0,
    mapName = "",
    gamemode = ""
}

-- Checkpoint flash
local checkpointFlash = 0
local positionChangeTime = 0
local oldPosition = 0

-- ============================================
-- RACE HUD RENDERING
-- ============================================

function renderRaceHUD()
    if not raceActive then return end

    -- Position panel (top left)
    renderPositionPanel()

    -- Checkpoint info (top center)
    renderCheckpointInfo()

    -- Time panel (top right)
    renderTimePanel()

    -- Lap info (if multi-lap)
    if raceData.totalLaps > 1 then
        renderLapInfo()
    end

    -- Checkpoint flash effect
    renderCheckpointFlash()
end

function renderPositionPanel()
    local x = 20 * scale
    local y = 200 * scale
    local w = 120 * scale
    local h = 80 * scale

    -- Background
    dxDrawRectangle(x, y, w, h, tocolor(20, 22, 30, 220))

    -- Position number
    local posColor = getPositionColor(raceData.position)
    dxDrawText(tostring(raceData.position), x, y + 5, x + w, y + 55,
        tocolor(posColor[1], posColor[2], posColor[3], 255), 3.5 * scale, "pricedown", "center", "center")

    -- Ordinal suffix
    local suffix = getOrdinalSuffix(raceData.position)
    dxDrawText(suffix, x + w - 35 * scale, y + 15, x + w - 5, y + 35,
        tocolor(posColor[1], posColor[2], posColor[3], 200), 1.0 * scale, "default-bold", "left", "top")

    -- Total players
    dxDrawText("/ " .. raceData.totalPlayers, x, y + 55, x + w, y + h - 5,
        tocolor(150, 150, 150, 200), 1.0 * scale, "default-bold", "center", "center")

    -- Position change indicator
    if getTickCount() - positionChangeTime < 2000 then
        local diff = oldPosition - raceData.position
        if diff > 0 then
            dxDrawText("+" .. diff, x + w + 5, y + 20, x + w + 50, y + 50,
                tocolor(46, 204, 113, 255), 1.5 * scale, "default-bold", "left", "center")
        elseif diff < 0 then
            dxDrawText(tostring(diff), x + w + 5, y + 20, x + w + 50, y + 50,
                tocolor(231, 76, 60, 255), 1.5 * scale, "default-bold", "left", "center")
        end
    end
end

function renderCheckpointInfo()
    local w = 200 * scale
    local h = 50 * scale
    local x = (screenW - w) / 2
    local y = 20 * scale

    -- Background
    dxDrawRectangle(x, y, w, h, tocolor(20, 22, 30, 200))
    dxDrawRectangle(x, y + h - 3, w, 3, tocolor(41, 128, 185, 255))

    -- Checkpoint text
    local cpText = raceData.checkpoint .. " / " .. raceData.totalCheckpoints
    dxDrawText("CP", x + 10, y, x + 50, y + h,
        tocolor(100, 110, 120, 200), 0.9 * scale, "default-bold", "left", "center")
    dxDrawText(cpText, x + 50, y, x + w - 10, y + h,
        tocolor(255, 255, 255, 255), 1.3 * scale, "default-bold", "center", "center")

    -- Progress bar
    local progress = raceData.totalCheckpoints > 0 and (raceData.checkpoint / raceData.totalCheckpoints) or 0
    dxDrawRectangle(x, y + h - 3, w * progress, 3, tocolor(46, 204, 113, 255))
end

function renderTimePanel()
    local w = 180 * scale
    local h = 100 * scale
    local x = screenW - w - 20 * scale
    local y = 200 * scale

    -- Background
    dxDrawRectangle(x, y, w, h, tocolor(20, 22, 30, 220))

    -- Current time
    local currentTime = getTickCount() - raceData.startTime
    local timeStr = formatTime(currentTime)

    dxDrawText("TIME", x, y + 5, x + w, y + 25,
        tocolor(100, 110, 120, 200), 0.8 * scale, "default-bold", "center", "center")
    dxDrawText(timeStr, x, y + 25, x + w, y + 55,
        tocolor(255, 255, 255, 255), 1.5 * scale, "default-bold", "center", "center")

    -- Best lap (if available)
    if raceData.bestLap > 0 then
        local bestStr = formatTime(raceData.bestLap)
        dxDrawText("BEST", x, y + 55, x + w/2, y + 75,
            tocolor(100, 110, 120, 200), 0.7 * scale, "default-bold", "center", "center")
        dxDrawText(bestStr, x, y + 70, x + w/2, y + 95,
            tocolor(46, 204, 113, 200), 0.9 * scale, "default-bold", "center", "center")
    end

    -- Last lap (if available)
    if raceData.lastLap > 0 then
        local lastStr = formatTime(raceData.lastLap)
        dxDrawText("LAST", x + w/2, y + 55, x + w, y + 75,
            tocolor(100, 110, 120, 200), 0.7 * scale, "default-bold", "center", "center")
        dxDrawText(lastStr, x + w/2, y + 70, x + w, y + 95,
            tocolor(241, 196, 15, 200), 0.9 * scale, "default-bold", "center", "center")
    end
end

function renderLapInfo()
    local w = 100 * scale
    local h = 40 * scale
    local x = 20 * scale
    local y = 290 * scale

    -- Background
    dxDrawRectangle(x, y, w, h, tocolor(20, 22, 30, 200))

    -- Lap text
    local lapText = "LAP " .. raceData.lap .. "/" .. raceData.totalLaps
    dxDrawText(lapText, x, y, x + w, y + h,
        tocolor(255, 255, 255, 255), 1.0 * scale, "default-bold", "center", "center")
end

function renderCheckpointFlash()
    if checkpointFlash <= 0 then return end

    local alpha = checkpointFlash * 2.55
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(46, 204, 113, alpha * 0.3))

    checkpointFlash = checkpointFlash - 3
end

-- ============================================
-- COUNTDOWN
-- ============================================

local countdown = 0
local countdownStart = 0

function renderCountdown()
    if countdown <= 0 then return end

    local elapsed = getTickCount() - countdownStart
    local current = countdown - math.floor(elapsed / 1000)

    if current <= 0 then
        countdown = 0
        -- Show GO!
        showCenterText("GO!", {46, 204, 113}, 1000)
        return
    end

    -- Draw countdown number
    local pulse = 1 + math.sin(elapsed / 100) * 0.1
    local textScale = 5 * scale * pulse

    local color = current <= 1 and {231, 76, 60} or (current <= 2 and {241, 196, 15} or {255, 255, 255})

    dxDrawText(tostring(current), screenW/2 + 3, screenH/3 + 3, screenW/2 + 3, screenH/3 + 3,
        tocolor(0, 0, 0, 150), textScale, "pricedown", "center", "center")
    dxDrawText(tostring(current), screenW/2, screenH/3, screenW/2, screenH/3,
        tocolor(color[1], color[2], color[3], 255), textScale, "pricedown", "center", "center")
end

-- Center text
local centerText = nil
local centerTextEnd = 0

function showCenterText(text, color, duration)
    centerText = {text = text, color = color}
    centerTextEnd = getTickCount() + duration
end

function renderCenterText()
    if not centerText then return end
    if getTickCount() > centerTextEnd then
        centerText = nil
        return
    end

    local alpha = 255
    local remaining = centerTextEnd - getTickCount()
    if remaining < 300 then
        alpha = 255 * (remaining / 300)
    end

    dxDrawText(centerText.text, screenW/2 + 2, screenH/3 + 2, screenW/2 + 2, screenH/3 + 2,
        tocolor(0, 0, 0, alpha * 0.5), 4 * scale, "pricedown", "center", "center")
    dxDrawText(centerText.text, screenW/2, screenH/3, screenW/2, screenH/3,
        tocolor(centerText.color[1], centerText.color[2], centerText.color[3], alpha), 4 * scale, "pricedown", "center", "center")
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function formatTime(ms)
    local totalSeconds = math.floor(ms / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    local milliseconds = math.floor((ms % 1000) / 10)

    return string.format("%02d:%02d.%02d", minutes, seconds, milliseconds)
end

function getPositionColor(pos)
    if pos == 1 then return {255, 215, 0} end -- Gold
    if pos == 2 then return {192, 192, 192} end -- Silver
    if pos == 3 then return {205, 127, 50} end -- Bronze
    return {255, 255, 255}
end

function getOrdinalSuffix(n)
    if n == 1 then return "st"
    elseif n == 2 then return "nd"
    elseif n == 3 then return "rd"
    else return "th"
    end
end

-- ============================================
-- EVENTS
-- ============================================

addEventHandler("onClientRender", root, function()
    renderRaceHUD()
    renderCountdown()
    renderCenterText()
end)

addEvent("jebiga:race:start", true)
addEventHandler("jebiga:race:start", root, function(data)
    raceActive = true
    raceData = data
    raceData.startTime = getTickCount()
    oldPosition = data.position or 0
end)

addEvent("jebiga:race:stop", true)
addEventHandler("jebiga:race:stop", root, function()
    raceActive = false
end)

addEvent("jebiga:race:update", true)
addEventHandler("jebiga:race:update", root, function(data)
    -- Check for position change
    if data.position and data.position ~= raceData.position then
        oldPosition = raceData.position
        positionChangeTime = getTickCount()
    end

    for k, v in pairs(data) do
        raceData[k] = v
    end
end)

addEvent("jebiga:race:checkpoint", true)
addEventHandler("jebiga:race:checkpoint", root, function(cp, total)
    raceData.checkpoint = cp
    raceData.totalCheckpoints = total
    checkpointFlash = 100
    playSoundFrontEnd(44)
end)

addEvent("jebiga:race:countdown", true)
addEventHandler("jebiga:race:countdown", root, function(seconds)
    countdown = seconds
    countdownStart = getTickCount()
end)

addEvent("jebiga:race:finish", true)
addEventHandler("jebiga:race:finish", root, function(position, time)
    showCenterText("FINISHED " .. position .. getOrdinalSuffix(position), getPositionColor(position), 5000)
    playSoundFrontEnd(46)
end)

-- ============================================
-- EXPORTS
-- ============================================

function setRaceData(key, value)
    raceData[key] = value
end

function getRaceData()
    return raceData
end

function setRaceActive(active)
    raceActive = active
end
