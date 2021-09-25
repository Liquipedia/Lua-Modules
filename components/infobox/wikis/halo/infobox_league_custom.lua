---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:String')
local Template = require('Module:Template')
local Variables = require('Module:Variables')
local Tier = require('Module:Tier')
local PageLink = require('Module:Page')
local MapModes = require('Module:MapModes')
local Json = require('Module:Json')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args

local _ABBR_USD = '<abbr title="United States Dollar">USD</abbr>'
local _TODAY = os.date('%Y-%m-%d', os.time())
local _GAME = mw.loadData('Module:GameVersion')

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {
					CustomLeague._getGameVersion()
				}},
			}
	elseif id == 'prizepool' then
		return {
			Cell{
				name = 'Prize pool',
				content = {CustomLeague:_createPrizepool()},
			},
		}
	elseif id == 'liquipediatier' then
		return {
			Cell{
				name = 'Liquipedia tier',
				content = {CustomLeague:_createTierDisplay()},
			},
		}
	elseif id == 'customcontent' then
		if _args.player_number then
			table.insert(widgets, Title{name = 'Players'})
			table.insert(widgets, Cell{name = 'Number of players', content = {_args.player_number}})
		end

		--teams section
		if _args.team_number or (not String.isEmpty(_args.team1)) then
			Variables.varDefine('is_team_tournament', 1)
			table.insert(widgets, Title{name = 'Teams'})
		end
		table.insert(widgets, Cell{name = 'Number of teams', content = {_args.team_number}})
		if not String.isEmpty(_args.team1) then
			local teams = CustomLeague:_makeBasedListFromArgs('team')
			table.insert(widgets, Center{content = teams})
		end

		--maps
		if not String.isEmpty(_args.map1) then
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = CustomLeague:_makeMapList()})
		end
	end
	return widgets
end

--store maps
function League:addToLpdb(lpdbData, args)
	local maps = {}
	local index = 1
	while not String.isEmpty(args['map' .. index]) do
		local modes = {}
		if not String.isEmpty(args['map' .. index .. 'modes']) then
			local tempModesList = mw.text.split(args['map' .. index .. 'modes'], ',')
			for _, item in ipairs(tempModesList) do
				local currentMode = MapModes.clean({mode = item or ''})
				if not String.isEmpty(currentMode) then
					table.insert(modes, currentMode)
				end
			end
		end
		table.insert(maps, {
			map = args['map' .. index],
			modes = modes
		})
		index = index + 1
	end

	lpdbData.maps = CustomLeague:_concatArgs('map')

	lpdbData.participantsnumber = args.player_number or args.team_number
	lpdbData.extradata = {
		maps = Json.stringify(maps),
		individual = not String.isEmpty(args.player_number),
	}

	return lpdbData
end

function League:defineCustomPageVariables()
	if _args.player_number then
		Variables.varDefine('tournament_mode', 'solo')
	end
end

function CustomLeague:_concatArgs(base)
	local firstArg = _args[base] or _args[base .. '1']
	if String.isEmpty(firstArg) then
		return nil
	end
	local foundArgs = {mw.ext.TeamLiquidIntegration.resolve_redirect(firstArg)}
	local index = 2
	while not String.isEmpty(_args[base .. index]) do
		table.insert(foundArgs,
			mw.ext.TeamLiquidIntegration.resolve_redirect(_args[base .. index])
		)
		index = index + 1
	end

	return table.concat(foundArgs, ';')
end

function CustomLeague:_createPrizepool()
	if String.isEmpty(_args.prizepool) and
		String.isEmpty(_args.prizepoolusd) then
		return nil
	end

	local localCurrency = _args.localcurrency
	local prizePoolUSD = _args.prizepoolusd
	local prizePool = _args.prizepool

	prizePool = CustomLeague:_cleanPrizeValue(prizePool, localCurrency)
	prizePoolUSD = CustomLeague:_cleanPrizeValue(prizePoolUSD)

	if String.isEmpty(prizePool) and String.isEmpty(prizePoolUSD) then
		return nil
	end

	if localCurrency then
		localCurrency = localCurrency:upper()
		local exchangeDate = Variables.varDefault('tournament_enddate', _TODAY)
		local exchangeRate = CustomLeague:_currencyConversion(
			1,
			localCurrency,
			exchangeDate
		)
		--set currency vars for usage in prize pools
		Variables.varDefine('tournament_currency_rate', exchangeRate or '')
		Variables.varDefine('tournament_currency', localCurrency)
		if prizePool and not prizePoolUSD then
			if not exchangeRate then
				error('Invalid local currency "' .. localCurrency .. '"')
			end
			prizePoolUSD = exchangeRate * prizePool
		end
	end

	Variables.varDefine('tournament_prizepoolusd', prizePoolUSD or prizePool)
	Variables.varDefine('tournament_prizepoollocal', prizePool)

	if prizePoolUSD and prizePool then
		return Template.safeExpand(
			mw.getCurrentFrame(),
			'Local currency',
			{(localCurrency or 'usd'):lower(), prizepool = CustomLeague:_displayPrizeValue(prizePool, 2)}
		) .. '<br>(≃ $' .. CustomLeague:_displayPrizeValue(prizePoolUSD) .. ' ' .. _ABBR_USD .. ')'
	elseif prizePoolUSD then
		return '$' .. CustomLeague:_displayPrizeValue(prizePoolUSD, 2) .. ' ' .. _ABBR_USD
	elseif prizePool then
		return Template.safeExpand(
			mw.getCurrentFrame(),
			'Local currency',
			{(localCurrency or 'usd'):lower(), prizepool = CustomLeague:_displayPrizeValue(prizePool, 2)}
		)
	end
