util.require_natives(1681379138)

local SCRIPT = "Fuel mod"
local VERSION = "0.2.1"
local RESOURCES_DIR = filesystem.resources_dir() .. "user0092_fuel_mod"

local notify = function (message)
    util.toast(message)
end

local log = function (message)
    util.log(message)
end

local MAIN_FUEL_MOD_PATH = menu.my_root()

local MENU_LABELS = {
    ENABLE_FUEL_MOD = 'Enable Fuel Mod',
    SETTINGS_LIST = 'Settings',
    CREDIT_LIST = 'Credits',
    CREDITS_CREATED_BY = 'Created by User0092',
    CREDITS_MY_GITHUB = 'My Github'
}

local GAS_PUMP_TEXTURE = directx.create_texture(RESOURCES_DIR .. "\\images\\fuel-pump.png")

-- variables
local settings = {
    station_range = 5,
    base_fuel_level = 40,
    refuel = 3,
    manual_refuel = 1,
    consumption_rate = 2,
    percentage_green = 50,
    percentage_red = 10,
    x_display = 100,
    y_display = 100,
    text_scale = 1,
    picture_scale = 3,
    show_gas_texture = true,
    show_percentage_text = true,
    screen_width = 1920,
    screen_height = 1080,
    enable_mod_on_load = false
}

local fuel_usage = {
	[1.0] = 1.4,
	[0.9] = 1.2,
	[0.8] = 1.0,
	[0.7] = 0.9,
	[0.6] = 0.8,
	[0.5] = 0.7,
	[0.4] = 0.5,
	[0.3] = 0.4,
	[0.2] = 0.2,
	[0.1] = 0.1,
	[0.0] = 0.0
}

local fuel_thread = false
local refuel_thread = false
local features_thread = false
local idle_thread = false
local hub_thread = false

local class_fuel_capacity = {}
class_fuel_capacity[0] = {1.00, 50} -- Compacts
class_fuel_capacity[1] = {1.50, 90} -- Sedans
class_fuel_capacity[2] = {1.75, 95} -- SUVs
class_fuel_capacity[3] = {1.60, 70} -- Coupes
class_fuel_capacity[4] = {2.00, 75} -- Muscle
class_fuel_capacity[5] = {1.60, 65} -- Sports Classics
class_fuel_capacity[6] = {1.50, 70} -- Sports
class_fuel_capacity[7] = {2.50, 100} -- Super
class_fuel_capacity[8] = {0.50, 25} -- Motorcycles
class_fuel_capacity[9] = {1.60, 75} -- Off-road
class_fuel_capacity[10] = {6.00, 300} -- Industrial
class_fuel_capacity[11] = {2.25, 150} -- Utility
class_fuel_capacity[12] = {1.75, 105} -- Vans
class_fuel_capacity[13] = {0.00, 0} -- Cycles
class_fuel_capacity[14] = {0.00, 0} -- Boats
class_fuel_capacity[15] = {0.00, 0} -- Helicopters
class_fuel_capacity[16] = {0.00, 0} -- Planes
class_fuel_capacity[17] = {1.50, 100} -- Service
class_fuel_capacity[18] = {0.90, 70} -- Emergency
class_fuel_capacity[19] = {1.25, 150} -- Military
class_fuel_capacity[20] = {7.00, 350} -- Commercial
class_fuel_capacity[21] = {0.00, 0} -- Trains
class_fuel_capacity[22] = {6.00, 115} -- Open Wheel
class_fuel_capacity.electrics = {1.15, 100} -- Electric

local GAS_STATION_COORDS = {
    {x=-319.16561889648, y=-1471.2281494141, z=30.548429489136},
    {x=-527.99554443359, y=-1210.2166748047, z=18.184854507446},
    {x=-723.04473876953, y=-935.74060058594, z=19.214164733887},
    {x=-2096.1845703125, y=-320.16772460938, z=13.162784576416},
    {x=1180.9616699219, y=-329.51950073242, z=69.316268920898},
    {x=818.93316650391, y=-1027.8981933594, z=26.404323577881},
    {x=265.75106811523, y=-1261.3581542969, z=29.292930603027},
    {x=-71.286819458008, y=-1761.3170166016, z=29.53404045105},
    {x=-1437.5718994141, y=-275.3415222168, z=46.207656860352},
    {x=1180.7448730469, y=-329.48037719727, z=69.315986633301},
    {x=-1800.1677246094, y=802.81439208984, z=138.65116882324},
    {x=-2555.2531738281, y=2334.5502929688, z=33.077983856201},
    {x=620.67224121094, y=268.56155395508, z=103.08939361572},
    {x=263.97756958008, y=2607.5124511719, z=44.982418060303},
    {x=2679.9924316406, y=3263.9404296875, z=55.240566253662},
    {x=1785.9619140625, y=3331.0888671875, z=41.373741149902},
    {x=1701.3488769531, y=6415.7119140625, z=32.644836425781},
    {x=154.85752868652, y=6629.5419921875, z=31.833236694336},
    {x=2581.083984375, y=361.73327636719, z=108.46881866455},
    {x=1207.611328125, y=2660.6516113281, z=37.899841308594},
    {x=-94.196914672852, y=6419.69140625, z=31.489517211914},
    {x=49.409355163574, y=2778.783203125, z=58.0439453125},
    {x=2538.20703125, y=2594.052734375, z=37.944877624512},
    {x=2005.07421875, y=3774.4982910156, z=32.40393447876},
    {x=179.67831420898, y=6603.0625, z=31.868244171143},
}

