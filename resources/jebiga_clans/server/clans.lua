--[[
    Jebiga Multi-Gamemode - Clan System (Server)
    Handles clan creation, management, and chat
    Uses centralized MySQL database from jebiga_core
]]

local CLAN_COST = 10000

-- ============================================
-- DATABASE HELPERS
-- ============================================

function getClanById(clanId)
    return exports.jebiga_core:db_fetchOne("SELECT * FROM clans WHERE id = ?", clanId)
end

function getClanByTag(tag)
    return exports.jebiga_core:db_fetchOne("SELECT * FROM clans WHERE tag = ?", tag)
end

function getClanByName(name)
    return exports.jebiga_core:db_fetchOne("SELECT * FROM clans WHERE name = ?", name)
end

function getPlayerClan(player)
    local accountId = getElementData(player, "jebiga:accountId")
    if not accountId then
        local serial = getPlayerSerial(player)
        local account = exports.jebiga_core:getAccountBySerial(serial)
        if account then
            accountId = account.id
            setElementData(player, "jebiga:accountId", accountId)
        end
    end

    if not accountId then return nil end

    local membership = exports.jebiga_core:db_fetchOne(
        "SELECT cm.*, c.* FROM clan_members cm " ..
        "JOIN clans c ON cm.clan_id = c.id " ..
        "WHERE cm.account_id = ?", accountId
    )

    return membership
end

function getClanMembers(clanId)
    return exports.jebiga_core:db_fetchAll(
        "SELECT cm.*, a.username, a.serial FROM clan_members cm " ..
        "JOIN accounts a ON cm.account_id = a.id " ..
        "WHERE cm.clan_id = ?", clanId
    ) or {}
end

function getClanInvites(accountId)
    return exports.jebiga_core:db_fetchAll(
        "SELECT ci.*, c.name, c.tag, c.color_r, c.color_g, c.color_b FROM clan_invites ci " ..
        "JOIN clans c ON ci.clan_id = c.id " ..
        "WHERE ci.account_id = ? AND (ci.expires_at IS NULL OR ci.expires_at > NOW())", accountId
    ) or {}
end

function getAllClans()
    return exports.jebiga_core:db_fetchAll(
        "SELECT c.*, COUNT(cm.id) as member_count FROM clans c " ..
        "LEFT JOIN clan_members cm ON c.id = cm.clan_id " ..
        "GROUP BY c.id ORDER BY member_count DESC"
    ) or {}
end

-- ============================================
-- CLAN DATA LOADING
-- ============================================

function loadPlayerClanData(player)
    local membership = getPlayerClan(player)
    if membership then
        setElementData(player, "jebiga:clanId", membership.clan_id)
        setElementData(player, "jebiga:clanTag", membership.tag)
        setElementData(player, "jebiga:clanRank", membership.rank)
    else
        setElementData(player, "jebiga:clanId", nil)
        setElementData(player, "jebiga:clanTag", nil)
        setElementData(player, "jebiga:clanRank", nil)
    end
end

-- Load clan data on join
addEventHandler("onPlayerJoin", root, function()
    setTimer(function(player)
        if isElement(player) then
            loadPlayerClanData(player)
        end
    end, 2500, 1, source)
end)

-- Load for existing players
addEventHandler("onResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        loadPlayerClanData(player)
    end
end)

-- ============================================
-- CLAN EVENTS
-- ============================================

addEvent("jebiga:clans:getData", true)
addEventHandler("jebiga:clans:getData", root, function()
    local player = source
    local accountId = getElementData(player, "jebiga:accountId")

    local myClan = nil
    local members = {}
    local invites = {}
    local myRank = nil

    if accountId then
        local membership = getPlayerClan(player)
        if membership then
            myClan = {
                id = membership.clan_id,
                name = membership.name,
                tag = membership.tag,
                description = membership.description,
                color = {membership.color_r, membership.color_g, membership.color_b},
                money = membership.money,
                level = membership.level,
                wins = membership.wins
            }
            myRank = membership.rank
            members = getClanMembers(membership.clan_id)

            -- Check online status for members
            for i, member in ipairs(members) do
                member.online = false
                for _, p in ipairs(getElementsByType("player")) do
                    if getPlayerSerial(p) == member.serial then
                        member.online = true
                        member.name = getPlayerName(p)
                        break
                    end
                end
            end
        end

        invites = getClanInvites(accountId)
    end

    local allClans = getAllClans()

    triggerClientEvent(player, "jebiga:clans:syncData", resourceRoot, myClan, members, invites, allClans, myRank)
end)

