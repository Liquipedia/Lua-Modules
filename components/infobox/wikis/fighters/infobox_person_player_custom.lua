---
-- @Liquipedia
-- wiki=fighters
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local GamesPlayed = require('Module:GamesPlayed')
local Lua = require('Module:Lua')
local YearsActive = require('Module:YearsActive') -- TODO Convert to use the commons YearsActive

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _games = {}

function CustomPlayer.run(frame)
	local player = Player(frame)

	local gamesText = GamesPlayed.get{game = player.args.game, player = mw.title.getCurrentTitle().baseText}
	_games = mw.text.split(gamesText, '</br>', true)

	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables

	return player:createInfobox()
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{name = 'Games', content = _games})

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		table.insert(widgets,
			Cell{name = 'Years Active', content = {YearsActive.get{player = mw.title.getCurrentTitle().baseText}}}
		)
	end

	return widgets
end

function CustomPlayer:defineCustomPageVariables(args)
	self.infobox:categories(unpack(Array.map(_games, function(game)
		return game .. ' Players'
	end)))
end

return CustomPlayer
