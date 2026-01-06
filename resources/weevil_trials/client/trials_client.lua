--[[
    Weevil Multi-Gamemode - Trials
    Client-side Trials gamemode
]]

local GAMEMODE = "trials"
local currentCheckpoint = 0
local falls = 0
local checkpoints = {}
local checkpointMarker = nil
local raceStartTime = 0
local fallCheckZ = -20

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[Weevil Trials] Trials client initialized")
end)

-- Create checkpoint marker
function createCheckpointMarker(index)
    local cp = checkpoints[index]
    if not cp then return end

    if checkpointMarker and isElement(checkpointMarker) then destroyElement(checkpointMarker) end

    local nextCp = checkpoints[index + 1]
    local markerType = nextCp and "checkpoint" or "finish"

    checkpointMarker = createMarker(cp.x, cp.y, cp.z, markerType, cp.size or 3, 100, 255, 255, 150)

    if nextCp then
        setMarkerTarget(checkpointMarker, nextCp.x, nextCp.y, nextCp.z)
    end

    addEventHandler("onClientMarkerHit", checkpointMarker, function(hitElement)
        if hitElement == localPlayer or (isPedInVehicle(localPlayer) and hitElement == getPedOccupiedVehicle(localPlayer)) then
            triggerServerEvent("weevil:trials:checkpointHit", localPlayer, index)
            exports.weevil_core:playSound("checkpoint")
        end
    end)
end

addEvent("weevil:trials:nextCheckpoint", true)
addEventHandler("weevil:trials:nextCheckpoint", root, function(index)
    currentCheckpoint = index
    createCheckpointMarker(index)
end)

-- Check for fall
addEventHandler("onClientPreRender", root, function()
    local gamemode = exports.weevil_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end

    local x, y, z = getElementPosition(localPlayer)
    if z < fallCheckZ then
        triggerServerEvent("weevil:trials:fell", localPlayer)
        falls = falls + 1
    end
end)

-- Reset key binding
bindKey("r", "down", function()
    local gamemode = exports.weevil_core:getCurrentGamemode()
    if gamemode == GAMEMODE then
        triggerServerEvent("weevil:trials:fell", localPlayer)
    end
end)

-- Render Trials HUD
addEventHandler("onClientRender", root, function()
    local gamemode = exports.weevil_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end

    local screenW, screenH = guiGetScreenSize()

    -- Time
    local raceTime = getTickCount() - raceStartTime
    dxDrawText(
        Utils.formatTime(raceTime),
        screenW / 2 - 80, 20,
        screenW / 2 + 80, 50,
        tocolor(100, 255, 255, 255),
        1.5, "default-bold", "center", "center"
    )

    -- Checkpoint
    dxDrawText(
        "CP: " .. currentCheckpoint .. "/" .. #checkpoints,
        screenW / 2 - 60, 55,
        screenW / 2 + 60, 75,
        tocolor(200, 200, 200, 255),
        0.9, "default", "center", "center"
    )

    -- Falls
    dxDrawText(
        "Falls: " .. falls,
        screenW / 2 - 50, 75,
        screenW / 2 + 50, 95,
        tocolor(255, 150, 100, 255),
        0.9, "default", "center", "center"
    )

    -- Reset hint
    dxDrawText(
        "Press R to reset",
        screenW / 2 - 60, screenH - 40,
        screenW / 2 + 60, screenH - 20,
        tocolor(150, 150, 150, 200),
        0.8, "default", "center", "center"
    )
end)

-- Reset on new round
addEvent(Events.Arena.ROUND_START, true)
addEventHandler(Events.Arena.ROUND_START, root, function(data)
    if data.gamemode ~= GAMEMODE then return end
    raceStartTime = getTickCount()
    currentCheckpoint = 0
    falls = 0
end)

-- Cleanup
addEvent(Events.Lobby.PLAYER_LEAVE, true)
addEventHandler(Events.Lobby.PLAYER_LEAVE, root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    if checkpointMarker and isElement(checkpointMarker) then destroyElement(checkpointMarker) end

    currentCheckpoint = 0
    falls = 0
    checkpoints = {}
end)
