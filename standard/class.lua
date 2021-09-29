---
-- @Liquipedia
-- wiki=commons
-- page=Module:
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---
-- @author Vogan for Liquipedia
--

local getArgs = require('Module:Arguments').getArgs
local Class = {}

Class.PRIVATE_FUNCTION_SPECIFIER = '_'

function Class.new(base, init)
    local instance = {}

    if not init and type(base) == 'function' then
        init = base
        base = nil
    elseif type(base) == 'table' then
        for index, value in pairs(base) do
            instance[index] = value
        end
      instance._base = base
    end

    instance.__index = instance

    local metatable = {}

    metatable.__call = function(class_tbl, ...)
        local object = {}
        setmetatable(object, instance)

        -- Call constructors
        if init and base and base.init then
            -- If the base class has a constructor,
            -- make sure to call that first
            base.init(object, ...)
            init(object, ...)
        elseif init then
            -- Else we just call our own
            init(object, ...)
        else
            -- And in cases where we don't have one but the
            -- base class does, call that one
            if base and base.init then
                base.init(object, ...)
            end
        end
        return object
    end

    instance.init = init
    instance.export = function(options)
        return Class.export(instance, options)
    end

    instance.is_a = function(self, class)
        local m = getmetatable(self)
        while m do
            if m == class then
                return true
            end
            m = m._base
        end
        return false
    end
    setmetatable(instance, metatable)
    return instance
end


function Class.export(class, options)
    for name, f in pairs(class) do
        -- We only want to export functions, and only functions which are public (no underscore)
        if (
            type(f) == 'function' and
            (not string.find(name, Class.PRIVATE_FUNCTION_SPECIFIER))
        ) then
            class[name] = Class._wrapFunction(class[name], options)
        end
    end
    return class
end

---
-- Wrap the given function with an argument parses so that both wikicode and lua
-- arguments are accepted
--
function Class._wrapFunction(f, options)
    return function(...)
        -- We cannot call getArgs with a spread operator when these are just lua
        -- args, so we need to wrap it
        local input = {...}

        local isFrame = #input == 1 and
            type(input[1]) == 'table' and
            type(input[1]['args']) == 'table'

        if isFrame then
            -- If this is a frame we just want to pass the spread operator
            input = input[1]
        end

        local arguments = getArgs(input, options)

        -- getArgs adds a metatable to the table. This breaks unpack. So we remove it.
        -- We also add all named params to a special table, since unpack removes them.
        local newArgs = {}
        local namedArgs = {}
        for key, value in pairs(arguments) do
            if tonumber(key) ~= nil then
                newArgs[key] = value
            else
                namedArgs[key] = value
            end
        end

        if Class._size(namedArgs) > 0 then
            return f(namedArgs, unpack(newArgs))
        else
            return f(unpack(newArgs))
        end
    end
end

-- We need to duplicate the Table.size() function here because the Table
-- module is dependent on this module
function Class._size(tbl)
    local i = 0
    for _ in pairs(tbl) do
        i = i + 1
    end
    return i
end

return Class
