--[[
    Jebiga Multi-Gamemode - VIP/Donatorship System
    Premium features for VIP players
]]

-- VIP levels
local vipLevels = {
    [0] = { name = "Member", color = {255, 255, 255}, prefix = "" },
    [1] = { name = "VIP", color = {46, 204, 113}, prefix = "[VIP]", multiplier = 1.5 },
    [2] = { name = "VIP+", color = {52, 152, 219}, prefix = "[VIP+]", multiplier = 2.0 },
    [3] = { name = "Premium", color = {155, 89, 182}, prefix = "[PREMIUM]", multiplier = 2.5 },
    [4] = { name = "Elite", color = {241, 196, 15}, prefix = "[ELITE]", multiplier = 3.0 }
}

-- VIP perks by level
local vipPerks = {
    [1] = {
        "1.5x Money & Points",
        "Custom nametag color",
        "Priority queue",
        "VIP chat commands",
        "/vip command access"
    },
    [2] = {
        "2x Money & Points",
        "Custom clan tag colors",
        "Reserved slot",
        "Custom vehicle spawns",
        "/car command"
    },
    [3] = {
        "2.5x Money & Points",
        "Custom chat prefix",
        "Map voting power x2",
        "Free garage slots",
        "/skin command"
    },
    [4] = {
        "3x Money & Points",
        "All previous perks",
        "Custom profile badge",
        "Monthly bonus rewards",
        "Priority support"
    }
}

-- ============================================
-- VIP FUNCTIONS
-- ============================================

function getPlayerVIP(player)
    local vipLevel = getElementData(player, "jebiga:vip") or 0
    return vipLevel, vipLevels[vipLevel]
end

function setPlayerVIP(player, level, duration)
    level = math.max(0, math.min(4, level))
    setElementData(player, "jebiga:vip", level)

    if duration and duration > 0 then
        local expiry = getRealTime().timestamp + (duration * 86400) -- days to seconds
        setElementData(player, "jebiga:vipExpiry", expiry)
    end

    local levelData = vipLevels[level]
    if level > 0 then
        outputChatBox("#" .. rgbToHex(levelData.color) .. "[VIP] #FFFFFFYou are now " .. levelData.name .. "!", player, 255, 255, 255, true)
        triggerClientEvent(player, "jebiga:vip:updated", resourceRoot, level, levelData)
    end
end

function getVIPMultiplier(player)
    local level = getElementData(player, "jebiga:vip") or 0
    return vipLevels[level] and vipLevels[level].multiplier or 1.0
end

function getVIPPrefix(player)
    local level = getElementData(player, "jebiga:vip") or 0
    return vipLevels[level] and vipLevels[level].prefix or ""
end

function isVIP(player, minLevel)
    local level = getElementData(player, "jebiga:vip") or 0
    return level >= (minLevel or 1)
end

-- ============================================
-- VIP BENEFITS APPLICATION
-- ============================================

-- Apply money multiplier
addEvent("jebiga:money:add", true)
addEventHandler("jebiga:money:add", root, function(amount, reason)
    local multiplier = getVIPMultiplier(source)
    local finalAmount = math.floor(amount * multiplier)

    local current = getElementData(source, "jebiga:money") or 0
    setElementData(source, "jebiga:money", current + finalAmount)

    if multiplier > 1 then
        outputChatBox("#2ECC71[VIP] #FFFFFFBonus applied! +" .. (finalAmount - amount) .. " extra!", source, 255, 255, 255, true)
    end
end)

-- ============================================
-- VIP COMMANDS
-- ============================================

