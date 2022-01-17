---
-- @Liquipedia
-- wiki=mobilelegends
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
local Json = require('Module:Json')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')
local PrizePoolCurrency = require('Module:Prize pool currency')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args

local _ABBR_USD = '<abbr title="United States Dollar">USD</abbr>'
local _TODAY = os.date('%Y-%m-%d', os.time())

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
			Cell{name = 'Patch', content = {
					CustomLeague._getPatchVersion()
				}},
			}
	elseif id == 'prizepool' then
		return {
			Cell{
				name = 'Prize pool',
				content = {CustomLeague:_createPrizepool()}
			},
		}
	elseif id == 'liquipediatier' then
		return {
			Cell{
				name = 'Liquipedia tier',
				content = {CustomLeague:_createTierDisplay()},
				classes = {_args['moonton-sponsored'] == 'true' and 'valvepremier-highlighted' or ''},
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
	end
	return widgets
end

function League:addToLpdb(lpdbData, args)
	lpdbData.participantsnumber = args.player_number or args.team_number

	return lpdbData
end

function League:defineCustomPageVariables()
	if _args.player_number then
		Variables.varDefine('tournament_mode', 'solo')
	end
	Variables.varDefine('tournament_patch', _args.patch)
	Variables.varDefine('tournament_endpatch', _args.epatch)

	Variables.varDefine('tournament_publishertier', _args['moonton-sponsored'])
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

function CustomLeague._getPatchVersion()
	if String.isEmpty(_args.patch) then return nil end
	
	local content = PageLink.makeInternalLink(_args.patch, 'Patch ' .. _args.patch)
	
	if not String.isEmpty(_args.epatch) then
		content = content .. '&nbsp;&ndash;&nbsp;'
		content = content .. PageLink.makeInternalLink(_args.epatch, 'Patch ' .. _args.epatch)
	end

	return content
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
