---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Tier = require('Module:Tier')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Template = require('Module:Template')

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

function CustomLeague.run(frame)
	local league = League(frame)

	-- Override links to allow one param to set multiple links
	league.args.datdota = league.args.leagueid
	league.args.dotabuff = league.args.leagueid

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories

	_league = league
	_args = _league.args

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
		name = 'Version',
		content = {CustomLeague:_createPatchCell(args)}
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
	if args.points then
		table.insert(widgets, Cell{
			name = 'Pro Circuit Points',
			content = {mw.language.new('en'):formatNum(tonumber(args.points))}
		})
	end
	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'liquipediatier' then
		widgets = {}
		if _args.pctier and _args.liquipediatiertype ~= 'Qualifier' then
			local valveIcon = ''
			if Logic.readBool(_args.valvepremier) then
				valveIcon = Template.safeExpand(mw.getCurrentFrame(), 'Valve/infobox')
			end
			table.insert(widgets,
				Cell{
					name = 'Pro Circuit Tier',
					content = {'[[Dota Pro Circuit|' .. _args.pctier .. ']] ' .. valveIcon},
					classes = {'valvepremier-highlighted'}
				}
			)
		end
		table.insert(widgets,
			Cell{
				name = 'Liquipedia Tier',
				content = {CustomLeague:_createLiquipediaTierDisplay()},
				classes = {Logic.readBool(_args.valvepremier) and 'valvepremier-highlighted' or nil}
			}
		)
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
	if String.isEmpty(_args.pctier) and Logic.readBool(_args.valvepremier) then
		tierDisplay = tierDisplay .. Template.safeExpand(mw.getCurrentFrame(), 'Valve/infobox')
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

function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end

	local displayText = '[['.. args.patch .. ']]'
	if args.epatch then
		displayText = displayText .. ' &ndash; [['.. args.epatch .. ']]'
	end
	return displayText
end

return CustomLeague
