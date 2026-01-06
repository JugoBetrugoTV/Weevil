--[[
    Jebiga Multi-Gamemode - Vehicle Neon System (Server)
    Handles neon synchronization between players
]]

-- Store neon data per vehicle
local vehicleNeons = {}

-- ============================================
-- NEON EVENTS
-- ============================================

addEvent("jebiga:neon:apply", true)
addEventHandler("jebiga:neon:apply", root, function(vehicle, color)
    if not isElement(vehicle) then return end
    if source ~= getVehicleOccupant(vehicle, 0) then return end -- Only driver can apply

    vehicleNeons[vehicle] = {
        color = color,
        owner = source
    }

    -- Sync to all players
    triggerClientEvent(root, "jebiga:neon:sync", resourceRoot, vehicle, color)

    outputDebugString("[Jebiga Neons] " .. getPlayerName(source) .. " applied neon to vehicle")
end)

addEvent("jebiga:neon:remove", true)
addEventHandler("jebiga:neon:remove", root, function(vehicle)
    if not isElement(vehicle) then return end
    if source ~= getVehicleOccupant(vehicle, 0) then return end

    vehicleNeons[vehicle] = nil

    -- Sync removal to all players
    triggerClientEvent(root, "jebiga:neon:sync", resourceRoot, vehicle, nil)
end)

-- ============================================
-- SYNC NEW PLAYERS
-- ============================================

addEventHandler("onPlayerJoin", root, function()
    -- Sync all existing neons to new player
    setTimer(function(player)
        if not isElement(player) then return end

        for vehicle, data in pairs(vehicleNeons) do
            if isElement(vehicle) then
                triggerClientEvent(player, "jebiga:neon:sync", resourceRoot, vehicle, data.color)
            end
        end
    end, 2000, 1, source)
end)

-- ============================================
-- CLEANUP
-- ============================================

addEventHandler("onVehicleDestroy", root, function()
    vehicleNeons[source] = nil
end)

addEventHandler("onResourceStop", resourceRoot, function()
    vehicleNeons = {}
end)

-- ============================================
-- EXPORTS
-- ============================================

function getVehicleNeon(vehicle)
    return vehicleNeons[vehicle]
end

function setVehicleNeon(vehicle, color)
    if isElement(vehicle) then
        vehicleNeons[vehicle] = { color = color }
        triggerClientEvent(root, "jebiga:neon:sync", resourceRoot, vehicle, color)
    end
end

function removeVehicleNeon(vehicle)
    vehicleNeons[vehicle] = nil
    triggerClientEvent(root, "jebiga:neon:sync", resourceRoot, vehicle, nil)
end
