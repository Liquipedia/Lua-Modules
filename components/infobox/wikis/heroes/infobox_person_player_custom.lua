---
-- @Liquipedia
-- wiki=heroes
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
	local heroIcons = Array.map(Player:getAllArgsForBase(_args, 'hero'),
		function(hero)
			return Template.safeExpand(mw.getCurrentFrame(), 'HeroIcon/' .. hero)
		end
	)
	table.insert(widgets, Cell{name = 'Signature Heroes', content = {table.concat(heroIcons, '&nbsp;')}})

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'history' and string.match(_args.retired or '', '%d%d%d%d') then
		table.insert(widgets, Cell{name = 'Retired', content = {_args.retired}})
	end
	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

return CustomPlayer
