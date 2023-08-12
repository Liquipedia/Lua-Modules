---
-- @Liquipedia
-- wiki=tetris
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args

local GAME_GROUPS = {
	classic = {'Tetris', 'NES (1989)', 'NES (1989) NTSC', 'NES (1989) PAL', 'NES (1989) DAS', 'Super Tetris',
		'Plus', 'Plus 2'},
	modern = {'Tetris Effect', 'Tetris Effect: Connected', 'Jstris', 'Worldwide Combos', 'TETR.IO', 'Nuketris',
		'Tetris 2', 'Puyo Puyo Tetris', 'Puyo Puyo Tetris 2', 'Tetris 99', 'Tetris DS', 'Tetris Friends',
		'Tetris Online Japan', 'Tetris Online Poland'},
	other = {'Attack', '64 (1998)', 'The New Tetris', 'Tetris & Dr.Mario', 'NullpoMino', 'Blockbox', 'Cultris 2',
		'TetriNET 2'},
	tgm = {'The Grand Master', 'The Grand Master 2', 'The Grand Master 3'},
}

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {_args.team_number}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {_args.player_number}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {
					Game.name{game = _args.game}
				}
			},
		}
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.game = Game.name{game = args.game}
	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''
	lpdbData.extradata.gamegroup = CustomLeague._determineGameGroup(lpdbData.game)

	return lpdbData
end

function CustomLeague._determineGameGroup(game)
	for gameGroup, games in pairs(GAME_GROUPS) do
		if Table.includes(games, game) then
			return gameGroup
		end
	end
end

function CustomLeague:defineCustomPageVariables(args)
	if args.team_number then
		Variables.varDefine('tournament_mode', 'team')
	else
		Variables.varDefine('tournament_mode', 'individual')
	end
	Variables.varDefine('tournament_publishertier', args.publisherpremier)
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.publisherpremier)
end

return CustomLeague