local GAS_PUMP_COORDS = {
    {x=-79.740203857422, y=-1761.1672363281, z=29.602794647217},
    {x=-69.812576293945, y=-1758.9458007812, z=29.534042358398},
    {x=-72.458236694336, y=-1766.0916748047, z=29.521533966064},
    {x=-63.233070373535, y=-1767.0146484375, z=29.259857177734},
    {x=-316.79049682617, y=-1477.0200195312, z=30.723524093628},
    {x=-322.94802856445, y=-1466.4416503906, z=30.724203109741},
    {x=-315.44735717773, y=-1462.1208496094, z=30.724203109741},
    {x=-309.28244018555, y=-1472.6748046875, z=30.723735809326},
    {x=-529.48718261719, y=-1204.2757568359, z=18.334457397461},
    {x=-524.97686767578, y=-1206.6217041016, z=18.333307266235},
    {x=-522.17358398438, y=-1207.7316894531, z=18.334680557251},
    {x=-528.64294433594, y=-1214.4475097656, z=18.332580566406},
    {x=-521.25378417969, y=-1217.9387207031, z=18.334680557251},
    {x=-533.48962402344, y=-1212.2509765625, z=18.334552764893},
    {x=-732.71771240234, y=-931.37512207031, z=19.213930130005},
    {x=-732.70050048828, y=-938.26049804688, z=19.210886001587},
    {x=-715.46942138672, y=-933.65051269531, z=19.213956832886},
    {x=-715.39978027344, y=-940.45043945312, z=19.201963424683},
    {x=-2104.7553710938, y=-312.05828857422, z=13.168632507324},
    {x=-2105.4638671875, y=-320.21374511719, z=13.168521881104},
    {x=-2106.1301269531, y=-326.65310668945, z=13.168478012085},
    {x=-2097.6362304688, y=-327.51107788086, z=13.167719841003},
    {x=-2097.0043945312, y=-321.15463256836, z=13.168622970581},
    {x=-2096.1743164062, y=-312.91360473633, z=13.168637275696},
    {x=-2088.9428710938, y=-328.46020507812, z=13.168607711792},
    {x=-1445.2377929688, y=-273.40512084961, z=46.397663116455},
    {x=-1434.7733154297, y=-285.35327148438, z=46.390823364258},
    {x=-1428.3271484375, y=-280.06127929688, z=46.390319824219},
    {x=-1438.8070068359, y=-267.92523193359, z=46.396072387695},
    {x=1185.3356933594, y=-338.31692504883, z=69.367340087891},
    {x=1183.8692626953, y=-329.94787597656, z=69.324287414551},
    {x=1176.6737060547, y=-322.07955932617, z=69.350883483887},
    {x=1184.1684570312, y=-320.85928344727, z=69.344306945801},
    {x=810.78063964844, y=-1029.6876220703, z=26.418870925903},
    {x=810.60400390625, y=-1027.3045654297, z=26.418821334839},
    {x=818.95965576172, y=-1027.3161621094, z=26.404344558716},
    {x=819.02435302734, y=-1029.8177490234, z=26.404321670532},
    {x=827.39385986328, y=-1029.8920898438, z=26.608219146729},
    {x=827.21051025391, y=-1027.2900390625, z=26.608222961426},
    {x=265.05072021484, y=-1267.6351318359, z=29.286539077759},
    {x=265.09075927734, y=-1260.2020263672, z=29.293184280396},
    {x=273.88891601562, y=-1254.4688720703, z=29.292943954468},
    {x=273.75216674805, y=-1262.3486328125, z=29.292953491211},
    {x=273.75979614258, y=-1269.7524414062, z=29.292833328247},
    {x=-77.97981262207, y=-1756.0246582031, z=29.800315856934},
    {x=-61.405563354492, y=-1761.8679199219, z=29.26173210144},
    {x=-330.22442626953, y=-1470.6551513672, z=30.72420501709},
    {x=-324.23989868164, y=-1481.3731689453, z=30.72416305542},
    {x=-517.68103027344, y=-1210.009765625, z=18.334680557251},
    {x=-525.85089111328, y=-1215.767578125, z=18.328662872314},
    {x=-528.56048583984, y=-1214.3754882812, z=18.33424949646},
    {x=-723.88812255859, y=-938.2802734375, z=19.210409164429},
    {x=-723.92083740234, y=-931.5205078125, z=19.213907241821},
    {x=-2087.2485351562, y=-313.8205871582, z=13.168509483337},
    {x=1180.0196533203, y=-339.43591308594, z=69.356491088867},
    {x=1187.4748535156, y=-338.06246948242, z=69.349151611328},
    {x=1185.9196777344, y=-329.51141357422, z=69.308319091797},
    {x=1176.8575439453, y=-322.15591430664, z=69.350791931152},
    {x=-1802.8273925781, y=793.56744384766, z=138.68565368652},
    {x=-1807.8962402344, y=799.27008056641, z=138.68493652344},
    {x=-1801.6711425781, y=805.34509277344, z=138.64869689941},
    {x=-1790.1363525391, y=805.61193847656, z=138.69104003906},
    {x=-2551.4235839844, y=2341.4948730469, z=33.257022857666},
    {x=-2557.4099121094, y=2334.0661621094, z=33.256671905518},
    {x=-2557.0219726562, y=2326.7028808594, z=33.256202697754},
    {x=-2552.4594726562, y=2327.1279296875, z=33.257007598877},
    {x=-92.156227111816, y=6422.0986328125, z=31.639497756958},
    {x=256.33416748047, y=-1254.5048828125, z=29.29295539856},
    {x=256.43667602539, y=-1262.2907714844, z=29.29295539856},
    {x=264.96044921875, y=-1254.5067138672, z=29.29298210144},
    {x=1182.1430664062, y=-321.1591796875, z=69.350715637207},
    {x=629.47296142578, y=274.99069213867, z=103.27710723877},
    {x=629.52185058594, y=262.76156616211, z=103.27709960938},
    {x=621.15802001953, y=262.77651977539, z=103.27709960938},
    {x=621.14025878906, y=274.96008300781, z=103.27689361572},
    {x=612.43481445312, y=262.76968383789, z=103.27709960938},
    {x=-1796.501953125, y=799.66229248047, z=138.65112304688},
    {x=-2551.3935546875, y=2334.5229492188, z=33.25700378418},
    {x=265.59875488281, y=2607.2145996094, z=44.983169555664},
    {x=263.67175292969, y=2607.2045898438, z=45.023189544678},
    {x=2588.2980957031, y=357.53695678711, z=108.64779663086},
    {x=2580.8947753906, y=357.85488891602, z=108.64779663086},
    {x=2581.0124511719, y=363.14233398438, z=108.64779663086},
    {x=2573.8498535156, y=363.65469360352, z=108.64778900146},
    {x=2573.5241699219, y=358.17337036133, z=108.64779663086},
    {x=2680.2084960938, y=3265.6027832031, z=55.409370422363},
    {x=1785.6662597656, y=3331.1916503906, z=41.365455627441},
    {x=2000.8951416016, y=3771.4797363281, z=32.403312683105},
    {x=2003.3474121094, y=3772.7517089844, z=32.403804779053},
    {x=2005.2235107422, y=3774.4919433594, z=32.403938293457},
    {x=2008.2166748047, y=3776.3779296875, z=32.403991699219},
    {x=1700.7926025391, y=6417.0629882812, z=32.764030456543},
    {x=179.90325927734, y=6603.8686523438, z=32.047386169434},
    {x=154.81216430664, y=6630.2333984375, z=31.824007034302},
    {x=155.76705932617, y=6629.6298828125, z=31.819032669067},
    {x=-96.74959564209, y=6417.4848632812, z=31.639528274536},
    {x=1176.267578125, y=-331.1701965332, z=69.321327209473},
    {x=256.4557800293, y=-1267.5317382812, z=29.29295539856},
    {x=612.51007080078, y=275.14581298828, z=103.2770614624},
    {x=-1795.0804443359, y=811.064453125, z=138.52159118652},
    {x=2588.474609375, y=363.06756591797, z=108.64778900146},
    {x=1208.9169921875, y=2658.7575683594, z=37.89977645874},
    {x=1206.3184814453, y=2661.5354003906, z=37.89977645874},
    {x=2679.1088867188, y=3263.2922363281, z=55.40943145752},
    {x=1786.455078125, y=3329.2192382812, z=41.433242797852},
    {x=1696.7781982422, y=6418.8198242188, z=32.76403427124},
    {x=172.37554931641, y=6602.619140625, z=32.047370910645},
    {x=187.0263671875, y=6605.1904296875, z=32.047271728516},
    {x=1177.9296875, y=-339.76586914062, z=69.361373901367},
    {x=1704.7806396484, y=6415.134765625, z=32.76403427124},
    {x=-2557.7766113281, y=2341.515625, z=33.256671905518},
    {x=49.409355163574, y=2778.783203125, z=58.0439453125},
    {x=2538.20703125, y=2594.052734375, z=37.944877624512},
    {x=1178.4786376953, y=-330.734375, z=69.316558837891},
    {x=-2088.125, y=-322.03067016602, z=13.168471336365},
}

