package.path = "?.lua;" ..
    -- Load plugin for module name parsing
    "../plugins/?.lua;" ..
    -- Load test files
    "standard/?.lua;" ..
    -- Load main files
    "../standard/?.lua;" ..
    package.path

require('sumneko_plugin')

local require_original = require

function require(module)
    local newName = module
    if (string.find(module, 'Module:')) then
        newName = LuaifyModuleName(module)
    end
    if (newName == 'arguments') then
        return CreateMockArguments()
    end

    if (newName == 'table') then
        newName = 'table_utils'
    end

    return require_original(newName)
end

function CreateMockArguments()
    return {}
end

require('standard/standard_test')
