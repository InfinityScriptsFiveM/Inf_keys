ESX = nil
--[[
local Items = {
    {name = _U('scope'), desc = _U('remove_scope'), comtype = 'scope', type = 'component'},
    {name = _U('grip'), desc = _U('remove_grip'), comtype = 'grip', type = 'component'},
    {name = _U('flashlight'), desc = _U('remove_flashlight'), comtype = 'flashlight', type = 'component'},
    {name = _U('clip_extended'), desc = _U('remove_clip_extended'), comtype = 'clip_extended', type = 'component'},
    {name = _U('suppressor'), desc = _U('remove_suppressor'), comtype = 'suppressor', type = 'component'},
    {name = _U('luxary_finish'), desc = _U('remove_luxary_finish'), comtype = 'luxary_finish', type = 'component'},
    {name = _U('tint'), desc = _U('remove_tint'), type = 'tint'},
}

function OpenAttachmentMenuNativeUI()
    local ped = PlayerPedId()
	local hash = GetSelectedPedWeapon(ped)

    mainMenu = NativeUI.CreateMenu(_U('weapon_components'), '~b~'.. _U('remove_components'))
    _menuPool:Add(mainMenu)

    local Components = _menuPool:AddSubMenu(mainMenu, _U('components'))

    for k,v in pairs(Items) do
        local ComponentList = NativeUI.CreateItem(v.name, '~b~'.. v.desc)
        Components:AddItem(ComponentList)
        ComponentList.Activated = function(sender, index)
            if v.type == 'component' then
                TriggerServerEvent('esx_weaponammo:removeweaponcomponent', hash, v.comtype)
            elseif v.type == 'tint' then
                TriggerServerEvent('esx_weaponammo:removeweapontint', hash)
            end
        end
    end

    mainMenu:Visible(true)
    _menuPool:RefreshIndex()
    _menuPool:MouseControlsEnabled(false)
    _menuPool:MouseEdgeEnabled(false)
    _menuPool:ControlDisablingEnabled(false)
end]]

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(5)

		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end

    if ESX.IsPlayerLoaded() then
		ESX.PlayerData = ESX.GetPlayerData()
    end
end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(response)
	ESX.PlayerData = response
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(response)
	ESX.PlayerData["job"] = response
end)

local carMenu
local windowRolled = false
local window2Rolled = false
local window3Rolled = false
local window4Rolled = false
local ped = GetPlayerPed(-1)
local coords = GetEntityCoords(ped, true)
local inVeh = false
local menuOpen = false
local nativeTxt = ''
local menuvSize = ''

if Config.NativeUI == true then
    nativeTxt = 'native'
    menuvSize = 'size-125'
else
    nativeTxt = ''
    menuvSize = 'size-150'
end        

local locksmithMenu = MenuV:CreateMenu(false, Lang['locksmith_subtitle'], Config.Position, Config.MenuColorR, Config.MenuColorG, Config.MenuColorB, menuvSize, 'infrp', 'menuv', 'locksmithmenu', nativeTxt)
-- Shop Thread:
Citizen.CreateThread(function()
	while true do
        Citizen.Wait(1)
		local player = GetPlayerPed(-1)
		local coords = GetEntityCoords(player)
		for k,v in pairs(Config.Locksmith) do
			local dist = GetDistanceBetweenCoords(v.Pos[1], v.Pos[2], v.Pos[3], coords.x, coords.y, coords.z, false)
			local mk = v.Marker
			if mk.Enable and dist <= mk.DrawDist and not menuOpen then
				DrawMarker(mk.Type, v.Pos[1], v.Pos[2], v.Pos[3]-0.97, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, mk.Scale.x, mk.Scale.y, mk.Scale.z, mk.Color.r, mk.Color.g, mk.Color.b, mk.Color.a, false, true, 2, false, false, false, false)
			end
			if dist <= 1.5 and not menuOpen then
				DrawText3Ds(v.Pos[1], v.Pos[2], v.Pos[3]+0.2, Lang['open_locksmith'])
				if IsControlJustPressed(0, v.Key) then
					MenuV:OpenMenu(locksmithMenu)
					Citizen.Wait(250)
				end
            end    
		end
	end
end)