addEvent("jebiga:clans:create", true)
addEventHandler("jebiga:clans:create", root, function(name, tag)
    local player = source
    local accountId = getElementData(player, "jebiga:accountId")

    if not accountId then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "You must be logged in!")
        return
    end

    -- Check if already in a clan
    local existing = getPlayerClan(player)
    if existing then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "You are already in a clan!")
        return
    end

    -- Validate name and tag
    if #name < 3 or #name > 20 then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "Clan name must be 3-20 characters!")
        return
    end

    if #tag < 1 or #tag > 4 then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "Clan tag must be 1-4 characters!")
        return
    end

    -- Check for duplicates
    if getClanByName(name) then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "Clan name already taken!")
        return
    end

    if getClanByTag(tag:upper()) then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "Clan tag already taken!")
        return
    end

    -- Check money
    local money = getElementData(player, "jebiga:money") or 0
    if money < CLAN_COST then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "You need $" .. CLAN_COST .. " to create a clan!")
        return
    end

    -- Deduct money
    setElementData(player, "jebiga:money", money - CLAN_COST)
    exports.jebiga_core:db_execute(
        "UPDATE accounts SET money = money - ? WHERE id = ?",
        CLAN_COST, accountId
    )

    -- Create clan
    local success = exports.jebiga_core:db_execute(
        "INSERT INTO clans (name, tag, owner_id) VALUES (?, ?, ?)",
        name, tag:upper(), accountId
    )

    if success then
        -- Get the new clan ID
        local newClan = getClanByTag(tag:upper())
        if newClan then
            -- Add creator as leader
            exports.jebiga_core:db_execute(
                "INSERT INTO clan_members (clan_id, account_id, rank) VALUES (?, ?, 'leader')",
                newClan.id, accountId
            )

            loadPlayerClanData(player)
            triggerClientEvent(player, "jebiga:clans:result", resourceRoot, true, "Clan created successfully!")
            outputDebugString("[Jebiga Clans] " .. getPlayerName(player) .. " created clan: [" .. tag:upper() .. "] " .. name)
        end
    else
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "Failed to create clan!")
    end
end)

addEvent("jebiga:clans:leave", true)
addEventHandler("jebiga:clans:leave", root, function()
    local player = source
    local accountId = getElementData(player, "jebiga:accountId")

    if not accountId then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "You must be logged in!")
        return
    end

    local membership = getPlayerClan(player)
    if not membership then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "You are not in a clan!")
        return
    end

    local clanId = membership.clan_id
    local isLeader = membership.rank == "leader"

    -- Remove from clan
    exports.jebiga_core:db_execute(
        "DELETE FROM clan_members WHERE account_id = ?", accountId
    )

    -- Check remaining members
    local remainingMembers = getClanMembers(clanId)

    if #remainingMembers == 0 then
        -- Delete the clan
        exports.jebiga_core:db_execute("DELETE FROM clan_invites WHERE clan_id = ?", clanId)
        exports.jebiga_core:db_execute("DELETE FROM clans WHERE id = ?", clanId)
    elseif isLeader then
        -- Transfer leadership to first officer, or first member
        local newLeader = nil
        for _, member in ipairs(remainingMembers) do
            if member.rank == "officer" then
                newLeader = member
                break
            end
        end
        if not newLeader and #remainingMembers > 0 then
            newLeader = remainingMembers[1]
        end

        if newLeader then
            exports.jebiga_core:db_execute(
                "UPDATE clan_members SET rank = 'leader' WHERE account_id = ?",
                newLeader.account_id
            )
            exports.jebiga_core:db_execute(
                "UPDATE clans SET owner_id = ? WHERE id = ?",
                newLeader.account_id, clanId
            )
        end
    end

    loadPlayerClanData(player)
    triggerClientEvent(player, "jebiga:clans:result", resourceRoot, true, "You have left the clan!")
