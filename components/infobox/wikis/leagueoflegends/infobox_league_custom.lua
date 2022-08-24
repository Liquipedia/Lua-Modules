---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

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

	return league:createInfobox(frame)
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
	return widgets
end

function CustomLeague:appendLiquipediatierDisplay()
	if Logic.readBool(_args.riotpremier) then
		return ' ' .. RIOT_ICON
	end
	return ''
end

function CustomLeague:liquipediaTierHighlighted()
	return Logic.readBool(_args.riotpremier)
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.participantsnumber = args.participants_number or args.team_number
	lpdbData.publishertier = Logic.readBool(args.riotpremier) and '1' or ''

	lpdbData.extradata = {
		individual = String.isNotEmpty(args.participants_number) or
			String.isNotEmpty(args.individual) and 'true' or '',
		['is riot premier'] = String.isNotEmpty(args.riotpremier) and 'true' or '',
	}

	return lpdbData
end

function CustomLeague:defineCustomPageVariables()
	-- Custom Vars
	Variables.varDefine('tournament_riot_premier', _args.riotpremier)
	Variables.varDefine('tournament_publisher_major', _args.riotpremier)
	Variables.varDefine('tournament_publishertier', Logic.readBool(_args.riotpremier) and '1' or nil)

	--Legacy vars
	Variables.varDefine('tournament_ticker_name', _args.tickername or '')
	Variables.varDefine('tournament_tier', _args.liquipediatier or '')
	Variables.varDefine('tournament_tier_type', Variables.varDefault('tournament_liquipediatiertype'))
	Variables.varDefine('tournament_mode', _args.mode or '')

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

return CustomLeague