locksmithMenu:On('open', function(locksmith)
    locksmithMenu:ClearItems()
    ped = GetPlayerPed(-1)
    menuOpen = true
	FreezeEntityPosition(ped, true)
	
	ESX.TriggerServerCallback("inf_keys:fetchData", function(vehicles)
		
		for k,v in pairs(vehicles) do
			local vehHash = v.vehicle.model
			local vehName = GetDisplayNameFromVehicleModel(vehHash)
			local vehLabel = GetLabelText(vehName)
            local plate = v.plate
			locksmithMenu:AddButton({ icon = '🔑', label = vehLabel.." ("..v.plate..") " .."Anzahl:"..v.gotKey.."", value = vehName, description = Lang['locksmith_desc'],  plate = v.plate, gotKey = v.gotKey, select = function(vehName) 
                TriggerServerEvent('inf_keys:registerNewKey', plate)
                ESX.ShowNotification(Lang['key_registert'])
                MenuV:CloseMenu(locksmithMenu)
                Wait(100)
                MenuV:OpenMenu(locksmithMenu)
            end})    
		end
	end)
end)
locksmithMenu:On('close', function(Closelocksmith)
    ped = GetPlayerPed(-1)
    menuOpen = false
    FreezeEntityPosition(ped, false)
end)    
RegisterCommand('engine', function(source, args)
	startEngine()
end, false)

RegisterKeyMapping('engine', 'Toggle Engine', 'keyboard', 'M')

