--[[
    Jebiga Multi-Gamemode - Clan System (Server)
    Handles clan creation, management, and chat
]]

-- Clan data storage (in production, use database)
local clans = {}
local playerClans = {} -- playerSerial -> clanId
local clanInvites = {} -- playerSerial -> {clanId, ...}

local CLAN_COST = 10000

-- ============================================
-- CLAN DATA MANAGEMENT
-- ============================================

function getClanData(clanId)
    return clans[clanId]
end

function getPlayerClan(player)
    local serial = getPlayerSerial(player)
    local clanId = playerClans[serial]
    if clanId then
        return clans[clanId], clanId
    end
    return nil
end

function getClanMembers(clanId)
    local clan = clans[clanId]
    if not clan then return {} end

    local members = {}
    for serial, data in pairs(clan.members) do
        local online = false
        local playerName = data.name

        -- Check if online
        for _, player in ipairs(getElementsByType("player")) do
            if getPlayerSerial(player) == serial then
                online = true
                playerName = getPlayerName(player)
                break
            end
        end

        table.insert(members, {
            name = playerName,
            rank = data.rank,
            online = online,
            serial = serial
        })
    end

    return members
end

-- ============================================
-- CLAN EVENTS
-- ============================================

addEvent("jebiga:clans:getData", true)
addEventHandler("jebiga:clans:getData", root, function()
    local player = source
    local serial = getPlayerSerial(player)

    local myClan, myClanId = getPlayerClan(player)
    local members = {}
    local invites = {}

    if myClan then
        members = getClanMembers(myClanId)
        myClan.myRank = myClan.members[serial] and myClan.members[serial].rank or "Member"
        myClan.memberCount = #members
    end

    -- Get invites
    if clanInvites[serial] then
        for _, clanId in ipairs(clanInvites[serial]) do
            local clan = clans[clanId]
            if clan then
                table.insert(invites, {
                    id = clanId,
                    name = clan.name,
                    tag = clan.tag,
                    color = clan.color
                })
            end
        end
    end

    -- Get all clans for browse
    local allClans = {}
    for id, clan in pairs(clans) do
        local memberCount = 0
        for _ in pairs(clan.members) do memberCount = memberCount + 1 end
        table.insert(allClans, {
            id = id,
            name = clan.name,
            tag = clan.tag,
            color = clan.color,
            memberCount = memberCount
        })
    end

    triggerClientEvent(player, "jebiga:clans:syncData", resourceRoot, myClan, members, invites, allClans)
end)

addEvent("jebiga:clans:create", true)
addEventHandler("jebiga:clans:create", root, function(name, tag)
    local player = source
    local serial = getPlayerSerial(player)

    -- Validate
    if playerClans[serial] then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "You are already in a clan!")
        return
    end

    if #name < 3 or #name > 20 then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "Clan name must be 3-20 characters!")
        return
    end

    if #tag < 1 or #tag > 4 then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "Clan tag must be 1-4 characters!")
        return
    end

    -- Check for duplicate names/tags
    for _, clan in pairs(clans) do
        if clan.name:lower() == name:lower() then
            triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "Clan name already taken!")
            return
        end
        if clan.tag:lower() == tag:lower() then
            triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "Clan tag already taken!")
            return
        end
    end

    -- Check money
    local money = getElementData(player, "jebiga:money") or 0
    if money < CLAN_COST then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "You need $" .. CLAN_COST .. " to create a clan!")
        return
    end

    -- Deduct money
    setElementData(player, "jebiga:money", money - CLAN_COST)

    -- Create clan
    local clanId = "clan_" .. tostring(getTickCount()) .. "_" .. serial:sub(1, 8)
    clans[clanId] = {
        name = name,
        tag = tag:upper(),
        color = {46, 204, 113},
        leader = serial,
        members = {
            [serial] = {
                name = getPlayerName(player),
                rank = "Leader",
                joined = getRealTime().timestamp
            }
        },
        created = getRealTime().timestamp
    }

    playerClans[serial] = clanId

    triggerClientEvent(player, "jebiga:clans:result", resourceRoot, true, "Clan created successfully!")
    outputDebugString("[Jebiga Clans] " .. getPlayerName(player) .. " created clan: [" .. tag .. "] " .. name)
end)

addEvent("jebiga:clans:leave", true)
addEventHandler("jebiga:clans:leave", root, function()
    local player = source
    local serial = getPlayerSerial(player)

    local clan, clanId = getPlayerClan(player)
    if not clan then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "You are not in a clan!")
        return
    end

    -- Remove from clan
    clan.members[serial] = nil
    playerClans[serial] = nil

    -- If leader left and no members, delete clan
    local memberCount = 0
    for _ in pairs(clan.members) do memberCount = memberCount + 1 end

    if memberCount == 0 then
        clans[clanId] = nil
    elseif clan.leader == serial then
        -- Transfer leadership to first member
        for memberSerial, data in pairs(clan.members) do
            clan.leader = memberSerial
            data.rank = "Leader"
            break
        end
    end

    triggerClientEvent(player, "jebiga:clans:result", resourceRoot, true, "You have left the clan!")
