---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local Games = mw.loadData('Module:Games')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)
local _league
local _args
local _categories = {}

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = league.args

	_args.player_number = _args.participants_number

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.getWikiCategories = CustomLeague.getWikiCategories
	league.addToLpdb = CustomLeague.addToLpdb

	return league:createInfobox()
end

function CustomLeague.createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'sponsors' then
		local partners = _league:getAllArgsForBase(_args, 'partner')
		table.insert(widgets, Cell{
			name = 'Partner' .. (#partners > 1 and 's' or ''),
			content = Array.map(partners, Page.makeInternalLink)
		})
	elseif id == 'gamesettings' then
		local games = _league:getAllArgsForBase(_args, 'game')
		table.insert(widgets, Cell{
			name = 'Game' .. (#games > 1 and 's' or ''),
			content = Array.map(games,
					function(game)
						local info = Games[game:lower()]
						if not info then
							return 'Unknown game, check Module:Games.'
						end
						table.insert(_categories, info.link .. ' Competitions')
						return Page.makeInternalLink(info.name, info.link)
					end)
		})
	elseif id == 'customcontent' then
		table.insert(widgets, Title{name = String.isNotEmpty(_args.team_number) and 'Teams' or 'Players'})
		table.insert(widgets, Cell{
			name = 'Number of Teams',
			content = {_args.team_number}
		})
		table.insert(widgets, Cell{
			name = 'Number of Players',
			content = {_args.player_number}
		})

		local maps = _league:getAllArgsForBase(_args, 'map')
		if #maps > 0 then
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	end

	return widgets
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Array.any(_league:getAllArgsForBase(_args, 'organizer'),
		function(organizer)
			return organizer:find('Nadeo', 1, true) or organizer:find('Ubisoft', 1, true)
		end)
end

function CustomLeague:defineCustomPageVariables(args)
	Variables.varDefine('tournament_mode',
		Logic.emptyOr(
			args.mode,
			(String.isNotEmpty(args.team_number) and 'team' or nil),
			'solo'
		)
	)

	-- legacy variables, to be removed
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier', ''))
	Variables.varDefine('tournament_tier_type', Variables.varDefault('tournament_liquipediatiertype', ''))

	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate', ''))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate', ''))
	Variables.varDefine('tournament_date', Variables.varDefault('tournament_enddate', ''))
	Variables.varDefine('date', Variables.varDefault('tournament_enddate', ''))
	Variables.varDefine('sdate', Variables.varDefault('tournament_startdate', ''))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate', ''))
end

function CustomLeague:getWikiCategories(args)
	if CustomLeague:liquipediaTierHighlighted(args) then
		table.insert(_categories, 'Ubisoft Tournaments')
	end

	return _categories
end

function CustomLeague:addToLpdb(lpdbData, args)
	if String.isEmpty(args.tickername) then
		lpdbData.tickername = args.name
	end

	lpdbData.maps = table.concat(_league:getAllArgsForBase(_args, 'map'), ';')

	lpdbData.game = (Games[args.game] or {}).link

	-- Legacy, can be superseeded by lpdbData.mode
	lpdbData.extradata.individual = Variables.varDefault('tournament_mode', 'solo') == 'solo'

	return lpdbData
end

return CustomLeague
