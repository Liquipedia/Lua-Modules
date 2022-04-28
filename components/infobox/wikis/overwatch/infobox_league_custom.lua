---
-- @Liquipedia
-- wiki=overwatch
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
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')
local PageLink = require('Module:Page')
local PrizePoolCurrency = require('Module:Prize pool currency')

local _TODAY = os.date('%Y-%m-%d', os.time())

local _args
local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _GAMES = {
	overwatch = 'Overwatch',
	overwatch2 = 'Overwatch 2'
}

local _BLIZZARD_TIERS = {
	owl = 'Overwatch League',
	owc = 'Overwatch Contenders',
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
		name = 'Teams',
		content = {args.team_number}
	})
	table.insert(widgets, Cell{
		name = 'Game',
		content = {CustomLeague:_createGameCell(args)}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {args.player_number}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	local args = _args
	if id == 'customcontent' then
		if String.isNotEmpty(args.map1) then
			local game = String.isNotEmpty(args.game) and ('/' .. args.game) or ''
			local maps = {}

			for _, map in ipairs(_league:getAllArgsForBase(args, 'map')) do
				table.insert(maps, tostring(CustomLeague:_createNoWrappingSpan(
					PageLink.makeInternalLink({}, map, map .. game)
				)))
			end
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	elseif id == 'prizepool' then
		return {
			Cell{
				name = 'Prize pool',
				content = {CustomLeague:_createPrizepool()}
			},
		}
	elseif id == 'liquipediatier' then
		widgets = {
			Cell{
				name = 'Liquipedia Tier',
				content = {CustomLeague:_createLiquipediaTierDisplay()},
			}
		}
		if CustomLeague:_validPublisherTier(args.blizzardtier) then
			table.insert(widgets,
				Cell{
					name = 'Blizzard Tier',
					content = {'[['.._BLIZZARD_TIERS[args.blizzardtier:lower()]..']]'},
					classes = {'valvepremier-highlighted'}
				}
			)
		end
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(_league:getAllArgsForBase(args, 'map'), ';')

	if CustomLeague:_validPublisherTier(args.blizzardtier) then
		lpdbData.publishertier = args.blizzardtier:lower()
	end
	lpdbData.participantsnumber = args.player_number or args.team_number
	lpdbData.liquipediatiertype = args.liquipediatiertype
	lpdbData.extradata = {
		individual = String.isNotEmpty(args.player_number) and 'true' or '',
	}

	return lpdbData
end

function CustomLeague:_validPublisherTier(publishertier)
	return String.isNotEmpty(publishertier) and _BLIZZARD_TIERS[publishertier:lower()]
end

function CustomLeague:_createPrizepool()
	if String.isEmpty(_args.prizepool) and String.isEmpty(_args.prizepoolusd) then
		return nil
	end
	local date
	if String.isNotEmpty(_args.currency_rate) then
		date = _args.currency_date
	end

	return PrizePoolCurrency._get({
		prizepool = _args.prizepool,
		prizepoolusd = _args.prizepoolusd,
		currency = _args.localcurrency,
		rate = _args.currency_rate,
		date = date or Variables.varDefault('tournament_enddate', _TODAY),
	})
end

function CustomLeague:_createLiquipediaTierDisplay()
	local tier = _args.liquipediatier
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

	--Legacy date vars
	local sdate = Variables.varDefault('tournament_startdate', '')
	local edate = Variables.varDefault('tournament_enddate', '')
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)

	Variables.varDefine('tournament_blizzard_premier', _args.publishertier or '')
end

function CustomLeague:getWikiCategories(args)
	local categories = {}
	if String.isNotEmpty(args.player_number) then
		table.insert(categories, 'Individual Tournaments')
	end

	if not CustomLeague:_gameLookup(args.game) then
		table.insert(categories, 'Tournaments without game version')
	else
		table.insert(categories, CustomLeague:_gameLookup(args.game) .. ' Competitions')
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

	if String.isNotEmpty(game) then
		return '[['.. game ..']]'
	else
		return nil
	end
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
