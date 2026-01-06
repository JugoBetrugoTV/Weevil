--[[
    Jebiga Multi-Gamemode - Custom Chat System
    Beautiful chat with colors, badges, and formatting
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- Chat settings
local chatMessages = {}
local maxMessages = 15
local messageDuration = 15000 -- 15 seconds
local chatVisible = true
local chatFaded = true
local lastActivity = 0

-- ============================================
-- CHAT RENDERING
-- ============================================

function renderChat()
    if not chatVisible then return end

    local now = getTickCount()
    local x = 20 * scale
    local y = screenH - 350 * scale
    local lineH = 22 * scale

    -- Check if chat should fade
    local timeSinceActivity = now - lastActivity
    local baseAlpha = 255

    if chatFaded and timeSinceActivity > 8000 then
        baseAlpha = math.max(0, 255 - ((timeSinceActivity - 8000) / 2000) * 255)
    end

    if baseAlpha <= 0 then return end

    -- Render messages from bottom to top
    local visibleMessages = 0
    for i = #chatMessages, 1, -1 do
        if visibleMessages >= maxMessages then break end

        local msg = chatMessages[i]
        local age = now - msg.time

        -- Remove old messages
        if age > messageDuration then
            table.remove(chatMessages, i)
        else
            local alpha = baseAlpha

            -- Fade out old messages
            if age > messageDuration - 3000 then
                alpha = alpha * (1 - (age - (messageDuration - 3000)) / 3000)
            end

            if alpha > 10 then
                local msgY = y + (maxMessages - visibleMessages - 1) * lineH

                -- Shadow
                dxDrawText(msg.formatted, x + 1, msgY + 1, screenW - 20 * scale, msgY + lineH,
                    tocolor(0, 0, 0, alpha * 0.5), 0.85 * scale, "default-bold", "left", "center", false, false, false, true)

                -- Text
                dxDrawText(msg.formatted, x, msgY, screenW - 20 * scale, msgY + lineH,
                    tocolor(255, 255, 255, alpha), 0.85 * scale, "default-bold", "left", "center", false, false, false, true)

                visibleMessages = visibleMessages + 1
            end
        end
    end
end

-- ============================================
-- MESSAGE HANDLING
-- ============================================

function addChatMessage(formatted, raw)
    table.insert(chatMessages, {
        formatted = formatted,
        raw = raw or formatted,
        time = getTickCount()
    })

    lastActivity = getTickCount()

    -- Limit messages
    while #chatMessages > maxMessages * 2 do
        table.remove(chatMessages, 1)
    end
end

function formatPlayerMessage(player, message, type)
    local name = getPlayerName(player)
    local vipPrefix = getElementData(player, "jebiga:vipPrefix") or ""
    local clanTag = getElementData(player, "jebiga:clanTag") or ""
    local team = getPlayerTeam(player)

    -- Get player color
    local r, g, b = 255, 255, 255
    if team then
        r, g, b = getTeamColor(team)
    end

    local nameColor = string.format("#%02X%02X%02X", r, g, b)

    -- Build formatted message
    local formatted = ""

    -- Add VIP prefix
    if vipPrefix ~= "" then
        formatted = vipPrefix .. " "
    end

    -- Add clan tag
    if clanTag ~= "" then
        formatted = formatted .. "#95A5A6[" .. clanTag .. "] "
    end

    -- Add name
    formatted = formatted .. nameColor .. name .. "#FFFFFF: " .. message

    return formatted
end

-- ============================================
-- EVENTS
-- ============================================

addEventHandler("onClientRender", root, renderChat)

-- Intercept default chat
addEventHandler("onClientChatMessage", root, function(text, r, g, b)
    -- Convert to colored text
    local hexColor = string.format("#%02X%02X%02X", r or 255, g or 255, b or 255)
    addChatMessage(hexColor .. text, text)

    lastActivity = getTickCount()
end)

-- Custom chat messages
addEvent("jebiga:chat:message", true)
addEventHandler("jebiga:chat:message", root, function(formatted, raw)
    addChatMessage(formatted, raw)
end)

-- Player chat
addEvent("jebiga:chat:player", true)
addEventHandler("jebiga:chat:player", root, function(player, message, type)
    local formatted = formatPlayerMessage(player, message, type)
    addChatMessage(formatted, message)
end)

-- Show chat on key press
addEventHandler("onClientKey", root, function(button, press)
    if button == "t" or button == "y" then
        lastActivity = getTickCount()
        chatFaded = false

        -- Reset fade after typing
        setTimer(function()
            chatFaded = true
        end, 10000, 1)
    end
end)

-- ============================================
-- COMMANDS
-- ============================================

addCommandHandler("clearchat", function()
    chatMessages = {}
    outputChatBox("#2980B9[CHAT] #FFFFFFChat cleared.", 255, 255, 255, true)
end)

addCommandHandler("togglechat", function()
    chatVisible = not chatVisible
    outputChatBox("#2980B9[CHAT] #FFFFFFChat " .. (chatVisible and "shown" or "hidden"), 255, 255, 255, true)
end)

-- ============================================
-- EXPORTS
-- ============================================

function sendChatMessage(formatted)
    addChatMessage(formatted)
end
