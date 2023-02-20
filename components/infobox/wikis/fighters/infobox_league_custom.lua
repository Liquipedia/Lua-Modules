---
-- @Liquipedia
-- wiki=fighters
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Chronology = Widgets.Chronology

local _args
local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

	_args.game = Game.name{game = _args.game}
	_args.prizepoolassumed = false
	if String.isEmpty(_args.prizepool) and String.isEmpty(_args.prizepoolusd) then
		_args.prizepoolassumed = true
		if _args.localcurrency and _args.localcurrency:lower() ~= 'usd' then
			_args.prizepool = tonumber(_args.singlesfee) * tonumber(_args.player_number) + tonumber(_args.singlesbonus)
		else
			_args.prizepoolusd = tonumber(_args.singlesfee) * tonumber(_args.player_number) + tonumber(_args.singlesbonus)
		end
	end

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
	if _args.circuit or _args.points or _args.circuit_next or _args.circuit_previous then
		return {
			Title{name = 'Circuit Information'},
			Cell{name = 'Circuit', content = {}},
			Cell{name = 'Circuit Tier', content = {_args.circuittier and (_args.circuittier .. ' Tier') or nil}},
			Cell{name = 'Tournament Region', content = {_args.region}},
			Cell{name = 'Points', content = {}},
			Chronology{links = {}},
		}
	end

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'customcontent' then

	elseif id == 'gamesettings' then
		return {
			Cell{name = 'Game', content = _args.game},
			Cell{name = 'Version', content = _args.version},
		}
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.participantsnumber = (_args.player_number or ''):gsub(',', '')

	lpdbData.extradata.assumedprizepool = tostring(_args.prizepoolassumed)
	lpdbData.extradata.circuit = _args.circuit
	lpdbData.extradata.circuit_tier = _args.circuit_tier

	return lpdbData
end

function CustomLeague:defineCustomPageVariables()
	--Legacy vars
	Variables.varDefine('tournament_tier', _args.liquipediatier or '')
	Variables.varDefine('prizepoolusd', Variables.varDefault('tournament_prizepoolusd'))
	Variables.varDefine('tournament_entrants', (_args.player_number or ''):gsub(',', ''))
	Variables.varDefine('tournament_region', _args.region)
	Variables.varDefine('assumedpayout', tostring(_args.prizepoolassumed))
	Variables.varDefine('localcurrency', Variables.varDefault('tournament_currency'))
	Variables.varDefine('circuittier', _args.circuittier)
	Variables.varDefine('tournament_circuit', _args.circuit)

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

function CustomLeague:getWikiCategories(args)
	local categories = {}

	if _args.game then
		table.insert(categories, _args.game .. ' Competitions')
	end

	return categories
end

return CustomLeague
