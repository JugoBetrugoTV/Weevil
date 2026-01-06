--[[
    Weevil Multi-Gamemode - Notification System
    Client-side notifications and alerts
]]

local screenW, screenH = guiGetScreenSize()
local notifications = {}
local maxNotifications = 5

-- Notification types with colors
local notificationTypes = {
    info = { bg = tocolor(52, 152, 219, 220), icon = "ℹ" },
    success = { bg = tocolor(39, 174, 96, 220), icon = "✓" },
    warning = { bg = tocolor(241, 196, 15, 220), icon = "⚠" },
    error = { bg = tocolor(231, 76, 60, 220), icon = "✗" },
    achievement = { bg = tocolor(155, 89, 182, 220), icon = "★" }
}

-- Show notification
function showNotification(nType, message, duration)
    nType = nType or "info"
    duration = duration or 4000

    local notification = {
        type = nType,
        message = message,
        startTime = getTickCount(),
        duration = duration,
        alpha = 0,
        state = "fadein", -- fadein, visible, fadeout
        y = 0
    }

    -- Add to front of list
    table.insert(notifications, 1, notification)

    -- Remove oldest if too many
    while #notifications > maxNotifications do
        table.remove(notifications)
    end

    -- Update positions
    updateNotificationPositions()
end

-- Update notification positions
function updateNotificationPositions()
    local startY = 100
    local spacing = 60

    for i, notif in ipairs(notifications) do
        notif.targetY = startY + (i - 1) * spacing
    end
end

-- Render notifications
local function renderNotifications()
    local currentTime = getTickCount()
    local toRemove = {}

    for i, notif in ipairs(notifications) do
        local elapsed = currentTime - notif.startTime
        local typeData = notificationTypes[notif.type] or notificationTypes.info

        -- Handle states
        if notif.state == "fadein" then
            notif.alpha = math.min(255, notif.alpha + 15)
            if notif.alpha >= 255 then
                notif.state = "visible"
            end
        elseif notif.state == "visible" then
            if elapsed > notif.duration - 300 then
                notif.state = "fadeout"
            end
        elseif notif.state == "fadeout" then
            notif.alpha = math.max(0, notif.alpha - 15)
            if notif.alpha <= 0 then
                table.insert(toRemove, i)
            end
        end

        -- Animate Y position
        if notif.targetY then
            notif.y = notif.y + (notif.targetY - notif.y) * 0.2
        end

        -- Calculate dimensions
        local padding = 15
        local notifWidth = 300
        local notifHeight = 50
        local x = screenW - notifWidth - 20
        local y = notif.y

        -- Calculate alpha for background
        local bgAlpha = math.floor((notif.alpha / 255) * 220)

        -- Draw background
        local r, g, b = getColorFromTocolor(typeData.bg)
        dxDrawRectangle(x, y, notifWidth, notifHeight, tocolor(r, g, b, bgAlpha), true)

        -- Draw border
        dxDrawRectangle(x, y, 4, notifHeight, tocolor(255, 255, 255, bgAlpha), true)

        -- Draw icon
        dxDrawText(
            typeData.icon,
            x + 15,
            y,
            x + 40,
            y + notifHeight,
            tocolor(255, 255, 255, notif.alpha),
            1.2,
            "default-bold",
            "center",
            "center",
            false,
            false,
            true
        )

        -- Draw message
        dxDrawText(
            notif.message,
            x + 45,
            y,
            x + notifWidth - padding,
            y + notifHeight,
            tocolor(255, 255, 255, notif.alpha),
            1.0,
            "default",
            "left",
            "center",
            true,
            false,
            true
        )

        -- Draw progress bar
        local progress = 1 - (elapsed / notif.duration)
        if progress > 0 and progress <= 1 then
            dxDrawRectangle(
                x,
                y + notifHeight - 3,
                notifWidth * progress,
                3,
                tocolor(255, 255, 255, math.floor(notif.alpha * 0.5)),
                true
            )
        end
    end

    -- Remove finished notifications (reverse order to maintain indices)
    for i = #toRemove, 1, -1 do
        table.remove(notifications, toRemove[i])
    end

    updateNotificationPositions()
end

addEventHandler("onClientRender", root, renderNotifications)

-- Helper to extract RGB from tocolor
function getColorFromTocolor(color)
    local b = bitAnd(color, 255)
    local g = bitAnd(bitRshift(color, 8), 255)
    local r = bitAnd(bitRshift(color, 16), 255)
    return r, g, b
end

function bitAnd(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

function bitRshift(a, n)
    return math.floor(a / (2 ^ n))
end

-- Handle server notifications
addEvent(Events.Notification.SHOW, true)
addEventHandler(Events.Notification.SHOW, root, function(data)
    showNotification(data.type, data.message or data.title, data.duration)
end)

addEvent(Events.Notification.SHOW_INFO, true)
addEventHandler(Events.Notification.SHOW_INFO, root, function(message, duration)
    showNotification("info", message, duration)
end)

addEvent(Events.Notification.SHOW_SUCCESS, true)
addEventHandler(Events.Notification.SHOW_SUCCESS, root, function(message, duration)
    showNotification("success", message, duration)
end)

addEvent(Events.Notification.SHOW_WARNING, true)
addEventHandler(Events.Notification.SHOW_WARNING, root, function(message, duration)
    showNotification("warning", message, duration)
end)

addEvent(Events.Notification.SHOW_ERROR, true)
addEventHandler(Events.Notification.SHOW_ERROR, root, function(message, duration)
    showNotification("error", message, duration)
end)

-- Export
function exports.weevil_core:showNotification(nType, message, duration)
    showNotification(nType, message, duration)
end
