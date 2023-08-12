---
-- @Liquipedia
-- wiki=arenafps
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local _args
local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local MODES = {
	['arena'] = 'Arena',
	['shaft arena'] = 'Shaft Arena',
	['rocket arena'] = 'Rocket Arena',
	['duel'] = 'Duel',
	['sacrifice'] = 'Sacrifice',
	['team deathmatch'] = 'Team Deathmatch',
	['2vs2 tdm'] = '2vs2 Team Deathmatch',
	['3vs3 circuit'] = '3vs3 Circuit',
	['wipeout'] = 'Wipeout',
	['race'] = 'Race',
	['4vs4 team deathmatch'] = '4vs4 Team Deathmatch',
	['ctf'] = 'Capture the Flag',
	['free for all'] = 'Free For All',
	['macguffin'] = 'MacGuffin',
	['slipgate'] = 'Slipgate',
	['clan arena'] = 'Clan Arena',
}

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

	_args.player_number = _args.participants_number
	_args.game = Game.name{game = _args.game}
	_args.mode = CustomLeague:_modeLookup(_args.mode)

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
		name = 'Game',
		content = {_args.game}
	})
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

function CustomInjector:parse(id, widgets)
	if id == 'customcontent' then
		local maps = _league:getAllArgsForBase(_args, 'map')
		if #maps > 0 then
			local game = _args.game and ('/' .. _args.game) or ''

			maps = Array.map(maps, function(map)
				return tostring(CustomLeague:_createNoWrappingSpan(
					PageLink.makeInternalLink({}, map, map .. game)
				))
			end)

			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(_league:getAllArgsForBase(args, 'map'), ';')

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

	if Game.name{game = args.game} then
		table.insert(categories, Game.name{game = args.game} .. ' Competitions')
	else
		table.insert(categories, 'Tournaments without game version')
	end

	if args.mode then
		table.insert(categories, args.mode .. ' Tournaments')
	else
		table.insert(categories, 'Tournaments Missing Mode')
	end

	return categories
end

function CustomLeague:_modeLookup(mode)
	if not mode then
		return
	end

	return MODES[mode:lower()]
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
