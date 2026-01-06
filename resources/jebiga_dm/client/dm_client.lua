--[[
    Jebiga Multi-Gamemode - DM (Deathmatch Race)
    Client-side DM gamemode
]]

local GAMEMODE = "dm"
local currentCheckpoint = 0
local checkpoints = {}
local checkpointMarker = nil
local checkpointBlip = nil

-- Initialize
addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[Jebiga DM] DM client initialized")
end)

-- Create checkpoint marker
function createCheckpointMarker(index)
    local cp = checkpoints[index]
    if not cp then return end

    -- Remove old marker
    if checkpointMarker and isElement(checkpointMarker) then
        destroyElement(checkpointMarker)
    end
    if checkpointBlip and isElement(checkpointBlip) then
        destroyElement(checkpointBlip)
    end

    -- Create new marker
    local nextCp = checkpoints[index + 1]
    local markerType = nextCp and "checkpoint" or "finish"

    checkpointMarker = createMarker(cp.x, cp.y, cp.z, markerType, cp.size or 4, 255, 100, 100, 150)

    if nextCp then
        setMarkerTarget(checkpointMarker, nextCp.x, nextCp.y, nextCp.z)
    end

    checkpointBlip = createBlip(cp.x, cp.y, cp.z, 0, 2, 255, 100, 100)

    -- Hit handler
    addEventHandler("onClientMarkerHit", checkpointMarker, function(hitElement)
        if hitElement == localPlayer or (isPedInVehicle(localPlayer) and hitElement == getPedOccupiedVehicle(localPlayer)) then
            triggerServerEvent("weevil:dm:checkpointHit", localPlayer, index)
            exports.jebiga_core:playSound("checkpoint")
        end
    end)
end

-- Handle next checkpoint
addEvent("weevil:dm:nextCheckpoint", true)
addEventHandler("weevil:dm:nextCheckpoint", root, function(index)
    currentCheckpoint = index
    createCheckpointMarker(index)
end)

-- Render DM HUD
addEventHandler("onClientRender", root, function()
    local gamemode = exports.jebiga_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end

    local screenW, screenH = guiGetScreenSize()

    -- Checkpoint counter
    dxDrawText(
        "Checkpoint: " .. currentCheckpoint .. "/" .. #checkpoints,
        screenW / 2 - 100, 50,
        screenW / 2 + 100, 80,
        tocolor(255, 100, 100, 255),
        1.2, "default-bold", "center", "center"
    )
end)

-- Cleanup on gamemode leave
addEvent(Events.Lobby.PLAYER_LEAVE, true)
addEventHandler(Events.Lobby.PLAYER_LEAVE, root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    if checkpointMarker and isElement(checkpointMarker) then
        destroyElement(checkpointMarker)
    end
    if checkpointBlip and isElement(checkpointBlip) then
        destroyElement(checkpointBlip)
    end

    currentCheckpoint = 0
    checkpoints = {}
end)