local menu = MenuV:CreateMenu(false, Lang['car_subtitle'], Config.Position, Config.MenuColorR, Config.MenuColorG, Config.MenuColorB, menuvSize, 'infrp', 'menuv', 'carmenu', nativeTxt)  -- if you want a title replace false with Lang['car_title']
menu:OpenWith('KEYBOARD', 'F4') -- Press F1 to open Menu
local button_engine = menu:AddButton({ icon = '🚘', label = Lang['engine_title'], value = 'engine', description = Lang['engine_desc'], disabled = false })
button_engine:On('select', function(item)
    local car = nil
    ped = GetPlayerPed(-1)

    if IsPedInAnyVehicle(ped,  false) then
		car = GetVehiclePedIsIn(ped, false)
	else
		car = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
	end  
    if IsPedInAnyVehicle(ped, true) then
        if GetIsVehicleEngineRunning(car) then
            SetVehicleEngineOn(car,false,true,true)
            ESX.ShowNotification(Lang['engine_off'])
        else
            SetVehicleEngineOn(car,true,true,true)
            ESX.ShowNotification(Lang['engine_on'])
        end
    else
        ESX.ShowNotification(Lang['not_in_veh'])    
    end 
end) 
local neon = MenuV:CreateMenu(false, Lang['neon_title'], Config.Position, Config.MenuColorR, Config.MenuColorG, Config.MenuColorB, menuvSize, 'infrp', false, false, nativeTxt)
local button_neon = menu:AddButton({ icon = '💡', label = Lang['neon_title'], value = neon })
local button_neon_all = neon:AddButton({ icon = '💡', label = Lang['neon_all_title'], value = 'neonAll', description = Lang['neon_desc'] })
button_neon_all:On('select', function(item)
    local car = nil
    ped = GetPlayerPed(-1)
    if IsPedInAnyVehicle(ped,  false) then
		car = GetVehiclePedIsIn(ped, false)
	else
		car = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
	end  
    if DoesEntityExist(car) then
        if IsPedInAnyVehicle(ped,  false) then
            if GetIsVehicleEngineRunning(car) then
                if IsVehicleNeonLightEnabled(car,0) then
                    SetVehicleNeonLightEnabled(car,0,false)
                    SetVehicleNeonLightEnabled(car,1,false)
                    SetVehicleNeonLightEnabled(car,2,false)
                    SetVehicleNeonLightEnabled(car,3,false)
                elseif IsVehicleNeonLightEnabled(car,1) then   
                    SetVehicleNeonLightEnabled(car,0,false)
                    SetVehicleNeonLightEnabled(car,1,false)
                    SetVehicleNeonLightEnabled(car,2,false)
                    SetVehicleNeonLightEnabled(car,3,false)
                elseif IsVehicleNeonLightEnabled(car,2) then  
                    SetVehicleNeonLightEnabled(car,0,false)
                    SetVehicleNeonLightEnabled(car,1,false)
                    SetVehicleNeonLightEnabled(car,2,false)
                    SetVehicleNeonLightEnabled(car,3,false)
                elseif IsVehicleNeonLightEnabled(car,3) then  
                    SetVehicleNeonLightEnabled(car,0,false)
                    SetVehicleNeonLightEnabled(car,1,false)
                    SetVehicleNeonLightEnabled(car,2,false)
                    SetVehicleNeonLightEnabled(car,3,false)
                else
                    SetVehicleNeonLightEnabled(car,0,true)
                    SetVehicleNeonLightEnabled(car,1,true)
                    SetVehicleNeonLightEnabled(car,2,true)
                    SetVehicleNeonLightEnabled(car,3,true)
                end
            else
                ESX.ShowNotification(Lang['engine_must_on'])
            end
        else    
            ESX.ShowNotification(Lang['no_veh_nearby'])
        end      
    else
        ESX.ShowNotification(Lang['no_veh_nearby'])
    end
end) 
local slider_neons = neon:AddSlider({ icon = '💡', label = Lang['neon_title'], value = 'neonSlider', values = {
    { label =  Lang['neon_l_title'], value = 0, description = Lang['neon_desc'] },
    { label = Lang['neon_r_title'], value = 1, description = Lang['neon_desc'] },
    { label = Lang['neon_b_title'], value = 3, description = Lang['neon_desc'] },
    { label = Lang['neon_f_title'], value = 2, description = Lang['neon_desc'] }
}})
slider_neons:On('select', function(item, value)
    local car = nil
    ped = GetPlayerPed(-1)
    if IsPedInAnyVehicle(ped,  false) then
		car = GetVehiclePedIsIn(ped, false)
	else
		car = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
	end 
    if DoesEntityExist(car) then
        if IsPedInAnyVehicle(ped,  false) then
            if GetIsVehicleEngineRunning(car) then
                if IsVehicleNeonLightEnabled(car,value) then
                    SetVehicleNeonLightEnabled(car,value,false)
                else
                    SetVehicleNeonLightEnabled(car,value,true)
                end  
            else
                ESX.ShowNotification(Lang['engine_must_on'])
            end  
        else 
            ESX.ShowNotification(Lang['no_veh_nearby'])
        end    
    else
        ESX.ShowNotification(Lang['no_veh_nearby'])
    end          
end)
local windows = MenuV:CreateMenu(false, Lang['window_title'], Config.Position, Config.MenuColorR, Config.MenuColorG, Config.MenuColorB, menuvSize, 'infrp', false, false, nativeTxt)
local button_windows = menu:AddButton({ icon = '🚗', label = Lang['window_title'], value = windows })
local button_window_all = windows:AddButton({ icon = '🚗', label = Lang['window_all_title'], value = 'windowAll', description = Lang['window_desc'] })
button_window_all:On('select', function(item)
    local car = nil
    ped = GetPlayerPed(-1)
    if IsPedInAnyVehicle(ped,  false) then
		car = GetVehiclePedIsIn(ped, false)
	else
		car = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
	end  
    if DoesEntityExist(car) then
        if IsPedInAnyVehicle(ped,  false) then
            if windowRolled then
                RollUpWindow(car, 0)
                RollUpWindow(car, 1)
                RollUpWindow(car, 2)
                RollUpWindow(car, 3)
                windowRolled = false
                window2Rolled = false
                window3Rolled = false
                window4Rolled = false
            elseif window2Rolled then   
                RollUpWindow(car, 0)
                RollUpWindow(car, 1)
                RollUpWindow(car, 2)
                RollUpWindow(car, 3)
                windowRolled = false
                window2Rolled = false
                window3Rolled = false
                window4Rolled = false
            elseif window3Rolled then  
                RollUpWindow(car, 0)
                RollUpWindow(car, 1)
                RollUpWindow(car, 2)
                RollUpWindow(car, 3)
                windowRolled = false
                window2Rolled = false
                window3Rolled = false
                window4Rolled = false
            elseif window4Rolled then  
                RollUpWindow(car, 0)
                RollUpWindow(car, 1)
                RollUpWindow(car, 2)
                RollUpWindow(car, 3)
                windowRolled = false
                window2Rolled = false
                window3Rolled = false
                window4Rolled = false
            else
                RollDownWindow(car, 0)
                RollDownWindow(car, 1)
                RollDownWindow(car, 2)
                RollDownWindow(car, 3)
                windowRolled = true
                window2Rolled = true
                window3Rolled = true
                window4Rolled = true
            end
        else    
            ESX.ShowNotification(Lang['no_veh_nearby'])
        end    
    else
        ESX.ShowNotification(Lang['no_veh_nearby'])
    end
end) 
local slider_windows = windows:AddSlider({ icon = '🚗', label = Lang['window_title'], value = 'windowSlider', values = {
    { label =  Lang['window_f_l_title'], value = 0, description = Lang['window_desc'] },
    { label = Lang['window_f_r_title'], value = 1, description = Lang['window_desc'] },
    { label = Lang['window_b_l_title'], value = 3, description = Lang['window_desc'] },    
    { label = Lang['window_b_r_title'], value = 2, description = Lang['window_desc'] }   
}})
slider_windows:On('select', function(item, value)
    local car = nil
    ped = GetPlayerPed(-1)
    if IsPedInAnyVehicle(ped,  false) then
		car = GetVehiclePedIsIn(ped, false)
	else
		car = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
	end 
    if value == 0 and IsPedInAnyVehicle(ped, false) then
        if not windowRolled then 
            RollDownWindow(car, 0)
            windowRolled = true
        else 
            RollUpWindow(car, 0)
            windowRolled = false
        end	
    elseif value == 1 and IsPedInAnyVehicle(ped, false) then   
        if not window2Rolled then 
            RollDownWindow(car, 1)
            window2Rolled = true
        else 
            RollUpWindow(car, 1)
            window2Rolled = false
        end	 
    elseif value == 2 and IsPedInAnyVehicle(ped, false) then
        if DoesVehicleHaveDoor(car, 3) then
            if not window3Rolled then 
                RollDownWindow(car, 3)
                window3Rolled = true
            else 
                RollUpWindow(car, 3)
                window3Rolled = false
            end
        else
            ESX.ShowNotification(Lang['window_no_door'])
        end        
    elseif value == 3 and IsPedInAnyVehicle(ped, false) then
        if DoesVehicleHaveDoor(car, 2) then
            if not window4Rolled then 
                RollDownWindow(car, 2)
                window4Rolled = true
            else 
                RollUpWindow(car, 2)
                window4Rolled = false
            end
        else
            ESX.ShowNotification(Lang['window_no_door'])
        end    
    elseif not IsPedInAnyVehicle(ped, false) then
        ESX.ShowNotification(Lang['no_veh_nearby'])
    end                
end)
local doors = MenuV:CreateMenu(false, Lang['door_title'], Config.Position, Config.MenuColorR, Config.MenuColorG, Config.MenuColorB, menuvSize, 'infrp', false, false, nativeTxt)
local button_doors = menu:AddButton({ icon = '🚪', label = Lang['door_title'], value = doors })
local button_door_all = doors:AddButton({ icon = '🚪', label = Lang['door_all_title'], value = 'doorsAll', description = Lang['door_desc'] })
button_door_all:On('select', function(item)
    local car = nil
    ped = GetPlayerPed(-1)
    coords = GetEntityCoords(ped, true)
    if IsPedInAnyVehicle(ped,  false) then
		car = GetVehiclePedIsIn(ped, false)
    else
        car = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
    end

    if DoesEntityExist(car) then
        local CarDoors = GetNumberOfVehicleDoors(car)
        for i = 0,CarDoors do
            if DoesVehicleHaveDoor(car, i) then
                if GetVehicleDoorAngleRatio(car, 0) > 0.0 then 
                    SetVehicleDoorShut(car, 0, false)
                    SetVehicleDoorShut(car, 1, false)
                    SetVehicleDoorShut(car, 2, false)
                    SetVehicleDoorShut(car, 3, false)
                    SetVehicleDoorShut(car, 4, false)
                    SetVehicleDoorShut(car, 5, false)
                else 
                    SetVehicleDoorOpen(car, 0, false)
                    SetVehicleDoorOpen(car, 1, false)
                    SetVehicleDoorOpen(car, 2, false)
                    SetVehicleDoorOpen(car, 3, false)
                    SetVehicleDoorOpen(car, 4, false)
                    SetVehicleDoorOpen(car, 5, false)
                end
            end
        end
    else
        ESX.ShowNotification(Lang['no_veh_nearby'])
    end
end)    
local slider_doors = doors:AddSlider({ icon = '🚪', label = Lang['door_title'], value = 'doorSlider', values = {
    { label =  Lang['door_l_title'], value = 0, description = Lang['window_desc'] },
    { label = Lang['door_r_title'], value = 1, description = Lang['window_desc'] },
    { label = Lang['door_b_title'], value = 2, description = Lang['window_desc'] },    
    { label = Lang['door_b_r_title'], value = 3, description = Lang['window_desc'] },
    { label = Lang['door_trunk_title'], value = 5, description = Lang['window_desc'] },
    { label = Lang['door_hood_title'], value = 4, description = Lang['window_desc'] },   
}})
slider_doors:On('select', function(item, value)
    local car = nil
    ped = GetPlayerPed(-1)
    coords = GetEntityCoords(ped, true)
    if IsPedInAnyVehicle(ped,  false) then
		car = GetVehiclePedIsIn(ped, false)
	else
		car = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
	end 
    if DoesEntityExist(car) then
        if DoesVehicleHaveDoor(car, value) then
            if GetVehicleDoorAngleRatio(car, value) > 0.0 then
                SetVehicleDoorShut(car, value, false)
            else 
                SetVehicleDoorOpen(car, value, false) 
            end
        else
            ESX.ShowNotification(Lang['no_door'])  
        end            
    else
        ESX.ShowNotification(Lang['no_veh_nearby'])
    end
end)
local sellChoose = MenuV:CreateMenu(false, Lang['sell_confirm'], Config.Position, Config.MenuColorR, Config.MenuColorG, Config.MenuColorB, menuvSize, 'infrp', false, false, nativeTxt)
local button_sell = menu:AddButton({ icon = '💳', label = Lang['sell_title'], value = sellChoose, description = Lang['sell_desc'], disabled = false })
local confirmSell = sellChoose:AddConfirm({ icon = '💳', label = 'Bestätigen', value = 'no' })
confirmSell:On('confirm', function(item) 
    local ped = GetPlayerPed(-1)
    local coords = GetEntityCoords(ped)
    local vehicle = GetNearestVehicleinPool(coords, 5)
    local player, distance = ESX.Game.GetClosestPlayer()
    if not IsPedInAnyVehicle(ped, false) then
        if distance ~= -1 and distance <= 2.0 then
            if vehicle.state ~= nil then
                TaskTurnPedToFaceEntity(ped, vehicle.vehicle, 1500)
                TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
                Wait(5000)
                ClearPedTasksImmediately(ped)
                local plate = GetVehicleNumberPlateText(vehicle.vehicle)
                local userid = ESX.Game.GetClosestPlayer()
                TriggerServerEvent("inf_keys:transfercar", GetPlayerServerId(player), plate)
            else
                ESX.ShowNotification(Lang['no_veh_nearby'])
            end
        else
            ESX.ShowNotification(Lang['no_players_nearby'])
        end    
    else
        ESX.ShowNotification(Lang['sell_get_out_veh'])
    end
end)
confirmSell:On('deny', function(item) MenuV:CloseMenu(sellChoose) end)
local keys = MenuV:CreateMenu(false, Lang['key_title'], Config.Position, Config.MenuColorR, Config.MenuColorG, Config.MenuColorB, menuvSize, 'infrp', false, false, nativeTxt)
local button_keys_menu = menu:AddButton({ icon = '🔑', label = Lang['key_title'], value = keys })
local all_keys = MenuV:CreateMenu(false, Lang['all_key_title'], Config.Position, Config.MenuColorR, Config.MenuColorG, Config.MenuColorB, menuvSize, 'infrp', false, false, nativeTxt)
local button_keys = {} --keys:AddButton({ icon = '🔑', label = Lang['key_title'], value = 'keys', description = Lang['keys_desc'], disabled = false })
local lendeble_keys = MenuV:CreateMenu(false, Lang['lendeble_key_title'], Config.Position, Config.MenuColorR, Config.MenuColorG, Config.MenuColorB, menuvSize, 'infrp', false, false, nativeTxt)
local recived_keys = MenuV:CreateMenu(false, Lang['recived_key_title'], Config.Position, Config.MenuColorR, Config.MenuColorG, Config.MenuColorB, menuvSize, 'infrp', false, false, nativeTxt)
local gived_keys = MenuV:CreateMenu(false, Lang['lended_key_title'], Config.Position, Config.MenuColorR, Config.MenuColorG, Config.MenuColorB, menuvSize, 'infrp', false, false, nativeTxt)
local button_all_keys_menu = keys:AddButton({ icon = '🔑', label = Lang['all_key_title'], value = all_keys })
local button_lendeble_keys_menu = keys:AddButton({ icon = '🔑', label = Lang['lendeble_key_title'], value = lendeble_keys })
local button_recived_keys_menu = keys:AddButton({ icon = '🔑', label = Lang['recived_key_title'], value = recived_keys })
local button_gived_keys_menu = keys:AddButton({ icon = '🔑', label = Lang['lended_key_title'], value = gived_keys })
all_keys:On('open', function(allkeys)
    all_keys:ClearItems()
    ped = GetPlayerPed(-1)
    ESX.TriggerServerCallback("inf_keys:fetchData", function(vehicles)
        for k,v in pairs(vehicles) do
            local vehHash = v.vehicle.model
            local vehName = GetDisplayNameFromVehicleModel(vehHash)
            local vehLabel = GetLabelText(vehName)
            all_keys:AddButton({ icon = '🔑', label = vehLabel.." ("..v.plate..") " .."Anzahl:"..v.gotKey.."", value = vehName, description = Lang['keys_desc'],  plate = v.plate, gotKey = v.gotKey, select = function(vehName) 
            local player, distance = ESX.Game.GetClosestPlayer()
            if v.gotKey >= 1 then
                if distance ~= -1 and distance <= 2.0 then
                    TriggerServerEvent('inf_keys:lendCarKeys', GetPlayerServerId(player), v.plate, v.gotKey)
                    MenuV:CloseMenu(all_keys)
                    Wait(100)
                    MenuV:OpenMenu(all_keys)
                else
                    ESX.ShowNotification(Lang['no_players_nearby'])
                end
            else
                ESX.ShowNotification(Lang['no_lendeble_key'])    
            end    
            end })
        end
    end)
end)
lendeble_keys:On('open', function(lendeble_keys)
    lendeble_keys:ClearItems()
    ped = GetPlayerPed(-1)
    ESX.TriggerServerCallback("inf_keys:fetchData", function(vehicles)
        for k,v in pairs(vehicles) do
            local vehHash = v.vehicle.model
            local vehName = GetDisplayNameFromVehicleModel(vehHash)
            local vehLabel = GetLabelText(vehName)
            if v.gotKey >= 1 then
                lendeble_keys:AddButton({ icon = '🔑', label = vehLabel.." ("..v.plate..") " .."Anzahl:"..v.gotKey.."", value = vehName, description = Lang['keys_desc'],  plate = v.plate, gotKey = v.gotKey, select = function(vehName) 
                local player, distance = ESX.Game.GetClosestPlayer()
                if distance ~= -1 and distance <= 2.0 then
                    TriggerServerEvent('inf_keys:lendCarKeys', GetPlayerServerId(player), v.plate, v.gotKey)
                    MenuV:CloseMenu(lendeble_keys)
                    Wait(100)
                    MenuV:OpenMenu(lendeble_keys)
                else
                    ESX.ShowNotification(Lang['no_players_nearby'])
                end 
                end })  
            end    
        end
    end)
end)
recived_keys:On('open', function(recived_keys)
    recived_keys:ClearItems()
    ped = GetPlayerPed(-1)
    local vehHash = nil
    local vehName = nil
    local vehLabel = nil
    local gotKey = nil
    ESX.TriggerServerCallback("inf_keys:fetchData", function(vehicles)
        ESX.TriggerServerCallback("inf_keys:fetchDataKey", function(keys)
            for k,v in pairs(vehicles) do
                vehHash = v.vehicle.model
                vehName = GetDisplayNameFromVehicleModel(vehHash)
                vehLabel = GetLabelText(vehName)  
                gotKey = v.gotKey 
            end 
            for k,v in pairs(keys) do
                local reciver = v.reciver
                recived_keys:AddButton({ icon = '🔑', label = vehLabel.." ("..v.plate..") ", value = vehName, description = Lang['recived_desc'],  plate = v.plate, select = function(vehName)
                    ESX.TriggerServerCallback("inf_keys:fetchDataKeyOwner", function(keysOwner)
                        local owner = v.owner
                        local player, distance = ESX.Game.GetClosestPlayer()
                        if distance ~= -1 and distance <= 2.0 then
                            TriggerServerEvent('inf_keys:lendCarKeysBack', GetPlayerServerId(player), v.plate, gotKey, owner)
                            MenuV:CloseMenu(recived_keys)
                            Wait(100)
                            MenuV:OpenMenu(recived_keys)
                        else
                            ESX.ShowNotification(Lang['no_players_nearby'])
                        end    
                    end)
                end })  
            end    
        end)
    end)    
end)
gived_keys:On('open', function(gived_keys)
    gived_keys:ClearItems()
    ped = GetPlayerPed(-1)
    local vehHash = nil
    local vehName = nil
    local vehLabel = nil
    local gotKey = nil
    ESX.TriggerServerCallback("inf_keys:fetchData", function(vehicles)
        ESX.TriggerServerCallback("inf_keys:fetchDataKeyOwner", function(keysOwner)
            for k,v in pairs(vehicles) do
                vehHash = v.vehicle.model
                vehName = GetDisplayNameFromVehicleModel(vehHash)
                vehLabel = GetLabelText(vehName)   
                gotKey = v.gotKey 
            end 
            for k,v in pairs(keysOwner) do
                local reciver = v.reciver
                local owner = v.owner
                gived_keys:AddButton({ icon = '🔑', label = vehLabel.." ("..v.plate..") ", value = vehName, description = Lang['back_desc'],  plate = v.plate, select = function(vehName)
                    ESX.TriggerServerCallback("inf_keys:fetchDataKeyOwner", function(keysOwner)
                        local owner = v.owner
                        local player, distance = ESX.Game.GetClosestPlayer()
                        if distance ~= -1 and distance <= 2.0 then
                            TriggerServerEvent('inf_keys:lendCarKeysBackOwner', GetPlayerServerId(player), v.plate, gotKey, reciver)
                            MenuV:CloseMenu(gived_keys)
                            Wait(100)
                            MenuV:OpenMenu(gived_keys)
                        else
                            ESX.ShowNotification(Lang['no_players_nearby'])
                        end    
                    end)
                end })   
            end    
        end)
    end)    
end)

