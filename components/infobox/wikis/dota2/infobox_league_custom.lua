---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Tier = require('Module:Tier')
local Class = require('Module:Class')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local _args
local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _GAMES = {
	dota2 = {name = 'Dota 2', category = 'Dota 2 Competitions'},
	dota = {name = 'DotA', category = 'DotA Competitions'},
	hon = {name = 'Heroes of Newerth', category = 'Heroes of Newerth Competitions'},
	['auto chess'] = {name = 'Auto Chess', category = 'Auto Chess Competitions'},
}

local _UBISOFT_TIERS = {
	si = 'Six Invitational',
	pl = 'Pro League',
	cl = 'Challenger League',
	national = 'National',
	major = 'Six Major',
	minor = 'Minor',
}

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
	table.insert(widgets, Cell{
		name = 'Game',
		content = {CustomLeague:_createGameCell(args)}
	})
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {args.team_number}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {args.player_number}
	})
	table.insert(widgets, Cell{
		name = 'Dota TV Ticket',
		content = {args.dotatv}
	})
	table.insert(widgets, Cell{
		name = 'Pro Circuit Points',
		content = {args.points} -- TODO: Format nicely
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'liquipediatier' then
		widgets = {
			Cell{
				name = 'Liquipedia Tier',
				content = {CustomLeague:_createLiquipediaTierDisplay()},  -- TODO: Add Valve icon
			}
		}
		if CustomLeague:_validPublisherTier(_args.pctier) and _args.liquipediatiertype ~= 'Qualifier' then
			table.insert(widgets,
				Cell{
					name = 'Pro Circuit Tier',
					content = {'[[Dota Pro Circuit|{{{' .. _args.pctier .. '}}}]]'}, -- TODO: Add Valve icon
					classes = {'valvepremier-highlighted'}
				}
			)
		end
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.publishertier = args.pctier
	lpdbData.participantsnumber = args.team_number or args.player_number
	lpdbData.extradata = {
		valvepremier = String.isNotEmpty(args.valvepremier) and '1' or '0',
		individual = String.isNotEmpty(args.player_number) and 'true' or '',
		dpcpoints = String.isNotEmpty(args.points) or '',
		series2 = String.isNotEmpty(args.series2) or '',
	}

	return lpdbData
end

function CustomLeague:_createLiquipediaTierDisplay()
	local tier = _args.liquipediatier or ''
	local tierType = _args.liquipediatiertype or ''
	if String.isEmpty(tier) then
		return nil
	end

	local function buildTierString(tierString)
		local tierText = Tier.text[tierString]
		if not tierText then
			table.insert(_league.warnings, tierString .. ' is not a known Liquipedia Tier/Tiertype')
			return ''
		else
			return '[[' .. tierText .. ' Tournaments|' .. tierText .. ']]'
		end
	end

	local tierDisplay = buildTierString(tier)

	if String.isNotEmpty(tierType) then
		tierDisplay = buildTierString(tierType) .. '&nbsp;(' .. tierDisplay .. ')'
	end

	return tierDisplay
end

function CustomLeague:defineCustomPageVariables()
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', _args.tickername or '')
	Variables.varDefine('tournament_tier', _args.liquipediatier or '')
	Variables.varDefine('tournament_tier_type', _args.liquipediatiertype)
	Variables.varDefine('tournament_prizepool', _args.prizepool or '')
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

function CustomLeague:getWikiCategories(args)
	local categories = {}
	if String.isNotEmpty(args.player_number) then
		table.insert(categories, 'Individual Tournaments')
	end

	local tier = args.liquipediatier
	local tierType = args.liquipediatiertype

	if String.isNotEmpty(tier) and String.isNotEmpty(Tier.text[tier]) then
		table.insert(categories, Tier.text[tier]  .. ' Tournaments')
	end

	if String.isNotEmpty(tierType) and String.isNotEmpty(Tier.text[tierType]) then
		table.insert(categories, Tier.text[tierType] .. ' Tournaments')
	end

	return categories
end

function CustomLeague:_gameLookup(game)
	if String.isEmpty(game) then
		return nil
	end

	return _GAMES[game:lower()]
end

function CustomLeague:_createGameCell(args)
	if String.isEmpty(args.game) then
		return nil
	end

	local game = CustomLeague:_gameLookup(args.game)

	if game then
		return '[['.. game.name ..']]' .. '[[Category:'.. game.category ..']]'
	else
		return nil
	end
end

return CustomLeague
