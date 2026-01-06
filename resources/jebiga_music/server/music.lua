--[[
    Jebiga Multi-Gamemode - Music System (Server)
    Handles custom radio stations and server-side music control
]]

-- Custom station URLs (can be configured)
local customStations = {
    -- Example: { name = "Station Name", url = "http://stream.url" }
}

-- ============================================
-- STATION MANAGEMENT
-- ============================================

function setCustomStation(index, url, name)
    customStations[index] = { url = url, name = name }
    triggerClientEvent(root, "jebiga:music:setStation", resourceRoot, index, url, name)
end

function getCustomStations()
    return customStations
end

-- Sync custom stations to new players
addEventHandler("onPlayerJoin", root, function()
    setTimer(function(player)
        if not isElement(player) then return end
        for index, station in pairs(customStations) do
            triggerClientEvent(player, "jebiga:music:setStation", resourceRoot, index, station.url, station.name)
        end
    end, 2000, 1, source)
end)

-- ============================================
-- ADMIN COMMANDS
-- ============================================

addCommandHandler("setstation", function(player, cmd, index, url)
    if not hasObjectPermissionTo(player, "command.start") then
        outputChatBox("#E74C3C[JEBIGA] #FFFFFFYou don't have permission!", player, 255, 255, 255, true)
        return
    end

    index = tonumber(index)
    if not index or not url then
        outputChatBox("#9B59B6[MUSIC] #FFFFFFUsage: /setstation [index] [url]", player, 255, 255, 255, true)
        return
    end

    setCustomStation(index, url)
    outputChatBox("#9B59B6[MUSIC] #FFFFFFStation " .. index .. " URL set!", player, 255, 255, 255, true)
end)

-- ============================================
-- EXPORTS
-- ============================================

function broadcastMusic(url)
    for _, player in ipairs(getElementsByType("player")) do
        triggerClientEvent(player, "jebiga:music:play", resourceRoot, url)
    end
end

function stopBroadcast()
    for _, player in ipairs(getElementsByType("player")) do
        triggerClientEvent(player, "jebiga:music:stop", resourceRoot)
    end
end
