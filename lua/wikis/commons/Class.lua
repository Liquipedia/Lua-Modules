---
-- @Liquipedia
-- wiki=commons
-- page=Module:Class
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')

local Class = {}

Class.PRIVATE_FUNCTION_SPECIFIER = '_'

---@class BaseClass
---@operator call:self
---@field init fun(self, ...)

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

		instance.init(object, ...)

		return object
	end

	instance.init = function(object, ...)
		if base then
			base.init(object, ...)
		end
		if init then
			init(object, ...)
		end
	end

	instance.export = function(options)
		return Class.export(instance, options)
	end

	setmetatable(instance, metatable)
	return instance
end

---@generic T:table
---@param class T
---@param options ?table
---@return T
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
---@generic F:fun(props: table)
---@param f F
---@param options table?
---@return F
function Class._wrapFunction(f, options)
	options = options or {}
	local alwaysRewriteArgs = options.trim
		or options.removeBlanks
		or options.valueFunc ~= nil

	return function(...)
		-- We cannot call getArgs with a spread operator when these are just lua
		-- args, so we need to wrap it
		local input = {...}

		local frame = input[1]
		local shouldRewriteArgs = alwaysRewriteArgs
			or (
				#input == 1
					and type(frame) == 'table'
					and type(frame.args) == 'table'
			)

		if shouldRewriteArgs then
			local args = Arguments.getArgs(frame, options)
			return f(args)
		else
			return f(...)
		end
	end
end

---@param instance any
---@param class BaseClass
---@return boolean
function Class.instanceOf(instance, class)
	local metatable = getmetatable(instance)
	while metatable do
		if metatable == class then
			return true
		end
		metatable = metatable._base
	end
	return false
end

return Class
