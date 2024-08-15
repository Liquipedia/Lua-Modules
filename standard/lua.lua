---
-- @Liquipedia
-- wiki=commons
-- page=Module:Lua
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FeatureFlag = require('Module:FeatureFlag')
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
---By default it will include the /dev module if in dev mode activated. This can be turned off by setting
--- the requireDevIfEnabled option to false.
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
---By default it will include the /dev module if in dev mode activated. This can be turned off by setting
--- the requireDevIfEnabled option to false.
--- Optionally mw.loaddata can be used instead of require by passing the loadData option.
---@param name string
---@param options {requireDevIfEnabled: boolean?, loadData: boolean?}?
---@return unknown
function Lua.import(name, options)
	options = options or {}
	local importFunction = options.loadData and mw.loadData or require
	if options.requireDevIfEnabled ~= false then
		if StringUtils.endsWith(name, '/dev') then
			error('Lua.import: Module name should not end in \'/dev\'')
		end

		local devName = name .. '/dev'
		local devEnabled = FeatureFlag.get('dev')
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

	local devActive = devEnabled(frame)
	local flags = {dev = devActive}
	return FeatureFlag.with(flags, function()
		local module = Lua.import('Module:' .. moduleName)
		local context = {baseModuleName = 'Module:' .. moduleName, module = module}
		return Lua.withPerfSetup(context, function()
			return Lua.callAndDisplayErrors(module[fnName], frame, devActive)
		end)
	end)
end

---@param fn function
---@param frame Frame
---@param hardErrors boolean?
---@return string
function Lua.callAndDisplayErrors(fn, frame, hardErrors)
	local ErrorDisplay = require('Module:Error/Display')
	local ErrorExt = require('Module:Error/Ext')

	local result = Logic.tryOrElseLog(function() return fn(frame) end)
	local parts = result and {tostring(result)} or {}

	local errors = ErrorExt.Stash.retrieve()
	if #errors > 0 then
		if hardErrors then
			for _, error in ipairs(errors) do
				table.insert(parts, ErrorDisplay.ClassicError(error))
			end
		else
			table.insert(parts, tostring(ErrorDisplay.ErrorList{errors = errors}))
		end
		mw.ext.TeamLiquidIntegration.add_category('Pages with script errors')
	end

	return table.concat(parts)
end


---Automatically sets up performance instrumentation if using Lua.invoke
---@param context {baseModuleName: string, module: unknown}
---@param f fun(): ...
---@return ...
function Lua.withPerfSetup(context, f)
	if FeatureFlag.get('perf') then
		require('Module:Performance/Util').startFromInvoke(context)
	end
	local function post(...)
		if FeatureFlag.get('perf') then
			require('Module:Performance/Util').stopAndSave()
		end
		return ...
	end
	return post(f())
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
		return FeatureFlag.with(flags, function()
			local variantModule = Lua.import(baseModuleName)
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