end

function CustomLeague:_createTierDisplay()
	local tier = _args.liquipediatier or ''
	local tierType = _args.liquipediatiertype or _args.tiertype or ''
	if String.isEmpty(tier) then
		return nil
	end

	local tierText = Tier['text'][tier]
	local hasInvalidTier = tierText == nil
	tierText = tierText or tier

	local hasInvalidTierType = false

	local output = '[[' .. tierText .. ' Tournaments|' .. tierText .. ']]'
		.. '[[Category:' .. tierText .. ' Tournaments]]'

	if not String.isEmpty(tierType) then
		tierType = Tier['types'][string.lower(tierType or '')] or tierType
		hasInvalidTierType = Tier['types'][string.lower(tierType or '')] == nil
		tierType = '[[' .. tierType .. ' Tournaments|' .. tierType .. ']]'
			.. '[[Category:' .. tierType .. ' Tournaments]]'
		output = tierType .. '&nbsp;(' .. output .. ')'
	end

	output = output ..
		(hasInvalidTier and '[[Category:Pages with invalid Tier]]' or '') ..
		(hasInvalidTierType and '[[Category:Pages with invalid Tiertype]]' or '')

	Variables.varDefine('tournament_tier', tier)
	Variables.varDefine('tournament_tiertype', tierType)
	return output
end

function CustomLeague._getGameVersion()
	local game = string.lower(_args.game or '')
	return _GAME[game]
end

function CustomLeague:_currencyConversion(localPrize, currency, exchangeDate)
	if exchangeDate and currency and currency ~= 'USD' then
		localPrize = tonumber(localPrize)
		if localPrize then
			local usdPrize = mw.ext.CurrencyExchange.currencyexchange(
				localPrize,
				currency,
				'USD',
				exchangeDate
			)
			if type(usdPrize) == 'number' then
				return usdPrize
			end
		end
	end

	return nil
end

function CustomLeague:_displayPrizeValue(value, numDigits)
	if String.isEmpty(value) or value == 0 or value == '0' then
		return '-'
	end

	numDigits = tonumber(numDigits or 0) or 0
	local factor = 10^numDigits
	value = math.floor(value * factor + 0.5) / factor

	--split value into
	--left = first digit
	--num = all remaining digits before a possible '.'
	--right = the '.' and all digits after it (unless they are all 0 or do not exist)
	local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
	if right:len() > 0 then
		local decimal = string.sub('0' .. right, 3)
		right = '.' .. decimal .. string.rep('0', 2 - string.len(decimal))
	end
	return left .. (num:reverse():gsub('(%d%d%d)','%1,'):reverse()) .. right
end

function CustomLeague:_cleanPrizeValue(value, currency)
	if String.isEmpty(value) then
		return nil
	end

	--remove currency abbreviations
	value = value:gsub('<abbr.*abbr>', '')
	value = value:gsub(',', '')

	--remove currency symbol
	if currency then
		Template.safeExpand(mw.getCurrentFrame(), 'Local currency', {currency:lower()})
		local symbol = Variables.varDefaultMulti('localcurrencysymbol', 'localcurrencysymbolafter') or ''
		value = value:gsub(symbol, '')
	else --remove $ symbol
		value = value:gsub('%$', '')
	end

	return value
end

function CustomLeague:_makeMapList()
	local date = Variables.varDefaultMulti('tournament_enddate', 'tournament_startdate', os.date('%Y-%m-%d'))
	local map1 = PageLink.makeInternalLink({}, _args['map1'])
	local map1Modes = CustomLeague:_getMapModes(_args['map1modes'], date)

	local foundMaps = {
		tostring(CustomLeague:_createNoWrappingSpan(map1Modes .. map1))
	}
	local index = 2
	while not String.isEmpty(_args['map' .. index]) do
		local currentMap = PageLink.makeInternalLink({}, _args['map' .. index])
		local currentModes = CustomLeague:_getMapModes(_args['map' .. index .. 'modes'], date)

		table.insert(
			foundMaps,
			'&nbsp;• ' .. tostring(CustomLeague:_createNoWrappingSpan(currentModes .. currentMap))
		)
		index = index + 1
	end
	return foundMaps
end

function CustomLeague:_getMapModes(modesString, date)
	if String.isEmpty(modesString) then
		return ''
	end
	local display = ''
	local tempModesList = mw.text.split(modesString, ',')
	for _, item in ipairs(tempModesList) do
		local mode = MapModes.clean(item)
		if not String.isEmpty(mode) then
			if display ~= '' then
				display = display .. '&nbsp;'
			end
			display = display .. MapModes.get({mode = mode, date = date, size = 15})
		end
	end
	return display .. '&nbsp;'
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

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
