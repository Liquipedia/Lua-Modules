---
-- @Liquipedia
-- page=Module:Namespace
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local NS_MAIN = 0
local NS_USER = 2
local NS_PROJECT = 4 -- "Liquipedia" namespace
local NS_TEMPLATE = 10
local NS_HELP = 12
local NS_MODULE = 828
local NS_MODULE_TALK = 829

local Namespace = {}

---Determins whether a given title object is in the given namespaces, and optionally their talk namespaces.
---@param title Title
---@param namespaces (string|integer)[]
---@param includeTalk boolean?
---@return boolean
local function isInNamespace(title, namespaces, includeTalk)
	if includeTalk then
		return Array.any(namespaces, function (namespace)
			return title:hasSubjectNamespace(namespace)
		end)
	end
	return title:inNamespaces(unpack(namespaces))
end

---Determines if a title object is in the Main namespace.
---`NS_MODULE_TALK` is treated as Main namespace for ScribuntoUnit to work properly.
---Will use the title object of the page this module is invoked on if no title is provided.
---@param title Title?
---@return boolean
function Namespace.isMain(title)
	title = title or mw.title.getCurrentTitle()
	return isInNamespace(title, {NS_MAIN, NS_MODULE_TALK})
end

---Determines if a title object is in the User namespace, also considers
---the User Talk namespace (unless excluded using the `excludeTalk` paramater).
---Will use the title object of the page this module is invoked on if no title is provided.
---@param title Title?
---@param excludeTalk boolean?
---@return boolean
function Namespace.isUser(title, excludeTalk)
	title = title or mw.title.getCurrentTitle()
	return isInNamespace(title, {NS_USER}, not excludeTalk)
end

---Determines if a title object is in a namespace used for documentation purposes (`NS_PROJECT`,
---`NS_TEMPLATE`, `NS_HELP`, and `NS_MODULE`), also considers their talk pages (unless excluded
---using the `excludeTalk` paramater). Will use the title object of the page this module is
---invoked on if no title is provided.
---@param title Title?
---@param excludeTalk boolean?
---@return boolean
function Namespace.isDocumentative(title, excludeTalk)
	title = title or mw.title.getCurrentTitle()
	return isInNamespace(title, {NS_PROJECT, NS_TEMPLATE, NS_HELP, NS_MODULE}, not excludeTalk)
end

Namespace.getIdsByName = FnUtil.memoize(function()
	return Table.map(mw.site.namespaces, function(id, ns) return ns.name, id end)
end)

---Fetches the namespace id (number) for a given namespace name
---@param name string?
---@return integer?
function Namespace.idFromName(name)
	name = (name or ''):gsub('_', ' ')
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

return Namespace
