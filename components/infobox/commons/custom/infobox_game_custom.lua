---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Game/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Game = Lua.import('Module:Infobox/Game', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

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
