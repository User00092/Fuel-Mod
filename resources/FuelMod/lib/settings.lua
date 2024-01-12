labels = require(stand_lib_path .. "labels")

local settings = {}
settings.stand = {}
settings.enabled = false;

-- functions
settings.load_default = function ()
    if not menu.get_value(settings.stand.enable_button) then
        menu.set_value(settings.stand.enable_button, config_handler:get("enable_on_load", false))
    end

    menu.set_value(settings.stand.enable_on_load_button, config_handler:get("enable_on_load", false))
    menu.set_value(settings.stand.enable_blips_button, config_handler:get("enable_blips", false))
    menu.set_value(settings.stand.set_blip_scale_button, utilities.float_to_stand(config_handler:get("blip_scale", 0.8)))
    menu.set_value(settings.stand.set_consumption_rate, utilities.float_to_stand(config_handler:get("consumption_rate", 0.8)))
    menu.set_value(settings.stand.set_base_fuel_level_button, config_handler:get("base_fuel_level", 40))
    menu.set_value(settings.stand.set_station_range_button, config_handler:get("station_range", 5))
    menu.set_value(settings.stand.set_refuel_rate, config_handler:get("refuel_rate", 3))
    menu.set_value(settings.stand.set_manual_refuel_rate, config_handler:get("manual_refuel_rate", 1))
    menu.set_value(settings.stand.set_enable_percentage_text, config_handler:get("show_gas_percentage", false))

    local color_data = config_handler:get("show_gas_percentage_text_color", {
        r=255,
        g=255,
        b=255,
        a=255,
    })

    menu.set_value(menu.ref_by_command_name("setfuelmodgaspercentagetextcolorred"), color_data.r)
    menu.set_value(menu.ref_by_command_name("setfuelmodgaspercentagetextcolorgreen"), color_data.g)
    menu.set_value(menu.ref_by_command_name("setfuelmodgaspercentagetextcolorblue"), color_data.b)
    menu.set_value(menu.ref_by_command_name("setfuelmodgaspercentagetextcoloropacity"), color_data.a)

    menu.set_value(settings.stand.set_show_gas_percentage_text_position_x, utilities.float_to_stand(config_handler:get("show_gas_percentage_text_pos_x", 0.15)))
    menu.set_value(settings.stand.set_show_gas_percentage_text_position_y, utilities.float_to_stand(config_handler:get("show_gas_percentage_text_pos_y", 0.15)))
    menu.set_value(settings.stand.set_show_gas_percentage_text_scale, utilities.float_to_stand(config_handler:get("show_gas_percentage_text_scale", 1)))
end

settings.save_default = function ()
    config_handler:write()
end

-- Root
settings.stand.root = menu.my_root()
settings.stand.enable_button = menu.toggle(settings.stand.root, labels.SETTINGS_ENABLE_SCRIPT, {"enable_fuel_mod"}, "", function (state)
    settings.enabled = state
    settings.enabled = state
    if state then
        enable_script()
    else
        utilities.remove_blips()
    end
end)

-- Refuel manager
settings.stand.refuel_vehicle = menu.list_action(settings.stand.root, labels.SETTINGS_REFUEL_VEHICLE, {}, "", {{1, "Current"}, {2, "All"}}, function(action_id, action_name)
    if action_id == 1 then
        utilities.refuel_specific_vehicle(utilities.get_user_vehicle_as_handle())
    elseif action_id == 2 then
        utilities.refuel_all_vehicles()
    else
        utilities.refuel_specific_vehicle(action_id)
    end
end)

-- Vehicle manager
settings.stand.vehicle_manager_root = menu.list(settings.stand.root, labels.SETTINGS_VEHICLE_MANAGER)

-- Settings
settings.stand.settings_root = menu.list(settings.stand.root, labels.SETTINGS_SETTINGS_LABEL)

settings.stand.load_settings_button = menu.action(settings.stand.settings_root, labels.SETTINGS_LOAD_SETTINGS_LABEL, {"load_fuel_mod_settings"}, "", function ()
    settings.load_default()
    utilities.notify("Loaded settings.")
end)

settings.stand.enable_on_load_button = menu.toggle(settings.stand.settings_root, labels.SETTINGS_ENABLE_SCRIPT_ON_LOAD, {}, "", function (state)
    config_handler.data["enable_on_load"] = state
end)

settings.stand.enable_blips_button = menu.toggle(settings.stand.settings_root, labels.SETTINGS_ENABLE_BLIPS, {}, "", function (state)
    config_handler.data["enable_blips"] = state
    if not state then
        utilities.remove_blips()
    else
        utilities.create_blips()
    end
end)

settings.stand.set_blip_scale_button = menu.slider_float(settings.stand.settings_root, labels.SETTINGS_BLIP_SCALE, {"set_fuel_mod_blip_scale"}, "", utilities.float_to_stand(0.01), utilities.float_to_stand(10), utilities.float_to_stand(0.8), utilities.float_to_stand(0.1), function (standScale)
    local scale = utilities.stand_to_float(standScale)
    config_handler.data["blip_scale"] = scale

    if settings.enabled then
        utilities.create_blips()
    end
end)