addCommandHandler("vip", function(player, cmd, ...)
    local args = {...}
    local subCmd = args[1]

    if not subCmd then
        -- Show VIP info
        local level, data = getPlayerVIP(player)
        outputChatBox("#9B59B6═══════════════════════════", player, 255, 255, 255, true)
        outputChatBox("#9B59B6       VIP INFORMATION       ", player, 255, 255, 255, true)
        outputChatBox("#9B59B6═══════════════════════════", player, 255, 255, 255, true)

        if level > 0 then
            outputChatBox("#FFFFFF Your VIP Level: #" .. rgbToHex(data.color) .. data.name, player, 255, 255, 255, true)
            outputChatBox("#FFFFFF Your Perks:", player, 255, 255, 255, true)
            for _, perk in ipairs(vipPerks[level] or {}) do
                outputChatBox("#95A5A6  • " .. perk, player, 255, 255, 255, true)
            end
        else
            outputChatBox("#FFFFFF You are not a VIP member.", player, 255, 255, 255, true)
            outputChatBox("#FFFFFF Visit our website to upgrade!", player, 255, 255, 255, true)
        end
        return
    end

    -- VIP-only commands
    if not isVIP(player) then
        outputChatBox("#E74C3C[VIP] #FFFFFFThis command requires VIP status!", player, 255, 255, 255, true)
        return
    end

    if subCmd == "color" and isVIP(player, 2) then
        -- Custom nametag color
        local r, g, b = tonumber(args[2]), tonumber(args[3]), tonumber(args[4])
        if r and g and b then
            setElementData(player, "jebiga:nametagColor", {r, g, b})
            outputChatBox("#2ECC71[VIP] #FFFFFFNametag color updated!", player, 255, 255, 255, true)
        else
            outputChatBox("#E74C3C[VIP] #FFFFFFUsage: /vip color [r] [g] [b]", player, 255, 255, 255, true)
        end
    end
end)

-- /car command for VIP+
addCommandHandler("car", function(player, cmd, modelStr)
    if not isVIP(player, 2) then
        outputChatBox("#E74C3C[VIP] #FFFFFFThis command requires VIP+ or higher!", player, 255, 255, 255, true)
        return
    end

    local model = tonumber(modelStr)
    if not model or model < 400 or model > 611 then
        outputChatBox("#E74C3C[VIP] #FFFFFFUsage: /car [vehicle ID 400-611]", player, 255, 255, 255, true)
        return
    end

    -- Destroy old vehicle
    local oldVeh = getPedOccupiedVehicle(player)
    if oldVeh then
        destroyElement(oldVeh)
    end

    local x, y, z = getElementPosition(player)
    local _, _, rz = getElementRotation(player)
    local veh = createVehicle(model, x, y, z + 1, 0, 0, rz)

    if veh then
        warpPedIntoVehicle(player, veh)
        outputChatBox("#2ECC71[VIP] #FFFFFFVehicle spawned!", player, 255, 255, 255, true)
    end
end)

-- /skin command for Premium
addCommandHandler("skin", function(player, cmd, skinStr)
    if not isVIP(player, 3) then
        outputChatBox("#E74C3C[VIP] #FFFFFFThis command requires Premium or higher!", player, 255, 255, 255, true)
        return
    end

    local skin = tonumber(skinStr)
    if not skin or skin < 0 or skin > 312 then
        outputChatBox("#E74C3C[VIP] #FFFFFFUsage: /skin [skin ID 0-312]", player, 255, 255, 255, true)
        return
    end

    setElementModel(player, skin)
    outputChatBox("#2ECC71[VIP] #FFFFFFSkin changed!", player, 255, 255, 255, true)
end)

-- ============================================
-- ADMIN COMMANDS
-- ============================================

addCommandHandler("setvip", function(player, cmd, targetName, level, days)
    if not hasObjectPermissionTo(player, "command.start") then
        outputChatBox("#E74C3C[VIP] #FFFFFFYou don't have permission!", player, 255, 255, 255, true)
        return
    end

    local target = getPlayerFromName(targetName)
    if not target then
        outputChatBox("#E74C3C[VIP] #FFFFFFPlayer not found!", player, 255, 255, 255, true)
        return
    end

    level = tonumber(level) or 1
    days = tonumber(days) or 30

    setPlayerVIP(target, level, days)
    outputChatBox("#2ECC71[VIP] #FFFFFFSet " .. getPlayerName(target) .. " to VIP level " .. level .. " for " .. days .. " days.", player, 255, 255, 255, true)
end)

-- ============================================
-- UTILITY
-- ============================================

function rgbToHex(color)
    return string.format("%02X%02X%02X", color[1], color[2], color[3])
end

-- ============================================
-- EXPORTS
-- ============================================

_G.getPlayerVIP = getPlayerVIP
_G.setPlayerVIP = setPlayerVIP
_G.getVIPMultiplier = getVIPMultiplier
_G.getVIPPrefix = getVIPPrefix
_G.isVIP = isVIP