end)

addEvent("jebiga:clans:requestJoin", true)
addEventHandler("jebiga:clans:requestJoin", root, function(clanId)
    local player = source
    local accountId = getElementData(player, "jebiga:accountId")

    if not accountId then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "You must be logged in!")
        return
    end

    local existing = getPlayerClan(player)
    if existing then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "You are already in a clan!")
        return
    end

    local clan = getClanById(clanId)
    if not clan then
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, false, "Clan not found!")
        return
    end

    -- Check for invite
    local invite = exports.jebiga_core:db_fetchOne(
        "SELECT * FROM clan_invites WHERE clan_id = ? AND account_id = ?",
        clanId, accountId
    )

    if invite then
        -- Has invite, join directly
        exports.jebiga_core:db_execute(
            "INSERT INTO clan_members (clan_id, account_id, rank) VALUES (?, ?, 'member')",
            clanId, accountId
        )
        exports.jebiga_core:db_execute(
            "DELETE FROM clan_invites WHERE clan_id = ? AND account_id = ?",
            clanId, accountId
        )

        loadPlayerClanData(player)
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, true, "You have joined [" .. clan.tag .. "] " .. clan.name .. "!")
    else
        -- No invite, for now auto-join (could add request system later)
        exports.jebiga_core:db_execute(
            "INSERT INTO clan_members (clan_id, account_id, rank) VALUES (?, ?, 'member')",
            clanId, accountId
        )

        loadPlayerClanData(player)
        triggerClientEvent(player, "jebiga:clans:result", resourceRoot, true, "You have joined [" .. clan.tag .. "] " .. clan.name .. "!")
    end
end)

addEvent("jebiga:clans:acceptInvite", true)
addEventHandler("jebiga:clans:acceptInvite", root, function(clanId)
    local player = source
    local accountId = getElementData(player, "jebiga:accountId")

    if not accountId then return end

    local invite = exports.jebiga_core:db_fetchOne(
        "SELECT * FROM clan_invites WHERE clan_id = ? AND account_id = ?",
        clanId, accountId
    )

    if invite then
        local clan = getClanById(clanId)
        if clan then
            exports.jebiga_core:db_execute(
                "INSERT INTO clan_members (clan_id, account_id, rank) VALUES (?, ?, 'member')",
                clanId, accountId
            )
            exports.jebiga_core:db_execute(
                "DELETE FROM clan_invites WHERE clan_id = ? AND account_id = ?",
                clanId, accountId
            )

            loadPlayerClanData(player)
            triggerClientEvent(player, "jebiga:clans:result", resourceRoot, true, "You have joined [" .. clan.tag .. "] " .. clan.name .. "!")
        end
    end
end)

-- ============================================
-- CLAN CHAT
-- ============================================

