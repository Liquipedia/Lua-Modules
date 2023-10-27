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

---Checks for the existence of a Lua module
---@param name string
---@return boolean
function Lua.moduleExists(name)
	if package.loaded[name] then
		return true
	else
		-- Package.Searchers was renamed from Loaders in lua5.2, have support for both
		---@diagnostic disable-next-line: deprecated
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

---Imports a module if it exists by its name.
---
---Allows requireDevIfEnabled option (requires the development version of a module if it
---exists and the dev feature flag is enabled. Otherwise requires the non-development module).
---@param name string
---@param options {requireDevIfEnabled: boolean, loadData: boolean?}?
---@return unknown?
function Lua.requireIfExists(name, options)
	if Lua.moduleExists(name) then
		return Lua.import(name, options)
	end
end

---Loads (mw.loadData) a data module if it exists by its name.
---@deprecated use `Lua.requireIfExists` with `loadData` option instead
---@param name string
---@return unknown?
function Lua.loadDataIfExists(name)
	mw.ext.TeamLiquidIntegration.add_category('Pages using deprecated Lua.loadDataIfExists function')
	return Lua.requireIfExists(name, {loadData = true})
end

---Imports a module by its name.
---
---Allows requireDevIfEnabled option (requires the development version of a module if it
---exists and the dev feature flag is enabled. Otherwise requires the non-development module).
---@param name string
---@param options {requireDevIfEnabled: boolean?, loadData: boolean?}?
---@return unknown
function Lua.import(name, options)
	options = options or {}
	local importFunction = options.loadData and mw.loadData or require
	if options.requireDevIfEnabled then
		if StringUtils.endsWith(name, '/dev') then
			error('Lua.import: Module name should not end in \'/dev\'')
		end

		local devName = name .. '/dev'
		local devEnabled = require('Module:FeatureFlag').get('dev')
		if devEnabled and require('Module:Namespace').isMain() then
			mw.ext.TeamLiquidIntegration.add_category('Pages using dev modules')
		end
		if devEnabled and Lua.moduleExists(devName) then
			return importFunction(devName)
		else
			return importFunction(name)
		end
	else
		return importFunction(name)
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
---@param frame Frame
---@return unknown
function Lua.invoke(frame)
	local moduleName = frame.args.module
	local fnName = frame.args.fn
	assert(moduleName, 'Lua.invoke: args.module is missing')
	assert(fnName, 'Lua.invoke: args.fn is missing')
	assert(
		not StringUtils.endsWith(moduleName, '/dev'),
		'Lua.invoke: Module name should not end in \'/dev\''
	)
	assert(
		not StringUtils.startsWith(moduleName, 'Module:'),
		'Lua.invoke: Module name should not begin with \'Module:\''
	)

	frame.args.module = nil
	frame.args.fn = nil

	local devEnabled = function(startFrame)
		local currentFrame = startFrame
		while currentFrame do
			if Logic.readBoolOrNil(currentFrame.args.dev) ~= nil then
				return Logic.readBool(currentFrame.args.dev)
			end
			currentFrame = currentFrame:getParent()
		end
	end

	local flags = {dev = devEnabled(frame)}
	return require('Module:FeatureFlag').with(flags, function()
		local module = Lua.import('Module:' .. moduleName, {requireDevIfEnabled = true})
		return module[fnName](frame)
	end)
end

--[[
Incorporates Lua.invoke functionality into an entry point. The resulting entry
point can be #invoked directly, without needing Lua.invoke.

Usage:

function JayModule.TemplateJay(frame) ... end
JayModule.TemplateJay = Lua.wrapAutoInvoke(JayModule, 'Module:JayModule', 'TemplateJay')

]]
---@param module table
---@param baseModuleName string
---@param fnName string
---@return fun(frame: Frame|table): unknown
function Lua.wrapAutoInvoke(module, baseModuleName, fnName)
	assert(
		not StringUtils.endsWith(baseModuleName, '/dev'),
		'Lua.wrapAutoInvoke: Module name should not end in \'/dev\''
	)
	assert(
		StringUtils.startsWith(baseModuleName, 'Module:'),
		'Lua.wrapAutoInvoke: Module name must begin with \'Module:\''
	)

	local moduleFn = module[fnName]

	return function(frame)
		local dev
		if type(frame.args) == 'table' then
			dev = frame.args.dev
		else
			dev = frame.dev
		end

		local flags = {dev = Logic.readBoolOrNil(dev)}
		return require('Module:FeatureFlag').with(flags, function()
			local variantModule = Lua.import(baseModuleName, {requireDevIfEnabled = true})
			local fn = module == variantModule and moduleFn or variantModule[fnName]
			return fn(frame)
		end)
	end
end

--[[
Incorporates Lua.invoke functionality into entry points of a module. The entry
points can then be invoked directly, without needing Lua.invoke.

This is intended for widely #invoked entry points where it is difficult to
migrate existing wikicode calls to Lua.invoke. Avoid applying on entry points
#invoked by a single template.

Functions whose names begin with 'Template' are assumed to be the entry points.
Specify fnNames to override this.

Usage:
local Jay = {}
function Jay.TemplateJay(frame) ... end

Lua.autoInvokeEntryPoints(JayModule, 'Module:JayModule')

]]
---@param module table
---@param baseModuleName string
---@param fnNames string[]?
function Lua.autoInvokeEntryPoints(module, baseModuleName, fnNames)
	fnNames = fnNames or Lua.getDefaultEntryPoints(module)

	for _, fnName in ipairs(fnNames) do
		module[fnName] = Lua.wrapAutoInvoke(module, baseModuleName, fnName)
	end
end

--[[
Returns the functions whose names begin with 'Template'. Functions that start
with 'Template' are presumably entry points.
]]
---@param module table
---@return string[]
function Lua.getDefaultEntryPoints(module)
	local fnNames = {}
	for fnName, fn in pairs(module) do
		if type(fn) == 'function' and StringUtils.startsWith(fnName, 'Template') then
			table.insert(fnNames, fnName)
		end
	end
	return fnNames
end

return Lua
