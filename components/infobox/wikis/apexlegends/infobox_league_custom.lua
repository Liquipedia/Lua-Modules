---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:String')
local Variables = require('Module:Variables')
local Tier = require('Module:Tier')
local PageLink = require('Module:Page')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local PrizePoolCurrency = require('Module:Prize pool currency')

local _GAME_MODE = mw.loadData('Module:GameMode')
local _GAME_PERSPECTIVE = mw.loadData('Module:GamePerspective')--needed??????
local _EA_ICON = '[[File:EA icon.png|x15px|middle|link=Electronic Arts|'
	.. 'Tournament sponsored by Electronirc Arts & Respawn.]]'
local _TODAY = os.date('%Y-%m-%d', os.time())

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		table.insert(widgets, Cell{name = 'Game mode', content = {
					CustomLeague._getGameMode()
				}})
		table.insert(widgets, Cell{name = 'Platform', content = {
					CustomLeague._getPlatform()
				}})
		return widgets
	elseif id == 'prizepool' then
		return {
			Cell{
				name = 'Prize pool',
				content = {CustomLeague:_createPrizepool()},
			},
		}
	elseif id == 'liquipediatier' then
		local algsTier = _args.algstier
		if not String.isEmpty(algsTier) then
			widgets = {
				Cell{
					name = 'ALGS circuit tier',
					content = {'[[Apex Legends Global Series|' .. algsTier .. ']]'},
					classes = {'valvepremier-highlighted'}
				}
			}
		end
		table.insert(widgets, Cell{
			name = 'Liquipedia tier',
			content = {CustomLeague:_createLiquipediaTierDisplay()},
			classes = {String.isEmpty(_args['ea-sponsored']) and '' or 'valvepremier-highlighted'}
		})
		table.insert(widgets, Cell{
			name = 'EA tier',
			content = {Tier['ea'][string.lower(_args.eatier or '')]},
			classes = {'valvepremier-highlighted'}
		})
		return widgets
	elseif id == 'customcontent' then
		--maps
		if not String.isEmpty(_args.map1) then
			table.insert(widgets, Title{name = _args.maptitle or 'Maps'})
			table.insert(widgets, Center{content = CustomLeague:_makeBasedListFromArgs('map')})
		elseif not String.isEmpty(_args['2map1']) then
			table.insert(widgets, Title{name = _args['2maptitle'] or '2v2 Maps'})
			table.insert(widgets, Center{content = CustomLeague:_makeBasedListFromArgs('2map')})
		end
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{name = 'Teams', content = {_args.team_number}})
	table.insert(widgets, Cell{name = 'Number of players', content = {_args.player_number}})

	return widgets
end

function CustomLeague:_createPrizepool()
	local date
	if not String.isEmpty(_args.currency_rate) then
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
	local tier = _args.liquipediatier or ''
	local tierType = _args.liquipediatiertype or _args.tiertype or ''
	if String.isEmpty(tier) then
		return nil
	end

	--clean tier from unallowed values
	--convert from text (old entries) to numbers
	tier = Tier.number[string.lower(tier)] or tier
	local tierText = Tier.text[tier]
	local hasInvalidTier = tierText == nil
	local hasTypeSetAsTier
	--the following convertsa tiers that should be types to tiertypes
	if hasInvalidTier then
		local tempTypeForCheck = Tier.numberToType[tier] or tier
		tempTypeForCheck = Tier.types[string.lower(tempTypeForCheck)]
		if tempTypeForCheck then
			hasTypeSetAsTier = true
			hasInvalidTier = nil
			if String.isEmpty(tierType) then
				tierType = tempTypeForCheck
			end
		end
	end
	tierText = tierText or tier

	local hasInvalidTierType = false

	local tierDisplay = '[[' .. tierText .. ' Tournaments|' .. tierText .. ']]'
		.. '[[Category:' .. tierText .. ' Tournaments]]'


	if not String.isEmpty(tierType) then
		tierType = Tier['types'][string.lower(tierType or '')] or tierType
		hasInvalidTierType = Tier['types'][string.lower(tierType or '')] == nil
		local tierTypeDIsplay
		tierTypeDIsplay = '[[' .. tierType .. ' Tournaments|' .. tierType .. ']]'
			.. '[[Category:' .. tierType .. ' Tournaments]]'
		if not hasTypeSetAsTier or tierType ~= tierTypeDIsplay  then
			tierDisplay = tierTypeDIsplay .. '&nbsp;(' .. tierDisplay .. ')'
		end
	end

	tierDisplay = tierDisplay ..
		(_args['ea-sponsored'] == 'true' and _EA_ICON or '') ..
		(hasInvalidTier and '[[Category:Pages with invalid Tier]]' or '') ..
		(hasInvalidTierType and '[[Category:Pages with invalid Tiertype]]' or '') ..
		(hasTypeSetAsTier and '[[Category:Pages with Tiertype set as Tier]]' or '')

	Variables.varDefine('tournament_tier', tier)
	Variables.varDefine('tournament_tiertype', tierType)
	return tierDisplay
