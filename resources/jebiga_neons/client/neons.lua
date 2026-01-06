--[[
    Jebiga Multi-Gamemode - Vehicle Neon System
    Inspired by Vultaic MGM
    Features: Customizable neon lights under vehicles
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- Neon configurations
local neonColors = {
    { name = "Red", color = {255, 0, 0} },
    { name = "Blue", color = {0, 100, 255} },
    { name = "Green", color = {0, 255, 0} },
    { name = "Purple", color = {155, 0, 255} },
    { name = "Yellow", color = {255, 255, 0} },
    { name = "Orange", color = {255, 140, 0} },
    { name = "Pink", color = {255, 20, 147} },
    { name = "Cyan", color = {0, 255, 255} },
    { name = "White", color = {255, 255, 255} },
    { name = "Rainbow", color = "rainbow" }
}

-- Active neons table
local activeNeons = {}
local rainbowHue = 0

-- Neon settings
local neonSettings = {
    intensity = 2.0,
    size = 1.5,
    height = -0.5,
    pulseEnabled = false,
    pulseSpeed = 2
}

-- ============================================
-- NEON RENDERING
-- ============================================

function renderNeons()
    rainbowHue = rainbowHue + 0.5
    if rainbowHue >= 360 then rainbowHue = 0 end

    for vehicle, neonData in pairs(activeNeons) do
        if isElement(vehicle) and getElementType(vehicle) == "vehicle" then
            local vx, vy, vz = getElementPosition(vehicle)
            local _, _, rz = getElementRotation(vehicle)

            -- Get vehicle dimensions
            local minX, minY, minZ, maxX, maxY, maxZ = getElementBoundingBox(vehicle)
            local vehWidth = (maxX - minX) * 0.9
            local vehLength = (maxY - minY) * 0.9

            -- Calculate neon color
            local r, g, b
            if neonData.color == "rainbow" then
                r, g, b = hsvToRgb(rainbowHue, 1, 1)
            else
                r, g, b = unpack(neonData.color)
            end

            -- Apply pulse effect
            local intensity = neonSettings.intensity
            if neonSettings.pulseEnabled then
                local pulse = math.sin(getTickCount() / 1000 * neonSettings.pulseSpeed * math.pi) * 0.5 + 0.5
                intensity = intensity * (0.5 + pulse * 0.5)
            end

            -- Calculate corner positions based on vehicle rotation
            local rad = math.rad(rz)
            local cos = math.cos(rad)
            local sin = math.sin(rad)

            local hw = vehWidth / 2
            local hl = vehLength / 2
            local neonZ = vz + neonSettings.height

            -- Front left
            local fl_x = vx + cos * hl - sin * (-hw)
            local fl_y = vy + sin * hl + cos * (-hw)

            -- Front right
            local fr_x = vx + cos * hl - sin * hw
            local fr_y = vy + sin * hl + cos * hw

            -- Back left
            local bl_x = vx + cos * (-hl) - sin * (-hw)
            local bl_y = vy + sin * (-hl) + cos * (-hw)

            -- Back right
            local br_x = vx + cos * (-hl) - sin * hw
            local br_y = vy + sin * (-hl) + cos * hw

            -- Draw neon lights (coronas)
            local neonSize = neonSettings.size

            -- Front neon
            drawNeonLine(fl_x, fl_y, neonZ, fr_x, fr_y, neonZ, r, g, b, neonSize, intensity)

            -- Back neon
            drawNeonLine(bl_x, bl_y, neonZ, br_x, br_y, neonZ, r, g, b, neonSize, intensity)

            -- Left side neon
            drawNeonLine(fl_x, fl_y, neonZ, bl_x, bl_y, neonZ, r, g, b, neonSize, intensity)

            -- Right side neon
            drawNeonLine(fr_x, fr_y, neonZ, br_x, br_y, neonZ, r, g, b, neonSize, intensity)

        else
            -- Vehicle no longer exists
            activeNeons[vehicle] = nil
        end
    end
end

function drawNeonLine(x1, y1, z1, x2, y2, z2, r, g, b, size, intensity)
    local distance = getDistanceBetweenPoints3D(x1, y1, z1, x2, y2, z2)
    local segments = math.max(3, math.floor(distance / 0.3))

    for i = 0, segments do
        local t = i / segments
        local px = x1 + (x2 - x1) * t
        local py = y1 + (y2 - y1) * t
        local pz = z1 + (z2 - z1) * t

        -- Draw corona/light using 3D markers for glow effect
        local camX, camY, camZ = getCameraMatrix()
        local dist = getDistanceBetweenPoints3D(camX, camY, camZ, px, py, pz)

        if dist < 50 then -- Only render nearby neons
            -- Create light effect using corona marker
            local alpha = math.min(255, (80 * intensity) * (1 - dist / 50))

            -- Draw 3D light marker
            dxDrawMaterialLine3D(px, py, pz, px, py, pz + 0.01, nil, size * 0.3,
                tocolor(r, g, b, alpha), px, py, pz + 1)

            -- Screen-space glow
            local sx, sy = getScreenFromWorldPosition(px, py, pz, 10)
            if sx then
                local screenSize = (size * 30) / (dist * 0.3)
                -- Draw multiple layers for glow effect
                for j = 4, 1, -1 do
                    local glowSize = screenSize * j * 0.5
                    local glowAlpha = (60 / j) * intensity * (1 - dist / 50)
                    -- Draw circle approximation using rectangles
                    drawGlowCircle(sx, sy, glowSize, r, g, b, glowAlpha)
                end
            end
        end
    end
end

-- Draw a soft glow circle using rectangles
function drawGlowCircle(cx, cy, radius, r, g, b, alpha)
    local segments = 12
    for i = 1, segments do
        local angle = (i / segments) * math.pi * 2
        local nextAngle = ((i + 1) / segments) * math.pi * 2

        local x1 = cx + math.cos(angle) * radius * 0.7
        local y1 = cy + math.sin(angle) * radius * 0.7
        local x2 = cx + math.cos(nextAngle) * radius * 0.7
        local y2 = cy + math.sin(nextAngle) * radius * 0.7

        dxDrawLine(x1, y1, x2, y2, tocolor(r, g, b, alpha * 0.8), radius * 0.3)
    end
    -- Center glow
    dxDrawRectangle(cx - radius * 0.15, cy - radius * 0.15, radius * 0.3, radius * 0.3,
        tocolor(r, g, b, alpha * 0.5))
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function hsvToRgb(h, s, v)
    local r, g, b
    local i = math.floor(h / 60) % 6
    local f = h / 60 - math.floor(h / 60)
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

-- ============================================
-- NEON GUI
-- ============================================

local guiVisible = false
local selectedColor = 1
local panelAlpha = 0

function showNeonGUI()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then
        exports.jebiga_core:showNotification("You must be in a vehicle!", "error")
        return
    end

    guiVisible = true
end

function hideNeonGUI()
    guiVisible = false
end

function renderNeonGUI()
    if not guiVisible then
        if panelAlpha > 0 then
            panelAlpha = panelAlpha - 15
        end
    else
        if panelAlpha < 255 then
            panelAlpha = panelAlpha + 15
        end
    end

    if panelAlpha <= 0 then return end

    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then
        guiVisible = false
        return
    end

    local panelW = 350 * scale
    local panelH = 450 * scale
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Background
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(20, 22, 30, panelAlpha * 0.95))

    -- Header
    dxDrawRectangle(panelX, panelY, panelW, 50 * scale, tocolor(41, 128, 185, panelAlpha * 0.8))
    dxDrawText("NEON LIGHTS", panelX, panelY, panelX + panelW, panelY + 50 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.3 * scale, "default-bold", "center", "center")

    -- Color selection
    local startY = panelY + 70 * scale
    local colorH = 35 * scale
    local padding = 15 * scale

    for i, colorData in ipairs(neonColors) do
        local y = startY + (i - 1) * (colorH + 5)
        local isSelected = selectedColor == i
        local hasNeon = activeNeons[vehicle] and
            ((type(activeNeons[vehicle].color) == "string" and activeNeons[vehicle].color == colorData.color) or
             (type(activeNeons[vehicle].color) == "table" and type(colorData.color) == "table" and
              activeNeons[vehicle].color[1] == colorData.color[1]))

        -- Button background
        local bgColor = isSelected and tocolor(50, 55, 70, panelAlpha) or tocolor(35, 40, 50, panelAlpha)
        dxDrawRectangle(panelX + padding, y, panelW - padding * 2, colorH, bgColor)

        -- Color preview
        if colorData.color == "rainbow" then
            local r, g, b = hsvToRgb(rainbowHue, 1, 1)
            dxDrawRectangle(panelX + padding + 5, y + 5, 25 * scale, colorH - 10, tocolor(r, g, b, panelAlpha))
        else
            dxDrawRectangle(panelX + padding + 5, y + 5, 25 * scale, colorH - 10,
                tocolor(colorData.color[1], colorData.color[2], colorData.color[3], panelAlpha))
        end

        -- Color name
        dxDrawText(colorData.name, panelX + padding + 40 * scale, y, panelX + panelW - padding, y + colorH,
            tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

        -- Active indicator
        if hasNeon then
            dxDrawText("ACTIVE", panelX + panelW - padding - 60 * scale, y, panelX + panelW - padding - 10, y + colorH,
                tocolor(46, 204, 113, panelAlpha), 0.8 * scale, "default-bold", "right", "center")
        end

        -- Selection highlight
        if isSelected then
            dxDrawRectangle(panelX + padding, y, 3, colorH, tocolor(41, 128, 185, panelAlpha))
        end
    end

    -- Bottom buttons
    local btnW = (panelW - padding * 3) / 2
    local btnH = 40 * scale
    local btnY = panelY + panelH - btnH - padding

    -- Apply button
    dxDrawRectangle(panelX + padding, btnY, btnW, btnH, tocolor(46, 204, 113, panelAlpha * 0.8))
    dxDrawText("APPLY", panelX + padding, btnY, panelX + padding + btnW, btnY + btnH,
        tocolor(255, 255, 255, panelAlpha), 1.0 * scale, "default-bold", "center", "center")

    -- Remove button
    dxDrawRectangle(panelX + padding * 2 + btnW, btnY, btnW, btnH, tocolor(231, 76, 60, panelAlpha * 0.8))
    dxDrawText("REMOVE", panelX + padding * 2 + btnW, btnY, panelX + padding * 2 + btnW * 2, btnY + btnH,
        tocolor(255, 255, 255, panelAlpha), 1.0 * scale, "default-bold", "center", "center")

    -- Instructions
    dxDrawText("Use ↑↓ to select, ENTER to apply, DELETE to remove", panelX, btnY - 25 * scale, panelX + panelW, btnY,
        tocolor(150, 150, 150, panelAlpha * 0.7), 0.7 * scale, "default", "center", "center")
end

-- ============================================
-- INPUT HANDLING
-- ============================================

function handleNeonInput(button, press)
    if not guiVisible or not press then return end

    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then return end

    if button == "arrow_u" then
        selectedColor = selectedColor - 1
        if selectedColor < 1 then selectedColor = #neonColors end
        playSoundFrontEnd(37)
    elseif button == "arrow_d" then
        selectedColor = selectedColor + 1
        if selectedColor > #neonColors then selectedColor = 1 end
        playSoundFrontEnd(37)
    elseif button == "enter" then
        applyNeon(vehicle, neonColors[selectedColor].color)
        playSoundFrontEnd(40)
    elseif button == "delete" then
        removeNeon(vehicle)
        playSoundFrontEnd(39)
    elseif button == "escape" or button == "backspace" then
        hideNeonGUI()
    end
end

function handleNeonClick(button, state, absX, absY)
    if button ~= "left" or state ~= "down" or not guiVisible then return end

    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then return end

    local panelW = 350 * scale
    local panelH = 450 * scale
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2
    local padding = 15 * scale
    local colorH = 35 * scale
    local startY = panelY + 70 * scale

    -- Check color clicks
    for i = 1, #neonColors do
        local y = startY + (i - 1) * (colorH + 5)
        if absX >= panelX + padding and absX <= panelX + panelW - padding and
           absY >= y and absY <= y + colorH then
            selectedColor = i
            playSoundFrontEnd(37)
            return
        end
    end

    -- Check button clicks
    local btnW = (panelW - padding * 3) / 2
    local btnH = 40 * scale
    local btnY = panelY + panelH - btnH - padding

    -- Apply button
    if absX >= panelX + padding and absX <= panelX + padding + btnW and
       absY >= btnY and absY <= btnY + btnH then
        applyNeon(vehicle, neonColors[selectedColor].color)
        playSoundFrontEnd(40)
        return
    end

    -- Remove button
    if absX >= panelX + padding * 2 + btnW and absX <= panelX + padding * 2 + btnW * 2 and
       absY >= btnY and absY <= btnY + btnH then
        removeNeon(vehicle)
        playSoundFrontEnd(39)
        return
    end
end

-- ============================================
-- NEON MANAGEMENT
-- ============================================

function applyNeon(vehicle, color)
    if not isElement(vehicle) then return end

    activeNeons[vehicle] = {
        color = color
    }

    -- Sync with server
    triggerServerEvent("jebiga:neon:apply", localPlayer, vehicle,
        type(color) == "table" and color or "rainbow")

    exports.jebiga_core:showNotification("Neon lights applied!", "success")
end

function removeNeon(vehicle)
    if not isElement(vehicle) then return end

    activeNeons[vehicle] = nil

    -- Sync with server
    triggerServerEvent("jebiga:neon:remove", localPlayer, vehicle)

    exports.jebiga_core:showNotification("Neon lights removed!", "info")
end

-- ============================================
-- EVENTS
-- ============================================

addEventHandler("onClientRender", root, function()
    renderNeons()
    renderNeonGUI()
end)

addEventHandler("onClientKey", root, handleNeonInput)
addEventHandler("onClientClick", root, handleNeonClick)

-- Sync neons from server
addEvent("jebiga:neon:sync", true)
addEventHandler("jebiga:neon:sync", root, function(vehicle, color)
    if isElement(vehicle) then
        activeNeons[vehicle] = { color = color }
    end
end)

-- Remove neon when vehicle is destroyed
addEventHandler("onClientElementDestroy", root, function()
    if getElementType(source) == "vehicle" then
        activeNeons[source] = nil
    end
end)

-- ============================================
-- COMMANDS & KEYBINDS
-- ============================================

addCommandHandler("neon", function()
    if guiVisible then
        hideNeonGUI()
    else
        showNeonGUI()
    end
end)

bindKey("n", "down", function()
    if guiVisible then
        hideNeonGUI()
    else
        showNeonGUI()
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

function setNeonColor(vehicle, r, g, b)
    if isElement(vehicle) then
        activeNeons[vehicle] = { color = {r, g, b} }
    end
end

function getNeonColor(vehicle)
    if activeNeons[vehicle] then
        return activeNeons[vehicle].color
    end
    return nil
end

function hasNeon(vehicle)
    return activeNeons[vehicle] ~= nil
end
