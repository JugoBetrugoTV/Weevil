--[[
    Jebiga Multi-Gamemode - Custom Chat System (Server)
]]

-- Override default chat
addEventHandler("onPlayerChat", root, function(message, type)
    cancelEvent()

    local player = source

    -- Build formatted message
    local name = getPlayerName(player)
    local vipLevel = getElementData(player, "jebiga:vip") or 0
    local clanTag = getElementData(player, "jebiga:clanTag")
    local team = getPlayerTeam(player)

    -- VIP prefixes
    local vipPrefixes = {
        [1] = "#2ECC71[VIP]",
        [2] = "#3498DB[VIP+]",
        [3] = "#9B59B6[PREMIUM]",
        [4] = "#F1C40F[ELITE]"
    }

    local vipPrefix = vipPrefixes[vipLevel] or ""

    -- Team color
    local r, g, b = 255, 255, 255
    if team then
        r, g, b = getTeamColor(team)
    end
    local nameColor = string.format("#%02X%02X%02X", r, g, b)

    -- Build message
    local formatted = ""

    if vipPrefix ~= "" then
        formatted = vipPrefix .. " "
    end

    if clanTag and clanTag ~= "" then
        formatted = formatted .. "#95A5A6[" .. clanTag .. "] "
    end

    formatted = formatted .. nameColor .. name .. "#FFFFFF: " .. message

    -- Send to all players
    for _, p in ipairs(getElementsByType("player")) do
        triggerClientEvent(p, "jebiga:chat:message", resourceRoot, formatted, message)
    end

    -- Also output to server log
    outputServerLog("[CHAT] " .. name .. ": " .. message)
end)

-- Team chat
addEventHandler("onPlayerChat", root, function(message, type)
    if type == 1 then -- Team chat
        cancelEvent()

        local player = source
        local team = getPlayerTeam(player)

        if not team then
            outputChatBox("#E74C3C[TEAM] #FFFFFFYou are not in a team!", player, 255, 255, 255, true)
            return
        end

        local name = getPlayerName(player)
        local r, g, b = getTeamColor(team)
        local teamName = getTeamName(team)

        local formatted = "#" .. string.format("%02X%02X%02X", r, g, b) .. "[" .. teamName .. "] " .. name .. ": #FFFFFF" .. message

        -- Send to team members only
        for _, p in ipairs(getPlayersInTeam(team)) do
            triggerClientEvent(p, "jebiga:chat:message", resourceRoot, formatted, message)
        end
    end
end)

-- Admin announce command
addCommandHandler("announce", function(player, cmd, ...)
    if not hasObjectPermissionTo(player, "command.start") then
        outputChatBox("#E74C3C[ANNOUNCE] #FFFFFFYou don't have permission!", player, 255, 255, 255, true)
        return
    end

    local message = table.concat({...}, " ")
    if message == "" then
        outputChatBox("#E74C3C[ANNOUNCE] #FFFFFFUsage: /announce [message]", player, 255, 255, 255, true)
        return
    end

    local formatted = "#E74C3C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    triggerClientEvent(root, "jebiga:chat:message", resourceRoot, formatted)

    formatted = "#F1C40F[ANNOUNCEMENT] #FFFFFF" .. message
    triggerClientEvent(root, "jebiga:chat:message", resourceRoot, formatted)

    formatted = "#E74C3C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    triggerClientEvent(root, "jebiga:chat:message", resourceRoot, formatted)
end)
