---
-- @Liquipedia
-- wiki=fifa
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _args
local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local PLATFORMS = {
	pc = 'PC',
	['xbox 360'] = 'Xbox 360',
	['xbox one'] = 'Xbox One',
	ps3 = 'Playstation 3',
	['playstation 3'] = 'Playstation 3',
	ps4 = 'Playstation 4',
	['playstation 4'] = 'Playstation 4',
	ps5 = 'Playstation 5',
	['playstation 5'] = 'Playstation 5',
	['xbox playstation'] = 'Xbox and PlayStation',
	['xbox and playstation'] = 'Xbox and PlayStation',
}

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

	_args.player_number = _args.participants_number
	_args.game = Game.name{game = _args.game}
	_args.mode = (_args.mode or '1v1'):lower()
	_args.platform = PLATFORMS[(_args.platform or 'pc'):lower()]

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Mode',
		content = {_args.mode}
	})
	table.insert(widgets, Cell{
		name = 'Platform',
		content = {_args.platform}
	})
	table.insert(widgets, Cell{
		name = 'Game',
		content = {_args.game}
	})
	table.insert(widgets, Cell{
		name = 'Number of Players',
		content = {_args.player_number}
	})
	table.insert(widgets, Cell{
		name = 'Number of Teams',
		content = {_args.team_number}
	})

	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.participantsnumber = args.player_number or args.team_number

	return lpdbData
end

function CustomLeague:defineCustomPageVariables()
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', _args.tickername or _args.name)
	Variables.varDefine('tournament_tier', _args.liquipediatier)
	Variables.varDefine('tournament_mode', _args.mode)

	--Legacy date vars
	local sdate = Variables.varDefault('tournament_startdate', '')
	local edate = Variables.varDefault('tournament_enddate', '')
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)
	Variables.varDefine('date', edate)
	Variables.varDefine('sdate', sdate)
	Variables.varDefine('edate', edate)
	Variables.varDefine('mode', _args.mode)
end

function CustomLeague:getWikiCategories(args)
	local categories = {}

	if _args.game then
		table.insert(categories, _args.game .. ' Competitions')
	else
		table.insert(categories, 'Tournaments without game version')
	end

	if _args.platform then
		table.insert(categories, _args.platform .. ' Tournaments')
	else
		table.insert(categories, 'Tournaments without platform')
	end

	return categories
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
