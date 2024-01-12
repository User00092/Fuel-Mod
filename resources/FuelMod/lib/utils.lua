
local utils = {}
utils.used_vehicles = {}
utils.log_file = nil

utils.getCurrentDateTime = function()
    return os.date("%Y-%m-%d %H:%M:%S")
end

function debug(text)
    local timestamp = utils.getCurrentDateTime()
    if config_handler:get("debug_to_file", false) then
        if not utils.log_file then
            utils.log_file = io.open(stand_log_path .. "log_" .. timestamp .. ".log", "w")
        end
        utils.log_file:write("[" .. timestamp .. "]" .. text .. "\n")
        util.log("[Fuel Mod Logs][" .. timestamp .. "]" .. text .. "\n")
    end

    if config_handler:get("debug_to_console", false) then
        print("[Fuel Mod Logs][" .. timestamp .. "]" .. text)
    end
end

utils.create_file = function(filename, data)
    local file = io.open(filename, "r")

    if not file then
        file = io.open(filename, "w")
        if file then
            file:write(data or "")
            file:close()
            return true
        else
            return false
        end
    else
        file:close()
        return true
    end
end

utils.notify = function (message)
    util.toast(message)
end

utils.created_blips = {}
utils.last_blip = nil

utils.create_blips = function ()
    if not config_handler:get("enable_blips", false) or not settings.enabled then
        return
    end

    while (util.is_session_transition_active() == true) do
        util.yield(10)
    end

    if utils.last_blip then
        utils.remove_blips()
    end

    for _, coords in ipairs(fuel.GAS_STATION_COORDS) do
        local hubBlip = HUD.ADD_BLIP_FOR_COORD(coords.x, coords.y, coords.z)
        HUD.SET_BLIP_SPRITE(hubBlip, 361)
        HUD.SET_BLIP_COLOUR(hubBlip, 75)
        HUD.SET_BLIP_SCALE(hubBlip, config_handler:get("blip_scale", 0.8))

        table.insert(utils.created_blips, {blip = hubBlip, coords_ = coords})
        utils.last_blip = hubBlip
    end
end

utils.remove_blips = function ()
    for _, blip in utils.created_blips do
        if blip and blip.blip then
            util.remove_blip(blip.blip)
        end

    end
    utils.created_blips = {}
    utils.last_blip = nil
end

utils.stand_to_float = function (value)
    return value / 100
end

utils.float_to_stand = function (value)
    return value * 100
end

utils.get_vehicle_display_name = function (player)
    return VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(players.get_vehicle_model(player or players.user()))
end

utils.get_vehicle_model_value = function (player)
    return VEHICLE.GET_VEHICLE_CLASS_FROM_NAME(players.get_vehicle_model(player or players.user()))
end

utils.get_vehicle_fuel_capacity = function (vm)
    return fuel.class_fuel_capacity[vm or utils.get_vehicle_model_value()][2]
end

utils.does_vehicle_exist = function (v_handle)
    if not v_handle or not utils.used_vehicles[v_handle] then
        return false
    elseif not ENTITY.DOES_ENTITY_EXIST(v_handle)then
        return false
    elseif not ENTITY.IS_ENTITY_A_VEHICLE(v_handle) then
        return false
    elseif VEHICLE.GET_VEHICLE_ENGINE_HEALTH(v_handle) <= 0 then
        return false
    elseif OBJECT.GET_HAS_OBJECT_BEEN_COMPLETELY_DESTROYED(v_handle) then
        return false
    end
    return true
end

utils.is_electric = function (vehicle_display_name)
    for _, v in fuel.electric_vehicle_list do
        if string.lower(vehicle_display_name or utils.get_vehicle_display_name()) == string.lower(v) then
            return true
        end
    end
    return false
end

utils.is_empty = function (search)
    return search == nil or search == ''
end

utils.get_user_vehicle_as_handle = function ()
    local e = entities.get_user_vehicle_as_handle(false)
    if e == -1 or not e then
        return nil
    end
    return e
end

utils.get_user_vehicle_as_pointer = function ()
    local e = entities.get_user_vehicle_as_pointer(false)
    if e == 0 or not e then
        return nil
    end
    return e
end

utils.vehicle_manager_options = {}

utils.remove_vehicle = function (v_handle)
    utils.remove_menu_ref(utils.vehicle_manager_options[v_handle]["root"] or nil)
    utils.vehicle_manager_options[v_handle] = nil
    utils.used_vehicles[v_handle] = nil
    utils.update_vehicle_options()
end

utils.remove_menu_ref = function (ref)
    if not ref or not menu.is_ref_valid(ref) then
        return
    end

    menu.delete(ref)
end 

