--[[
    Weevil Multi-Gamemode - Stuntage
    Client-side Stuntage gamemode
]]

local GAMEMODE = "stuntage"
local stunts = {}
local completedStunts = {}
local stuntMarkers = {}
local stuntBlips = {}

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[Weevil Stuntage] Stuntage client initialized")
end)

-- Load stunts from server
addEvent("weevil:stuntage:loadStunts", true)
addEventHandler("weevil:stuntage:loadStunts", root, function(stuntData)
    stunts = stuntData or {}
    createStuntMarkers()
end)

-- Create markers for all stunts
function createStuntMarkers()
    -- Clear existing
    for _, marker in ipairs(stuntMarkers) do
        if isElement(marker) then destroyElement(marker) end
    end
    for _, blip in ipairs(stuntBlips) do
        if isElement(blip) then destroyElement(blip) end
    end

    stuntMarkers = {}
    stuntBlips = {}

    for i, stunt in ipairs(stunts) do
        if not completedStunts[i] then
            local marker = createMarker(stunt.x, stunt.y, stunt.z, "corona", stunt.radius or 5, 255, 255, 0, 150)
            local blip = createBlip(stunt.x, stunt.y, stunt.z, 0, 2, 255, 255, 0)

            stuntMarkers[i] = marker
            stuntBlips[i] = blip

            addEventHandler("onClientMarkerHit", marker, function(hitElement)
                if hitElement == localPlayer or (isPedInVehicle(localPlayer) and hitElement == getPedOccupiedVehicle(localPlayer)) then
                    completeStunt(i)
                end
            end)
        end
    end
end

-- Complete stunt
function completeStunt(index)
    if completedStunts[index] then return end

    completedStunts[index] = true
    triggerServerEvent("weevil:stuntage:complete", localPlayer, index)

    -- Remove marker
    if stuntMarkers[index] and isElement(stuntMarkers[index]) then
        destroyElement(stuntMarkers[index])
    end
    if stuntBlips[index] and isElement(stuntBlips[index]) then
        destroyElement(stuntBlips[index])
    end

    exports.weevil_core:playSound("finish")
    exports.weevil_core:showNotification("success", "Stunt Complete! " .. stunts[index].name, 3000)
end

-- Render Stuntage HUD
addEventHandler("onClientRender", root, function()
    local gamemode = exports.weevil_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end

    local screenW, screenH = guiGetScreenSize()

    -- Stunt counter
    local completed = 0
    for _ in pairs(completedStunts) do completed = completed + 1 end

    dxDrawText(
        "Stunts: " .. completed .. "/" .. #stunts,
        screenW / 2 - 80, 20,
        screenW / 2 + 80, 50,
        tocolor(255, 255, 100, 255),
        1.2, "default-bold", "center", "center"
    )

    -- Nearest stunt indicator
    local px, py, pz = getElementPosition(localPlayer)
    local nearestDist = 9999
    local nearestStunt = nil

    for i, stunt in ipairs(stunts) do
        if not completedStunts[i] then
            local dist = getDistanceBetweenPoints3D(px, py, pz, stunt.x, stunt.y, stunt.z)
            if dist < nearestDist then
                nearestDist = dist
                nearestStunt = stunt
            end
        end
    end

    if nearestStunt then
        dxDrawText(
            "Nearest: " .. nearestStunt.name .. " (" .. math.floor(nearestDist) .. "m)",
            screenW / 2 - 150, 55,
            screenW / 2 + 150, 80,
            tocolor(200, 200, 200, 255),
            0.9, "default", "center", "center"
        )
    end
end)

-- Cleanup
addEvent(Events.Lobby.PLAYER_LEAVE, true)
addEventHandler(Events.Lobby.PLAYER_LEAVE, root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    for _, marker in ipairs(stuntMarkers) do
        if isElement(marker) then destroyElement(marker) end
    end
    for _, blip in ipairs(stuntBlips) do
        if isElement(blip) then destroyElement(blip) end
    end

    stunts = {}
    completedStunts = {}
    stuntMarkers = {}
    stuntBlips = {}
end)