local run_fuel_mod = false

local last_pos = {
    x = 0,
    y = 0,
    z = 0,
    FOR_INFO = 0
}

local current = {
    fuel_level = 30,
    tank_size = 100,
    consumption_rate = 1,
    latest_hash = nil,
    latest_coords = nil
}

local created_blips = {}
local used_vehicles = {}
local last_blip = nil
local increase_fuel_level_notified = false
local SETTINGS_FILE = RESOURCES_DIR .. "\\settings.txt"

-- functions
local function split(inputstr, sep)
    return string.split(inputstr, sep)
end

local function convert_to_type(str)
    if (string.lower(str) == "true" or str == true) then
        return true
    end
    if (string.lower(str) == "false" or str == false) then
        return false
    end
    local num = tonumber(str)
    if (num ~= nil) then
        return num
    end
    return str
end

local function save_settings()
    if (not filesystem.exists(SETTINGS_FILE)) then
        util.register_file(SETTINGS_FILE)
    end

    local str = ""
    local file = io.open(SETTINGS_FILE, "w")
    for k, v in settings do
        str = str .. k .. "=" .. v .. "\n"
    end

    file:write(str)
    file:close()
end

local function load_settings()
    if (not filesystem.exists(SETTINGS_FILE)) then
        return
    end
    
    local file = io.open(SETTINGS_FILE, "r")
    local str = file:read("*all")
    local first_split = split(str, "\n")
    for first_split as v do
        if (not v) then
            goto continue
        end
        local second_split = split(v, '=')
        if (not second_split[1] or not second_split[2]) then
            goto continue
        end

        settings[second_split[1]] = convert_to_type(second_split[2])
        ::continue::
    end
