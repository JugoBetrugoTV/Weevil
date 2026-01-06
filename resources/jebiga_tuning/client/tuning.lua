--[[
    Jebiga Multi-Gamemode - Vehicle Tuning System
    Inspired by Vultaic MGM
    Features: Vehicle customization (paint, wheels, nitro, hydraulics)
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- Tuning state
local tuningOpen = false
local currentCategory = 1
local currentItem = 1
local panelAlpha = 0
local previewVehicle = nil

-- Tuning categories
local categories = {
    {
        name = "Paint",
        icon = "🎨",
        items = {
            { name = "Primary Color", type = "color", slot = 1 },
            { name = "Secondary Color", type = "color", slot = 2 },
            { name = "Pearl Color", type = "pearl" },
            { name = "Metallic", type = "metallic" }
        }
    },
    {
        name = "Wheels",
        icon = "🛞",
        items = {
            { name = "Shadow", id = 1073 },
            { name = "Mega", id = 1074 },
            { name = "Rimshine", id = 1075 },
            { name = "Wires", id = 1076 },
            { name = "Classic", id = 1077 },
            { name = "Twist", id = 1078 },
            { name = "Cutter", id = 1079 },
            { name = "Switch", id = 1080 },
            { name = "Grove", id = 1081 },
            { name = "Import", id = 1082 },
            { name = "Dollar", id = 1083 },
            { name = "Trance", id = 1084 },
            { name = "Atomic", id = 1085 },
            { name = "Ahab", id = 1096 },
            { name = "Virtual", id = 1097 },
            { name = "Access", id = 1098 }
        }
    },
    {
        name = "Nitro",
        icon = "💨",
        items = {
            { name = "2x Nitro", id = 1008 },
            { name = "5x Nitro", id = 1009 },
            { name = "10x Nitro", id = 1010 }
        }
    },
    {
        name = "Spoilers",
        icon = "🏎️",
        items = {
            { name = "Pro", id = 1000 },
            { name = "Win", id = 1001 },
            { name = "Drag", id = 1002 },
            { name = "Alpha", id = 1003 },
            { name = "Champ Scoop", id = 1004 },
            { name = "Fury", id = 1005 },
            { name = "X-Flow", id = 1014 },
            { name = "Alien", id = 1015 },
            { name = "Race", id = 1016 },
            { name = "Worx", id = 1017 }
        }
    },
    {
        name = "Exhaust",
        icon = "💨",
        items = {
            { name = "Alien", id = 1029 },
            { name = "X-Flow", id = 1028 },
            { name = "Large", id = 1018 },
            { name = "Medium", id = 1019 },
            { name = "Small", id = 1020 },
            { name = "Upswept", id = 1021 }
        }
    },
    {
        name = "Hood",
        icon = "🚗",
        items = {
            { name = "Champ Scoop", id = 1004 },
            { name = "Race Scoop", id = 1011 },
            { name = "Worx Scoop", id = 1012 }
        }
    },
    {
        name = "Hydraulics",
        icon = "⬆️",
        items = {
            { name = "Install Hydraulics", id = 1087 }
        }
    },
    {
        name = "Stereo",
        icon = "🔊",
        items = {
            { name = "Bass Boost", id = 1086 }
        }
    }
}

-- Color palette
local colorPalette = {
    -- Row 1: Reds
    {177, 25, 25}, {108, 10, 10}, {190, 50, 50}, {255, 60, 60}, {230, 80, 80},
    -- Row 2: Oranges/Yellows
    {255, 140, 0}, {255, 180, 0}, {255, 220, 0}, {255, 255, 0}, {200, 200, 0},
    -- Row 3: Greens
    {0, 100, 0}, {0, 150, 0}, {0, 200, 0}, {50, 255, 50}, {100, 255, 100},
    -- Row 4: Blues
    {0, 0, 100}, {0, 0, 180}, {0, 100, 255}, {0, 180, 255}, {100, 200, 255},
    -- Row 5: Purples
    {100, 0, 100}, {150, 0, 150}, {200, 0, 200}, {255, 0, 255}, {255, 100, 255},
    -- Row 6: Whites/Grays/Blacks
    {0, 0, 0}, {50, 50, 50}, {100, 100, 100}, {180, 180, 180}, {255, 255, 255}
}

local selectedColor = {255, 255, 255}

-- ============================================
-- TUNING GUI
-- ============================================

function openTuning()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then
        exports.jebiga_core:showNotification("You must be in a vehicle!", "error")
        return
    end

    tuningOpen = true
    showCursor(true)
    previewVehicle = vehicle
end

function closeTuning()
    tuningOpen = false
    showCursor(false)
    previewVehicle = nil
end

function renderTuning()
    if not tuningOpen then
        if panelAlpha > 0 then panelAlpha = panelAlpha - 20 end
        if panelAlpha <= 0 then return end
    else
        if panelAlpha < 255 then panelAlpha = panelAlpha + 20 end
    end

    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then
        closeTuning()
        return
    end

    local panelW = 700 * scale
    local panelH = 500 * scale
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Main background
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(15, 17, 23, panelAlpha * 0.97))

    -- Header
    dxDrawRectangle(panelX, panelY, panelW, 60 * scale, tocolor(25, 28, 35, panelAlpha))
    dxDrawRectangle(panelX, panelY + 60 * scale - 3, panelW, 3, tocolor(41, 128, 185, panelAlpha))
    dxDrawText("VEHICLE TUNING", panelX, panelY, panelX + panelW, panelY + 60 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.5 * scale, "default-bold", "center", "center")

    -- Categories panel (left side)
    local catX = panelX + 15 * scale
    local catY = panelY + 75 * scale
    local catW = 180 * scale
    local catH = panelH - 90 * scale

    dxDrawRectangle(catX, catY, catW, catH, tocolor(25, 28, 35, panelAlpha * 0.8))

    dxDrawText("CATEGORIES", catX, catY + 5, catX + catW, catY + 35 * scale,
        tocolor(150, 150, 150, panelAlpha), 0.9 * scale, "default-bold", "center", "center")

    local btnH = 40 * scale
    for i, cat in ipairs(categories) do
        local y = catY + 40 * scale + (i - 1) * (btnH + 5)
        local isSelected = currentCategory == i

        local bgColor = isSelected and tocolor(41, 128, 185, panelAlpha * 0.8) or tocolor(35, 40, 50, panelAlpha * 0.6)
        dxDrawRectangle(catX + 5, y, catW - 10, btnH, bgColor)

        dxDrawText(cat.icon .. " " .. cat.name, catX + 5, y, catX + catW - 5, y + btnH,
            tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default-bold", "center", "center")
    end

    -- Items panel (right side)
    local itemX = panelX + catW + 30 * scale
    local itemY = catY
    local itemW = panelW - catW - 45 * scale
    local itemH = catH

    dxDrawRectangle(itemX, itemY, itemW, itemH, tocolor(25, 28, 35, panelAlpha * 0.8))

    local currentCat = categories[currentCategory]
    dxDrawText(currentCat.name:upper() .. " OPTIONS", itemX, itemY + 5, itemX + itemW, itemY + 35 * scale,
        tocolor(150, 150, 150, panelAlpha), 0.9 * scale, "default-bold", "center", "center")

    -- Handle different item types
    if currentCat.items[1] and currentCat.items[1].type == "color" then
        -- Color picker mode
        renderColorPicker(itemX + 10, itemY + 45 * scale, itemW - 20, itemH - 100 * scale, panelAlpha)
    else
        -- Regular items list
        local itemBtnH = 35 * scale
        local startY = itemY + 45 * scale

        for i, item in ipairs(currentCat.items) do
            local y = startY + (i - 1) * (itemBtnH + 5)
            if y + itemBtnH > itemY + itemH - 60 * scale then break end

            local isSelected = currentItem == i
            local bgColor = isSelected and tocolor(46, 204, 113, panelAlpha * 0.6) or tocolor(40, 45, 55, panelAlpha * 0.6)
            dxDrawRectangle(itemX + 10, y, itemW - 20, itemBtnH, bgColor)

            dxDrawText(item.name, itemX + 20, y, itemX + itemW - 20, y + itemBtnH,
                tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

            -- Check if installed
            if item.id and vehicle then
                local upgrades = getVehicleUpgrades(vehicle)
                local isInstalled = false
                for _, upg in ipairs(upgrades or {}) do
                    if upg == item.id then isInstalled = true break end
                end
                if isInstalled then
                    dxDrawText("INSTALLED", itemX + 10, y, itemX + itemW - 20, y + itemBtnH,
                        tocolor(46, 204, 113, panelAlpha), 0.8 * scale, "default-bold", "right", "center")
                end
            end
        end

        -- Apply button
        local applyY = itemY + itemH - 50 * scale
        dxDrawRectangle(itemX + 10, applyY, itemW - 20, 40 * scale, tocolor(41, 128, 185, panelAlpha * 0.8))
        dxDrawText("APPLY UPGRADE", itemX + 10, applyY, itemX + itemW - 10, applyY + 40 * scale,
            tocolor(255, 255, 255, panelAlpha), 1.0 * scale, "default-bold", "center", "center")
    end

    -- Close button
    local closeX = panelX + panelW - 35 * scale
    local closeY = panelY + 10 * scale
    dxDrawRectangle(closeX, closeY, 25 * scale, 25 * scale, tocolor(231, 76, 60, panelAlpha * 0.8))
    dxDrawText("X", closeX, closeY, closeX + 25 * scale, closeY + 25 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.0 * scale, "default-bold", "center", "center")

    -- Instructions
    dxDrawText("Press ESC or click X to close", panelX, panelY + panelH + 5, panelX + panelW, panelY + panelH + 25 * scale,
        tocolor(150, 150, 150, panelAlpha * 0.7), 0.7 * scale, "default", "center", "center")
end

function renderColorPicker(x, y, w, h, alpha)
    local cellSize = w / 5
    local vehicle = getPedOccupiedVehicle(localPlayer)

    dxDrawText("Select a color:", x, y - 25 * scale, x + w, y,
        tocolor(200, 200, 200, alpha), 0.85 * scale, "default", "left", "center")

    for i, color in ipairs(colorPalette) do
        local row = math.floor((i - 1) / 5)
        local col = (i - 1) % 5
        local cx = x + col * cellSize + 5
        local cy = y + row * cellSize + 5
        local cs = cellSize - 10

        -- Color cell
        dxDrawRectangle(cx, cy, cs, cs, tocolor(color[1], color[2], color[3], alpha))

        -- Highlight if selected
        if selectedColor[1] == color[1] and selectedColor[2] == color[2] and selectedColor[3] == color[3] then
            dxDrawRectangle(cx - 2, cy - 2, cs + 4, 2, tocolor(255, 255, 255, alpha))
            dxDrawRectangle(cx - 2, cy + cs, cs + 4, 2, tocolor(255, 255, 255, alpha))
            dxDrawRectangle(cx - 2, cy, 2, cs, tocolor(255, 255, 255, alpha))
            dxDrawRectangle(cx + cs, cy, 2, cs, tocolor(255, 255, 255, alpha))
        end
    end

    -- Preview
    local previewY = y + h - 80 * scale
    dxDrawText("Preview:", x, previewY, x + w, previewY + 20 * scale,
        tocolor(200, 200, 200, alpha), 0.85 * scale, "default", "left", "center")

    dxDrawRectangle(x, previewY + 25 * scale, 60 * scale, 40 * scale,
        tocolor(selectedColor[1], selectedColor[2], selectedColor[3], alpha))

    -- Apply buttons
    local btnW = (w - 20) / 2
    dxDrawRectangle(x, previewY + 75 * scale, btnW, 35 * scale, tocolor(41, 128, 185, alpha * 0.8))
    dxDrawText("PRIMARY", x, previewY + 75 * scale, x + btnW, previewY + 110 * scale,
        tocolor(255, 255, 255, alpha), 0.9 * scale, "default-bold", "center", "center")

    dxDrawRectangle(x + btnW + 20, previewY + 75 * scale, btnW, 35 * scale, tocolor(155, 89, 182, alpha * 0.8))
    dxDrawText("SECONDARY", x + btnW + 20, previewY + 75 * scale, x + w, previewY + 110 * scale,
        tocolor(255, 255, 255, alpha), 0.9 * scale, "default-bold", "center", "center")
end

-- ============================================
-- INPUT HANDLING
-- ============================================

function handleTuningClick(button, state, absX, absY)
    if button ~= "left" or state ~= "down" or not tuningOpen then return end

    local panelW = 700 * scale
    local panelH = 500 * scale
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Close button
    local closeX = panelX + panelW - 35 * scale
    local closeY = panelY + 10 * scale
    if absX >= closeX and absX <= closeX + 25 * scale and absY >= closeY and absY <= closeY + 25 * scale then
        closeTuning()
        playSoundFrontEnd(39)
        return
    end

    -- Categories
    local catX = panelX + 15 * scale
    local catY = panelY + 75 * scale
    local catW = 180 * scale
    local btnH = 40 * scale

    for i = 1, #categories do
        local y = catY + 40 * scale + (i - 1) * (btnH + 5)
        if absX >= catX + 5 and absX <= catX + catW - 5 and absY >= y and absY <= y + btnH then
            currentCategory = i
            currentItem = 1
            playSoundFrontEnd(37)
            return
        end
    end

    -- Items
    local itemX = panelX + catW + 30 * scale
    local itemY = catY
    local itemW = panelW - catW - 45 * scale
    local itemH = panelH - 90 * scale

    local currentCat = categories[currentCategory]

    if currentCat.items[1] and currentCat.items[1].type == "color" then
        -- Color picker clicks
        local colorX = itemX + 10
        local colorY = itemY + 45 * scale
        local cellSize = (itemW - 20) / 5

        for i, color in ipairs(colorPalette) do
            local row = math.floor((i - 1) / 5)
            local col = (i - 1) % 5
            local cx = colorX + col * cellSize + 5
            local cy = colorY + row * cellSize + 5
            local cs = cellSize - 10

            if absX >= cx and absX <= cx + cs and absY >= cy and absY <= cy + cs then
                selectedColor = {color[1], color[2], color[3]}
                playSoundFrontEnd(37)
                return
            end
        end

        -- Color apply buttons
        local previewY = itemY + itemH - 80 * scale
        local btnW = (itemW - 40) / 2

        if absX >= itemX + 10 and absX <= itemX + 10 + btnW and
           absY >= previewY + 75 * scale and absY <= previewY + 110 * scale then
            applyColor(1)
            return
        end

        if absX >= itemX + 30 + btnW and absX <= itemX + itemW - 10 and
           absY >= previewY + 75 * scale and absY <= previewY + 110 * scale then
            applyColor(2)
            return
        end
    else
        -- Regular items
        local itemBtnH = 35 * scale
        local startY = itemY + 45 * scale

        for i, item in ipairs(currentCat.items) do
            local y = startY + (i - 1) * (itemBtnH + 5)
            if y + itemBtnH > itemY + itemH - 60 * scale then break end

            if absX >= itemX + 10 and absX <= itemX + itemW - 10 and absY >= y and absY <= y + itemBtnH then
                currentItem = i
                playSoundFrontEnd(37)
                return
            end
        end

        -- Apply button
        local applyY = itemY + itemH - 50 * scale
        if absX >= itemX + 10 and absX <= itemX + itemW - 10 and absY >= applyY and absY <= applyY + 40 * scale then
            applyUpgrade()
            return
        end
    end
end

function handleTuningKey(button, press)
    if not tuningOpen or not press then return end

    if button == "escape" then
        closeTuning()
    end
end

-- ============================================
-- UPGRADE APPLICATION
-- ============================================

function applyUpgrade()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then return end

    local currentCat = categories[currentCategory]
    local item = currentCat.items[currentItem]

    if not item or not item.id then return end

    triggerServerEvent("jebiga:tuning:apply", localPlayer, vehicle, item.id)
    playSoundFrontEnd(40)
end

function applyColor(slot)
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then return end

    triggerServerEvent("jebiga:tuning:color", localPlayer, vehicle, slot,
        selectedColor[1], selectedColor[2], selectedColor[3])
    playSoundFrontEnd(40)
    exports.jebiga_core:showNotification("Color applied!", "success")
end

-- ============================================
-- EVENTS
-- ============================================

addEventHandler("onClientRender", root, renderTuning)
addEventHandler("onClientClick", root, handleTuningClick)
addEventHandler("onClientKey", root, handleTuningKey)

addEvent("jebiga:tuning:result", true)
addEventHandler("jebiga:tuning:result", root, function(success, message)
    if success then
        exports.jebiga_core:showNotification(message or "Upgrade applied!", "success")
    else
        exports.jebiga_core:showNotification(message or "Could not apply upgrade!", "error")
    end
end)

-- ============================================
-- COMMANDS
-- ============================================

addCommandHandler("tuning", function()
    if tuningOpen then
        closeTuning()
    else
        openTuning()
    end
end)

addCommandHandler("tune", function()
    if tuningOpen then
        closeTuning()
    else
        openTuning()
    end
end)

bindKey("F6", "down", function()
    if tuningOpen then
        closeTuning()
    else
        openTuning()
    end
end)
