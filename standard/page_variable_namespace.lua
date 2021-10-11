---
-- @Liquipedia
-- wiki=commons
-- page=Module:PageVariableNamespace
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local StringUtils = require('Module:StringUtils')

local Namespace = Class.new(function(self, prefix)
	self.prefix = prefix
end)

function Namespace:get(key)
	return StringUtils.nilIfEmpty(mw.ext.VariablesLua.var(self.prefix .. key))
end

function Namespace:set(key, value)
	mw.ext.VariablesLua.vardefine(self.prefix .. key, StringUtils.nilIfEmpty(value))
end

function Namespace:delete(key)
	self:set(key, nil)
end

local CachedTable = Class.new(function(self, table)
	self.results = {}
	self.table = table
end)

function CachedTable:get(key)
	if not self.results[key] then
		self.results[key] = self.table:get(key)
	end
	return self.results[key]
end

function CachedTable:set(key, value)
	self.results[key] = nil
	self.table:set(key, value)
end

function CachedTable:delete(key)
	self:set(key, nil)
end

local PageVariableNamespace = {}

function PageVariableNamespace.readOptions(options)
	if not options then
		options = {}
	elseif type(options) == 'string' then
		options = {namespace = options}
	end

	options.cached = Logic.nilOr(options.cached, false)
	options.separator = options.separator or '.'
	return options
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
