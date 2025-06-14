---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class PokemonLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local MODES = mw.loadData('Module:GameModes')
local FORMATS = mw.loadData('Module:GameFormats')

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.format = league:_getGameFormat()

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {Game.name{game = args.game}}},
			Cell{name = 'Game mode', content = {self.caller:_getGameMode()}},
		}
	elseif id == 'customcontent' then
		if args.player_number then
			table.insert(widgets, Title{children = 'Players'})
			table.insert(widgets, Cell{name = 'Number of players', content = {args.player_number}})
		elseif args.team_number then
			table.insert(widgets, Title{children = 'Teams'})
			table.insert(widgets, Cell{name = 'Number of teams', content = {args.team_number}})
		end
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''

	return lpdbData
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.mode = self:_getGameMode()
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy Vars:
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
end

---@return string?
function CustomLeague:_getGameMode()
	return MODES[string.lower(self.args.mode or '')]
end

---@return string?
function CustomLeague:_getGameFormat()
	return FORMATS[string.lower(self.args.format or '')]
end

return CustomLeague
