--[[
    Jebiga Multi-Gamemode - Achievements GUI
]]

local screenW, screenH = guiGetScreenSize()
local achievementPopups = {}

-- Handle achievement unlock
addEvent(Events.Achievements.UNLOCKED, true)
addEventHandler(Events.Achievements.UNLOCKED, root, function(data)
    table.insert(achievementPopups, {
        name = data.name,
        description = data.description,
        points = data.points,
        startTime = getTickCount(),
        duration = 5000,
        y = -100
    })

    exports.jebiga_core:playSound("win")
end)

-- Render popups
addEventHandler("onClientRender", root, function()
    local toRemove = {}

    for i, popup in ipairs(achievementPopups) do
        local elapsed = getTickCount() - popup.startTime
        local progress = elapsed / popup.duration

        if progress >= 1 then
            table.insert(toRemove, i)
        else
            local targetY = 100 + (i - 1) * 90
            popup.y = popup.y + (targetY - popup.y) * 0.1

            local alpha = 255
            if progress > 0.8 then
                alpha = math.floor(255 * (1 - (progress - 0.8) / 0.2))
            end

            local popupW = 350
            local popupH = 80
            local popupX = screenW - popupW - 20

            -- Background
            dxDrawRectangle(popupX, popup.y, popupW, popupH, tocolor(30, 30, 30, alpha))
            dxDrawRectangle(popupX, popup.y, 5, popupH, tocolor(255, 215, 0, alpha))

            -- Icon
            dxDrawText("★", popupX + 15, popup.y, popupX + 55, popup.y + popupH, tocolor(255, 215, 0, alpha), 2.0, "default-bold", "center", "center")

            -- Title
            dxDrawText("ACHIEVEMENT UNLOCKED!", popupX + 60, popup.y + 10, popupX + popupW - 10, popup.y + 30, tocolor(255, 215, 0, alpha), 0.8, "default-bold", "left", "center")

            -- Name
            dxDrawText(popup.name, popupX + 60, popup.y + 30, popupX + popupW - 60, popup.y + 50, tocolor(255, 255, 255, alpha), 1.0, "default-bold", "left", "center")

            -- Points
            dxDrawText("+" .. popup.points .. " pts", popupX + popupW - 70, popup.y + 30, popupX + popupW - 10, popup.y + 50, tocolor(100, 255, 100, alpha), 0.9, "default", "right", "center")

            -- Description
            dxDrawText(popup.description, popupX + 60, popup.y + 50, popupX + popupW - 10, popup.y + 70, tocolor(180, 180, 180, alpha), 0.75, "default", "left", "center")
        end
    end

    for i = #toRemove, 1, -1 do
        table.remove(achievementPopups, toRemove[i])
    end
end)