settings.stand.set_base_fuel_level_button = menu.slider(settings.stand.settings_root, labels.SETTINGS_BASE_FUEL_LEVEL, {"set_fuel_mod_base_fuel_level"}, "", 1, 100, 40, 5, function (value)
    config_handler.data["base_fuel_level"] = value
end)

settings.stand.set_station_range_button = menu.slider(settings.stand.settings_root, labels.SETTINGS_STATION_RANGE, {"set_fuel_mod_station_range"}, "", 1, 100, 5, 1, function (value)
    config_handler.data["station_range"] = value
end)

settings.stand.set_consumption_rate = menu.slider_float(settings.stand.settings_root, labels.SETTINGS_CONSUMPTION_RATE, {"set_fuel_mod_consumption_rate"}, "", utilities.float_to_stand(0.01), utilities.float_to_stand(10), utilities.float_to_stand(0.8), utilities.float_to_stand(0.1), function (standScale)
    local scale = utilities.stand_to_float(standScale)
    config_handler.data["consumption_rate"] = scale
end)

settings.stand.set_refuel_rate = menu.slider(settings.stand.settings_root, labels.SETTINGS_REFUEL_RATE, {"set_fuel_mod_refuel_rate"}, "", 1, 100, 5, 1, function (value)
    config_handler.data["refuel_rate"] = value
end)

settings.stand.set_manual_refuel_rate = menu.slider(settings.stand.settings_root, labels.SETTINGS_MANUAL_REFUEL_RATE, {"set_fuel_mod_manual_refuel_rate"}, "", 1, 100, 5, 1, function (value)
    config_handler.data["manual_refuel_rate"] = value
end)

settings.stand.set_enable_percentage_text = menu.toggle(settings.stand.settings_root, labels.SETTINGS_ENABLE_PERCENTAGE_TEXT, {}, "", function (state)
    config_handler.data["show_gas_percentage"] = state
end)

settings.stand.set_show_gas_percentage_text_color = menu.colour(settings.stand.settings_root, labels.SETTINGS_GAS_PERCENTAGE_TEXT_COLOR, {"set_fuel_mod_gas_percentage_text_color"}, "", { r=1, g=1, b=1, a=1 }, true, function (value)
    config_handler.data["show_gas_percentage_text_color"] = {
        r=utilities.stand_to_color(value["r"]),
        g=utilities.stand_to_color(value["g"]),
        b=utilities.stand_to_color(value["b"]),
        a=utilities.stand_to_color(value["a"]),
    }
end)

-- Text position
settings.stand.set_show_gas_percentage_text_position_root = menu.list(settings.stand.settings_root, labels.SETTINGS_SHOW_GAS_PERCENTAGE_TEXT_POS)
settings.stand.set_show_gas_percentage_text_position_x = menu.slider_float(settings.stand.set_show_gas_percentage_text_position_root, labels.SETTINGS_SHOW_GAS_PERCENTAGE_TEXT_POS_X, {"set_fuel_mod_gas_percentage_text_pos_x"}, "", utilities.float_to_stand(0.01), utilities.float_to_stand(1), utilities.float_to_stand(0.15), utilities.float_to_stand(0.01), function (standScale)
    local scale = utilities.stand_to_float(standScale)
    config_handler.data["show_gas_percentage_text_pos_x"] = scale
end)

settings.stand.set_show_gas_percentage_text_position_y = menu.slider_float(settings.stand.set_show_gas_percentage_text_position_root, labels.SETTINGS_SHOW_GAS_PERCENTAGE_TEXT_POS_Y, {"set_fuel_mod_gas_percentage_text_pos_y"}, "", utilities.float_to_stand(0.01), utilities.float_to_stand(1), utilities.float_to_stand(0.15), utilities.float_to_stand(0.01), function (standScale)
    local scale = utilities.stand_to_float(standScale)
    config_handler.data["show_gas_percentage_text_pos_y"] = scale
end)

settings.stand.set_show_gas_percentage_text_scale = menu.slider_float(settings.stand.set_show_gas_percentage_text_position_root, labels.SETTINGS_SHOW_GAS_PERCENTAGE_TEXT_SCALE, {"set_fuel_mod_gas_percentage_text_scale"}, "", utilities.float_to_stand(0.1), utilities.float_to_stand(10), utilities.float_to_stand(1), utilities.float_to_stand(0.05), function (standScale)
    local scale = utilities.stand_to_float(standScale)
    config_handler.data["show_gas_percentage_text_scale"] = scale
end)


settings.stand.save_settings_button = menu.action(settings.stand.settings_root, labels.SETTINGS_SAVE_SETTINGS_LABEL, {"save_fuel_mod_settings"}, "", function ()
    settings.save_default()
    utilities.notify("Saved settings.")
end)

return settings