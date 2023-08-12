---
-- @Liquipedia
-- wiki=simracing
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _args
local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local SPECIAL_SPONSORS = {
	polyphony ='[[File:Polyphony Digital.png|x18px|Premier Tournament held by Polyphony Digital]]',
	sms ='[[File:Slightly Mad Studios.png|x18px|Premier Tournament held by Slightly Mad Studios]]',
	sector3 ='[[File:Sector3.png|x18px|Premier Tournament held by Sector3]]',
	turn10 ='[[File:Turn10.png|x18px|Premier Tournament held by Turn10]]',
	fia ='[[File:FIA logo.png|x18px|Premier Tournament held by FIA]]',
	iracing ='[[File:IRacing Logo.png|x18px|Official World Championships sanctioned by iRacing]]',
	f1 ='[[File:F1 New Logo.png|x10px|Official Championship of the FIA Formula One World Championship]]',
}

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

	_args.game = Game.name{game = _args.game}

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.getWikiCategories = CustomLeague.getWikiCategories
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.appendLiquipediatierDisplay = CustomLeague.appendLiquipediatierDisplay

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
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

function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or args.name)
	Variables.varDefine('tournament_tier', args.liquipediatier)
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

	if args.game then
		table.insert(categories, args.game .. ' Competitions')
	else
		table.insert(categories, 'Tournaments without game version')
	end

	return categories
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Table.any(SPECIAL_SPONSORS, function(key)
		return args[key..'-sponsored']
	end)
end

function CustomLeague:appendLiquipediatierDisplay(args)
	local content = ''

	for param, icon in pairs(SPECIAL_SPONSORS) do
		if args[param..'-sponsored'] then
			content = content .. icon
		end
	end

	return content
end

return CustomLeague
