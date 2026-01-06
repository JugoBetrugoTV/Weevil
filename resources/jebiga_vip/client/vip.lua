--[[
    Jebiga Multi-Gamemode - VIP System Client
    Shows VIP badges and effects
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

local myVIPLevel = 0
local myVIPData = nil

-- VIP badge rendering on screen
function renderVIPBadge()
    if myVIPLevel <= 0 then return end

    local x = screenW - 130 * scale
    local y = 100 * scale
    local w = 110 * scale
    local h = 30 * scale

    -- Badge background
    local color = myVIPData and myVIPData.color or {155, 89, 182}
    dxDrawRectangle(x, y, w, h, tocolor(color[1], color[2], color[3], 200))

    -- Badge text
    local prefix = myVIPData and myVIPData.name or "VIP"
    dxDrawText(prefix, x, y, x + w, y + h,
        tocolor(255, 255, 255, 255), 0.9 * scale, "default-bold", "center", "center")
end

-- VIP spawn effect
function playVIPEffect()
    if myVIPLevel >= 3 then
        -- Premium/Elite spawn effect
        local x, y, z = getElementPosition(localPlayer)
        fxAddSparks(x, y, z, 0, 0, 1, 2, 50, 0, 0, 0, true, 1, 1)
    end
end

-- Events
addEvent("jebiga:vip:updated", true)
addEventHandler("jebiga:vip:updated", root, function(level, data)
    myVIPLevel = level
    myVIPData = data
    playVIPEffect()
end)

addEventHandler("onClientRender", root, renderVIPBadge)

-- Request VIP status on join
addEventHandler("onClientResourceStart", resourceRoot, function()
    triggerServerEvent("jebiga:vip:request", localPlayer)
end)

addEvent("jebiga:vip:sync", true)
addEventHandler("jebiga:vip:sync", root, function(level, data)
    myVIPLevel = level
    myVIPData = data
end)
