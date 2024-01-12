---
-- @Liquipedia
-- wiki=simracing
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args

	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox()
end

function CustomInjector:addCustomCells(widgets)
	local games = Array.map(Player:getAllArgsForBase(_args, 'game'),
		function(game)
			return Template.safeExpand(mw.getCurrentFrame(), 'Game/' .. game)
		end
	)
	table.insert(widgets, Cell{name = 'Games', content = {table.concat(games, '&nbsp;')}})

	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

return CustomPlayer
