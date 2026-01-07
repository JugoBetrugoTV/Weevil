--[[
    Jebiga Multi-Gamemode - Settings System (Server)
    Saves and loads player settings from MySQL database
]]

-- ============================================
-- DEFAULT SETTINGS
-- ============================================

local DefaultSettings = {
    hud = true,
    speedometer = true,
    nametags = true,
    nametagHealth = true,
    radar = true,
    killMessages = true,
    sounds = true,
    music = true,
    musicVolume = 50,
    soundVolume = 80,
    autoRespawn = true,
    showFPS = false,
    showPing = true,
    chatTimestamps = false,
    chatFilter = true,
    pmNotifications = true,
    shaders = true,
    particles = true,
    neonLights = true,
    showOnlineStatus = true,
    allowPM = true,
    showLocation = true
}

-- ============================================
-- DATABASE INTEGRATION
-- ============================================

function loadPlayerSettings(player)
    local accountId = getElementData(player, "jebiga:accountId")
    if not accountId then
        -- Try to get account from serial
        local serial = getPlayerSerial(player)
        local account = exports.jebiga_core:getAccountBySerial(serial)
        if account then
            accountId = account.id
            setElementData(player, "jebiga:accountId", accountId)
        end
    end

    if not accountId then
        triggerClientEvent(player, "jebiga:settings:sync", resourceRoot, DefaultSettings)
        return DefaultSettings
    end

    local settings = exports.jebiga_core:getPlayerSettings(accountId)

    if settings then
        -- Convert database format to client format
        local clientSettings = {
            hud = settings.hud == 1,
            speedometer = settings.speedometer == 1,
            nametags = settings.nametags == 1,
            nametagHealth = settings.nametag_health == 1,
            radar = settings.radar == 1,
            killMessages = settings.kill_messages == 1,
            sounds = settings.sounds == 1,
            music = settings.music == 1,
            musicVolume = settings.music_volume or 50,
            soundVolume = settings.sound_volume or 80,
            autoRespawn = settings.auto_respawn == 1,
            showFPS = settings.show_fps == 1,
            showPing = settings.show_ping == 1,
            chatTimestamps = settings.chat_timestamps == 1,
            chatFilter = settings.chat_filter == 1,
            pmNotifications = settings.pm_notifications == 1,
            shaders = settings.shaders == 1,
            particles = settings.particles == 1,
            neonLights = settings.neon_lights == 1,
            showOnlineStatus = settings.show_online_status == 1,
            allowPM = settings.allow_pm == 1,
            showLocation = settings.show_location == 1
        }

        setElementData(player, "jebiga:settings", clientSettings)
        triggerClientEvent(player, "jebiga:settings:sync", resourceRoot, clientSettings)
        return clientSettings
    end

    triggerClientEvent(player, "jebiga:settings:sync", resourceRoot, DefaultSettings)
    return DefaultSettings
end

function savePlayerSettingsToDb(player, settings)
    local accountId = getElementData(player, "jebiga:accountId")
    if not accountId then return false end

    -- Convert client format to database format
    local dbSettings = {
        hud = settings.hud and 1 or 0,
        speedometer = settings.speedometer and 1 or 0,
        nametags = settings.nametags and 1 or 0,
        nametag_health = settings.nametagHealth and 1 or 0,
        radar = settings.radar and 1 or 0,
        kill_messages = settings.killMessages and 1 or 0,
        sounds = settings.sounds and 1 or 0,
        music = settings.music and 1 or 0,
        music_volume = settings.musicVolume or 50,
        sound_volume = settings.soundVolume or 80,
        auto_respawn = settings.autoRespawn and 1 or 0,
        show_fps = settings.showFPS and 1 or 0,
        show_ping = settings.showPing and 1 or 0,
        chat_timestamps = settings.chatTimestamps and 1 or 0,
        chat_filter = settings.chatFilter and 1 or 0,
        pm_notifications = settings.pmNotifications and 1 or 0,
        shaders = settings.shaders and 1 or 0,
        particles = settings.particles and 1 or 0,
        neon_lights = settings.neonLights and 1 or 0,
        show_online_status = settings.showOnlineStatus and 1 or 0,
        allow_pm = settings.allowPM and 1 or 0,
        show_location = settings.showLocation and 1 or 0
    }

    return exports.jebiga_core:savePlayerSettings(accountId, dbSettings)
end

-- ============================================
-- EVENTS
-- ============================================

addEvent("jebiga:settings:save", true)
addEventHandler("jebiga:settings:save", root, function(settings)
    setElementData(source, "jebiga:settings", settings)
    savePlayerSettingsToDb(source, settings)
end)

addEvent("jebiga:settings:load", true)
addEventHandler("jebiga:settings:load", root, function()
    loadPlayerSettings(source)
end)

-- Sync settings on join
addEventHandler("onPlayerJoin", root, function()
    setTimer(function(player)
        if isElement(player) then
            loadPlayerSettings(player)
        end
    end, 3000, 1, source)
end)

-- Load settings for existing players on resource start
addEventHandler("onResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        loadPlayerSettings(player)
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

function getPlayerSettings(player)
    return getElementData(player, "jebiga:settings") or DefaultSettings
end

function getPlayerSetting(player, key)
    local settings = getPlayerSettings(player)
    return settings[key]
end
