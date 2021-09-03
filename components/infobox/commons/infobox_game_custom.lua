---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Game/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Infobox/Game')
local Injector = require('Module:Infobox/Widget/Injector')

local CustomGame = Class.new()

local CustomInjector = Class.new(Injector)

function CustomGame.run(frame)
	local customGame = Game(frame)
	customGame.createWidgetInjector = CustomGame.createWidgetInjector
	return customGame:createInfobox(frame)
end

function CustomGame:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	return widgets
end

return CustomGame
