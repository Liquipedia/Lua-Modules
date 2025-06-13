---
-- @Liquipedia
-- page=Module:PageVariableNamespace
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local StringUtils = require('Module:StringUtils')

---@class Namespace
---@field prefix string
local Namespace = Class.new(function(self, prefix)
	self.prefix = prefix
end)

---@param key wikiVariableKey
---@return string?
function Namespace:get(key)
	return StringUtils.nilIfEmpty(mw.ext.VariablesLua.var(self.prefix .. key))
end

---@param key wikiVariableKey
---@param value wikiVariableValue
function Namespace:set(key, value)
	mw.ext.VariablesLua.vardefine(self.prefix .. key, Logic.emptyOr(value))
end

---@param key wikiVariableKey
function Namespace:delete(key)
	self:set(key, nil)
end

---@class PageVariableNamespaceCachedTable
---@field results table
---@field table table
local CachedTable = Class.new(function(self, tbl)
	self.results = {}
	self.table = tbl
end)

---@param key string|number
---@return string|number|nil
function CachedTable:get(key)
	if not self.results[key] then
		self.results[key] = self.table:get(key)
	end
	return self.results[key]
end

---@param key string|number
---@param value string|number|nil
function CachedTable:set(key, value)
	self.results[key] = nil
	self.table:set(key, value)
end

---@param key string|number
function CachedTable:delete(key)
	self:set(key, nil)
end

---@class PageVariableNamespace
---@operator call(string?):Namespace
local PageVariableNamespace = {}

---@param options {cached: boolean?, separator: string?, namespace: string?}?
---@return {cached: boolean, separator: string, namespace: string?}
---@overload fun(options: string): {cached: boolean, separator: string, namespace: string?}
---@overload fun(): {cached: false, separator: string}
function PageVariableNamespace.readOptions(options)
	local parsedOptions = {}

	options = options or {}
	if type(options) == 'string' then
		parsedOptions = {namespace = options}
	end

	parsedOptions.cached = Logic.nilOr(options.cached, false)
	parsedOptions.separator = options.separator or '.'
	parsedOptions.namespace = parsedOptions.namespace or options.namespace

	return parsedOptions
end

PageVariableNamespace.Namespace = Namespace
PageVariableNamespace.CachedTable = CachedTable

setmetatable(PageVariableNamespace, {
	__call = function(_, options_)
		local options = PageVariableNamespace.readOptions(options_)

		local prefix = options.namespace and options.namespace .. options.separator or ''
		local pageVars = Namespace(prefix)
		return options.cached
			and CachedTable(pageVars)
			or pageVars
	end,
})

return PageVariableNamespace
