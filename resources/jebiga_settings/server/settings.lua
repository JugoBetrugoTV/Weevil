--[[
    Jebiga Multi-Gamemode - Settings System (Server)
    Saves and loads player settings
]]

-- Player settings storage
local playerSettings = {}

addEvent("jebiga:settings:save", true)
addEventHandler("jebiga:settings:save", root, function(settings)
    local serial = getPlayerSerial(source)
    playerSettings[serial] = settings

    -- Save to database if available
    local core = getResourceFromName("jebiga_core")
    if core and getResourceState(core) == "running" then
        -- exports.jebiga_core:dbExec("UPDATE accounts SET settings = ? WHERE serial = ?",
        --     toJSON(settings), serial)
    end

    setElementData(source, "jebiga:settings", settings)
end)

addEvent("jebiga:settings:load", true)
addEventHandler("jebiga:settings:load", root, function()
    local serial = getPlayerSerial(source)
    local settings = playerSettings[serial] or DefaultSettings

    triggerClientEvent(source, "jebiga:settings:sync", resourceRoot, settings)
end)

-- Sync settings on join
addEventHandler("onPlayerJoin", root, function()
    local serial = getPlayerSerial(source)
    local settings = playerSettings[serial] or DefaultSettings
    setElementData(source, "jebiga:settings", settings)
end)

-- Export
function getPlayerSettings(player)
    return getElementData(player, "jebiga:settings") or DefaultSettings
end

function getPlayerSetting(player, key)
    local settings = getPlayerSettings(player)
    return settings[key]
end