utils.update_vehicle_manager = function()
    for v_handle, v_data in utils.used_vehicles do
        if utils.does_vehicle_exist(v_handle) then
            local vehicle_percentage = (v_data.fuel_level / v_data.tank_size) * 100
            local vehicle_on_text = "Off"

            if VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(v_handle) then
                vehicle_on_text = "Running"
            end

            -- Create the manager
            if utils.is_empty(utils.vehicle_manager_options[v_handle]) then
                utils.vehicle_manager_options[v_handle] = {}
                utils.vehicle_manager_options[v_handle]["root"] = menu.list(settings.stand.vehicle_manager_root, v_data.v_name .. " (" ..  v_handle .. ")")

                utils.vehicle_manager_options[v_handle]["fuel_text"] = menu.readonly(utils.vehicle_manager_options[v_handle]["root"], "-- " .. labels.VEHICLE_MANAGER_FUEL .. " --", utils.formatNumber(vehicle_percentage, 2) .. "%")
                utils.vehicle_manager_options[v_handle]["handle_text"] = menu.readonly(utils.vehicle_manager_options[v_handle]["root"], "-- " .. labels.VEHICLE_MANAGER_HANDLE .. " --", v_handle)
                utils.vehicle_manager_options[v_handle]["engine_state_text"] = menu.readonly(utils.vehicle_manager_options[v_handle]["root"], "-- " .. labels.VEHICLE_MANAGER_ENGINE_STATE .. " --", vehicle_on_text)

                utils.vehicle_manager_options[v_handle]["refuel_action"] = menu.action(utils.vehicle_manager_options[v_handle]["root"], labels.VEHICLE_MANAGER_REFUEL, {}, "", function ()
                    utils.refuel_specific_vehicle(v_handle)
                end)

                utils.vehicle_manager_options[v_handle]["toggle_engine"] = menu.action(utils.vehicle_manager_options[v_handle]["root"], labels.VEHICLE_MANAGER_TOGGLE_ENGINE, {}, "", function ()
                    if (VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(v_handle)) then
                        VEHICLE.SET_VEHICLE_ENGINE_ON(v_handle, false, false, true)
                    else
                        VEHICLE.SET_VEHICLE_ENGINE_ON(v_handle, true, true, false)
                    end

                end)

                utils.vehicle_manager_options[v_handle]["remove_action"] = menu.action(utils.vehicle_manager_options[v_handle]["root"], labels.VEHICLE_MANAGER_REMOVE, {}, "", function ()
                    utils.remove_vehicle(v_handle)
                end)

            -- Update the vehicle data in the manager
            else
                menu.set_value(utils.vehicle_manager_options[v_handle]["fuel_text"], utils.formatNumber(vehicle_percentage, 2) .. "%")
                menu.set_value(utils.vehicle_manager_options[v_handle]["engine_state_text"], vehicle_on_text)
            end
        end
    end

end

utils.update_vehicle_options = function ()
    local refuel_options = {
        {1, "Current"},
        {2, "All"},
    }

    for v_handle, v_data in utils.used_vehicles do
        if utils.does_vehicle_exist(v_handle) then
            table.insert(refuel_options, {v_handle, v_data.v_name})
        end
    end
    menu.set_list_action_options(settings.stand.refuel_vehicle, refuel_options)

    utils.update_vehicle_manager()
end

utils.remove_all_vehicles = function()
    for v_handle, _ in utilities.used_vehicles do
        utils.remove_vehicle(v_handle)
    end
end

utils.update_vehicle = function(v_handle)
    local vh = v_handle or utils.get_user_vehicle_as_handle()

    if not vh then
        utils.update_vehicle_options()
        return
    end

    if utils.is_empty(utils.used_vehicles[vh]) then
        local vm = utils.get_vehicle_model_value()
        local tank_capacity
        local v_is_electric = utils.is_electric()
        if v_is_electric then
            tank_capacity = fuel.class_fuel_capacity.electrics[2]
        else
            tank_capacity = utils.get_vehicle_fuel_capacity(vm)
        end

        utils.used_vehicles[vh] = {
            v_name = utils.get_vehicle_display_name(),
            v_handle = vh,
            v_model = vm,
            fuel_level = config_handler:get("base_fuel_level", 40) / 100 * tank_capacity,
            tank_size = tank_capacity,
            latest_coords = entities.get_position(entities.handle_to_pointer(vh)),
            is_electric = v_is_electric
        }

    else
        utils.used_vehicles[vh].latest_coords = entities.get_position(entities.handle_to_pointer(vh))
    end
    utils.update_vehicle_options()
end

utils.refresh_vehicles = function()
    for v_handle, _ in utils.used_vehicles do
        if not utils.does_vehicle_exist(v_handle) then
            utils.remove_vehicle(v_handle)
        end
    end
