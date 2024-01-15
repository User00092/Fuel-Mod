util.require_natives("3095a")

stand_script_path = filesystem.scripts_dir()
settings_file = stand_script_path .. "\\resources\\FuelMod\\settings.json"
stand_lib_path = ".\\resources\\FuelMod\\lib\\"
stand_log_path = stand_script_path .. "\\resources\\FuelMod\\logs\\"

local required_files = {
    stand_script_path .. stand_lib_path .. "utils.lua",
    stand_script_path .. stand_lib_path .. "config.lua",
    stand_script_path .. stand_lib_path .. "settings.lua",
    stand_script_path .. stand_lib_path .. "labels.lua",
    stand_script_path .. stand_lib_path .. "fuel.lua"
}

function remove_string_prefix(original, prefix)
    if string.sub(original, 1, #prefix) == prefix then
        local modifiedString = string.sub(original, #prefix + 1)
        return modifiedString

    else
        return original
    end
end

local function file_exists(path)
    local file = io.open(path, "r")
    if not file then
        return false
    else
        file:close()
        return true
    end
end

function enable_script()
    if settings.enabled ~= true then
        return
    end

    utilities.create_blips()
    utilities.update_vehicle()
    utilities.update_vehicle_options()

    -- Fuel consumption
    util.create_thread(
        function()
            while settings.enabled == true do
                while util.is_session_transition_active() do
                    util.yield(100)
                end

                for v_handle, v_data in utilities.used_vehicles do
                    if not utilities.does_vehicle_exist(v_handle) or utilities.is_empty(utilities.used_vehicles[v_handle]) then
                        utilities.used_vehicles[v_handle] = nil
                    else
                        utilities.decrease_vehicle_fuel_level(v_handle, v_data.v_model)
                    end
                end
                util.yield(1500)
            end
        end
    )

    -- Features
    util.create_thread(function()
        while settings.enabled == true do
            while util.is_session_transition_active() do
                utilities.remove_all_vehicles()
                util.yield(100)
            end

            utilities.refresh_vehicles()
            utilities.update_vehicle()
            utilities.update_vehicle_options()

            for v_handle, v_data in utilities.used_vehicles do
                if not utilities.does_vehicle_exist(v_handle) then
                    goto continue
                end

                if v_data.fuel_level == 0 then
                    VEHICLE.SET_VEHICLE_ENGINE_ON(v_handle, false, false, true)
                end

                local vehicle_percentage = (v_data.fuel_level / v_data.tank_size) * 100

                if config_handler:get("show_gas_percentage", false) and utilities.get_user_vehicle_as_handle() == v_handle then
                    local text_pos_x = config_handler:get("show_gas_percentage_text_pos_x", 15)
                    local text_pos_y = config_handler:get("show_gas_percentage_text_pos_y", 15)
                    local text_scale = config_handler:get("show_gas_percentage_text_scale", 1)
                    text_color = config_handler:get("show_gas_percentage_text_color", {r=255, g=255, b=255, a=1})

                    directx.draw_text(
                            text_pos_x,
                            text_pos_y,
                            utilities.formatNumber(vehicle_percentage, 1) .. "%",
                            ALIGN_TOP_LEFT,
                            text_scale,
                            text_color,
                            true
                    )
                end


                ::continue::
            end

            util.yield(1)
        end
    end)

    -- Refueling
    util.create_thread(function()
        while settings.enabled do
            while util.is_session_transition_active() do
                util.yield(100)
            end
            for v_handle, v_data in utilities.used_vehicles do
                if utilities.can_refuel(v_data.latest_coords) then
                    utilities.increase_fuel_level(v_handle)
                else
                    utilities.manual_refuel(v_handle)
                end
            end
            util.yield(150)
        end
    end)
end

local function init()
    log_file = false

    for _, filename in ipairs(required_files) do
        if not file_exists(filename) then
            util.toast(
                string.format(
                    'Failed to initialize. Required file does not exist: "%s"',
                    remove_string_prefix(filename, stand_script_path)
                )
            )
            return false
        end
    end

    utilities = require(stand_lib_path .. "utils")
    settings = require(stand_lib_path .. "settings")
    fuel = require(stand_lib_path .. "fuel")
    local config = require(stand_lib_path .. "config")

    if not utilities or not config or not settings or not fuel then
        util.toast("Failed to initialize. Failed to import required libraries.")
        return false
    end

    utilities.create_file(settings_file, "{}")
    config_handler = config.new(settings_file)
    settings.load_default()
end

init()

util.on_pre_stop(function()
    utilities.remove_blips()
end)

util.on_stop(function()
    if log_file then
        log_file:close()
    end
end)
