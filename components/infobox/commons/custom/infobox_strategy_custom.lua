---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Strategy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Strategy = Lua.import('Module:Infobox/Strategy', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

local CustomStrategy = Class.new()

local CustomInjector = Class.new(Injector)

function CustomStrategy.run(frame)
	local customStrategy = Strategy(frame)
	customStrategy.createWidgetInjector = CustomStrategy.createWidgetInjector
	return customStrategy:createInfobox(frame)
end

function CustomStrategy:createWidgetInjector()
	return CustomInjector()
end

return CustomStrategy