end

local function gallons_to_liters(gallons)
    return gallons * 3.785412
end

local function liters_to_gallons(liters)
    return liters / 3.785412
end

local function round(num, dp)
    local mult = 10^(dp or 0)
    return math.floor(num * mult + 0.5)/mult
end

local function get_user_vehicle_as_pointer()
    local e = entities.get_user_vehicle_as_pointer(false)
    if e == 0 or not e then
        return nil
    end
    return e
end

local function get_user_vehicle_as_handle()
    local e = entities.get_user_vehicle_as_handle(false)
    if e == -1 or not e then
        return nil
    end
    return e
end

local function get_player_ped() 
    return players.user_ped()
end

local function is_driving()
    if get_user_vehicle_as_pointer() ~= nil then
        if VEHICLE.IS_VEHICLE_STOPPED(get_user_vehicle_as_handle()) then 
            return false
        else
            return true
        end
    end
    
    return false
end

local function get_vehicle_model_id()
    return players.get_vehicle_model(players.user())
end

local function get_distance_between_coords(first, second)
    local x = second.x - first.x
    local y = second.y - first.y
    local z = second.z - first.z
    return math.sqrt(x * x + y * y + z * z)
end

local function get_vehicle_display_name()
    return VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(players.get_vehicle_model(players.user()))
end

local function is_electric()
    local evList = {"VOLTIC2", "VOLTIC", "CYCLONE2", "CYCLONE", "TEZERACT", "IWAGEN", "NEON", "RAIDEN", "AIRTUG", "CADDY3", "CADDY2", "CADDY", "IMORGON", "KHAMEL", "DILETTANTE", "SURGE", "OMNISEGT"}
    for evList as v do
        if string.lower(get_vehicle_display_name()) == string.lower(v) then
            return true
        end
    end
    return false
end

local function get_vehicle_speed()
    return ENTITY.GET_ENTITY_SPEED(get_user_vehicle_as_handle())
end

local function get_vehicle_model_value()
    return VEHICLE.GET_VEHICLE_CLASS_FROM_NAME(players.get_vehicle_model(players.user()))
end

local function is_empty(search)
    return search == nil or search == ''
end

