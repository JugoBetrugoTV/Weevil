--[[
    Jebiga Multi-Gamemode - Music/Radio System
    Inspired by Vultaic MGM
    Features: Custom radio stations, music player, volume control
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- Music state
local musicOpen = false
local panelAlpha = 0
local currentStation = 0
local currentSound = nil
local volume = 0.5
local isPlaying = false

-- Radio stations
local stations = {
    {
        name = "Jebiga Radio",
        url = "",  -- Can be set by server
        genre = "Mixed",
        icon = "📻"
    },
    {
        name = "Radio Los Santos",
        id = 1,  -- GTA radio ID
        genre = "Hip-Hop",
        icon = "🎤"
    },
    {
        name = "K-DST",
        id = 2,
        genre = "Rock",
        icon = "🎸"
    },
    {
        name = "Bounce FM",
        id = 3,
        genre = "Funk",
        icon = "🪩"
    },
    {
        name = "SF-UR",
        id = 4,
        genre = "House",
        icon = "🎧"
    },
    {
        name = "Radio X",
        id = 5,
        genre = "Alternative",
        icon = "🎵"
    },
    {
        name = "CSR",
        id = 6,
        genre = "Soul",
        icon = "💜"
    },
    {
        name = "K-JAH West",
        id = 7,
        genre = "Reggae",
        icon = "🌴"
    },
    {
        name = "Master Sounds",
        id = 8,
        genre = "Rare Groove",
        icon = "🎺"
    },
    {
        name = "WCTR",
        id = 9,
        genre = "Talk Radio",
        icon = "🗣️"
    },
    {
        name = "Radio Off",
        id = 0,
        genre = "None",
        icon = "🔇"
    }
}

-- ============================================
-- MUSIC GUI
-- ============================================

function openMusic()
    musicOpen = true
    showCursor(true)
end

function closeMusic()
    musicOpen = false
    showCursor(false)
end

function renderMusic()
    if not musicOpen then
        if panelAlpha > 0 then panelAlpha = panelAlpha - 20 end
        if panelAlpha <= 0 then return end
    else
        if panelAlpha < 255 then panelAlpha = panelAlpha + 20 end
    end

    local panelW = 400 * scale
    local panelH = 550 * scale
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Main background
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(15, 17, 23, panelAlpha * 0.97))

    -- Header with gradient
    dxDrawRectangle(panelX, panelY, panelW, 70 * scale, tocolor(25, 28, 35, panelAlpha))
    dxDrawRectangle(panelX, panelY + 67 * scale, panelW, 3, tocolor(155, 89, 182, panelAlpha))

    dxDrawText("🎵 MUSIC PLAYER", panelX, panelY, panelX + panelW, panelY + 70 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.4 * scale, "default-bold", "center", "center")

    -- Now playing section
    local npY = panelY + 85 * scale
    dxDrawRectangle(panelX + 15, npY, panelW - 30, 80 * scale, tocolor(30, 33, 42, panelAlpha * 0.9))

    local currentStationData = stations[currentStation] or { name = "None", genre = "N/A", icon = "🔇" }
    dxDrawText("NOW PLAYING", panelX + 25, npY + 8, panelX + panelW - 25, npY + 28 * scale,
        tocolor(150, 150, 150, panelAlpha), 0.75 * scale, "default", "left", "center")

    dxDrawText(currentStationData.icon .. " " .. currentStationData.name, panelX + 25, npY + 30, panelX + panelW - 25, npY + 55 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.1 * scale, "default-bold", "left", "center")

    dxDrawText(currentStationData.genre, panelX + 25, npY + 55, panelX + panelW - 25, npY + 75 * scale,
        tocolor(155, 89, 182, panelAlpha), 0.85 * scale, "default", "left", "center")

    -- Volume control
    local volY = npY + 95 * scale
    dxDrawText("VOLUME", panelX + 15, volY, panelX + 70, volY + 20 * scale,
        tocolor(150, 150, 150, panelAlpha), 0.8 * scale, "default", "left", "center")

    local volBarX = panelX + 80
    local volBarW = panelW - 110
    local volBarH = 12 * scale

    dxDrawRectangle(volBarX, volY + 4, volBarW, volBarH, tocolor(40, 45, 55, panelAlpha))
    dxDrawRectangle(volBarX, volY + 4, volBarW * volume, volBarH, tocolor(155, 89, 182, panelAlpha))

    -- Volume percentage
    dxDrawText(math.floor(volume * 100) .. "%", panelX + panelW - 50, volY, panelX + panelW - 15, volY + 20 * scale,
        tocolor(255, 255, 255, panelAlpha), 0.8 * scale, "default", "right", "center")

    -- Station list
    local listY = volY + 35 * scale
    dxDrawText("STATIONS", panelX + 15, listY, panelX + panelW - 15, listY + 25 * scale,
        tocolor(150, 150, 150, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

    local stationH = 40 * scale
    local stationStartY = listY + 30 * scale

    for i, station in ipairs(stations) do
        local y = stationStartY + (i - 1) * (stationH + 3)
        if y + stationH > panelY + panelH - 60 * scale then break end

        local isSelected = currentStation == i
        local bgColor = isSelected and tocolor(155, 89, 182, panelAlpha * 0.4) or tocolor(30, 33, 42, panelAlpha * 0.6)

        dxDrawRectangle(panelX + 15, y, panelW - 30, stationH, bgColor)

        -- Station icon and name
        dxDrawText(station.icon, panelX + 25, y, panelX + 55, y + stationH,
            tocolor(255, 255, 255, panelAlpha), 1.2 * scale, "default", "center", "center")

        dxDrawText(station.name, panelX + 60, y, panelX + panelW - 100, y + stationH,
            tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

        -- Genre tag
        dxDrawText(station.genre, panelX + panelW - 100, y, panelX + panelW - 25, y + stationH,
            tocolor(120, 130, 140, panelAlpha), 0.75 * scale, "default", "right", "center")

        -- Selection indicator
        if isSelected then
            dxDrawRectangle(panelX + 15, y, 3, stationH, tocolor(155, 89, 182, panelAlpha))
        end
    end

    -- Close button
    local closeX = panelX + panelW - 35 * scale
    local closeY = panelY + 10 * scale
    dxDrawRectangle(closeX, closeY, 25 * scale, 25 * scale, tocolor(231, 76, 60, panelAlpha * 0.8))
    dxDrawText("X", closeX, closeY, closeX + 25 * scale, closeY + 25 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.0 * scale, "default-bold", "center", "center")

    -- Instructions
    dxDrawText("Click a station to play | Scroll to adjust volume", panelX, panelY + panelH + 5, panelX + panelW, panelY + panelH + 25 * scale,
        tocolor(150, 150, 150, panelAlpha * 0.7), 0.7 * scale, "default", "center", "center")
end

-- ============================================
-- INPUT HANDLING
-- ============================================

function handleMusicClick(button, state, absX, absY)
    if not musicOpen then return end
    if button ~= "left" or state ~= "down" then return end

    local panelW = 400 * scale
    local panelH = 550 * scale
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Close button
    local closeX = panelX + panelW - 35 * scale
    local closeY = panelY + 10 * scale
    if absX >= closeX and absX <= closeX + 25 * scale and absY >= closeY and absY <= closeY + 25 * scale then
        closeMusic()
        playSoundFrontEnd(39)
        return
    end

    -- Volume bar click
    local npY = panelY + 85 * scale
    local volY = npY + 95 * scale
    local volBarX = panelX + 80
    local volBarW = panelW - 110
    local volBarH = 12 * scale

    if absX >= volBarX and absX <= volBarX + volBarW and absY >= volY and absY <= volY + 20 * scale then
        volume = math.max(0, math.min(1, (absX - volBarX) / volBarW))
        applyVolume()
        return
    end

    -- Station clicks
    local listY = volY + 35 * scale
    local stationH = 40 * scale
    local stationStartY = listY + 30 * scale

    for i, station in ipairs(stations) do
        local y = stationStartY + (i - 1) * (stationH + 3)
        if y + stationH > panelY + panelH - 60 * scale then break end

        if absX >= panelX + 15 and absX <= panelX + panelW - 15 and absY >= y and absY <= y + stationH then
            selectStation(i)
            playSoundFrontEnd(37)
            return
        end
    end
end

function handleMusicScroll(key)
    if not musicOpen then return end

    if key == "mouse_wheel_up" then
        volume = math.min(1, volume + 0.05)
        applyVolume()
    elseif key == "mouse_wheel_down" then
        volume = math.max(0, volume - 0.05)
        applyVolume()
    end
end

function handleMusicKey(button, press)
    if not press then return end

    if button == "escape" and musicOpen then
        closeMusic()
    end
end

-- ============================================
-- MUSIC CONTROL
-- ============================================

function selectStation(index)
    currentStation = index
    local station = stations[index]

    if not station then return end

    -- Stop current sound
    if isElement(currentSound) then
        destroyElement(currentSound)
        currentSound = nil
    end

    -- Handle different station types
    if station.url and station.url ~= "" then
        -- Stream URL
        currentSound = playSound(station.url, false)
        if currentSound then
            setSoundVolume(currentSound, volume)
        end
        isPlaying = true
    elseif station.id and station.id > 0 then
        -- In-vehicle radio
        local vehicle = getPedOccupiedVehicle(localPlayer)
        if vehicle then
            setRadioChannel(station.id)
        end
        isPlaying = true
    else
        -- Radio off
        setRadioChannel(0)
        isPlaying = false
    end

    exports.jebiga_core:showNotification("Now playing: " .. station.name, "info")
end

function applyVolume()
    if isElement(currentSound) then
        setSoundVolume(currentSound, volume)
    end

    -- Also apply to in-game radio (simplified)
    -- Note: MTA doesn't have direct radio volume control
end

function stopMusic()
    if isElement(currentSound) then
        destroyElement(currentSound)
        currentSound = nil
    end
    setRadioChannel(0)
    isPlaying = false
    currentStation = #stations -- "Radio Off"
end

-- ============================================
-- MINI PLAYER (always visible)
-- ============================================

function renderMiniPlayer()
    if musicOpen then return end -- Don't show when full player is open
    if currentStation == 0 or currentStation == #stations then return end -- No station selected

    local station = stations[currentStation]
    if not station then return end

    local miniW = 200 * scale
    local miniH = 35 * scale
    local miniX = screenW - miniW - 20 * scale
    local miniY = 140 * scale

    -- Background
    dxDrawRectangle(miniX, miniY, miniW, miniH, tocolor(20, 22, 30, 200))
    dxDrawRectangle(miniX, miniY, 3, miniH, tocolor(155, 89, 182, 255))

    -- Icon and station name
    dxDrawText(station.icon, miniX + 10, miniY, miniX + 35, miniY + miniH,
        tocolor(255, 255, 255, 220), 1.0 * scale, "default", "center", "center")

    dxDrawText(station.name, miniX + 40, miniY, miniX + miniW - 10, miniY + miniH,
        tocolor(255, 255, 255, 200), 0.75 * scale, "default-bold", "left", "center")
end

-- ============================================
-- EVENTS
-- ============================================

addEventHandler("onClientRender", root, function()
    renderMusic()
    renderMiniPlayer()
end)

addEventHandler("onClientClick", root, handleMusicClick)
addEventHandler("onClientKey", root, handleMusicKey)

bindKey("mouse_wheel_up", "down", handleMusicScroll)
bindKey("mouse_wheel_down", "down", handleMusicScroll)

-- Server can set custom station URLs
addEvent("jebiga:music:setStation", true)
addEventHandler("jebiga:music:setStation", root, function(index, url, name)
    if stations[index] then
        stations[index].url = url
        if name then stations[index].name = name end
    end
end)

-- ============================================
-- COMMANDS & KEYBINDS
-- ============================================

addCommandHandler("music", function()
    if musicOpen then
        closeMusic()
    else
        openMusic()
    end
end)

addCommandHandler("radio", function()
    if musicOpen then
        closeMusic()
    else
        openMusic()
    end
end)

bindKey("F8", "down", function()
    if musicOpen then
        closeMusic()
    else
        openMusic()
    end
end)

-- M key to toggle music on/off (quick toggle without panel)
bindKey("m", "down", function()
    if isPlaying then
        stopMusic()
        exports.jebiga_core:showNotification("Music OFF", "info")
    else
        -- Resume last station or play first one
        if currentStation == 0 or currentStation == #stations then
            selectStation(1)
        else
            selectStation(currentStation)
        end
    end
end)

-- Quick volume commands
addCommandHandler("vol", function(cmd, vol)
    vol = tonumber(vol)
    if vol then
        volume = math.max(0, math.min(100, vol)) / 100
        applyVolume()
        outputChatBox("#9B59B6[MUSIC] #FFFFFFVolume set to " .. math.floor(volume * 100) .. "%", 255, 255, 255, true)
    else
        outputChatBox("#9B59B6[MUSIC] #FFFFFFCurrent volume: " .. math.floor(volume * 100) .. "%", 255, 255, 255, true)
    end
end)
