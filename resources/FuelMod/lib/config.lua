local json = require("json")

local json_handler = {}
json_handler.__index = json_handler -- This is required. KEEP IT

function json_handler.new(filename)
    local self = setmetatable({}, json_handler)
    self.filename = filename
    self.data = {}

    self:load()

    return self
end

function json_handler:write()
    local file = io.open(self.filename, "w")
    if file then
        file:write(json.encode(self.data, { pretty = true }))
        file:close()
        return true
    else
        return false
    end
end

function json_handler:load()
    local file = io.open(self.filename, "r")
    if file then
        local content = file:read("*all")
        file:close()
        self.data = json.decode(content) or {}
    else
        self.data = {}
        utilities.notify("File not found:", remove_string_prefix(self.filename, stand_script_path))
        print("File not found:", remove_string_prefix(self.filename, stand_script_path))
    end
end

function json_handler:get(key, default)
    if self.data[key] ~= nil then
        return self.data[key]
    else
        return nil or default
    end
end

function json_handler:reload()
    self:load()
end

return json_handler