local function can_refuel()
    for GAS_PUMP_COORDS as coords do
        local pos = players.get_position(players.user())
        if get_distance_between_coords(pos, coords) <= settings.station_range then
            return true
        end
    end
    return false
end

local function update_vehicles()
    if is_empty(used_vehicles[get_user_vehicle_as_handle()]) then
        used_vehicles[get_user_vehicle_as_handle()] = settings.base_fuel_level / 100 * class_fuel_capacity[get_vehicle_model_value()][2]
        current.fuel_level = settings.base_fuel_level / 100 * class_fuel_capacity[get_vehicle_model_value()][2]
    else
        current.fuel_level = used_vehicles[get_user_vehicle_as_handle()]
    end
end

local function decrease_fuel_level()
    if (current.fuel_level > 0 and get_vehicle_speed() > 4) then
        if is_electric() then
            current.fuel_level = used_vehicles[get_user_vehicle_as_handle()] - fuel_usage[round(entities.get_rpm(get_user_vehicle_as_handle()), 1)] * (class_fuel_capacity.electrics[1]) * (settings.consumption_rate / 10)
            current.tank_size = class_fuel_capacity.electrics[2]
        else
            current.fuel_level = used_vehicles[get_user_vehicle_as_handle()] - (fuel_usage[round(entities.get_rpm(get_user_vehicle_as_pointer()), 1)] * (class_fuel_capacity[get_vehicle_model_value()][1]) * (settings.consumption_rate / 10)) / 15
            current.tank_size = class_fuel_capacity[get_vehicle_model_value()][2]
        end

        if current.fuel_level < 0 then current.fuel_level = 0 end
        if current.fuel_level > current.tank_size then current.fuel_level = current.tank_size end
        used_vehicles[get_user_vehicle_as_handle()] = current.fuel_level
    end
end

local function find_best_station()
    local lowest = {distance = nil, coords = nil}
    local pos = players.get_position(players.user())
    for GAS_STATION_COORDS as coords do
        local dist = get_distance_between_coords(pos, coords)
        if (lowest.distance == nil) then
            lowest.distance = dist
            lowest.coords = coords
        end

        if (dist < lowest.distance) then
            lowest.distance = dist
            lowest.coords = coords
        end
    end
    return lowest
end

local function create_blips()
    while (util.is_session_started() ~= true) do
        util.yield(10)
    end

    for GAS_STATION_COORDS as coords do
        local blip = HUD.ADD_BLIP_FOR_COORD(coords.x, coords.y, coords.z)
        HUD.SET_BLIP_SPRITE(blip, 361)
        HUD.SET_BLIP_COLOUR(blip, 75)
        
        table.insert(created_blips, {blip_ = blip, coords_ = coords})
        last_blip = blip
    end
end

local function increase_fuel_level()
    if (can_refuel()) then
        if (VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(get_user_vehicle_as_handle())) then
            return
        end
        if current.fuel_level < current.tank_size and get_vehicle_speed() < 1 then
            current.fuel_level = used_vehicles[get_user_vehicle_as_handle()] + (settings.refuel / 10)
            used_vehicles[get_user_vehicle_as_handle()] = current.fuel_level
        end
        if (current.fuel_level > current.tank_size) then
            current.fuel_level = current.tank_size
        end
    end
end

local function manual_refuelling()
    if (is_driving() == false) then
        local pos = players.get_position(players.user())
        if (current.latest_coords == nil) then
            goto continue
        end
        if (used_vehicles[current.latest_hash] < current.tank_size and WEAPON.GET_SELECTED_PED_WEAPON(players.user_ped()) == util.joaat("weapon_petrolcan") and
            get_distance_between_coords(current.latest_coords, pos) <= settings.station_range) then
            used_vehicles[current.latest_hash] = used_vehicles[current.latest_hash] + (settings.manual_refuel / 10)
            if (used_vehicles[current.latest_hash] > current.tank_size) then
                used_vehicles[current.latest_hash] = current.tank_size
            end 
            local fuel_level = round(used_vehicles[current.latest_hash] * 100 / current.tank_size, 0)
        end
        ::continue::
    end
end

