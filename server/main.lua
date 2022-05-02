ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
carKeys = {}

-- Callback to fetch whitelisted vehicle key:
ESX.RegisterServerCallback("inf_keys:fetchCarWlKey", function(source, cb, hashKey)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer then
		local HasWhitelist = false
		for k,v in pairs(Config.WhitelistCars) do
			if hashKey == v.model then
				for _,y in pairs (Config.WhitelistCars[k].job) do
					if xPlayer.job.name == y then
						HasWhitelist = true
					end
				end
			end
		end
		if HasWhitelist then
			cb(true)
		else
			cb(false)
		end
	end
end)

-- Callback to fetch owned vehicle key:
ESX.RegisterServerCallback("inf_keys:fetchCarKey", function(source, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    local vehicles = {}
    local KeyFound = false
    if xPlayer then
        MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate=@plate AND owner=@identifier',{ ['@plate'] = plate, ['@identifier'] = xPlayer.getIdentifier()}, function(data)
            if data[1] ~= nil then
                if xPlayer.identifier == data[1].owner then
                    KeyFound = true
                end
            end
            if KeyFound then
                cb(true)
            else
                cb(false)
            end
        end) 
    end
end)

-- Callback to fetch lend vehicle key:
ESX.RegisterServerCallback("inf_keys:fetchLendKey", function(source, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    local vehicles = {}
    local KeyFound = false
    if xPlayer then
        MySQL.Async.fetchAll('SELECT * FROM lend_vehicles WHERE plate=@plate AND reciver=@identifier',{ ['@plate'] = plate, ['@identifier'] = xPlayer.getIdentifier()}, function(data)
            if data[1] ~= nil then
                if xPlayer.identifier == data[1].reciver then
                    KeyFound = true
                end
            end
            if KeyFound then
                cb(true)
            else
                cb(false)
            end
        end)  
    end
end)

ESX.RegisterServerCallback("inf_keys:fetchData", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local vehicles = {}
    if xPlayer then
        MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner=@identifier',{['@identifier'] = xPlayer.getIdentifier()}, function(data)
            for k,v in pairs(data) do
                local vehicle = json.decode(v.vehicle)
                table.insert(vehicles, {owner = v.owner, vehicle = vehicle, plate = v.plate, gotKey = v.gotKey, alarm = v.alarm})
            end
            cb(vehicles)
        end)
    end
end)

ESX.RegisterServerCallback("inf_keys:fetchDataKey", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local check = xPlayer.getIdentifier()
    local steam = GetPlayerIdentifier(source, steam)
    local keys = {}
    if xPlayer then
        TriggerClientEvent('inf_keys:getSteam', check)
        MySQL.Async.fetchAll('SELECT * FROM lend_vehicles WHERE reciver=@identifier',{['@identifier'] = xPlayer.getIdentifier()}, function(data)
            for k,v in pairs(data) do
                local key = json.decode(v.key)
                table.insert(keys, {plate = v.plate, owner = v.owner, reciver = v.reciver, steam = v.steam})
            end
            cb(keys) 
        end)
    end
end)

ESX.RegisterServerCallback("inf_keys:fetchDataKeyOwner", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local check = xPlayer.getIdentifier()
    local steam = GetPlayerIdentifier(source, steam)
    local keysOwner = {}
    if xPlayer then
        MySQL.Async.fetchAll('SELECT * FROM lend_vehicles WHERE owner=@identifier',{['@identifier'] = xPlayer.getIdentifier()}, function(data)
            for k,v in pairs(data) do
                local key = json.decode(v.key)
                table.insert(keysOwner, {plate = v.plate, owner = v.owner, reciver = v.reciver, steam = v.steam})
            end
            cb(keysOwner) 
        end)
    end
end)

function MysqlKeys(type,query,var)
    if type == 'fetchAll' then
        local data = nil
        local res = MySQL.Async.fetchAll(query, var, function(result)
            data = result
        end)
        while data == nil do Wait(1) end
        return data
    end
    if type == 'execute'then
        MySQL.Sync.execute(query,var) 
    end

end

-- transfer vehicle to another player
RegisterServerEvent('inf_keys:transfercar')
AddEventHandler('inf_keys:transfercar', function(target, plate)
    plate = string.gsub(tostring(plate), '^%s*(.-)%s*$', '%1'):upper()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local transfer = ESX.GetPlayerFromId(target)
    if target == nil then
        xPlayer.showNotification("Ungültige User-ID! (Dürfen nur Ziffern sein)", 1, 0)
    else
        if xPlayer then
            if plate and transfer then
                local result = MysqlKeys('fetchAll','SELECT * FROM owned_vehicles WHERE plate=@plate and owner=@owner LIMIT 1', { 
                    ['@plate'] = plate, 
                    ['@owner'] = xPlayer.identifier
                })
                if #result > 0 then
                    MySQL.Async.execute('UPDATE owned_vehicles SET owner = @owner WHERE plate = @plate', {
                        ['plate'] = plate,
                        ['owner'] = transfer.identifier
                    })
                    xPlayer.showNotification("Sie übertragen das Auto mit dem Kennzeichen #"..plate.." zu "..transfer.name.."", 1, 0)
                    transfer.showNotification("Sie erhielten ein Auto mit dem Kennzeichen #"..plate.." von "..xPlayer.name.."", 1, 0)
                else
                    xPlayer.showNotification("Sie besitzen dieses Fahrzeug nicht!", 1, 0)
                end
            elseif not transfer then
                xPlayer.showNotification("Spieler existiert nicht!", 1, 0)
            else
                xPlayer.showNotification("Ungültiges Kennzeichen! (Dürfen nur Ziffern sein)", 1, 0)
            end
        end
    end
end)

