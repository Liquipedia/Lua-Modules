---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Strategy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Strategy = require('Module:Infobox/Strategy')
local Injector = require('Module:Infobox/Widget/Injector')

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
