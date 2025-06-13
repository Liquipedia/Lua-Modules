---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local InfoboxPrizePool = Lua.import('Module:Infobox/Extensions/PrizePool')
local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class HearthstoneLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local MODES = {
	standard = 'Standard',
	wild = 'Wild',
	battlegrounds = 'Battlegrounds',
	arena = 'Arena',
	duels = 'Duels',
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.player_number = league.args.participants_number
	league.args.mode = MODES[string.lower(league.args.mode or '')]

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
			Cell{name = 'Number of Players', content = {args.player_number}},
			Cell{name = 'Number of Teams', content = {args.team_number}}
		)
	elseif id == 'prizepool' then
		if args.bin or args.binusd then
			table.insert(widgets, Cell{name = 'Buy-in', content = {
				InfoboxPrizePool.display{
					prizepool = args.bin,
					prizepoolusd = args.binusd,
					currency = args.localcurrency,
					setvariables = false,
				}
			}})
		end
	end

	return widgets
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or args.name)
	Variables.varDefine('tournament_tier', args.liquipediatier)
	Variables.varDefine('tournament_prizepool', args.prizepoolusd)
	Variables.varDefine('mode', args.mode)

	--Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDatesdate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	return {args.mode and (args.mode .. ' Tournaments') or nil}
end

---@param args table
---@return string
function CustomLeague:appendLiquipediatierDisplay(args)
	if Logic.readBool(args.blizzardpremier) then
		return '[[File:Blizzard_logo.png|x12px|link=Blizzard Entertainment|Premier Tournament held by Blizzard]]'
	end

	return ''
end

return CustomLeague
