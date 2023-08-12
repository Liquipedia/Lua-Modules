---
-- @Liquipedia
-- wiki=hearthstone
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local InfoboxPrizePool = Lua.import('Module:Infobox/Extensions/PrizePool', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _args
local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local MODES = {
	standard = 'Standard',
	wild = 'Wild',
	battlegrounds = 'Battlegrounds',
}

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

	_args.player_number = _args.participants_number
	_args.mode = CustomLeague:_modeLookup(_args.mode)

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories
	league.appendLiquipediatierDisplay = CustomLeague.appendLiquipediatierDisplay

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'prizepool' then
		if _args.bin or _args.binusd then
			table.insert(widgets, Cell{name = 'Buy-in', content = {
				InfoboxPrizePool.display{
					prizepool = _args.bin,
					prizepoolusd = _args.binusd,
					currency = _args.localcurrency,
					setVariables = false,
				}
			}})
		end
	end

	return widgets
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Mode',
		content = {_args.mode}
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

	return lpdbData
end

function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or args.name)
	Variables.varDefine('tournament_tier', args.liquipediatier)
	Variables.varDefine('tournament_prizepool', args.prizepoolusd)
	Variables.varDefine('tournament_mode', args.mode)

	--Legacy date vars
	local sdate = Variables.varDefault('tournament_startdate', '')
	local edate = Variables.varDefault('tournament_enddate', '')
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)
	Variables.varDefine('date', edate)
	Variables.varDefine('sdate', sdate)
	Variables.varDefine('edate', edate)
	Variables.varDefine('mode', args.mode)
end

function CustomLeague:getWikiCategories(args)
	local categories = {}

	if args.mode then
		table.insert(categories, args.mode .. ' Tournaments')
	end

	return categories
end

function CustomLeague:appendLiquipediatierDisplay(args)
	if Logic.readBool(args.blizzardpremier) then
		return '[[File:Blizzard_logo.png|x12px|link=Blizzard Entertainment|Premier Tournament held by Blizzard]]'
	end

	return ''
end

function CustomLeague:_modeLookup(mode)
	if not mode then
		return
	end

	return MODES[mode:lower()]
end

return CustomLeague