menu:On('switch', function(item, currentItem, prevItem) end)
RegisterCommand('carmenu', function(source, args)
	MenuV:OpenMenu(menu)
end, false)

function ShowCarNew()
    local car = nil
    ped = GetPlayerPed(-1)
    coords = GetEntityCoords(ped, true)
    if IsPedInAnyVehicle(ped,  false) then
		car = GetVehiclePedIsIn(ped, false)
	else
		car = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
	end   
end     

--Thread For Key Binding to Toggle Car Locks and Engine:
Citizen.CreateThread(function()
    local once = false
    local once2 = false
    ped = GetPlayerPed(-1)
	while true do
		Wait(0)
		local car = nil
		if IsPedInAnyVehicle(ped,  false) then
			car = GetVehiclePedIsIn(ped, false)
            inVeh = true
            if once == false then
                once = true
                once2 = false
                if carMenu ~= nil then
                    carMenu:Visible(false)
                end    
            end    
		else
			car = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
            inVeh = false
            if once2 == false then
                once2 = true
                once = false
                if carMenu ~= nil then
                    carMenu:Visible(false)
                end    
            end    
		end
		if IsControlJustReleased(0, 182) then
			ToggleVehicleLock()
		end 
	end
end)    

function startEngine()
    local car = nil
    ped = GetPlayerPed(-1)
    if IsPedInAnyVehicle(ped,  false) then
		car = GetVehiclePedIsIn(ped, false)
	else
		car = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
	end
    if IsPedInAnyVehicle(ped, true) then
        if GetIsVehicleEngineRunning(car) then
            SetVehicleEngineOn(car,false,true,true)
            ESX.ShowNotification(Lang['engine_off'])
        else
            SetVehicleEngineOn(car,true,true,true)
            ESX.ShowNotification(Lang['engine_on'])
        end		
    end	
