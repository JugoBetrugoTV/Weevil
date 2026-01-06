--[[
    Weevil Multi-Gamemode - Admin Panel Server
]]

-- Get admin panel data
function getAdminPanelData(admin)
    local data = {
        players = {},
        serverStats = {
            uptime = exports.weevil_core:getServerUptime(),
            totalPlayers = #getElementsByType("player"),
            registeredAccounts = 0
        },
        recentLogs = {}
    }

    -- Get players
    for _, player in ipairs(getElementsByType("player")) do
        local pData = exports.weevil_core:getCachedPlayerData(player)
        table.insert(data.players, {
            name = getPlayerName(player),
            ping = getPlayerPing(player),
            serial = getPlayerSerial(player),
            ip = getPlayerIP(player),
            adminLevel = pData and pData.adminLevel or 0,
            money = pData and pData.money or 0,
            points = pData and pData.totalPoints or 0,
            gamemode = exports.weevil_core:getCurrentGamemode(player)
        })
    end

    -- Get account count
    local queryHandle = dbQuery(exports.weevil_core:dbQuery, "SELECT COUNT(*) as count FROM accounts")
    if queryHandle then
        local result = dbPoll(queryHandle, -1)
        dbFree(queryHandle)
        if result and #result > 0 then
            data.serverStats.registeredAccounts = result[1].count
        end
    end

    -- Get recent admin logs
    local logQuery = dbQuery(exports.weevil_core:dbQuery, [[
        SELECT al.*, a.username as admin_name
        FROM admin_log al
        LEFT JOIN accounts a ON al.admin_id = a.id
        ORDER BY al.created_at DESC
        LIMIT 20
    ]])

    if logQuery then
        local result = dbPoll(logQuery, -1)
        dbFree(logQuery)
        if result then
            data.recentLogs = result
        end
    end

    return data
end

-- Request handler
addEvent(Events.Admin.REQUEST_PANEL, true)
addEventHandler(Events.Admin.REQUEST_PANEL, root, function()
    local player = client
    if not exports.weevil_core:isPlayerAdmin(player, 1) then
        triggerClientEvent(player, Events.Notification.SHOW_ERROR, player, "Access denied", 3000)
        return
    end

    local data = getAdminPanelData(player)
    triggerClientEvent(player, Events.Admin.PANEL_OPEN, player, data)
end)

-- Kick handler
addEvent(Events.Admin.KICK_PLAYER, true)
addEventHandler(Events.Admin.KICK_PLAYER, root, function(targetName, reason)
    local admin = client
    if not exports.weevil_core:isPlayerAdmin(admin, 1) then return end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        triggerClientEvent(admin, Events.Notification.SHOW_ERROR, admin, "Player not found", 3000)
        return
    end

    reason = reason or "No reason"
    kickPlayer(target, admin, reason)

    exports.weevil_core:broadcastMessage("#FF0000[Admin] #FFFFFF" .. getPlayerName(target) .. " was kicked by " .. getPlayerName(admin))
    exports.weevil_core:logAdminAction(admin, "kick", target, reason)
end)

-- Ban handler
addEvent(Events.Admin.BAN_PLAYER, true)
addEventHandler(Events.Admin.BAN_PLAYER, root, function(targetName, duration, reason)
    local admin = client
    if not exports.weevil_core:isPlayerAdmin(admin, 2) then return end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        triggerClientEvent(admin, Events.Notification.SHOW_ERROR, admin, "Player not found", 3000)
        return
    end

    reason = reason or "No reason"
    exports.weevil_core:banPlayer(target, admin, reason, duration)
    exports.weevil_core:logAdminAction(admin, "ban", target, reason)
end)

-- Mute handler
addEvent(Events.Admin.MUTE_PLAYER, true)
addEventHandler(Events.Admin.MUTE_PLAYER, root, function(targetName, duration)
    local admin = client
    if not exports.weevil_core:isPlayerAdmin(admin, 1) then return end

    local target = getPlayerFromPartialName(targetName)
    if target then
        local data = exports.weevil_core:getCachedPlayerData(target)
        if data then
            data.muted = true
            data.muteExpires = getRealTime().timestamp + (duration * 60)

            triggerClientEvent(target, Events.Notification.SHOW_WARNING, target, "You have been muted for " .. duration .. " minutes", 5000)
            triggerClientEvent(admin, Events.Notification.SHOW_SUCCESS, admin, "Muted " .. getPlayerName(target), 3000)
        end
    end
end)

-- Command to open admin panel
addCommandHandler("admin", function(player)
    if exports.weevil_core:isPlayerAdmin(player, 1) then
        triggerServerEvent(Events.Admin.REQUEST_PANEL, player)
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
