---
-- @Liquipedia
-- wiki=callofduty
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _league

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args
	_league = league

	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	return {
		Cell{name = 'Number of teams', content = {_args.team_number}},
		Cell{name = 'Number of players', content = {_args.player_number}},
	}
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {Cell{name = 'Game', content = {Game.name{game = _args.game}}}}
	elseif id == 'customcontent' then
		if String.isNotEmpty(_args.map1) then
			local maps = Array.map(_league:getAllArgsForBase(_args, 'map'), function(map)
				return tostring(CustomLeague:_createNoWrappingSpan(PageLink.makeInternalLink(map)))
			end)
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(_league:getAllArgsForBase(args, 'map'), ';')

	lpdbData.game = Game.name{game = args.game}
	lpdbData.extradata.individual = not String.isEmpty(args.player_number)

	return lpdbData
end

function CustomLeague:defineCustomPageVariables(args)
	if _args.player_number then
		Variables.varDefine('tournament_mode', 'solo')
	end
	Variables.varDefine('tournament_game', Game.name{game = args.game})
	Variables.varDefine('tournament_publishertier', args['atvi-sponsored'])

	--Legacy Vars:
	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args['atvi-sponsored'])
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
