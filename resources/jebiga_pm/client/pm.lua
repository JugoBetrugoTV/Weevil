--[[
    Jebiga Multi-Gamemode - Private Messages Client
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

local pmNotifications = {}
local maxNotifications = 3

addEvent("jebiga:pm:received", true)
addEventHandler("jebiga:pm:received", root, function(sender, message)
    -- Play sound
    playSoundFrontEnd(12)

    -- Add notification
    table.insert(pmNotifications, 1, {
        sender = sender,
        message = message,
        time = getTickCount()
    })

    while #pmNotifications > maxNotifications do
        table.remove(pmNotifications)
    end
end)

function renderPMNotifications()
    local now = getTickCount()
    local y = screenH - 200 * scale

    for i = #pmNotifications, 1, -1 do
        local pm = pmNotifications[i]
        local age = now - pm.time

        if age > 8000 then
            table.remove(pmNotifications, i)
        else
            local alpha = 255
            if age > 6000 then
                alpha = 255 * (1 - (age - 6000) / 2000)
            end

            local w = 350 * scale
            local h = 50 * scale
            local x = screenW - w - 20 * scale

            -- Background
            dxDrawRectangle(x, y, w, h, tocolor(30, 33, 42, alpha * 0.9))
            dxDrawRectangle(x, y, 4, h, tocolor(155, 89, 182, alpha))

            -- Sender
            dxDrawText("PM from " .. pm.sender, x + 15, y + 5, x + w - 10, y + 22,
                tocolor(155, 89, 182, alpha), 0.8 * scale, "default-bold", "left", "center")

            -- Message (truncate if too long)
            local msg = pm.message
            if #msg > 35 then msg = msg:sub(1, 35) .. "..." end
            dxDrawText(msg, x + 15, y + 25, x + w - 10, y + h - 5,
                tocolor(255, 255, 255, alpha), 0.85 * scale, "default", "left", "center")

            y = y - (h + 5)
        end
    end
end

addEventHandler("onClientRender", root, renderPMNotifications)
