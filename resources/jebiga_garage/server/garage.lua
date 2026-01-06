--[[
    Jebiga Multi-Gamemode - Garage System
]]

local vehicleShop = {
    { id = 411, name = "Infernus", price = 50000, category = "Sports" },
    { id = 451, name = "Turismo", price = 45000, category = "Sports" },
    { id = 522, name = "NRG-500", price = 20000, category = "Bikes" },
    { id = 521, name = "FCR-900", price = 15000, category = "Bikes" },
    { id = 541, name = "Bullet", price = 55000, category = "Sports" },
    { id = 415, name = "Cheetah", price = 40000, category = "Sports" },
    { id = 429, name = "Banshee", price = 35000, category = "Sports" },
    { id = 506, name = "Super GT", price = 48000, category = "Sports" },
    { id = 477, name = "ZR-350", price = 38000, category = "Sports" },
    { id = 402, name = "Buffalo", price = 25000, category = "Muscle" },
    { id = 542, name = "Clover", price = 18000, category = "Muscle" },
    { id = 603, name = "Phoenix", price = 30000, category = "Muscle" },
    { id = 560, name = "Sultan", price = 28000, category = "Tuner" },
    { id = 561, name = "Stratum", price = 22000, category = "Tuner" },
    { id = 565, name = "Flash", price = 20000, category = "Tuner" },
    { id = 559, name = "Jester", price = 32000, category = "Tuner" },
    { id = 558, name = "Uranus", price = 26000, category = "Tuner" },
    { id = 562, name = "Elegy", price = 35000, category = "Tuner" },
    { id = 425, name = "Hunter", price = 100000, category = "Aircraft" },
    { id = 520, name = "Hydra", price = 150000, category = "Aircraft" },
    { id = 432, name = "Rhino", price = 200000, category = "Military" }
}

function getPlayerVehicles(player)
    local accountId = getElementData(player, "jebiga:accountId")
    if not accountId then return {} end

    local result = exports.jebiga_core:db_fetchAll([[
        SELECT * FROM player_vehicles WHERE account_id = ?
    ]], accountId)

    return result or {}
end

function hasVehicle(player, vehicleId)
    local vehicles = getPlayerVehicles(player)
    for _, v in ipairs(vehicles) do
        if v.vehicle_id == vehicleId then return true end
    end
    return false
end

function purchaseVehicle(player, vehicleId)
    if hasVehicle(player, vehicleId) then
        return false, "You already own this vehicle"
    end

    local vehicleInfo
    for _, v in ipairs(vehicleShop) do
        if v.id == vehicleId then vehicleInfo = v break end
    end

    if not vehicleInfo then return false, "Invalid vehicle" end

    local playerMoney = exports.jebiga_core:getPlayerMoney(player)
    if playerMoney < vehicleInfo.price then
        return false, "Insufficient funds"
    end

    local accountId = getElementData(player, "jebiga:accountId")
    if not accountId then return false, "Not logged in" end

    -- Deduct money
    exports.jebiga_core:removePlayerMoney(player, vehicleInfo.price, "Vehicle purchase: " .. vehicleInfo.name)

    -- Add vehicle
    exports.jebiga_core:db_execute([[
        INSERT INTO player_vehicles (account_id, vehicle_model) VALUES (?, ?)
    ]], accountId, vehicleId)

    triggerClientEvent(player, Events.Notification.SHOW_SUCCESS, player, "Purchased " .. vehicleInfo.name .. "!", 3000)

    return true
end

-- Request handlers
addEvent(Events.Garage.REQUEST_OPEN, true)
addEventHandler(Events.Garage.REQUEST_OPEN, root, function()
    local vehicles = getPlayerVehicles(client)
    triggerClientEvent(client, Events.Garage.OPEN, client, {
        owned = vehicles,
        shop = vehicleShop
    })
end)

addEvent(Events.Garage.PURCHASE_VEHICLE, true)
addEventHandler(Events.Garage.PURCHASE_VEHICLE, root, function(vehicleId)
    purchaseVehicle(client, vehicleId)
    -- Refresh
    local vehicles = getPlayerVehicles(client)
    triggerClientEvent(client, Events.Garage.UPDATE_VEHICLES, client, vehicles)
end)
