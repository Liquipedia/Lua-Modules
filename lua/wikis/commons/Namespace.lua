---
-- @Liquipedia
-- wiki=commons
-- page=Module:Namespace
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Namespace = {}

---Determines if the page this module is invoked on is in main space
---829 (ModuleTalk) is treated as main space for ScribuntoUnit to work properly
---@return boolean
function Namespace.isMain()
	return mw.title.getCurrentTitle():inNamespace(0) or mw.title.getCurrentTitle():inNamespace(829)
end

Namespace.getIdsByName = FnUtil.memoize(function()
	return Table.map(mw.site.namespaces, function(id, ns) return ns.name, id end)
end)

---Fetches the namespace id (number) for a given namespace name
---@param name string?
---@return integer?
function Namespace.idFromName(name)
	return Namespace.getIdsByName()[name]
end

---Fetches the namespace name for a given namespace id (number)
---@param id integer|string|nil
---@return string?
function Namespace.nameFromId(id)
	return (mw.site.namespaces[tonumber(id)] or {}).name
end

---Builds the namespace prefix for a given namespace id (number)
---@param id integer|string|nil
---@return string?
function Namespace.prefixFromId(id)
	local name = Namespace.nameFromId(id)
	if String.isNotEmpty(name) then
		return name .. ':'
	end

	return name
end

return Class.export(Namespace, {frameOnly = true})
