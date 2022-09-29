---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Patch = Lua.import('Module:Infobox/Patch', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

local CustomPatch = Class.new()

local CustomInjector = Class.new(Injector)

function CustomPatch.run(frame)
	local customPatch = Patch(frame)
	customPatch.createWidgetInjector = CustomPatch.createWidgetInjector
	return customPatch:createInfobox(frame)
end

function CustomPatch:createWidgetInjector()
	return CustomInjector()
end

return CustomPatch
