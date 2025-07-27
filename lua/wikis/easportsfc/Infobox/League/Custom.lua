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
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class EafcLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local PLATFORMS = {
	pc = 'PC',
	xbox = 'Xbox (2001)',
	xbox360 = 'Xbox 360',
	xboxone = 'Xbox One',
	ps3 = 'PlayStation 3',
	playstation3 = 'PlayStation 3',
	ps4 = 'PlayStation 4',
	playstation4 = 'PlayStation 4',
	ps5 = 'PlayStation 5',
	playstation5 = 'PlayStation 5',
	xboxplaystation = 'Xbox and PlayStation',
	xboxandplaystation = 'Xbox and PlayStation',
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.player_number = league.args.participants_number
	league.args.game = Game.name{game = league.args.game}
	league.args.mode = (league.args.mode or '1v1'):lower()
	league.args.platform = PLATFORMS[(league.args.platform or 'pc'):lower():gsub(' ', '')]

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Mode', content = {args.mode}},
			Cell{name = 'Platform', content = {args.platform}},
			Cell{name = 'Game', content = {args.game}},
			Cell{name = 'Number of Players', content = {args.player_number}},
			Cell{name = 'Number of Teams', content = {args.team_number}}
		)
	end

	return widgets
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or args.name)
	Variables.varDefine('tournament_tier', args.liquipediatier)
	Variables.varDefine('mode', args.mode)

	--Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	return {
		args.game and (args.game .. ' Competitions') or 'Tournaments without game version',
		args.platform and (args.platform .. ' Tournaments') or 'Tournaments without platform',
	}
end

return CustomLeague
