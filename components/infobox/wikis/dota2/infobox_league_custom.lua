---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League/temp', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class Dota2LeagueInfobox: InfoboxLeagueTemp
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	-- Override links to allow one param to set multiple links
	league.args.datdota = league.args.leagueid
	league.args.dotabuff = league.args.leagueid
	league.args.stratz = league.args.leagueid

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		local points = tonumber(args.points)

		Array.appendWith(widgets,
			Cell{name = 'Game', content = {Game.text{game = args.game}}},
			Cell{name = 'Version', content = {self.caller:_createPatchCell(args)}},
			Cell{name = 'Teams', content = {args.team_number}},
			Cell{name = 'Players', content = {args.player_number}},
			Cell{name = 'Dota TV Ticket', content = {args.dotatv}},
			Cell{name = 'Pro Circuit Points', content = {points and mw.language.new('en'):formatNum(points)}}
		)
	elseif id == 'liquipediatier' and args.pctier and args.liquipediatiertype ~= 'Qualifier' then
		local valveIcon = ''
		if Logic.readBool(args.valvepremier) then
			valveIcon = Template.safeExpand(mw.getCurrentFrame(), 'Valve/infobox')
		end
		table.insert(widgets,
			Cell{
				name = 'Pro Circuit Tier',
				content = {'[[Dota Pro Circuit|' .. args.pctier .. ']] ' .. valveIcon},
				classes = {'valvepremier-highlighted'}
			}
		)
	end

	return widgets
end

---@param args table
---@return string
function CustomLeague:appendLiquipediatierDisplay(args)
	if String.isEmpty(args.pctier) and Logic.readBool(args.valvepremier) then
		return ' ' .. Template.safeExpand(mw.getCurrentFrame(), 'Valve/infobox')
	end
	return ''
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.valvepremier)
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.valvepremier = String.isNotEmpty(args.valvepremier) and '1' or '0'
	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''
	lpdbData.extradata.dpcpoints = String.isNotEmpty(args.points) or ''

	return lpdbData
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.publishertier = args.pctier
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	-- Custom Vars
	Variables.varDefine('tournament_pro_circuit_points', args.points or '')
	local isIndividual = String.isNotEmpty(args.individual) or String.isNotEmpty(args.player_number)
	Variables.varDefine('tournament_individual', isIndividual and 'true' or '')
	Variables.varDefine('tournament_valve_premier', args.valvepremier)
	Variables.varDefine('tournament_publisher_major', args.valvepremier)
	Variables.varDefine('tournament_pro_circuit_tier', args.pctier)

	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or '')
	Variables.varDefine('tournament_tier', args.liquipediatier or '')
	Variables.varDefine('tournament_tier_type', args.liquipediatiertype)
	Variables.varDefine('tournament_prizepool', args.prizepool or '')

	--Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
end

---@param args table
---@return string?
function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end

	local displayText = '[['.. args.patch .. ']]'
	if args.epatch then
		displayText = displayText .. ' &ndash; [['.. args.epatch .. ']]'
	end
	return displayText
end

return CustomLeague
