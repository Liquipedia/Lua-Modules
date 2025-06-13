---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class TetrisLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

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

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox(frame)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Teams', content = {args.team_number}},
			Cell{name = 'Players', content = {args.player_number}}
		)
	elseif id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {Game.name{game = args.game}}},
		}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''
	lpdbData.extradata.gamegroup = CustomLeague._determineGameGroup(lpdbData.game)

	return lpdbData
end

---@param game string?
---@return string?
function CustomLeague._determineGameGroup(game)
	for gameGroup, games in pairs(GAME_GROUPS) do
		if Table.includes(games, game) then
			return gameGroup
		end
	end
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.mode = args.team_number and 'team' or 'individual'
end

return CustomLeague
