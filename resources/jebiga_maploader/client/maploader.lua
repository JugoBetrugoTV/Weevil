--[[
    Jebiga Multi-Gamemode - Map Loader Client
    Checkpoint display, minimap markers, sounds
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- Current map state
local currentMap = nil
local checkpoints = {}
local currentCheckpoint = 1
local totalCheckpoints = 0
local currentLap = 1
local totalLaps = 1
local nextCheckpointPos = nil

-- Blips
local checkpointBlip = nil

-- Sounds
local checkpointSound = nil
local finishSound = nil

-- Map music
local currentMapMusic = nil
local mapMusicEnabled = true

-- ============================================
-- MAP EVENTS
-- ============================================

addEvent("jebiga:maploader:mapLoaded", true)
addEventHandler("jebiga:maploader:mapLoaded", root, function(mapData)
    currentMap = mapData.name
    checkpoints = mapData.checkpoints or {}
    totalCheckpoints = #checkpoints
    currentCheckpoint = 1
    currentLap = 1
    totalLaps = mapData.settings and mapData.settings.laps or 1

    -- Create blip for first checkpoint
    if checkpoints[1] then
        updateCheckpointBlip(checkpoints[1])
    end

    -- Handle map music
    stopMapMusic()
    if mapMusicEnabled and mapData.settings then
        local musicUrl = mapData.settings.musicUrl or mapData.settings.music
        if musicUrl and musicUrl ~= "" then
            playMapMusic(musicUrl, mapData.settings.musicVolume or 0.5)
        end
    end

    outputChatBox("#2980B9[MAP] #FFFFFFMap loaded: " .. (mapData.name or "Unknown"), 255, 255, 255, true)
end)

addEvent("jebiga:maploader:mapUnloaded", true)
addEventHandler("jebiga:maploader:mapUnloaded", root, function()
    currentMap = nil
    checkpoints = {}
    currentCheckpoint = 1
    totalCheckpoints = 0
    nextCheckpointPos = nil

    if checkpointBlip and isElement(checkpointBlip) then
        destroyElement(checkpointBlip)
        checkpointBlip = nil
    end

    -- Stop map music when map unloads
    stopMapMusic()
end)

addEvent("jebiga:maploader:updateCheckpoint", true)
addEventHandler("jebiga:maploader:updateCheckpoint", root, function(data)
    currentCheckpoint = data.current
    totalCheckpoints = data.total
    currentLap = data.lap
    totalLaps = data.totalLaps

    if data.checkpoint then
        nextCheckpointPos = {x = data.checkpoint.x, y = data.checkpoint.y, z = data.checkpoint.z}
        updateCheckpointBlip(data.checkpoint)
    end
end)

addEvent("jebiga:maploader:checkpointHit", true)
addEventHandler("jebiga:maploader:checkpointHit", root, function(index, isFinish)
    -- Play sound
    if isFinish then
        playSound("sounds/finish.mp3")
    else
        playSound("sounds/checkpoint.mp3")
    end

    -- Show notification
    if not isFinish then
        showCheckpointNotification(index, totalCheckpoints)
    end
end)

addEvent("jebiga:maploader:pickupCollected", true)
addEventHandler("jebiga:maploader:pickupCollected", root, function(pickupType)
    playSound("sounds/pickup.mp3")

    if pickupType == "nitro" then
        outputChatBox("#00FF00[PICKUP] #FFFFFFNitro collected!", 255, 255, 255, true)
    elseif pickupType == "repair" then
        outputChatBox("#FFFF00[PICKUP] #FFFFFFVehicle repaired!", 255, 255, 255, true)
    elseif pickupType == "vehiclechange" then
        outputChatBox("#FF00FF[PICKUP] #FFFFFFVehicle changed!", 255, 255, 255, true)
    end
end)

addEvent("jebiga:maploader:finished", true)
addEventHandler("jebiga:maploader:finished", root, function(position, time)
    playSound("sounds/finish.mp3")

    -- Format time
    local mins = math.floor(time / 60000)
    local secs = math.floor((time % 60000) / 1000)
    local ms = time % 1000
    local timeStr = string.format("%02d:%02d.%03d", mins, secs, ms)

    -- Show finish screen (could be expanded)
    local posColors = {"#FFD700", "#C0C0C0", "#CD7F32"}
    local posColor = posColors[position] or "#FFFFFF"

    outputChatBox(" ", 255, 255, 255, true)
    outputChatBox("#2980B9═══════════════════════════", 255, 255, 255, true)
    outputChatBox(posColor .. "     FINISHED #" .. position .. "     ", 255, 255, 255, true)
    outputChatBox("#FFFFFF     Time: " .. timeStr .. "     ", 255, 255, 255, true)
    outputChatBox("#2980B9═══════════════════════════", 255, 255, 255, true)
end)

addEvent("jebiga:maploader:raceStarted", true)
addEventHandler("jebiga:maploader:raceStarted", root, function()
    outputChatBox("#00FF00[RACE] #FFFFFFGO! GO! GO!", 255, 255, 255, true)
    playSound("sounds/go.mp3")
end)

-- ============================================
-- CHECKPOINT BLIP
-- ============================================

function updateCheckpointBlip(checkpoint)
    if checkpointBlip and isElement(checkpointBlip) then
        destroyElement(checkpointBlip)
    end

    if checkpoint then
        checkpointBlip = createBlip(checkpoint.x, checkpoint.y, checkpoint.z, 0, 2, 255, 0, 0, 255)
        nextCheckpointPos = {x = checkpoint.x, y = checkpoint.y, z = checkpoint.z}
    end
end

-- ============================================
-- CHECKPOINT HUD
-- ============================================

local notificationAlpha = 0
local notificationText = ""
local notificationTimer = nil

function showCheckpointNotification(current, total)
    notificationText = "Checkpoint " .. current .. "/" .. total
    notificationAlpha = 255

    if notificationTimer and isTimer(notificationTimer) then
        killTimer(notificationTimer)
    end

    notificationTimer = setTimer(function()
        notificationAlpha = 0
    end, 2000, 1)
end

function renderCheckpointHUD()
    if not currentMap then return end
    if totalCheckpoints == 0 then return end

    -- Checkpoint counter (top right)
    local x = screenW - 200 * scale
    local y = 150 * scale
    local w = 180 * scale
    local h = 60 * scale

    -- Background
    dxDrawRectangle(x, y, w, h, tocolor(30, 30, 30, 200))
    dxDrawRectangle(x, y, 4, h, tocolor(41, 128, 185, 255))

    -- Checkpoint text
    dxDrawText("CP", x + 15, y + 5, x + w, y + 25, tocolor(150, 150, 150, 255), 0.8 * scale, "default-bold", "left", "center")
    dxDrawText(currentCheckpoint .. "/" .. totalCheckpoints, x + 15, y + 25, x + w - 10, y + h - 5, tocolor(255, 255, 255, 255), 1.5 * scale, "default-bold", "left", "center")

    -- Lap counter (if multiple laps)
    if totalLaps > 1 then
        local lapY = y + h + 5
        dxDrawRectangle(x, lapY, w, 40 * scale, tocolor(30, 30, 30, 200))
        dxDrawRectangle(x, lapY, 4, 40 * scale, tocolor(241, 196, 15, 255))
        dxDrawText("LAP " .. currentLap .. "/" .. totalLaps, x + 15, lapY, x + w - 10, lapY + 40 * scale, tocolor(255, 255, 255, 255), 1.0 * scale, "default-bold", "left", "center")
    end

    -- Distance to checkpoint
    if nextCheckpointPos then
        local px, py, pz = getElementPosition(localPlayer)
        local distance = getDistanceBetweenPoints3D(px, py, pz, nextCheckpointPos.x, nextCheckpointPos.y, nextCheckpointPos.z)

        local distY = y + h + (totalLaps > 1 and 50 * scale or 5)
        dxDrawText(math.floor(distance) .. "m", x + 15, distY, x + w - 10, distY + 30 * scale, tocolor(150, 150, 150, 200), 0.9 * scale, "default", "left", "center")
    end

    -- Checkpoint notification
    if notificationAlpha > 0 then
        -- Fade out
        notificationAlpha = notificationAlpha - 3

        local centerX = screenW / 2
        local notifY = 200 * scale

        dxDrawText(notificationText, centerX - 200, notifY, centerX + 200, notifY + 50,
            tocolor(255, 255, 255, notificationAlpha), 2.0 * scale, "default-bold", "center", "center")
    end
end

addEventHandler("onClientRender", root, renderCheckpointHUD)

-- ============================================
-- ARROW INDICATOR
-- ============================================

function renderCheckpointArrow()
    if not nextCheckpointPos then return end

    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then return end

    local px, py, pz = getElementPosition(vehicle)
    local _, _, rz = getElementRotation(vehicle)

    local dx = nextCheckpointPos.x - px
    local dy = nextCheckpointPos.y - py

    local angle = math.deg(math.atan2(dy, dx)) - 90
    local relAngle = angle - rz

    -- Normalize angle
    while relAngle > 180 do relAngle = relAngle - 360 end
    while relAngle < -180 do relAngle = relAngle + 360 end

    -- Draw arrow indicator
    local centerX = screenW / 2
    local arrowY = 100 * scale
    local arrowSize = 30 * scale

    -- Calculate arrow points based on angle
    local rad = math.rad(relAngle - 90)
    local ax = centerX + math.cos(rad) * arrowSize
    local ay = arrowY + math.sin(rad) * arrowSize

    -- Simple arrow (triangle)
    local r, g, b = 255, 50, 50
    if math.abs(relAngle) < 30 then
        r, g, b = 50, 255, 50 -- Green when pointing forward
    elseif math.abs(relAngle) < 60 then
        r, g, b = 255, 255, 50 -- Yellow
    end

    -- Draw direction indicator
    dxDrawText("▼", ax - 15, ay - 15, ax + 15, ay + 15, tocolor(r, g, b, 200), 2.0 * scale, "default", "center", "center")
end

addEventHandler("onClientRender", root, renderCheckpointArrow)

-- ============================================
-- SOUNDS
-- ============================================

function playLocalSound(path)
    -- Try to play from this resource first
    local sound = playSound(path)
    if not sound then
        -- Fallback - create simple beep
        -- MTA doesn't have built-in beep, so we skip if file missing
    end
end

-- ============================================
-- MAP MUSIC
-- ============================================

function playMapMusic(url, volume)
    stopMapMusic()

    if not url or url == "" then return end

    volume = volume or 0.5

    -- Check if it's a URL or a local file path
    if url:find("://") then
        -- It's a URL (http:// or https://)
        currentMapMusic = playSound(url, false)
    else
        -- It's a local file - try to load from map resource
        currentMapMusic = playSound(url, false)
    end

    if currentMapMusic and isElement(currentMapMusic) then
        setSoundVolume(currentMapMusic, volume)
        setSoundLooped(currentMapMusic, true)
        outputDebugString("[MapLoader] Playing map music: " .. url)
    else
        outputDebugString("[MapLoader] Failed to load map music: " .. url, 2)
    end
end

function stopMapMusic()
    if currentMapMusic and isElement(currentMapMusic) then
        destroyElement(currentMapMusic)
        currentMapMusic = nil
    end
end

function toggleMapMusic()
    mapMusicEnabled = not mapMusicEnabled
    if not mapMusicEnabled then
        stopMapMusic()
        outputChatBox("#2980B9[MUSIC] #FFFFFFMap music disabled", 255, 255, 255, true)
    else
        outputChatBox("#2980B9[MUSIC] #FFFFFFMap music enabled", 255, 255, 255, true)
    end
end

-- Command to toggle map music
addCommandHandler("mapmusic", toggleMapMusic)

-- ============================================
-- RESOURCE START
-- ============================================

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[MapLoader] Client initialized")
end)
