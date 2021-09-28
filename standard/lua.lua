---
-- @Liquipedia
-- wiki=commons
-- page=Module:Lua
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local StringUtils = require('Module:StringUtils')

local Lua = {}

function Lua.moduleExists(name)
	if package.loaded[name] then
		return true
	else
		for _, searcher in ipairs(package.searchers or package.loaders) do
			local loader = searcher(name)
			if type(loader) == 'function' then
				-- luacheck: ignore
				-- luacheck complains about package.preload being read-only
				package.preload[name] = loader
				return true
			end
		end
		return false
	end
end

function Lua.requireIfExists(name, default)
	if Lua.moduleExists(name) then
		return require(name)
	else
		return default
	end
end

function Lua.loadDataIfExists(name, default)
	if Lua.moduleExists(name) then
		return mw.loadData(name)
	else
		return default
	end
end

--[[
Imports a module by its name.

options.requireDevIfEnabled:
Requires the development version of a module (with /dev appended to name) if it
exists and the dev feature flag is enabled. Otherwise requires the non-
development module.
]]
function Lua.import(name, options)
	options = options or {}
	if options.requireDevIfEnabled then
		if StringUtils.endsWith(name, '/dev') then
			error('Lua.import: Module name should not end in \'/dev\'')
		end

		local devName = name .. '/dev'
		if require('Module:FeatureFlag').get('dev') and Lua.moduleExists(devName) then
			return require(devName)
		else
			return require(name)
		end
	else
		return require(name)
	end
end

--[[
This function intended to be #invoke'd from wikicode.

Invokes a function inside a module or a dev module depending on the dev feature
flag. Can also set the dev feature flag inside the function scope by passing
dev=1.

The following 3 code snippets are equivalent, assuming that Module:Magpie/dev
exists and that feature_dev is unset previously.

{{#invoke:Lua|invoke|module=Magpie|fn=theive|foo=3|dev=1}}

{{#vardefine:feature_dev|1}}
{{#invoke:Magpie/dev|theive|foo=3}}
{{#vardefine:feature_dev|}}

require('Module:FeatureFlag').set('dev', true)
require('Module:Magpie/dev').theive({args = {foo = 3}})
require('Module:FeatureFlag').set('dev', nil)

]]
function Lua.invoke(frame)
	local moduleName = frame.args.module
	local fnName = frame.args.fn
	if StringUtils.endsWith(moduleName, '/dev') then
		error('Lua.invoke: Module name should not end in \'/dev\'')
	end
	assert(moduleName, 'Lua.invoke: args.fn is missing')
	assert(fnName, 'Lua.invoke: args.fn is missing')

	local flags = {dev = Logic.readBoolOrNil(frame.args.dev)}
	return require('Module:FeatureFlag').with(flags, function()
		local module = Lua.import('Module:' .. moduleName, {requireDevIfEnabled = true})
		return module[fnName](frame)
	end)
end

return Lua
