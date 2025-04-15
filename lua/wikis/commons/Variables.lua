---
-- @Liquipedia
-- wiki=commons
-- page=Module:Variables
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Variables = {}

---Stores a wiki-variable and returns the empty string
---@param name wikiVariableKey Key of the wiki-variable
---@param value wikiVariableValue Value of the wiki-variable
---@return string #always the empty string
function Variables.varDefine(name, value)
	return mw.ext.VariablesLua.vardefine(name, value)
end

---Stores a wiki-variable and returns the stored value
---@param name wikiVariableKey Key of the wiki-variable
---@param value wikiVariableValue Value of the wiki-variable
---@return string
function Variables.varDefineEcho(name, value)
	return mw.ext.VariablesLua.vardefineecho(name, value)
end

---Gets the stored value of a wiki-variable
---@generic T
---@param name wikiVariableKey Key of the wiki-variable
---@param default T fallback value if wiki-variable is not defined
---@return string|T
---@overload fun(name: wikiVariableKey):string?
function Variables.varDefault(name, default)
	local val = mw.ext.VariablesLua.var(name)
	return (val ~= '' and val ~= nil) and val or default
end

---
---@param ... wikiVariableKey wiki-variable keys
---@return string
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

---@param name wikiVariableKey Key of the wiki-variable
---@return boolean
function Variables.varExists(name)
	return Variables.varDefault(name) ~= nil
end

return Variables
