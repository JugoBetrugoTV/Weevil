--[[
    Jebiga Multi-Gamemode - Custom Nametags
    Beautiful 3D nametags with health bars and clan tags
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- Settings
local settings = {
    enabled = true,
    showHealth = true,
    showClan = true,
    showDistance = true,
    maxDistance = 100,
    fadeDistance = 80
}

-- ============================================
-- NAMETAG RENDERING
-- ============================================

function renderNametags()
    if not settings.enabled then return end

    local camX, camY, camZ = getCameraMatrix()

    for _, player in ipairs(getElementsByType("player")) do
        if player ~= localPlayer and isElementOnScreen(player) and not isElementInWater(player) then
            renderPlayerNametag(player, camX, camY, camZ)
        end
    end
end

function renderPlayerNametag(player, camX, camY, camZ)
    local px, py, pz = getElementPosition(player)

    -- Add height offset
    local dim = getElementBoundingBox(player)
    pz = pz + 1.2

    -- Calculate distance
    local distance = getDistanceBetweenPoints3D(camX, camY, camZ, px, py, pz)

    if distance > settings.maxDistance then return end

    -- Check line of sight
    if not isLineOfSightClear(camX, camY, camZ, px, py, pz, true, false, false, true, false) then
        return
    end

    -- Get screen position
    local sx, sy = getScreenFromWorldPosition(px, py, pz, 0.08)
    if not sx then return end

    -- Calculate alpha based on distance
    local alpha = 255
    if distance > settings.fadeDistance then
        alpha = 255 * (1 - (distance - settings.fadeDistance) / (settings.maxDistance - settings.fadeDistance))
    end
    alpha = math.max(0, math.min(255, alpha))

    -- Scale based on distance
    local distScale = 1 - (distance / settings.maxDistance) * 0.5
    distScale = math.max(0.5, distScale)

    -- Player info
    local name = getPlayerName(player)
    local health = getElementHealth(player)
    local armor = getPedArmor(player)
    local team = getPlayerTeam(player)
    local clanTag = getElementData(player, "jebiga:clanTag")

    -- Team color
    local r, g, b = 255, 255, 255
    if team then
        r, g, b = getTeamColor(team)
    end

    -- Build display name
    local displayName = name
    if settings.showClan and clanTag and clanTag ~= "" then
        displayName = "[" .. clanTag .. "] " .. name
    end

    -- Dimensions
    local textScale = 0.9 * scale * distScale
    local barW = 80 * scale * distScale
    local barH = 6 * scale * distScale
    local spacing = 4 * scale * distScale

    -- Calculate total height
    local totalH = 20 * scale * distScale
    if settings.showHealth then
        totalH = totalH + barH + spacing
        if armor > 0 then
            totalH = totalH + barH + spacing
        end
    end

    local startY = sy - totalH / 2

    -- Background
    local bgW = barW + 20 * scale * distScale
    local bgH = totalH + 10 * scale * distScale
    dxDrawRectangle(sx - bgW/2, startY - 5 * scale * distScale, bgW, bgH,
        tocolor(0, 0, 0, alpha * 0.4))

    -- Name
    dxDrawText(displayName, sx - 200, startY, sx + 200, startY + 18 * scale * distScale,
        tocolor(r, g, b, alpha), textScale, "default-bold", "center", "center", false, false, false)

    -- Health bar
    if settings.showHealth then
        local healthY = startY + 20 * scale * distScale

        -- Health background
        dxDrawRectangle(sx - barW/2, healthY, barW, barH, tocolor(40, 40, 40, alpha * 0.8))

        -- Health fill
        local healthPercent = math.max(0, health / 100)
        local healthColor = getHealthColor(healthPercent)
        dxDrawRectangle(sx - barW/2, healthY, barW * healthPercent, barH,
            tocolor(healthColor[1], healthColor[2], healthColor[3], alpha))

        -- Armor bar (if any)
        if armor > 0 then
            local armorY = healthY + barH + spacing
            dxDrawRectangle(sx - barW/2, armorY, barW, barH, tocolor(40, 40, 40, alpha * 0.8))
            dxDrawRectangle(sx - barW/2, armorY, barW * (armor / 100), barH,
                tocolor(100, 150, 255, alpha))
        end
    end

    -- Distance text
    if settings.showDistance and distance > 20 then
        local distText = math.floor(distance) .. "m"
        dxDrawText(distText, sx - 50, startY + totalH, sx + 50, startY + totalH + 15 * scale * distScale,
            tocolor(150, 150, 150, alpha * 0.7), 0.7 * scale * distScale, "default", "center", "top")
    end
end

function getHealthColor(percent)
    if percent > 0.6 then
        return {46, 204, 113}
    elseif percent > 0.3 then
        return {241, 196, 15}
    else
        return {231, 76, 60}
    end
end

-- ============================================
-- VEHICLE NAMETAGS
-- ============================================

function renderVehicleNametags()
    if not settings.enabled then return end

    local camX, camY, camZ = getCameraMatrix()

    for _, vehicle in ipairs(getElementsByType("vehicle")) do
        local driver = getVehicleOccupant(vehicle, 0)
        if driver and driver ~= localPlayer then
            renderVehicleNametag(vehicle, driver, camX, camY, camZ)
        end
    end
end

function renderVehicleNametag(vehicle, driver, camX, camY, camZ)
    local vx, vy, vz = getElementPosition(vehicle)
    vz = vz + 1.5

    local distance = getDistanceBetweenPoints3D(camX, camY, camZ, vx, vy, vz)
    if distance > settings.maxDistance then return end

    local sx, sy = getScreenFromWorldPosition(vx, vy, vz, 0.08)
    if not sx then return end

    local alpha = 255
    if distance > settings.fadeDistance then
        alpha = 255 * (1 - (distance - settings.fadeDistance) / (settings.maxDistance - settings.fadeDistance))
    end

    local name = getPlayerName(driver)
    local clanTag = getElementData(driver, "jebiga:clanTag")

    local displayName = name
    if settings.showClan and clanTag and clanTag ~= "" then
        displayName = "[" .. clanTag .. "] " .. name
    end

    local team = getPlayerTeam(driver)
    local r, g, b = 255, 255, 255
    if team then r, g, b = getTeamColor(team) end

    local distScale = 1 - (distance / settings.maxDistance) * 0.5

    -- Vehicle health
    local vehHealth = getElementHealth(vehicle) / 10

    -- Draw name
    dxDrawText(displayName, sx - 150, sy - 30, sx + 150, sy,
        tocolor(r, g, b, alpha), 0.9 * scale * distScale, "default-bold", "center", "center", false, false, false)

    -- Vehicle health bar
    local barW = 60 * scale * distScale
    local barH = 4 * scale * distScale
    dxDrawRectangle(sx - barW/2, sy + 5, barW, barH, tocolor(40, 40, 40, alpha * 0.7))

    local healthColor = getHealthColor(vehHealth / 100)
    dxDrawRectangle(sx - barW/2, sy + 5, barW * (vehHealth / 100), barH,
        tocolor(healthColor[1], healthColor[2], healthColor[3], alpha))
end

-- ============================================
-- EVENTS
-- ============================================

addEventHandler("onClientRender", root, function()
    renderNametags()
end)

-- Settings sync
addEvent("jebiga:nametags:settings", true)
addEventHandler("jebiga:nametags:settings", root, function(newSettings)
    for k, v in pairs(newSettings) do
        settings[k] = v
    end
end)

-- ============================================
-- COMMANDS
-- ============================================

addCommandHandler("nametags", function()
    settings.enabled = not settings.enabled
    outputChatBox("#2980B9[NAMETAGS] #FFFFFF" .. (settings.enabled and "Enabled" or "Disabled"), 255, 255, 255, true)
end)

addCommandHandler("nametaghealth", function()
    settings.showHealth = not settings.showHealth
    outputChatBox("#2980B9[NAMETAGS] #FFFFFFHealth bars " .. (settings.showHealth and "enabled" or "disabled"), 255, 255, 255, true)
end)

-- ============================================
-- DISABLE DEFAULT NAMETAGS
-- ============================================

addEventHandler("onClientResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        setPlayerNametagShowing(player, false)
    end
end)

addEventHandler("onClientPlayerJoin", root, function()
    setPlayerNametagShowing(source, false)
end)

-- ============================================
-- EXPORTS
-- ============================================

function setNametagsEnabled(enabled)
    settings.enabled = enabled
end

function setNametagSetting(key, value)
    settings[key] = value
end
