---
-- @Liquipedia
-- wiki=commons
-- page=Module:Variables
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local Variables = {}

function Variables.varDefine(name, val)
	return mw.ext.VariablesLua.vardefine(name, val)
end

function Variables.varDefineEcho(name, val)
	mw.ext.VariablesLua.vardefine(name, val)
	return val
end

function Variables.varDefault(name, default)
	local val = mw.ext.VariablesLua.var(name)
	return (val ~= '' and val ~= nil) and val or default
end

function Variables.varDefaultMulti(...)
	--pack varargs
	local varargs = { n = select('#', ...), ... }

	for i = 1, varargs.n do
		local val = Variables.varDefault(varargs[i])
		if val then
			return val
		end
	end

	-- If even the last var didn't bring anything return the last argument
	return varargs[varargs.n]
end

return Class.export(Variables, {removeBlanks = false})
