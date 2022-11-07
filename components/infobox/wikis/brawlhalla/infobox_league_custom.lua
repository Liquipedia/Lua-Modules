---
-- @Liquipedia
-- wiki=brawlhalla
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _TODAY = os.date('%Y-%m-%d')

local _league

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	local args = _league.args
	if id == 'customcontent' then
		if not String.isEmpty(args.player_number) or not String.isEmpty(args.doubles_number) then
			table.insert(widgets, Title{name = 'Player Breakdown'})
			table.insert(widgets, Cell{
				name = 'Number of Players',
				content = {args.player_number}
			})
			table.insert(widgets, Cell{
				name = 'Doubles Players',
				content = {args.doubles_number}
			})
		end
	end
	return widgets
end

function CustomLeague:defineCustomPageVariables(args)
	-- Legacy vars
	local sdate = Variables.varDefault('tournament_startdate', _TODAY)
	local edate = Variables.varDefault('tournament_enddate', _TODAY)
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)

	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier'))
	Variables.varDefine('tournament_link', mw.title.getCurrentTitle().prefixedText)
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData['patch'] = args.patch
	lpdbData['participantsnumber'] = args.team_number or args.player_number
	lpdbData.extradata.region = args.region
	lpdbData.extradata.mode = args.mode

	return lpdbData
end

return CustomLeague
