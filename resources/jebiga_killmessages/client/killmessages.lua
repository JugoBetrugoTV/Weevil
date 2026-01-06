--[[
    Jebiga Multi-Gamemode - Kill Messages & Death List
    Shows kill feed and death notifications
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- Kill list
local killList = {}
local maxKills = 8
local killDuration = 8000 -- 8 seconds

-- Kill message styles
local killIcons = {
    ["0"] = "Fist",
    ["22"] = "Pistol",
    ["23"] = "Silenced",
    ["24"] = "Deagle",
    ["25"] = "Shotgun",
    ["26"] = "Sawn-off",
    ["27"] = "SPAS-12",
    ["28"] = "Uzi",
    ["29"] = "MP5",
    ["30"] = "AK-47",
    ["31"] = "M4",
    ["32"] = "Tec-9",
    ["33"] = "Rifle",
    ["34"] = "Sniper",
    ["37"] = "Fire",
    ["38"] = "Minigun",
    ["49"] = "Vehicle",
    ["50"] = "Heli Blades",
    ["51"] = "Explosion",
    ["53"] = "Drowned",
    ["54"] = "Splat",
    ["255"] = "Explosion"
}

-- ============================================
-- KILL LIST RENDERING
-- ============================================

function renderKillList()
    local now = getTickCount()
    local y = 150 * scale
    local padding = 10 * scale
    local entryH = 30 * scale

    -- Remove old entries
    for i = #killList, 1, -1 do
        if now - killList[i].time > killDuration then
            table.remove(killList, i)
        end
    end

    -- Render entries
    for i, kill in ipairs(killList) do
        local age = now - kill.time
        local alpha = 255

        -- Fade out in last 2 seconds
        if age > killDuration - 2000 then
            alpha = 255 * (1 - (age - (killDuration - 2000)) / 2000)
        end

        -- Fade in
        if age < 300 then
            alpha = 255 * (age / 300)
        end

        alpha = math.max(0, math.min(255, alpha))

        local entryY = y + (i - 1) * (entryH + 5)

        -- Background
        dxDrawRectangle(screenW - 350 * scale - padding, entryY, 350 * scale, entryH,
            tocolor(0, 0, 0, alpha * 0.5))

        -- Build kill text
        local killerColor = kill.killerTeam and getTeamColor(kill.killerTeam) or {255, 255, 255}
        local victimColor = kill.victimTeam and getTeamColor(kill.victimTeam) or {255, 255, 255}

        -- Render killer name
        local xOffset = screenW - 350 * scale

        if kill.killer then
            dxDrawText(kill.killer, xOffset, entryY, xOffset + 120 * scale, entryY + entryH,
                tocolor(killerColor[1], killerColor[2], killerColor[3], alpha),
                0.85 * scale, "default-bold", "right", "center", true)
            xOffset = xOffset + 125 * scale
        end

        -- Weapon/cause
        local weaponName = killIcons[tostring(kill.weapon)] or "Killed"
        local weaponColor = kill.killer and tocolor(200, 200, 200, alpha) or tocolor(150, 150, 150, alpha)

        dxDrawText("[" .. weaponName .. "]", xOffset, entryY, xOffset + 80 * scale, entryY + entryH,
            weaponColor, 0.75 * scale, "default", "center", "center", true)

        xOffset = xOffset + 85 * scale

        -- Victim name
        dxDrawText(kill.victim, xOffset, entryY, screenW - padding, entryY + entryH,
            tocolor(victimColor[1], victimColor[2], victimColor[3], alpha),
            0.85 * scale, "default-bold", "left", "center", true)
    end
end

function getTeamColor(teamName)
    -- Return color based on team name or default
    local colors = {
        ["Red"] = {231, 76, 60},
        ["Blue"] = {52, 152, 219},
        ["Green"] = {46, 204, 113},
        ["Yellow"] = {241, 196, 15},
        ["Orange"] = {230, 126, 34},
        ["Purple"] = {155, 89, 182}
    }
    return colors[teamName] or {255, 255, 255}
end

-- ============================================
-- KILL NOTIFICATION
-- ============================================

local myKillStreak = 0
local lastKillTime = 0

local streakMessages = {
    [3] = {"TRIPLE KILL!", {241, 196, 15}},
    [5] = {"KILLING SPREE!", {230, 126, 34}},
    [7] = {"RAMPAGE!", {231, 76, 60}},
    [10] = {"UNSTOPPABLE!", {155, 89, 182}},
    [15] = {"GODLIKE!", {255, 215, 0}}
}

function showKillNotification(victim, weapon, headshot)
    local now = getTickCount()

    -- Update streak
    if now - lastKillTime < 10000 then
        myKillStreak = myKillStreak + 1
    else
        myKillStreak = 1
    end
    lastKillTime = now

    -- Show streak message
    local streakData = streakMessages[myKillStreak]
    if streakData then
        showCenterMessage(streakData[1], streakData[2], 3000)
    end

    -- Headshot notification
    if headshot then
        exports.jebiga_core:showNotification("HEADSHOT!", "success")
    end
end

-- Center message system
local centerMessage = nil
local centerMessageEnd = 0

function showCenterMessage(text, color, duration)
    centerMessage = {text = text, color = color}
    centerMessageEnd = getTickCount() + duration
end

function renderCenterMessage()
    if not centerMessage then return end

    local now = getTickCount()
    if now > centerMessageEnd then
        centerMessage = nil
        return
    end

    local remaining = centerMessageEnd - now
    local alpha = 255

    -- Fade out
    if remaining < 500 then
        alpha = 255 * (remaining / 500)
    end

    local color = centerMessage.color or {255, 255, 255}

    -- Shadow
    dxDrawText(centerMessage.text, screenW/2 + 2, screenH/3 + 2, screenW/2 + 2, screenH/3 + 2,
        tocolor(0, 0, 0, alpha * 0.5), 2.5 * scale, "pricedown", "center", "center")

    -- Main text
    dxDrawText(centerMessage.text, screenW/2, screenH/3, screenW/2, screenH/3,
        tocolor(color[1], color[2], color[3], alpha), 2.5 * scale, "pricedown", "center", "center")
end

-- ============================================
-- EVENTS
-- ============================================

addEventHandler("onClientRender", root, function()
    renderKillList()
    renderCenterMessage()
end)

addEvent("jebiga:kill:add", true)
addEventHandler("jebiga:kill:add", root, function(killer, victim, weapon, killerTeam, victimTeam)
    -- Add to kill list
    table.insert(killList, 1, {
        killer = killer,
        victim = victim,
        weapon = weapon,
        killerTeam = killerTeam,
        victimTeam = victimTeam,
        time = getTickCount()
    })

    -- Limit list size
    while #killList > maxKills do
        table.remove(killList)
    end

    -- If I'm the killer
    if killer == getPlayerName(localPlayer) then
        showKillNotification(victim, weapon, false)
    end
end)

addEvent("jebiga:kill:headshot", true)
addEventHandler("jebiga:kill:headshot", root, function(victim)
    showKillNotification(victim, 0, true)
end)

-- Reset streak on death
addEventHandler("onClientPlayerWasted", localPlayer, function()
    myKillStreak = 0
end)

-- ============================================
-- EXPORTS
-- ============================================

function addKillToList(killer, victim, weapon)
    table.insert(killList, 1, {
        killer = killer,
        victim = victim,
        weapon = weapon,
        time = getTickCount()
    })
    while #killList > maxKills do
        table.remove(killList)
    end
end