--Server event to add keys to table
RegisterServerEvent("inf_keys:lendCarKeys")
AddEventHandler("inf_keys:lendCarKeys", function(target, plate, gotKey)
    local xPlayer = ESX.GetPlayerFromId(source)
	local tPlayer = ESX.GetPlayerFromId(target)
	local carPlate = tostring(plate)
    local Keys = tostring(gotKey)

    MySQL.Async.execute('INSERT INTO lend_vehicles (owner, plate, reciver) VALUES (@owner, @plate, @reciver)', {
        ['@owner'] = xPlayer.identifier,
        ['@plate'] = carPlate,
        ['@reciver'] = tPlayer.identifier
    })
    MySQL.Async.execute('UPDATE owned_vehicles SET gotKey=@gotKey WHERE plate=@plate',{['@plate'] = plate,['@gotKey'] = Keys - 1}, function() end)
	-- Send client notifications:
    xPlayer.showNotification(Lang['keys_lend_give'], 1, 0)
    tPlayer.showNotification(Lang['keys_lend_receive'], 1, 0)
end)

--Server event to remove keys from table
RegisterServerEvent("inf_keys:lendCarKeysBack")
AddEventHandler("inf_keys:lendCarKeysBack", function(target, plate, gotKey, owner)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xPlaxerSteam = xPlayer.getIdentifier()
	local tPlayer = ESX.GetPlayerFromId(target)
    local tPlayerSteam = tPlayer.getIdentifier()
	local carPlate = tostring(plate)
    local Keys = tostring(gotKey)
    local Owner = tostring(owner)
    local lended = false

    if Owner == tPlayerSteam then
        MySQL.Async.execute('DELETE from lend_vehicles WHERE owner = @owner AND plate = @plate AND reciver = @reciver LIMIT 1', {
            ['@owner'] = tPlayerSteam,
            ['@plate'] = plate,
            ['@reciver'] = xPlaxerSteam
        })
        MySQL.Async.execute('UPDATE owned_vehicles SET gotKey=@gotKey WHERE plate=@plate',{['@plate'] = plate,['@gotKey'] = Keys + 1}, function() end)
        -- Send client notifications:
        xPlayer.showNotification(Lang['keys_lend_back'], 1, 0)
        tPlayer.showNotification(Lang['keys_lend_back_reciver'], 1, 0)
    else
        xPlayer.showNotification(Lang['no_owner_nearby'], 1, 0)
    end 
end)

--Server event to remove keys from table
RegisterServerEvent("inf_keys:lendCarKeysBackOwner")
AddEventHandler("inf_keys:lendCarKeysBackOwner", function(target, plate, gotKey, reciver)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xPlayerSteam = xPlayer.getIdentifier()
	local tPlayer = ESX.GetPlayerFromId(target)
    local tPlayerSteam = tPlayer.getIdentifier()
	local carPlate = tostring(plate)
    local Keys = tostring(gotKey)
    local Reciver = tostring(reciver)

    if Reciver == tPlayerSteam then
        MySQL.Async.execute('DELETE from lend_vehicles WHERE owner = @owner AND plate = @plate AND reciver = @reciver LIMIT 1', {
            ['@owner'] = xPlayerSteam,
            ['@plate'] = plate,
            ['@reciver'] = tPlayerSteam
        })
        MySQL.Async.execute('UPDATE owned_vehicles SET gotKey=@gotKey WHERE plate=@plate',{['@plate'] = plate,['@gotKey'] = Keys + 1}, function() end)
        -- Send client notifications:
        xPlayer.showNotification(Lang['keys_lend_back_owner'], 1, 0)
        tPlayer.showNotification(Lang['keys_lend_back_owner_receiver'], 1, 0)
    else
        xPlayer.showNotification(Lang['no_players_nearby'], 1, 0)
    end        
end)

-- Server event to update vehicle insurance state:
RegisterServerEvent("inf_keys:registerNewKey")
AddEventHandler("inf_keys:registerNewKey", function(plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner=@identifier',{['@identifier'] = xPlayer.getIdentifier()}, function(data) 
			for k,v in pairs(data) do
				if plate == v.plate then
                    local Keys = v.gotKey
                    paidKey = false
                    if Config.KeyPayBankMoney then
                        if xPlayer.getAccount('bank').money >= Config.RegisterKeyPrice then
                            xPlayer.removeAccountMoney('bank', Config.RegisterKeyPrice)
                            paidKey = true
                        else
                            paidKey = false
                        end
                    else
                        if xPlayer.getMoney() >= Config.RegisterKeyPrice then
                            xPlayer.removeMoney(Config.RegisterKeyPrice)
                            paidKey = true
                        else
                            paidKey = false
                        end
                    end
                    if paidKey then
                        MySQL.Async.execute('UPDATE owned_vehicles SET gotKey=@gotKey WHERE plate=@plate',{['@plate'] = plate,['@gotKey'] = Keys + 1}, function() end)
                    else
                        xPlayer.showNotification(Lang['not_enough_money'])
                    end
				end
			end
		end)
	end
end)

-- Lock vehicle
RegisterServerEvent("inf_keys:lockVehicle")
AddEventHandler("inf_keys:lockVehicle", function(vehLock, car)
    local vLocked = vehLock
    local PlyCar = car
    print(vLocked)
    print(PlyCar)
    if vLocked then
        SetVehicleDoorsLocked(PlyCar, 1)
    else
        SetVehicleDoorsLocked(PlyCar, 2)
    end        
end)