end

utils.get_vehicle_speed = function (vh)
    return ENTITY.GET_ENTITY_SPEED(vh or utils.get_user_vehicle_as_handle())
end

utils.get_distance_between_coords = function (first, second)
    local x = second.x - first.x
    local y = second.y - first.y
    local z = second.z - first.z
    return math.sqrt(x * x + y * y + z * z)
end


utils.can_refuel = function (vehicle_coords)
    local pos
    if (vehicle_coords or false) == false then
        local player = players.user()
        pos =  players.get_position(player)
    else
        pos =  vehicle_coords
    end

    for _, coords in fuel.GAS_PUMP_COORDS do
        if utils.get_distance_between_coords(pos, coords) <= config_handler:get("station_range", 5) then
            return true
        end
    end
    return false
end

utils.formatNumber = function (number, decimalPlaces)
    local multiplier = 10 ^ (decimalPlaces or 1)
    return math.floor(number * multiplier + 0.5) / multiplier
end

utils.stand_to_color = function (value)
    return value * 255
end

utils.color_to_stand = function (value)
    return value / 255
end

utils.refuel_all_vehicles = function ()
    for v_handle, _ in utilities.used_vehicles do
        utils.used_vehicles[v_handle].fuel_level = utils.used_vehicles[v_handle].tank_size
    end
end

utils.refuel_specific_vehicle = function (v_handle)
    if not v_handle or not utils.used_vehicles[v_handle] then
        return
    end
    utils.used_vehicles[v_handle].fuel_level = utils.used_vehicles[v_handle].tank_size
end

utils.decrease_vehicle_fuel_level = function (v_handle, v_model)
    if (utils.used_vehicles[v_handle].fuel_level > 0 and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(v_handle)) then
        local rpm_value = fuel.fuel_usage[utils.formatNumber(entities.get_rpm(entities.handle_to_pointer(v_handle)), 1)]

        if utils.used_vehicles[v_handle].is_electric then
            utils.used_vehicles[v_handle].fuel_level = utils.used_vehicles[v_handle].fuel_level - rpm_value * (fuel.class_fuel_capacity.electrics[1]) * ((config_handler:get("consumption_rate", 0.8))/ 10)
            utils.used_vehicles[v_handle].tank_size = fuel.class_fuel_capacity.electrics[2]
        else
            if rpm_value == 0.0 then
                rpm_value = 0.002
            end

            utils.used_vehicles[v_handle].fuel_level = utils.used_vehicles[v_handle].fuel_level - (rpm_value * (fuel.class_fuel_capacity[v_model][1]) * (config_handler:get("consumption_rate", 0.8))) / 15

        end

        if utils.used_vehicles[v_handle].fuel_level < 0 then
            utils.used_vehicles[v_handle].fuel_level = 0
        end
        if utils.used_vehicles[v_handle].fuel_level > utils.used_vehicles[v_handle].tank_size then
            utils.used_vehicles[v_handle].fuel_level = utils.used_vehicles[v_handle].tank_size
        end
    end
end

utils.increase_fuel_level = function (v_handle)
    if utils.used_vehicles[v_handle].fuel_level < utils.used_vehicles[v_handle].tank_size and utils.get_vehicle_speed(v_handle) < 1 then
        utils.used_vehicles[v_handle].fuel_level = utils.used_vehicles[v_handle].fuel_level + (config_handler:get("refuel_rate", 3) / 10)
    end

    if utils.used_vehicles[v_handle].fuel_level > utils.used_vehicles[v_handle].tank_size then
        utils.used_vehicles[v_handle].fuel_level = utils.used_vehicles[v_handle].tank_size
    end
end

utils.manual_refuel = function (v_handle)
    local pos = players.get_position(players.user())
    if (utils.used_vehicles[v_handle].latest_coords == nil) then
        return
    end

    if utils.get_vehicle_speed(v_handle) < 1 and utils.used_vehicles[v_handle].fuel_level < utils.used_vehicles[v_handle].tank_size and WEAPON.GET_SELECTED_PED_WEAPON(players.user_ped()) == util.joaat("weapon_petrolcan") and utils.get_distance_between_coords(utils.used_vehicles[v_handle].latest_coords, pos) <= config_handler:get("station_range", 5) then
        utils.used_vehicles[v_handle].fuel_level = utils.used_vehicles[v_handle].fuel_level + (config_handler:get("manual_refuel_rate", 5) / 10)

        if utils.used_vehicles[v_handle].fuel_level > utils.used_vehicles[v_handle].tank_size then
            utils.used_vehicles[v_handle].fuel_level = utils.used_vehicles[v_handle].tank_size
        end
    end
end

return utils