end

function CustomLeague:_makeBasedListFromArgs(base)
	local firstArg = _args[base .. '1']
	local foundArgs = {PageLink.makeInternalLink({}, firstArg)}
	local index = 2

	while not String.isEmpty(_args[base .. index]) do
		local currentArg = _args[base .. index]
		table.insert(foundArgs, '&nbsp;• ' ..
			tostring(CustomLeague:_createNoWrappingSpan(
				PageLink.makeInternalLink({}, currentArg)
			))
		)
		index = index + 1
	end

	return foundArgs
end

function CustomLeague:defineCustomPageVariables()
	--overwrite vars set by the commons module
	local name = self.name
	Variables.varDefine('tournament_tickername', _args.tickername or name)

	--Legacy vars
	local name = self.name
	Variables.varDefine('tournament_ticker_name', _args.tickername or name)
	Variables.varDefine('tournament_tier', _args.liquipediatier or '')

	--Legacy date vars
	local sdate = Variables.varDefault('tournament_startdate', '')
	local edate = Variables.varDefault('tournament_enddate', '')
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)
	Variables.varDefine('date', edate)
	Variables.varDefine('sdate', sdate)
	Variables.varDefine('edate', edate)

	--Apexs specific vars
	Variables.varDefine('tournament_gamemode', string.lower(_args.mode or ''))
	Variables.varDefine('tournament_series2', _args.series2 or '')
	Variables.varDefine('tournament_publisher', _args['ea-sponsored'] or '')
	Variables.varDefine('tournament_pro_circuit_tier', _args.pctier or '')

	local eaMajor = _args.eamajor
	if String.isEmpty(eaMajor) then
		local eaTier = string.lower(_args.eatier or '')
		if eaTier == 'major' then
			eaMajor = 'true'
		else
			local algsTier = string.lower(_args.algstier or '')
			if algsTier == 'major' then
				eaMajor = 'true'
			else
				eaMajor = ''
			end
		end
	end
	Variables.varDefine('tournament_ea_amjor', eaMajor)
end

function CustomLeague:addToLpdb(lpdbData)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
	lpdbData.participantsnumber = _args.team_number
	lpdbData.publishertier = _args.pctier
	lpdbData.extradata = {
		['is ea major'] = Variables.varDefault('tournament_ea_amjor', '')
	}

	return lpdbData
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

function CustomLeague._getGameMode()
	local gameMode = _args.mode
	if String.isEmpty(gameMode) then
		return nil
	end
	gameMode = string.lower(gameMode)
	gameMode = _GAME_MODE[gameMode] or _GAME_MODE['default']

	local perspective = string.lower(_args.perspective or '')
	perspective = _GAME_PERSPECTIVE[perspective]
	if perspective then
		gameMode = gameMode .. '&nbsp;' .. perspective
	end

	return gameMode
end

function CustomLeague._getPlatform()
	local platform = string.lower(_args.platform or 'pc')
	if platform == 'pc' then
		return '[[PC]][[Category:PC Competitions]]'
	elseif platform == 'mobile' then
		return '[[Mobile]][[Category:Mobile Competitions]]'
	end
end

function CustomLeague.getWikiCategories(args)
	local categories = {}
	if not String.isEmpty(args.algstier) then
		table.insert(categories, 'Apex Legends Global Series Tournaments')
	end
	if not String.isEmpty(args.format) then
		table.insert(categories, args.format .. ' Format Tournaments')
	end
	if not String.isEmpty(args.player_number) or not String.isEmpty(args.participants_number) then
		table.insert(categories, 'Individual Tournaments')
	end
	if not String.isEmpty(args.eatier) or args['ea-sponsored'] == 'true' then
		table.insert(categories, 'Electronic Arts Tournaments')
	end
	return categories
end

return CustomLeague
