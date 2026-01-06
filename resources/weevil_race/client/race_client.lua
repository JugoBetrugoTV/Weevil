--[[
    Weevil Multi-Gamemode - Race (Oldschool)
    Client-side Race gamemode
]]

local GAMEMODE = "race"
local currentCheckpoint = 0
local totalCheckpoints = 0
local checkpoints = {}
local checkpointMarker = nil
local checkpointBlip = nil
local raceStartTime = 0

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[Weevil Race] Race client initialized")
end)

-- Create checkpoint marker
function createCheckpointMarker(index)
    local cp = checkpoints[index]
    if not cp then return end

    if checkpointMarker and isElement(checkpointMarker) then destroyElement(checkpointMarker) end
    if checkpointBlip and isElement(checkpointBlip) then destroyElement(checkpointBlip) end

    local nextCp = checkpoints[index + 1]
    local markerType = nextCp and "checkpoint" or "finish"

    checkpointMarker = createMarker(cp.x, cp.y, cp.z, markerType, cp.size or 4, 100, 255, 100, 150)

    if nextCp then
        setMarkerTarget(checkpointMarker, nextCp.x, nextCp.y, nextCp.z)
    end

    checkpointBlip = createBlip(cp.x, cp.y, cp.z, 0, 2, 100, 255, 100)

    addEventHandler("onClientMarkerHit", checkpointMarker, function(hitElement)
        if hitElement == localPlayer or (isPedInVehicle(localPlayer) and hitElement == getPedOccupiedVehicle(localPlayer)) then
            triggerServerEvent("weevil:race:checkpointHit", localPlayer, index)
            exports.weevil_core:playSound("checkpoint")
        end
    end)
end

addEvent("weevil:race:nextCheckpoint", true)
addEventHandler("weevil:race:nextCheckpoint", root, function(index)
    currentCheckpoint = index
    createCheckpointMarker(index)
end)

-- Render Race HUD
addEventHandler("onClientRender", root, function()
    local gamemode = exports.weevil_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end

    local screenW, screenH = guiGetScreenSize()

    -- Race time
    local raceTime = getTickCount() - raceStartTime
    dxDrawText(
        Utils.formatTime(raceTime),
        screenW / 2 - 80, 20,
        screenW / 2 + 80, 50,
        tocolor(100, 255, 100, 255),
        1.5, "default-bold", "center", "center"
    )

    -- Checkpoint counter
    dxDrawText(
        "CP: " .. currentCheckpoint .. "/" .. totalCheckpoints,
        screenW / 2 - 60, 55,
        screenW / 2 + 60, 80,
        tocolor(200, 200, 200, 255),
        1.0, "default", "center", "center"
    )
end)

-- Start race event
addEvent(Events.Arena.ROUND_START, true)
addEventHandler(Events.Arena.ROUND_START, root, function(data)
    if data.gamemode ~= GAMEMODE then return end
    raceStartTime = getTickCount()
    currentCheckpoint = 0
end)

-- Cleanup
addEvent(Events.Lobby.PLAYER_LEAVE, true)
addEventHandler(Events.Lobby.PLAYER_LEAVE, root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    if checkpointMarker and isElement(checkpointMarker) then destroyElement(checkpointMarker) end
    if checkpointBlip and isElement(checkpointBlip) then destroyElement(checkpointBlip) end

    currentCheckpoint = 0
    checkpoints = {}
end)