local function main_backend()
    while (run_fuel_mod) do
        if (is_driving()) then
            if (is_electric()) then
                current.tank_size = class_fuel_capacity.electrics[2]
            else
                current.tank_size = class_fuel_capacity[get_vehicle_model_value()][2]
            end
            update_vehicles()
            decrease_fuel_level()
            current.latest_hash = get_user_vehicle_as_handle()
            current.latest_coords = players.get_position(players.user())
            current.consumption_rate = class_fuel_capacity[get_vehicle_model_value()][1]
            
            local percentage = round(used_vehicles[current.latest_hash] * 100 / current.tank_size, 0)
            if percentage < 2 then
                VEHICLE.SET_VEHICLE_CAN_ENGINE_MISSFIRE(get_user_vehicle_as_handle(), true)
            else
                VEHICLE.SET_VEHICLE_CAN_ENGINE_MISSFIRE(get_user_vehicle_as_handle(), false)
            end
        else
            local handle = get_user_vehicle_as_handle()
            local latest = current.latest_hash
            if (handle == nil and latest == nil) then
                goto continue
            end

            if (handle) then
                if (VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle)) then
                    current.fuel_level = used_vehicles[handle] - (fuel_usage[round(entities.get_rpm(get_user_vehicle_as_pointer()), 1)] * (class_fuel_capacity[get_vehicle_model_value()][1]) * (settings.consumption_rate / 10)) / 35
                    if current.fuel_level < 0 then current.fuel_level = 0 end
                    used_vehicles[handle] = current.fuel_level
                end
            
            else
                if (VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(latest)) then
                    current.fuel_level = used_vehicles[latest] - (fuel_usage[round(entities.get_rpm(entities.handle_to_pointer(current.latest_hash)), 1)] * (current.consumption_rate) * (settings.consumption_rate / 10)) / 35
                    if current.fuel_level < 0 then current.fuel_level = 0 end
                    used_vehicles[latest] = current.fuel_level
                end
            end
            
        end
        ::continue::
        util.yield(1500)
    end
    fuel_thread = false
end

local function check_version()
    async_http.init('raw.githubusercontent.com', '/User00092/Fuel-Mod/main/VERSION', function(body, header_fields, status_code)
        if (status_code ~= 200) then
            notify('Failed to check version.')
        end
        if (body:gsub("\n", "") ~= VERSION) then
            notify('A new version is available!')
        else
            notify('You have the latest version!')
        end
    end, function()
        notify('Failed to check version.')
    end)
    async_http.dispatch()
end

local function main_refuel_backend()
    while (run_fuel_mod) do
        if (is_driving() == false and get_user_vehicle_as_pointer() ~= nil) then
            update_vehicles()
            increase_fuel_level()
        else
            if not is_empty(current.latest_hash) then
                manual_refuelling()
            end
        end
        ::continue::
        util.yield(250)
    end
    refuel_thread = false
end

local function main_hub_backend()
    while (run_fuel_mod) do
        if (last_blip ~= nil) then
            if (not HUD.DOES_BLIP_EXIST(last_blip)) then
                create_blips()
            end
        else
            create_blips()
        end
        util.yield(300)
    end
    hub_thread = false
end

local function main_features_thread()
    local bad = false
    while (run_fuel_mod) do
        if (get_user_vehicle_as_pointer() ~= nil) then
            local handle = get_user_vehicle_as_handle()
            if (class_fuel_capacity[get_vehicle_model_value()][2] == 0 or current.latest_hash == nil) then
                goto continue
            end
            local percentage = round(used_vehicles[current.latest_hash] * 100 / current.tank_size, 0)
            if (can_refuel()) then
                if (VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle) and get_vehicle_speed() < 1 and percentage < 99) then
                    if (increase_fuel_level_notified == false) then
                        notify('Please turn off your vehicle to begin fueling.')
                    end
                    increase_fuel_level_notified = true
                else
                    increase_fuel_level_notified = false
                end
            else
                increase_fuel_level_notified = false
            end

            if (percentage < 5) then
                if (bad == false) then
                    bad = true
                    VEHICLE.SET_VEHICLE_CAN_ENGINE_MISSFIRE(handle, true)
                    VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(handle) * 0.7)
                end
            else 
                if (bad == true) then
                    bad = false
                    VEHICLE.SET_VEHICLE_CAN_ENGINE_MISSFIRE(handle, false)
                    VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(handle))
                end
            end 
            if (current.fuel_level <= 0) then
                if (VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle)) then
                    VEHICLE.SET_VEHICLE_ENGINE_ON(handle, false, true, true)
                end
            end
        end
        ::continue::
        util.yield(10)
    end
    features_thread = false
    increase_fuel_level_notified = false
end

-- MAIN
local MAIN_ENABLE_FUEL_MOD = MAIN_FUEL_MOD_PATH:toggle(MENU_LABELS.ENABLE_FUEL_MOD, {'enablefuelmod'}, "", function (status)
    run_fuel_mod = status
    if (status) then
        if (refuel_thread == false) then
            refuel_thread = true
            util.create_thread(function() main_refuel_backend() end)
        end
        if (fuel_thread == false) then
            fuel_thread = true
            util.create_thread(function() main_backend() end)
        end
        if (hub_thread == false) then
            hub_thread = true
            util.create_thread(function() main_hub_backend() end)
        end
        if (features_thread == false) then
            features_thread = true
            util.create_thread(function() main_features_thread() end)
        end
    end
end)

