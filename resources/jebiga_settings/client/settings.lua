--[[
    Jebiga Multi-Gamemode - Settings System (Client)
    Settings GUI and application
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

local settingsOpen = false
local panelAlpha = 0
local currentCategory = 1
local mySettings = {}

-- Categories
local categories = {
    { name = "Visual", icon = "👁️", settings = {"hud", "speedometer", "nametags", "nametagHealth", "radar", "killMessages"} },
    { name = "Audio", icon = "🔊", settings = {"sounds", "music", "musicVolume", "soundVolume"} },
    { name = "Gameplay", icon = "🎮", settings = {"autoRespawn", "showFPS", "showPing"} },
    { name = "Chat", icon = "💬", settings = {"chatTimestamps", "chatFilter", "pmNotifications"} },
    { name = "Graphics", icon = "✨", settings = {"shaders", "particles", "neonLights"} },
    { name = "Privacy", icon = "🔒", settings = {"showOnlineStatus", "allowPM", "showLocation"} }
}

-- Setting labels
local settingLabels = {
    hud = "Show HUD",
    speedometer = "Show Speedometer",
    nametags = "Show Nametags",
    nametagHealth = "Show Health in Nametags",
    radar = "Show Radar",
    killMessages = "Show Kill Messages",
    sounds = "Enable Sounds",
    music = "Enable Music",
    musicVolume = "Music Volume",
    soundVolume = "Sound Volume",
    autoRespawn = "Auto Respawn",
    showFPS = "Show FPS",
    showPing = "Show Ping",
    chatTimestamps = "Chat Timestamps",
    chatFilter = "Chat Filter",
    pmNotifications = "PM Notifications",
    shaders = "Enable Shaders",
    particles = "Enable Particles",
    neonLights = "Enable Neon Lights",
    showOnlineStatus = "Show Online Status",
    allowPM = "Allow Private Messages",
    showLocation = "Show Location to Others"
}

-- ============================================
-- SETTINGS GUI
-- ============================================

function openSettings()
    settingsOpen = true
    showCursor(true)
end

function closeSettings()
    settingsOpen = false
    showCursor(false)
    saveSettings()
end

function renderSettings()
    if not settingsOpen then
        if panelAlpha > 0 then panelAlpha = panelAlpha - 20 end
        if panelAlpha <= 0 then return end
    else
        if panelAlpha < 255 then panelAlpha = panelAlpha + 20 end
    end

    local panelW = 600 * scale
    local panelH = 500 * scale
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Background
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(15, 17, 23, panelAlpha * 0.97))

    -- Header
    dxDrawRectangle(panelX, panelY, panelW, 55 * scale, tocolor(25, 28, 35, panelAlpha))
    dxDrawRectangle(panelX, panelY + 52 * scale, panelW, 3, tocolor(41, 128, 185, panelAlpha))
    dxDrawText("⚙️ SETTINGS", panelX, panelY, panelX + panelW, panelY + 55 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.3 * scale, "default-bold", "center", "center")

    -- Category tabs
    local tabW = panelW / #categories
    local tabY = panelY + 60 * scale
    local tabH = 35 * scale

    for i, cat in ipairs(categories) do
        local tabX = panelX + (i - 1) * tabW
        local isSelected = currentCategory == i

        local bgColor = isSelected and tocolor(41, 128, 185, panelAlpha * 0.4) or tocolor(25, 28, 35, panelAlpha * 0.3)
        dxDrawRectangle(tabX, tabY, tabW, tabH, bgColor)

        if isSelected then
            dxDrawRectangle(tabX, tabY + tabH - 2, tabW, 2, tocolor(41, 128, 185, panelAlpha))
        end

        dxDrawText(cat.icon .. " " .. cat.name, tabX, tabY, tabX + tabW, tabY + tabH,
            tocolor(255, 255, 255, panelAlpha * (isSelected and 1 or 0.6)), 0.8 * scale, "default-bold", "center", "center")
    end

    -- Settings content
    local contentX = panelX + 20 * scale
    local contentY = tabY + tabH + 20 * scale
    local contentW = panelW - 40 * scale
    local settingH = 40 * scale

    local cat = categories[currentCategory]
    for i, settingKey in ipairs(cat.settings) do
        local y = contentY + (i - 1) * (settingH + 5)
        local label = settingLabels[settingKey] or settingKey
        local value = mySettings[settingKey]

        -- Background
        dxDrawRectangle(contentX, y, contentW, settingH, tocolor(30, 33, 42, panelAlpha * 0.7))

        -- Label
        dxDrawText(label, contentX + 15, y, contentX + contentW * 0.6, y + settingH,
            tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

        -- Control (toggle or slider)
        if type(value) == "boolean" then
            -- Toggle
            local toggleX = contentX + contentW - 70 * scale
            local toggleW = 50 * scale
            local toggleH = 24 * scale
            local toggleY = y + (settingH - toggleH) / 2

            local toggleBg = value and tocolor(41, 128, 185, panelAlpha) or tocolor(60, 65, 75, panelAlpha)
            dxDrawRectangle(toggleX, toggleY, toggleW, toggleH, toggleBg)

            local knobX = value and (toggleX + toggleW - toggleH + 2) or (toggleX + 2)
            dxDrawRectangle(knobX, toggleY + 2, toggleH - 4, toggleH - 4, tocolor(255, 255, 255, panelAlpha))

        elseif type(value) == "number" then
            -- Slider
            local sliderX = contentX + contentW * 0.6
            local sliderW = contentW * 0.3
            local sliderH = 8 * scale
            local sliderY = y + (settingH - sliderH) / 2

            dxDrawRectangle(sliderX, sliderY, sliderW, sliderH, tocolor(50, 55, 65, panelAlpha))
            dxDrawRectangle(sliderX, sliderY, sliderW * (value / 100), sliderH, tocolor(41, 128, 185, panelAlpha))

            -- Value text
            dxDrawText(tostring(value), sliderX + sliderW + 10, y, contentX + contentW - 10, y + settingH,
                tocolor(150, 150, 150, panelAlpha), 0.85 * scale, "default-bold", "left", "center")
        end
    end

    -- Close button
    local closeX = panelX + panelW - 35 * scale
    local closeY = panelY + 10 * scale
    dxDrawRectangle(closeX, closeY, 25 * scale, 25 * scale, tocolor(231, 76, 60, panelAlpha * 0.8))
    dxDrawText("X", closeX, closeY, closeX + 25 * scale, closeY + 25 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.0 * scale, "default-bold", "center", "center")

    -- Instructions
    dxDrawText("Click toggles to change | Press ESC to close and save", panelX, panelY + panelH + 5, panelX + panelW, panelY + panelH + 25 * scale,
        tocolor(120, 130, 140, panelAlpha * 0.7), 0.75 * scale, "default", "center", "center")
end

function handleSettingsClick(button, state, absX, absY)
    if button ~= "left" or state ~= "down" or not settingsOpen then return end

    local panelW = 600 * scale
    local panelH = 500 * scale
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Close button
    local closeX = panelX + panelW - 35 * scale
    local closeY = panelY + 10 * scale
    if absX >= closeX and absX <= closeX + 25 * scale and absY >= closeY and absY <= closeY + 25 * scale then
        closeSettings()
        return
    end

    -- Category tabs
    local tabW = panelW / #categories
    local tabY = panelY + 60 * scale
    local tabH = 35 * scale

    for i = 1, #categories do
        local tabX = panelX + (i - 1) * tabW
        if absX >= tabX and absX <= tabX + tabW and absY >= tabY and absY <= tabY + tabH then
            currentCategory = i
            playSoundFrontEnd(37)
            return
        end
    end

    -- Settings toggles
    local contentX = panelX + 20 * scale
    local contentY = tabY + tabH + 20 * scale
    local contentW = panelW - 40 * scale
    local settingH = 40 * scale

    local cat = categories[currentCategory]
    for i, settingKey in ipairs(cat.settings) do
        local y = contentY + (i - 1) * (settingH + 5)
        local value = mySettings[settingKey]

        if type(value) == "boolean" then
            local toggleX = contentX + contentW - 70 * scale
            local toggleW = 50 * scale
            local toggleH = 24 * scale
            local toggleY = y + (settingH - toggleH) / 2

            if absX >= toggleX and absX <= toggleX + toggleW and absY >= toggleY and absY <= toggleY + toggleH then
                mySettings[settingKey] = not value
                applySetting(settingKey, mySettings[settingKey])
                playSoundFrontEnd(37)
                return
            end
        end
    end
end

function handleSettingsKey(button, press)
    if not press then return end

    if button == "escape" and settingsOpen then
        closeSettings()
    end

    if button == "F10" then
        if settingsOpen then
            closeSettings()
        else
            openSettings()
        end
    end
end

-- ============================================
-- SETTINGS APPLICATION
-- ============================================

function applySetting(key, value)
    -- Apply setting to relevant system
    if key == "hud" then
        -- Toggle HUD
        triggerEvent("jebiga:hud:toggle", localPlayer, value)
    elseif key == "speedometer" then
        -- Toggle speedometer
    elseif key == "nametags" then
        -- Toggle nametags
        if exports.jebiga_nametags then
            exports.jebiga_nametags:setNametagsEnabled(value)
        end
    elseif key == "sounds" then
        -- Toggle sounds
    elseif key == "music" then
        -- Toggle music
    end
end

function saveSettings()
    triggerServerEvent("jebiga:settings:save", localPlayer, mySettings)
end

function loadSettings()
    triggerServerEvent("jebiga:settings:load", localPlayer)
end

-- ============================================
-- EVENTS
-- ============================================

addEventHandler("onClientRender", root, renderSettings)
addEventHandler("onClientClick", root, handleSettingsClick)
addEventHandler("onClientKey", root, handleSettingsKey)

addEvent("jebiga:settings:sync", true)
addEventHandler("jebiga:settings:sync", root, function(settings)
    mySettings = settings
    -- Apply all settings
    for key, value in pairs(settings) do
        applySetting(key, value)
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Load defaults first
    for k, v in pairs(DefaultSettings) do
        mySettings[k] = v
    end
    -- Then request saved settings
    loadSettings()
end)

-- ============================================
-- COMMANDS
-- ============================================

addCommandHandler("settings", function()
    if settingsOpen then
        closeSettings()
    else
        openSettings()
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

function getSetting(key)
    return mySettings[key]
end

function setSetting(key, value)
    mySettings[key] = value
    applySetting(key, value)
end