end	

-- Toggle Car Locks:
function ToggleVehicleLock()
    local car = nil
    ped = GetPlayerPed(-1)
    coords = GetEntityCoords(ped, true)

    if IsPedInAnyVehicle(ped,  false) then
        car = GetVehiclePedIsIn(ped, false)
    else
        car = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
    end
    local closePlate = GetVehicleNumberPlateText(car)
    local closeHash = GetEntityModel(car)

    if DoesEntityExist(car) then
        ESX.TriggerServerCallback('inf_keys:fetchCarKey', function(hasKey)
            ESX.TriggerServerCallback('inf_keys:fetchCarWlKey', function(hasWlKey)
                ESX.TriggerServerCallback('inf_keys:fetchLendKey', function(hasLendKey)
                    Citizen.CreateThread(function()
                        if HasTempCarKeys(closePlate) or hasKey or hasWlKey or hasLendKey then
                            if GetVehicleDoorLockStatus(car) == 1 or GetVehicleDoorLockStatus(car) == 0 then
                                LockToggleEffects(car,false)
                            elseif GetVehicleDoorLockStatus(car) == 2 then
                                LockToggleEffects(car,true)
                            end
                        else
                            return ESX.ShowNotification(Lang['has_key_false'])
                        end
                    end)
                end, closePlate)
            end, closeHash)
        end, closePlate)
    else
        ESX.ShowNotification(Lang['no_veh_nearby'])
    end