MAIN_FUEL_MOD_PATH:action('Mark Nearest Station', {}, "", function()
    local lowest = find_best_station()
    HUD.SET_NEW_WAYPOINT(lowest.coords.x, lowest.coords.y)
end)

-- MAIN_FUEL_MOD_PATH:action('Copy coords', {}, "", function()
--     local pos = players.get_position(players.user())
--     util.copy_to_clipboard("{x=" .. pos.x .. ", y=" .. pos.y .. ", z=" .. pos.z .. "},")
-- end)

MAIN_FUEL_MOD_PATH:action('Toggle Engine', {}, "", function()
    local handle = get_user_vehicle_as_handle()
    if (handle == nil) then
        return
    end

    if (VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle)) then
        VEHICLE.SET_VEHICLE_ENGINE_ON(handle, false, false, true)
    else
        VEHICLE.SET_VEHICLE_ENGINE_ON(handle, true, false, false)
    end
end)

-- SETTINGS
local MAIN_SETTINGS_PATH = MAIN_FUEL_MOD_PATH:list(MENU_LABELS.SETTINGS_LIST)
local SETTINGS_X_POS = MAIN_SETTINGS_PATH:slider('X position', {'setfuelhudxvalue'}, "", 0, settings.screen_width, settings.x_display, 1, function(x)
    settings.x_display = x
end)

local SETTINGS_Y_POS = MAIN_SETTINGS_PATH:slider('Y position', {'setfuelhudyvalue'}, "", 0, settings.screen_height, settings.y_display, 1, function(y)
    settings.y_display = y
end)

local SETTINGS_IMAGE_SCALE = MAIN_SETTINGS_PATH:slider('Image scale', {'setfuealimagescale'}, "", 0, 100, settings.picture_scale, 1, function(val)
    settings.picture_scale = val
end)

local SETTINGS_TEXT_SCALE = MAIN_SETTINGS_PATH:slider('Text scale', {'setfuealtextscale'}, "", 0, 100, settings.text_scale, 1, function(val)
    settings.text_scale = val
end)

local SETTING_SHOW_GAS_TEXTURE = MAIN_SETTINGS_PATH:toggle('Show Gas Pump Texture', {}, "", function(status)
    settings.show_gas_texture = status
    
end, settings.show_gas_texture)

local SETTINGS_SHOW_TEXT_PERCENT = MAIN_SETTINGS_PATH:toggle('Show Percentage', {}, "", function(status)
    settings.show_percentage_text = status
    
end, settings.show_percentage_text)

local SETTINGS_SCREEN_WIDTH = MAIN_SETTINGS_PATH:slider('Screen Width', {'setfuelscreenwidth'}, "", 0, 10000, 1, 1, function(val)
    settings.screen_width = val
end)


local SETTINGS_SCREEN_HEIGHT = MAIN_SETTINGS_PATH:slider('Screen height', {'setfuelscreenwidth'}, "", 0, 10000, 1, 1, function(val)
    settings.screen_height = val
end)

local SETTINGS_REFUEL_RATE = MAIN_SETTINGS_PATH:slider('Refuel Rate', {'setfuelrefuelrate'}, "", 1, 100, 1, 1, function(val)
    settings.refuel = val
end)

local SETTINGS_MANUAL_REFUEL_RATE = MAIN_SETTINGS_PATH:slider('Manual Refuel Rate', {'setfuelmanualrefuelrate'}, "", 1, 100, 1, 1, function(val)
    settings.manual_refuel = val
end)

local SETTINGS_GREEN_TEXT_PERCENT = MAIN_SETTINGS_PATH:slider('Green Text at % or higher', {'setfuelpercentagegreen'}, "", 1, 100, 1, 1, function(val)
    settings.percentage_green = val
end)

local SETTINGS_RED_TEXT_PERCENT = MAIN_SETTINGS_PATH:slider('Red Text at % or lower', {'setfuelpercentagered'}, "", 1, 100, 1, 1, function(val)
    settings.percentage_red = val
end)

local SETTINGS_BASE_FUEL_LEVEL = MAIN_SETTINGS_PATH:slider('Base Fuel Level', {'setfuelbasefuellevel'}, "", 1, 100, 1, 1, function(val)
    settings.base_fuel_level = val
end)

local SETTINGS_CONSUMPTION_RATE = MAIN_SETTINGS_PATH:slider('Consumption Rate', {'setfuelconsumptionrate'}, "", 0, 100, 1, 1, function(val)
    settings.consumption_rate = val
end)

