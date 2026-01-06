--[[
    Jebiga Multi-Gamemode - Admin Panel Server
]]

-- Get admin panel data
function getAdminPanelData(admin)
    local data = {
        players = {},
        serverStats = {
            uptime = exports.jebiga_core:getServerUptime(),
            totalPlayers = #getElementsByType("player"),
            registeredAccounts = 0
        },
        recentLogs = {}
    }

    -- Get players
    for _, player in ipairs(getElementsByType("player")) do
        local pData = exports.jebiga_core:getCachedPlayerData(player)
        table.insert(data.players, {
            name = getPlayerName(player),
            ping = getPlayerPing(player),
            serial = getPlayerSerial(player),
            ip = getPlayerIP(player),
            adminLevel = pData and pData.adminLevel or 0,
            money = pData and pData.money or 0,
            points = pData and pData.totalPoints or 0,
            gamemode = exports.jebiga_core:getCurrentGamemode(player)
        })
    end

    -- Get account count
    local countResult = exports.jebiga_core:db_fetchOne("SELECT COUNT(*) as count FROM accounts")
    if countResult then
        data.serverStats.registeredAccounts = countResult.count
    end

    -- Get recent admin logs
    local logs = exports.jebiga_core:db_fetchAll([[
        SELECT al.*, a.username as admin_name
        FROM admin_log al
        LEFT JOIN accounts a ON al.admin_id = a.id
        ORDER BY al.created_at DESC
        LIMIT 20
    ]])
    if logs then
        data.recentLogs = logs
    end

    return data
end

-- Request handler
addEvent("weevil:admin:requestPanel", true)
addEventHandler("weevil:admin:requestPanel", root, function()
    local player = client
    if not exports.jebiga_core:isPlayerAdmin(player, 1) then
        triggerClientEvent(player, "weevil:notification:showError", player, "Access denied", 3000)
        return
    end

    local data = getAdminPanelData(player)
    triggerClientEvent(player, "weevil:admin:panelOpen", player, data)
end)

-- Kick handler
addEvent("weevil:admin:kickPlayer", true)
addEventHandler("weevil:admin:kickPlayer", root, function(targetName, reason)
    local admin = client
    if not exports.jebiga_core:isPlayerAdmin(admin, 1) then return end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        triggerClientEvent(admin, "weevil:notification:showError", admin, "Player not found", 3000)
        return
    end

    reason = reason or "No reason"
    kickPlayer(target, admin, reason)

    exports.jebiga_core:broadcastMessage("#FF0000[Admin] #FFFFFF" .. getPlayerName(target) .. " was kicked by " .. getPlayerName(admin))
end)

-- Ban handler
addEvent("weevil:admin:banPlayer", true)
addEventHandler("weevil:admin:banPlayer", root, function(targetName, duration, reason)
    local admin = client
    if not exports.jebiga_core:isPlayerAdmin(admin, 2) then return end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        triggerClientEvent(admin, "weevil:notification:showError", admin, "Player not found", 3000)
        return
    end

    reason = reason or "No reason"
    -- Ban logic would go here
    kickPlayer(target, admin, "Banned: " .. reason)
end)

-- Mute handler
addEvent("weevil:admin:mutePlayer", true)
addEventHandler("weevil:admin:mutePlayer", root, function(targetName, duration)
    local admin = client
    if not exports.jebiga_core:isPlayerAdmin(admin, 1) then return end

    local target = getPlayerFromPartialName(targetName)
    if target then
        local data = exports.jebiga_core:getCachedPlayerData(target)
        if data then
            data.muted = true
            data.muteExpires = getRealTime().timestamp + (duration * 60)

            triggerClientEvent(target, "weevil:notification:showWarning", target, "You have been muted for " .. duration .. " minutes", 5000)
            triggerClientEvent(admin, "weevil:notification:showSuccess", admin, "Muted " .. getPlayerName(target), 3000)
        end
    end
end)

-- Command to open admin panel
addCommandHandler("admin", function(player)
    if exports.jebiga_core:isPlayerAdmin(player, 1) then
        local data = getAdminPanelData(player)
        triggerClientEvent(player, "weevil:admin:panelOpen", player, data)
    else
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
    end
end)

-- Helper
function getPlayerFromPartialName(name)
    name = name:lower()
    for _, player in ipairs(getElementsByType("player")) do
        if getPlayerName(player):lower():find(name, 1, true) then
            return player
        end
    end
    return nil
end