end

-- Lock Toggle Anim Function /w effects:
function LockToggleEffects(car,locked)
    ped = GetPlayerPed(-1)
	local prop = GetHashKey('p_car_keys_01')
	local animDict = 'anim@mp_player_intmenu@key_fob@'
	local animLib = 'fob_click'
    local vehLock = locked
    coords = GetEntityCoords(ped, true)
    
	SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED")) 
	RequestModel(prop)
	while not HasModelLoaded(prop) do
	    Citizen.Wait(10)
	end
	local keyFob = CreateObject(prop, 1.0, 1.0, 1.0, 1, 1, 0)
	RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) do
		Citizen.Wait(1)
	end
	AttachEntityToEntity(keyFob, ped, GetPedBoneIndex(ped, 57005), 0.09, 0.04, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
	TaskPlayAnim(ped, animDict, animLib, 15.0, -10.0, 1500, 49, 0, false, false, false)
	PlaySoundFromEntity(-1, "Remote_Control_Fob", ped, "PI_Menu_Sounds", 1, 0)
	SetVehicleLights(car,2)
	Citizen.Wait(200)
	SetVehicleLights(car,1)
	Citizen.Wait(200)
	SetVehicleLights(car,2)
	Citizen.Wait(200)

    local player = ESX.Game.GetClosestPlayer(coords)

	if vehLock then
		SetVehicleDoorsLocked(car, 1)
        if player ~= nil then
            SetVehicleDoorsLockedForPlayer(car, player, false)
        end    
		PlayVehicleDoorOpenSound(car, 0)
		PlaySoundFromEntity(-1, "Remote_Control_Open", car, "PI_Menu_Sounds", 1, 0)
		ESX.ShowNotification(Lang['car_unlocked'])
		
	elseif not vehLock then
		SetVehicleDoorsLocked(car, 2)
        if player ~= nil then
            SetVehicleDoorsLockedForPlayer(car, player, true)
        end    
		PlayVehicleDoorCloseSound(car, 0)
		PlaySoundFromEntity(-1, "Remote_Control_Close", car, "PI_Menu_Sounds", 1, 0)
		ESX.ShowNotification(Lang['car_locked'])
	end
	
	Citizen.Wait(200)
	SetVehicleLights(car,1)
	SetVehicleLights(car,0)
	Citizen.Wait(200)
	DeleteEntity(keyFob)
end

carKeys = {}
plyIdentifier = 0
-- Sync Car Key Table from server to client:
RegisterNetEvent('inf_keys:syncTableKeys')
AddEventHandler('inf_keys:syncTableKeys', function(keysData, identifier)
    carKeys = keysData
    plyIdentifier = identifier
end)

-- Check if player has lended car keys:
function HasTempCarKeys(plate)
    if carKeys[plate] ~= nil then
        for k,v in pairs(carKeys[plate]) do
            if v.identifier == plyIdentifier then
                return true
            end
        end
        return false
    else
        return false
    end
end

function GetNearestVehicleinPool(coords)
    local data = {}
    data.dist = -1
    data.state = false
    for k,vehicle in pairs(GetGamePool('CVehicle')) do
        local vehcoords = GetEntityCoords(vehicle,false)
        local dist = #(coords-vehcoords)
        if data.dist == -1 or dist < data.dist then
            data.dist = dist
            data.vehicle = vehicle
            data.coords = vehcoords
            data.state = true
        end
    end
    return data
end

-- Map Blips:
Citizen.CreateThread(function()
	for k,v in pairs(Config.Locksmith) do
		CreateMapBlip(k,v)
	end	
end)

function CreateMapBlip(k,v)
	if v.Blip.Enable then
		local blip = AddBlipForCoord(v.Blip.Pos[1], v.Blip.Pos[2], v.Blip.Pos[3])
		SetBlipSprite (blip, v.Blip.Sprite)
		SetBlipDisplay(blip, v.Blip.Display)
		SetBlipScale  (blip, v.Blip.Scale)
		SetBlipColour (blip, v.Blip.Color)
		SetBlipAsShortRange(blip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(v.Blip.Name)
		EndTextCommandSetBlipName(blip)
	end
end

-- Function for 3D text:
function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())

    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 500
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 0, 0, 0, 80)
end