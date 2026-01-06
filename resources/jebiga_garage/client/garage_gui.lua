--[[
    Jebiga Multi-Gamemode - Garage GUI
]]

local screenW, screenH = guiGetScreenSize()
local isVisible = false
local garageData = {}
local currentTab = "owned"

local panelW = 700
local panelH = 500
local panelX = (screenW - panelW) / 2
local panelY = (screenH - panelH) / 2

function showGarage()
    isVisible = true
    showCursor(true)
end

function hideGarage()
    isVisible = false
    showCursor(false)
end

function renderGarage()
    if not isVisible then return end

    -- Background
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(0, 0, 0, 180))
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(25, 25, 25, 250))
    dxDrawRectangle(panelX, panelY, panelW, 4, tocolor(255, 102, 0, 255))

    -- Title
    dxDrawText("GARAGE", panelX, panelY + 15, panelX + panelW, panelY + 45, tocolor(255, 255, 255, 255), 1.4, "default-bold", "center", "center")

    -- Close button
    local closeX, closeY = panelX + panelW - 35, panelY + 10
    dxDrawRectangle(closeX, closeY, 25, 25, tocolor(200, 50, 50, 255))
    dxDrawText("X", closeX, closeY, closeX + 25, closeY + 25, tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center")

    -- Tabs
    local tabs = { "owned", "shop" }
    local tabW = 150
    local tabY = panelY + 55

    for i, tab in ipairs(tabs) do
        local tabX = panelX + 20 + (i - 1) * tabW
        local isActive = currentTab == tab
        local bgColor = isActive and tocolor(255, 102, 0, 255) or tocolor(50, 50, 50, 255)

        dxDrawRectangle(tabX, tabY, tabW - 5, 35, bgColor)
        dxDrawText(tab:upper(), tabX, tabY, tabX + tabW - 5, tabY + 35, tocolor(255, 255, 255, 255), 0.95, "default-bold", "center", "center")
    end

    -- Content
    local contentY = tabY + 50
    local contentH = panelH - 120

    if currentTab == "owned" then
        renderOwnedVehicles(contentY, contentH)
    else
        renderShop(contentY, contentH)
    end
end

function renderOwnedVehicles(startY, height)
    local vehicles = garageData.owned or {}

    if #vehicles == 0 then
        dxDrawText("You don't own any vehicles yet.", panelX + 20, startY + 20, panelX + panelW - 20, startY + 50, tocolor(150, 150, 150, 255), 1.0, "default", "center", "center")
        return
    end

    local y = startY
    for i, v in ipairs(vehicles) do
        if y + 40 < startY + height then
            dxDrawRectangle(panelX + 20, y, panelW - 40, 35, tocolor(40, 40, 40, 255))
            dxDrawText(getVehicleNameFromModel(v.vehicle_id), panelX + 30, y, panelX + 300, y + 35, tocolor(255, 255, 255, 255), 0.9, "default", "left", "center")
            dxDrawText("ID: " .. v.vehicle_id, panelX + 300, y, panelX + panelW - 30, y + 35, tocolor(150, 150, 150, 255), 0.85, "default", "right", "center")
            y = y + 40
        end
    end
end

function renderShop(startY, height)
    local shop = garageData.shop or {}
    local y = startY

    for i, v in ipairs(shop) do
        if y + 45 < startY + height then
            local owned = isVehicleOwned(v.id)
            local bgColor = owned and tocolor(40, 60, 40, 255) or tocolor(40, 40, 40, 255)

            dxDrawRectangle(panelX + 20, y, panelW - 40, 40, bgColor)
            dxDrawText(v.name, panelX + 30, y, panelX + 250, y + 40, tocolor(255, 255, 255, 255), 0.95, "default-bold", "left", "center")
            dxDrawText(v.category, panelX + 250, y, panelX + 400, y + 40, tocolor(150, 150, 150, 255), 0.85, "default", "left", "center")

            if owned then
                dxDrawText("OWNED", panelX + panelW - 120, y, panelX + panelW - 30, y + 40, tocolor(100, 255, 100, 255), 0.9, "default", "right", "center")
            else
                dxDrawText("$" .. Utils.formatNumber(v.price), panelX + panelW - 120, y, panelX + panelW - 30, y + 40, tocolor(255, 200, 100, 255), 0.9, "default", "right", "center")
            end

            y = y + 45
        end
    end
end

function isVehicleOwned(vehicleId)
    for _, v in ipairs(garageData.owned or {}) do
        if v.vehicle_id == vehicleId then return true end
    end
    return false
end

addEventHandler("onClientRender", root, renderGarage)

-- Handle click
addEventHandler("onClientClick", root, function(button, state, mx, my)
    if button ~= "left" or state ~= "down" or not isVisible then return end

    -- Close
    if mx >= panelX + panelW - 35 and mx <= panelX + panelW - 10 and my >= panelY + 10 and my <= panelY + 35 then
        hideGarage()
        return
    end

    -- Tabs
    local tabs = { "owned", "shop" }
    local tabW = 150
    local tabY = panelY + 55

    for i, tab in ipairs(tabs) do
        local tabX = panelX + 20 + (i - 1) * tabW
        if mx >= tabX and mx <= tabX + tabW - 5 and my >= tabY and my <= tabY + 35 then
            currentTab = tab
            return
        end
    end

    -- Shop items
    if currentTab == "shop" then
        local contentY = tabY + 85
        for i, v in ipairs(garageData.shop or {}) do
            local itemY = contentY + (i - 1) * 45
            if mx >= panelX + 20 and mx <= panelX + panelW - 20 and my >= itemY and my <= itemY + 40 then
                if not isVehicleOwned(v.id) then
                    triggerServerEvent(Events.Garage.PURCHASE_VEHICLE, localPlayer, v.id)
                end
                return
            end
        end
    end
end)

-- Handle key
addEventHandler("onClientKey", root, function(button, press)
    if button == "escape" and press and isVisible then
        hideGarage()
    end
end)

-- Handle data
addEvent(Events.Garage.OPEN, true)
addEventHandler(Events.Garage.OPEN, root, function(data)
    garageData = data or {}
    showGarage()
end)

addEvent(Events.Garage.UPDATE_VEHICLES, true)
addEventHandler(Events.Garage.UPDATE_VEHICLES, root, function(vehicles)
    garageData.owned = vehicles or {}
end)