addEvent("jebiga:clans:sendChat", true)
addEventHandler("jebiga:clans:sendChat", root, function(message)
    local player = source
    local membership = getPlayerClan(player)

    if not membership then
        outputChatBox("#E74C3C[CLAN] #FFFFFFYou are not in a clan!", player, 255, 255, 255, true)
        return
    end

    local clanId = membership.clan_id
    local members = getClanMembers(clanId)

    -- Send to all online clan members
    for _, member in ipairs(members) do
        for _, p in ipairs(getElementsByType("player")) do
            if getPlayerSerial(p) == member.serial then
                triggerClientEvent(p, "jebiga:clans:chat", resourceRoot, getPlayerName(player), message)
                break
            end
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

    local membership = getPlayerClan(target)
    if membership then
        outputChatBox("#2ECC71[CLAN] #FFFFFF" .. getPlayerName(target) .. " is in [" .. membership.tag .. "] " .. membership.name, player, 255, 255, 255, true)
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

    local membership = getPlayerClan(player)
    if not membership then
        outputChatBox("#E74C3C[CLAN] #FFFFFFYou are not in a clan!", player, 255, 255, 255, true)
        return
    end

    if membership.rank ~= "leader" and membership.rank ~= "officer" then
        outputChatBox("#E74C3C[CLAN] #FFFFFFOnly leaders and officers can invite players!", player, 255, 255, 255, true)
        return
    end

    local targetAccountId = getElementData(target, "jebiga:accountId")
    if not targetAccountId then
        outputChatBox("#E74C3C[CLAN] #FFFFFFTarget player has no account!", player, 255, 255, 255, true)
        return
    end

    local targetMembership = getPlayerClan(target)
    if targetMembership then
        outputChatBox("#E74C3C[CLAN] #FFFFFFThis player is already in a clan!", player, 255, 255, 255, true)
        return
    end

    -- Check existing invite
    local existingInvite = exports.jebiga_core:db_fetchOne(
        "SELECT * FROM clan_invites WHERE clan_id = ? AND account_id = ?",
        membership.clan_id, targetAccountId
    )

    if existingInvite then
        outputChatBox("#E74C3C[CLAN] #FFFFFFThis player already has an invite!", player, 255, 255, 255, true)
        return
    end

    -- Create invite (expires in 7 days)
    local accountId = getElementData(player, "jebiga:accountId")
    exports.jebiga_core:db_execute(
        "INSERT INTO clan_invites (clan_id, account_id, invited_by, expires_at) VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 7 DAY))",
        membership.clan_id, targetAccountId, accountId
    )

    outputChatBox("#2ECC71[CLAN] #FFFFFFYou invited " .. getPlayerName(target) .. " to your clan!", player, 255, 255, 255, true)
    outputChatBox("#2ECC71[CLAN] #FFFFFFYou have been invited to [" .. membership.tag .. "] " .. membership.name .. "! Use /clan to view invites.", target, 255, 255, 255, true)
end)

addCommandHandler("clankick", function(player, cmd, targetName)
    if not targetName then
        outputChatBox("#E74C3C[CLAN] #FFFFFFUsage: /clankick [player]", player, 255, 255, 255, true)
        return
    end

    local membership = getPlayerClan(player)
    if not membership then
        outputChatBox("#E74C3C[CLAN] #FFFFFFYou are not in a clan!", player, 255, 255, 255, true)
        return
    end

    if membership.rank ~= "leader" then
        outputChatBox("#E74C3C[CLAN] #FFFFFFOnly the leader can kick players!", player, 255, 255, 255, true)
        return
    end

    -- Find member by name
    local members = getClanMembers(membership.clan_id)
    local targetMember = nil
    for _, member in ipairs(members) do
        if member.username:lower() == targetName:lower() then
            targetMember = member
            break
        end
    end

    if not targetMember then
        outputChatBox("#E74C3C[CLAN] #FFFFFFMember not found in your clan!", player, 255, 255, 255, true)
        return
    end

    if targetMember.rank == "leader" then
        outputChatBox("#E74C3C[CLAN] #FFFFFFYou cannot kick the leader!", player, 255, 255, 255, true)
        return
    end

    exports.jebiga_core:db_execute(
        "DELETE FROM clan_members WHERE account_id = ?", targetMember.account_id
    )

    -- Reload for kicked player if online
    for _, p in ipairs(getElementsByType("player")) do
        if getPlayerSerial(p) == targetMember.serial then
            loadPlayerClanData(p)
            outputChatBox("#E74C3C[CLAN] #FFFFFFYou have been kicked from the clan!", p, 255, 255, 255, true)
            break
        end
    end

    outputChatBox("#2ECC71[CLAN] #FFFFFF" .. targetMember.username .. " has been kicked from the clan!", player, 255, 255, 255, true)
end)

-- ============================================
-- EXPORTS
-- ============================================

function getPlayerClanData(player)
    return getPlayerClan(player)
end

function getPlayerClanTag(player)
    return getElementData(player, "jebiga:clanTag")
end

function isPlayerInClan(player, clanId)
    local playerClanId = getElementData(player, "jebiga:clanId")
    return playerClanId == clanId
end
