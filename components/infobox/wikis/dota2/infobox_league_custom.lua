---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _args

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

function CustomLeague.run(frame)
	local league = League(frame)

	-- Override links to allow one param to set multiple links
	league.args.datdota = league.args.leagueid
	league.args.dotabuff = league.args.leagueid
	league.args.stratz = league.args.leagueid

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.appendLiquipediatierDisplay = CustomLeague.appendLiquipediatierDisplay
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.getWikiCategories = CustomLeague.getWikiCategories

	_args = league.args

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
	table.insert(widgets, Cell{
		name = 'Game',
		content = {Game.text{game = _args.game}}
	})
	table.insert(widgets, Cell{
		name = 'Version',
		content = {CustomLeague:_createPatchCell(args)}
	})
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {args.team_number}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {args.player_number}
	})
	table.insert(widgets, Cell{
		name = 'Dota TV Ticket',
		content = {args.dotatv}
	})
	if Logic.isNumeric(args.points) then
		table.insert(widgets, Cell{
			name = 'Pro Circuit Points',
			content = {mw.language.new('en'):formatNum(tonumber(args.points) --[[@as number]])}
		})
	end
	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'liquipediatier' then
		if _args.pctier and _args.liquipediatiertype ~= 'Qualifier' then
			local valveIcon = ''
			if Logic.readBool(_args.valvepremier) then
				valveIcon = Template.safeExpand(mw.getCurrentFrame(), 'Valve/infobox')
			end
			table.insert(widgets,
				Cell{
					name = 'Pro Circuit Tier',
					content = {'[[Dota Pro Circuit|' .. _args.pctier .. ']] ' .. valveIcon},
					classes = {'valvepremier-highlighted'}
				}
			)
		end
	end
	return widgets
end

function CustomLeague:appendLiquipediatierDisplay(args)
	if String.isEmpty(args.pctier) and Logic.readBool(args.valvepremier) then
		return ' ' .. Template.safeExpand(mw.getCurrentFrame(), 'Valve/infobox')
	end
	return ''
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.valvepremier)
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.valvepremier = String.isNotEmpty(args.valvepremier) and '1' or '0'
	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''
	lpdbData.extradata.dpcpoints = String.isNotEmpty(args.points) or ''

	return lpdbData
end

function CustomLeague:defineCustomPageVariables(args)
	-- Custom Vars
	Variables.varDefine('tournament_pro_circuit_points', args.points or '')
	local isIndividual = String.isNotEmpty(args.individual) or String.isNotEmpty(args.player_number)
	Variables.varDefine('tournament_individual', isIndividual and 'true' or '')
	Variables.varDefine('tournament_valve_premier', args.valvepremier)
	Variables.varDefine('tournament_publisher_major', args.valvepremier)
	Variables.varDefine('tournament_pro_circuit_tier', args.pctier)
	Variables.varDefine('tournament_publishertier', args.pctier)

	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or '')
	Variables.varDefine('tournament_tier', args.liquipediatier or '')
	Variables.varDefine('tournament_tier_type', args.liquipediatiertype)
	Variables.varDefine('tournament_prizepool', args.prizepool or '')
	Variables.varDefine('tournament_mode', args.mode or '')

	--Legacy date vars
	local sdate = Variables.varDefault('tournament_startdate', '')
	local edate = Variables.varDefault('tournament_enddate', '')
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)
	Variables.varDefine('date', edate)
	Variables.varDefine('sdate', sdate)
	Variables.varDefine('edate', edate)
end

---@param args table
---@return table
function CustomLeague:getWikiCategories(args)
	return {Game.name{game = args.game} .. " Competitions"}
end

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
