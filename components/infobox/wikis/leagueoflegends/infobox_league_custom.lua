---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _args

local RIOT_ICON = '[[File:Riot Games Tier Icon.png|x12px|link=Riot Games|Premier Tournament held by Riot Games]]'

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	_args.tickername = _args.tickername or _args.shortname


	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.appendLiquipediatierDisplay = CustomLeague.appendLiquipediatierDisplay

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {args.team_number}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {args.participants_number}
	})
	table.insert(widgets, Cell{
		name = 'Version',
		content = {CustomLeague:_createPatchCell(args)}
	})
	return widgets
end

function CustomLeague:appendLiquipediatierDisplay(args)
	if Logic.readBool(args.riotpremier) then
		return ' ' .. RIOT_ICON
	end
	return ''
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.riotpremier)
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.individual = String.isNotEmpty(args.participants_number) or
			String.isNotEmpty(args.individual) and 'true' or ''

	lpdbData.extradata['is riot premier'] = String.isNotEmpty(args.riotpremier) and 'true' or ''

	return lpdbData
end

function CustomLeague:defineCustomPageVariables(args)
	-- Custom Vars
	Variables.varDefine('tournament_riot_premier', args.riotpremier)
	Variables.varDefine('tournament_publisher_major', args.riotpremier)
	Variables.varDefine('tournament_publishertier', Logic.readBool(args.riotpremier) and '1' or nil)

	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or '')
	Variables.varDefine('tournament_tier', args.liquipediatier or '')
	Variables.varDefine('tournament_tier_type', Variables.varDefault('tournament_liquipediatiertype'))
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

function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end

	local displayText = '[[Patch ' .. args.patch .. ']]'
	if args.epatch then
		displayText = displayText .. ' &ndash; [[Patch ' .. args.epatch .. ']]'
	end
	return displayText
end

return CustomLeague
