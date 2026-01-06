--[[
    Jebiga Multi-Gamemode - Vehicle Tuning System (Server)
    Handles upgrade application and validation
]]

-- ============================================
-- UPGRADE EVENTS
-- ============================================

addEvent("jebiga:tuning:apply", true)
addEventHandler("jebiga:tuning:apply", root, function(vehicle, upgradeId)
    if not isElement(vehicle) then return end
    if source ~= getVehicleOccupant(vehicle, 0) then return end -- Only driver can tune

    -- Check if upgrade is compatible
    local compatible = getVehicleCompatibleUpgrades(vehicle, upgradeId)
    if not compatible then
        triggerClientEvent(source, "jebiga:tuning:result", resourceRoot, false, "This upgrade is not compatible!")
        return
    end

    -- Apply upgrade
    local success = addVehicleUpgrade(vehicle, upgradeId)

    if success then
        triggerClientEvent(source, "jebiga:tuning:result", resourceRoot, true, "Upgrade installed!")
        outputDebugString("[Jebiga Tuning] " .. getPlayerName(source) .. " applied upgrade " .. upgradeId)
    else
        triggerClientEvent(source, "jebiga:tuning:result", resourceRoot, false, "Failed to apply upgrade!")
    end
end)

addEvent("jebiga:tuning:color", true)
addEventHandler("jebiga:tuning:color", root, function(vehicle, slot, r, g, b)
    if not isElement(vehicle) then return end
    if source ~= getVehicleOccupant(vehicle, 0) then return end

    -- Validate color values
    r = math.max(0, math.min(255, tonumber(r) or 0))
    g = math.max(0, math.min(255, tonumber(g) or 0))
    b = math.max(0, math.min(255, tonumber(b) or 0))

    -- Get current colors
    local r1, g1, b1, r2, g2, b2 = getVehicleColor(vehicle, true)

    -- Apply new color
    if slot == 1 then
        setVehicleColor(vehicle, r, g, b, r2, g2, b2)
    else
        setVehicleColor(vehicle, r1, g1, b1, r, g, b)
    end

    outputDebugString("[Jebiga Tuning] " .. getPlayerName(source) .. " changed vehicle color")
end)

-- ============================================
-- ADMIN/VIP COMMANDS
-- ============================================

addCommandHandler("maxupgrades", function(player)
    if not hasObjectPermissionTo(player, "command.start") then
        outputChatBox("#E74C3C[JEBIGA] #FFFFFFYou don't have permission!", player, 255, 255, 255, true)
        return
    end

    local vehicle = getPedOccupiedVehicle(player)
    if not vehicle then
        outputChatBox("#E74C3C[JEBIGA] #FFFFFFYou must be in a vehicle!", player, 255, 255, 255, true)
        return
    end

    -- Get all compatible upgrades
    local upgrades = getVehicleCompatibleUpgrades(vehicle)

    -- Apply all compatible upgrades
    local applied = 0
    for _, upgradeId in ipairs(upgrades or {}) do
        if addVehicleUpgrade(vehicle, upgradeId) then
            applied = applied + 1
        end
    end

    outputChatBox("#2980B9[JEBIGA] #FFFFFFApplied " .. applied .. " upgrades to your vehicle!", player, 255, 255, 255, true)
end)

addCommandHandler("removeupgrades", function(player)
    local vehicle = getPedOccupiedVehicle(player)
    if not vehicle then
        outputChatBox("#E74C3C[JEBIGA] #FFFFFFYou must be in a vehicle!", player, 255, 255, 255, true)
        return
    end

    -- Remove all upgrades
    local upgrades = getVehicleUpgrades(vehicle)
    for _, upgradeId in ipairs(upgrades or {}) do
        removeVehicleUpgrade(vehicle, upgradeId)
    end

    outputChatBox("#2980B9[JEBIGA] #FFFFFFAll upgrades removed!", player, 255, 255, 255, true)
end)

-- ============================================
-- EXPORTS
-- ============================================

function applyVehicleUpgrade(vehicle, upgradeId)
    if isElement(vehicle) then
        return addVehicleUpgrade(vehicle, upgradeId)
    end
    return false
end

function setVehicleCustomColor(vehicle, slot, r, g, b)
    if not isElement(vehicle) then return false end

    local r1, g1, b1, r2, g2, b2 = getVehicleColor(vehicle, true)

    if slot == 1 then
        setVehicleColor(vehicle, r, g, b, r2, g2, b2)
    else
        setVehicleColor(vehicle, r1, g1, b1, r, g, b)
    end

    return true
end