local SETTINGS_STATION_RANGE = MAIN_SETTINGS_PATH:slider('Station Range', {'setfuelstationrange'}, "", 1, 100, 1, 1, function(val)
    settings.station_range = val
end)

local SETTINGS_ENABLE_ON_LOAD = MAIN_SETTINGS_PATH:toggle('Enable on Load', {}, "", function(status)
    settings.enable_mod_on_load = status
end)

MAIN_SETTINGS_PATH:action('Save Settings', {}, "", function()
    save_settings()
end)

local update_settings = function()
    menu.set_value(SETTINGS_X_POS, settings.x_display)
    menu.set_value(SETTINGS_Y_POS, settings.y_display)
    menu.set_value(SETTINGS_IMAGE_SCALE, settings.picture_scale)
    menu.set_value(SETTINGS_TEXT_SCALE, settings.text_scale)
    menu.set_value(SETTING_SHOW_GAS_TEXTURE, settings.show_gas_texture)
    menu.set_value(SETTINGS_SHOW_TEXT_PERCENT, settings.show_percentage_text)
    menu.set_value(SETTINGS_SCREEN_WIDTH, settings.screen_width)
    menu.set_value(SETTINGS_SCREEN_HEIGHT, settings.screen_height)
    menu.set_value(SETTINGS_REFUEL_RATE, settings.refuel)
    menu.set_value(SETTINGS_MANUAL_REFUEL_RATE, settings.manual_refuel)
    menu.set_value(SETTINGS_GREEN_TEXT_PERCENT, settings.percentage_green)
    menu.set_value(SETTINGS_RED_TEXT_PERCENT, settings.percentage_red)
    menu.set_value(SETTINGS_BASE_FUEL_LEVEL, settings.base_fuel_level)
    menu.set_value(SETTINGS_CONSUMPTION_RATE, settings.consumption_rate )
    menu.set_value(SETTINGS_STATION_RANGE, settings.station_range)
    menu.set_value(SETTINGS_ENABLE_ON_LOAD, settings.enable_mod_on_load)

    if (settings.enable_mod_on_load) then
        menu.set_value(MAIN_ENABLE_FUEL_MOD, true)
    end

    menu.set_max_value(SETTINGS_X_POS, settings.screen_width)
    menu.set_max_value(SETTINGS_Y_POS, settings.screen_height)
end

MAIN_SETTINGS_PATH:action('Load Settings', {}, "", function()
    load_settings()
    update_settings()
end)

-- CREDITS
local MAIN_CREDITS_PATH = MAIN_FUEL_MOD_PATH:list(MENU_LABELS.CREDIT_LIST)
MAIN_CREDITS_PATH:readonly(MENU_LABELS.CREDITS_CREATED_BY)
MAIN_CREDITS_PATH:hyperlink(MENU_LABELS.CREDITS_MY_GITHUB, "https://github.com/User00092")

util.create_tick_handler(function()
    if (run_fuel_mod == false) then
        goto continue
    end
    if (current.latest_coords == nil or current.latest_hash == nil) then
        return
    end
    
    if (get_distance_between_coords(players.get_position(players.user()), current.latest_coords) < 2 or get_user_vehicle_as_pointer()) then
        if (settings.show_gas_texture) then
            
        
            directx.draw_texture(
                GAS_PUMP_TEXTURE,	-- id
                settings.picture_scale*0.0056,				-- sizeX
                settings.picture_scale*0.0056,				-- sizeY
                0.5,				-- centerX
                0.5,				-- centerY
                settings.x_display/settings.screen_width,     -- posX
                settings.y_display/settings.screen_height,	    -- posY
                0.0,				-- rotation
                {					-- colour
                    ["r"] = 1.0,
                    ["g"] = 1.0,
                    ["b"] = 1.0,
                    ["a"] = 1.0
                }
            )
        end

        if (settings.show_percentage_text) then
            local percentage = round(used_vehicles[current.latest_hash] * 100 / current.tank_size, 1)
            if percentage > 100 then
                percentage = 100
            end

            local color = {}
            if (percentage >= settings.percentage_green) then
                color = {r=0, g=255, b=0, a=1}
            end
            if (percentage < settings.percentage_green and percentage > settings.percentage_red) then
                color = {r=255, g=255, b=0, a=1}
            end
            if (percentage <= settings.percentage_red) then
                color = {r=255, g=0, b=0, a=1}
            end

            directx.draw_text(
                ((settings.x_display+30)/settings.screen_width),  -- x
                (settings.y_display/settings.screen_height),       -- y
                percentage .. "%",               -- text
                0,                               -- alignment
                settings.text_scale,             -- scale
                color,                           -- color
                true                             -- force in bounds
            )
        end
    end
    ::continue::
end)

load_settings()
update_settings()
check_version()