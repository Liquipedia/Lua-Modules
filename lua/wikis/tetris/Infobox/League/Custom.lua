---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class TetrisLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local GAME_GROUPS = {
	classic = {'tetris', 'classic', 'classic ntsc', 'classic pal', 'classic das', 'super',
		'plus', 'plus 2'},
	modern = {'te', 'tec', 'jstris', 'wwc', 'tetrio', 'nuketris',
		'tetris 2', 'ppt1', 'ppt2', 't99', 'td', 'tetris friends',
		'tetris online japan', 'tetris online poland'},
	other = {'attack', '64', 'tnt', 'tetris & dr.mario', 'nullpomino', 'blockbox', 'cultris 2',
		'tetrinet 2'},
	tgm = {'tgm', 'tgm2', 'tgm3', 'tgm4'},
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
			Cell{name = 'Teams', children = {args.team_number}},
			Cell{name = 'Players', children = {args.player_number}}
		)
	elseif id == 'gamesettings' then
		return {
			Cell{name = 'Game version', children = {Game.name{game = args.game}}},
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
