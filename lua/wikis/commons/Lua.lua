---
-- @Liquipedia
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

---@param name string
---@param options {requireDevIfEnabled: boolean?}?
---@return any
local getModuleName = function(name, options)
	options = options or {}
	if options.requireDevIfEnabled == false then
		return name
	end
	if StringUtils.endsWith(name, '/dev') or StringUtils.contains(name, '/dev/') then
		error('Lua.import: Direct import of dev modules is not allowed')
	end
	local devFlag = FeatureFlag.get('dev')
	if not devFlag then
		return name
	end
	local devName = name .. '/dev' .. (type(devFlag) == 'string' and ('/' .. devFlag) or '')
	if require('Module:Namespace').isMain() then
		mw.ext.TeamLiquidIntegration.add_category('Pages using dev modules')
	end
	return Lua.moduleExists(devName) and devName or name
end

---Imports a module if it exists by its name.
---
---By default it will include the /dev module if in dev mode activated. This can be turned off by setting
--- the requireDevIfEnabled option to false.
---@param name string
---@param options {requireDevIfEnabled: boolean, loadData: boolean?}?
---@return unknown?
function Lua.requireIfExists(name, options)
	local moduleName = getModuleName(name, options)
	if Lua.moduleExists(moduleName) then
		return Lua.import(name, options)
	end
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
	local moduleName = getModuleName(name, options)
	return importFunction(moduleName)
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

	-- idealy would remove frame.args.module and frame.args.fn
	-- but due to how frame.args behaves this is not possible without having negative impact on the performance
	-- or causing other issues

	local getDevFlag = function(startFrame)
		local currentFrame = startFrame
		while currentFrame do
			if currentFrame.args.dev ~= nil then
				if Logic.readBoolOrNil(currentFrame.args.dev) ~= nil then
					return Logic.readBool(currentFrame.args.dev)
				else
					return currentFrame.args.dev
				end
			end
			currentFrame = currentFrame:getParent()
		end
	end

	local devFlag = getDevFlag(frame)
	local flags = {dev = devFlag}
	return FeatureFlag.with(flags, function()
		local module = Lua.import('Module:' .. moduleName)
		local context = {baseModuleName = 'Module:' .. moduleName, module = module}
		return Lua.withPerfSetup(context, function()
			return Lua.callAndDisplayErrors(module[fnName], frame, devFlag)
		end)
	end)
end

---@param fn function
---@param frame Frame
---@param hardErrors boolean|string?
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
				table.insert(parts, tostring(ErrorDisplay.ClassicError(error)))
			end
		else
			table.insert(parts, tostring(ErrorDisplay.ErrorList{errors = errors}))
		end
		if mw.title.getCurrentTitle().namespace == 2 then
			mw.ext.TeamLiquidIntegration.add_category('User pages with script errors')
		else
			mw.ext.TeamLiquidIntegration.add_category('Pages with script errors')
		end
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

return Lua
