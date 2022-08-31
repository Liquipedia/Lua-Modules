---
-- @Liquipedia
-- wiki=commons
-- page=Module:Class
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---
-- @author Vogan for Liquipedia
--

local Arguments = require('Module:Arguments')

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

---@generic T
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

local Table = {}

-- Duplicate Table.isNotEmpty() here to avoid circular dependencies with Table
function Table.isNotEmpty(tbl)
	-- luacheck: push ignore (Loop can be executed at most once)
	for _ in pairs(tbl) do
		return true
	end
	-- luacheck: pop
	return false
end

---
-- Wrap the given function with an argument parses so that both wikicode and lua
-- arguments are accepted
--
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
			local namedArgs, indexedArgs = Class._frameToArgs(frame, options)
			if namedArgs then
				return f(namedArgs, unpack(indexedArgs))
			else
				return f(unpack(indexedArgs))
			end
		else
			return f(...)
		end
	end
end

--[[
Translates a frame object into arguments expected by a lua function.
]]
function Class._frameToArgs(frame, options)
	local args = Arguments.getArgs(frame, options)

	-- getArgs adds a metatable to the table. This breaks unpack. So we remove it.
	-- We also add all named params to a special table, since unpack removes them.
	local indexedArgs = {}
	local namedArgs = {}
	for key, value in pairs(args) do
		if type(key) == 'number' then
			indexedArgs[key] = value
		else
			namedArgs[key] = value
		end
	end

	return (Table.isNotEmpty(namedArgs) and namedArgs or nil), indexedArgs
end

return Class
