--[[
    Weevil Multi-Gamemode - Utility Functions
    Shared utility functions for both client and server
]]

Utils = {}

-- Format time from milliseconds to MM:SS.mmm
function Utils.formatTime(ms)
    if not ms or ms < 0 then return "00:00.000" end

    local minutes = math.floor(ms / 60000)
    local seconds = math.floor((ms % 60000) / 1000)
    local milliseconds = ms % 1000

    return string.format("%02d:%02d.%03d", minutes, seconds, milliseconds)
end

-- Format time from milliseconds to HH:MM:SS
function Utils.formatTimeLong(ms)
    if not ms or ms < 0 then return "00:00:00" end

    local hours = math.floor(ms / 3600000)
    local minutes = math.floor((ms % 3600000) / 60000)
    local seconds = math.floor((ms % 60000) / 1000)

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- Format number with thousands separator
function Utils.formatNumber(num)
    if not num then return "0" end

    local formatted = tostring(math.floor(num))
    local k = #formatted % 3
    if k == 0 then k = 3 end

    local result = formatted:sub(1, k)
    for i = k + 1, #formatted, 3 do
        result = result .. "," .. formatted:sub(i, i + 2)
    end

    return result
end

-- Format money with currency symbol
function Utils.formatMoney(amount)
    return "$" .. Utils.formatNumber(amount)
end

-- Calculate distance between two 3D points
function Utils.getDistance3D(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end

-- Calculate distance between two 2D points
function Utils.getDistance2D(x1, y1, x2, y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

-- Interpolate between two values
function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Clamp value between min and max
function Utils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Convert hex color to RGB
function Utils.hexToRGB(hex)
    hex = hex:gsub("#", "")
    return {
        r = tonumber(hex:sub(1, 2), 16),
        g = tonumber(hex:sub(3, 4), 16),
        b = tonumber(hex:sub(5, 6), 16)
    }
end

-- Convert RGB to hex
function Utils.rgbToHex(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

-- Generate random string
function Utils.randomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, length do
        local index = math.random(1, #chars)
        result = result .. chars:sub(index, index)
    end
    return result
end

-- Check if table contains value
function Utils.tableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Get table length (for non-sequential tables)
function Utils.tableLength(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Deep copy table
function Utils.deepCopy(original)
    local copy
    if type(original) == "table" then
        copy = {}
        for key, value in next, original, nil do
            copy[Utils.deepCopy(key)] = Utils.deepCopy(value)
        end
        setmetatable(copy, Utils.deepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- Merge tables
function Utils.mergeTables(t1, t2)
    local result = Utils.deepCopy(t1)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = Utils.mergeTables(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

-- Sanitize string (remove special characters)
function Utils.sanitizeString(str)
    if not str then return "" end
    return str:gsub("[^%w%s%-_]", "")
end

-- Validate email format
function Utils.isValidEmail(email)
    if not email then return false end
    return email:match("^[%w.+-]+@[%w.-]+%.%w+$") ~= nil
end

-- Validate username format
function Utils.isValidUsername(username)
    if not username then return false end
    if #username < 3 or #username > 20 then return false end
    return username:match("^[%w_]+$") ~= nil
end

-- Get ordinal suffix (1st, 2nd, 3rd, etc.)
function Utils.getOrdinal(n)
    local suffix = "th"
    if n % 10 == 1 and n % 100 ~= 11 then
        suffix = "st"
    elseif n % 10 == 2 and n % 100 ~= 12 then
        suffix = "nd"
    elseif n % 10 == 3 and n % 100 ~= 13 then
        suffix = "rd"
    end
    return n .. suffix
end

-- Calculate rank from points
function Utils.calculateRank(points)
    local ranks = {
        { name = "Beginner", minPoints = 0, color = "#AAAAAA" },
        { name = "Novice", minPoints = 100, color = "#55FF55" },
        { name = "Amateur", minPoints = 500, color = "#55FFFF" },
        { name = "Semi-Pro", minPoints = 1500, color = "#5555FF" },
        { name = "Professional", minPoints = 5000, color = "#FF55FF" },
        { name = "Expert", minPoints = 15000, color = "#FFAA00" },
        { name = "Master", minPoints = 50000, color = "#FF5555" },
        { name = "Champion", minPoints = 100000, color = "#FFFF00" },
        { name = "Legend", minPoints = 250000, color = "#FF0000" },
        { name = "Immortal", minPoints = 500000, color = "#00FFFF" }
    }

    local currentRank = ranks[1]
    for _, rank in ipairs(ranks) do
        if points >= rank.minPoints then
            currentRank = rank
        else
            break
        end
    end

    return currentRank
end

-- Split string by delimiter
function Utils.split(str, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    for match in str:gmatch(pattern) do
        table.insert(result, match)
    end
    return result
end

-- Trim whitespace from string
function Utils.trim(str)
    return str:match("^%s*(.-)%s*$")
end

-- Check if string is empty or nil
function Utils.isEmpty(str)
    return str == nil or str == ""
end

-- Get time ago string
function Utils.timeAgo(timestamp)
    local now = getRealTime().timestamp
    local diff = now - timestamp

    if diff < 60 then
        return "just now"
    elseif diff < 3600 then
        local mins = math.floor(diff / 60)
        return mins .. " minute" .. (mins > 1 and "s" or "") .. " ago"
    elseif diff < 86400 then
        local hours = math.floor(diff / 3600)
        return hours .. " hour" .. (hours > 1 and "s" or "") .. " ago"
    elseif diff < 2592000 then
        local days = math.floor(diff / 86400)
        return days .. " day" .. (days > 1 and "s" or "") .. " ago"
    elseif diff < 31536000 then
        local months = math.floor(diff / 2592000)
        return months .. " month" .. (months > 1 and "s" or "") .. " ago"
    else
        local years = math.floor(diff / 31536000)
        return years .. " year" .. (years > 1 and "s" or "") .. " ago"
    end
end

-- Safe JSON encode
function Utils.jsonEncode(data)
    local success, result = pcall(toJSON, data)
    if success then
        return result
    end
    return nil
end

-- Safe JSON decode
function Utils.jsonDecode(str)
    local success, result = pcall(fromJSON, str)
    if success then
        return result
    end
    return nil
end

return Utils