end)

addEvent("jebiga:clans:requestJoin", true)
addEventHandler("jebiga:clans:requestJoin", root, function(clanId)
    local player = source
    local serial = getPlayerSerial(player)

    if playerClans[serial] then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "You are already in a clan!")
        return
    end

    local clan = clans[clanId]
    if not clan then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "Clan not found!")
        return
    end

    -- For now, auto-join (in production, send request to leader)
    clan.members[serial] = {
        name = getPlayerName(player),
        rank = "Member",
        joined = getRealTime().timestamp
    }
    playerClans[serial] = clanId

    triggerClientEvent(player, "jebiga:clans:result", resourceRoot, true, "You have joined [" .. clan.tag .. "] " .. clan.name .. "!")
end)

-- ============================================
-- CLAN CHAT
-- ============================================

addEvent("jebiga:clans:sendChat", true)
addEventHandler("jebiga:clans:sendChat", root, function(message)
    local player = source
    local clan, clanId = getPlayerClan(player)

    if not clan then
        outputChatBox("#E74C3C[CLAN] #FFFFFFYou are not in a clan!", player, 255, 255, 255, true)
        return
    end

    -- Send to all online clan members
    for _, p in ipairs(getElementsByType("player")) do
        local pSerial = getPlayerSerial(p)
        if clan.members[pSerial] then
            triggerClientEvent(p, "jebiga:clans:chat", resourceRoot, getPlayerName(player), message)
        end
    end
end)

-- ============================================
-- COMMANDS
-- ============================================

addCommandHandler("claninfo", function(player, cmd, targetName)
    local target = targetName and getPlayerFromName(targetName) or player
    if not target then
        outputChatBox("#E74C3C[CLAN] #FFFFFFPlayer not found!", player, 255, 255, 255, true)
        return
    end

    local clan = getPlayerClan(target)
    if clan then
        outputChatBox("#2ECC71[CLAN] #FFFFFF" .. getPlayerName(target) .. " is in [" .. clan.tag .. "] " .. clan.name, player, 255, 255, 255, true)
    else
        outputChatBox("#2ECC71[CLAN] #FFFFFF" .. getPlayerName(target) .. " is not in a clan.", player, 255, 255, 255, true)
    end
end)

addCommandHandler("claninvite", function(player, cmd, targetName)
    if not targetName then
        outputChatBox("#E74C3C[CLAN] #FFFFFFUsage: /claninvite [player]", player, 255, 255, 255, true)
        return
    end

    local target = getPlayerFromName(targetName)
    if not target then
        outputChatBox("#E74C3C[CLAN] #FFFFFFPlayer not found!", player, 255, 255, 255, true)
        return
    end

    local clan, clanId = getPlayerClan(player)
    if not clan then
        outputChatBox("#E74C3C[CLAN] #FFFFFFYou are not in a clan!", player, 255, 255, 255, true)
        return
    end

    local playerSerial = getPlayerSerial(player)
    if clan.members[playerSerial].rank ~= "Leader" then
        outputChatBox("#E74C3C[CLAN] #FFFFFFOnly the leader can invite players!", player, 255, 255, 255, true)
        return
    end

    local targetSerial = getPlayerSerial(target)
    if playerClans[targetSerial] then
        outputChatBox("#E74C3C[CLAN] #FFFFFFThis player is already in a clan!", player, 255, 255, 255, true)
        return
    end

    -- Add invite
    if not clanInvites[targetSerial] then
        clanInvites[targetSerial] = {}
    end
    table.insert(clanInvites[targetSerial], clanId)

    outputChatBox("#2ECC71[CLAN] #FFFFFFYou invited " .. getPlayerName(target) .. " to your clan!", player, 255, 255, 255, true)
    outputChatBox("#2ECC71[CLAN] #FFFFFFYou have been invited to [" .. clan.tag .. "] " .. clan.name .. "! Use /clan to view invites.", target, 255, 255, 255, true)
end)

-- ============================================
-- EXPORTS
-- ============================================

function getPlayerClanData(player)
    return getPlayerClan(player)
end

function getPlayerClanTag(player)
    local clan = getPlayerClan(player)
    if clan then
        return clan.tag
    end
    return nil
end

function isPlayerInClan(player, clanId)
    local serial = getPlayerSerial(player)
    return playerClans[serial] == clanId
end
