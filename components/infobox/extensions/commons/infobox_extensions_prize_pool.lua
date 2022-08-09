---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Extensions/PrizePool
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Currency = require('Module:Currency')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local PrizePoolCurrency = {}

local NOW = os.date('!%F')
local USD = 'USD'
local LANG = mw.language.new('en')
local CATEGRORY = '[[Category:Tournaments with invalid prize pool]]'

function PrizePoolCurrency.display(args)
	local currency = string.upper(args.currency or USD)
	local date = PrizePoolCurrency._cleanDate(args.date or NOW)
	local text = args.text or 'Currency exchange rate taken from exchangerate.host'
	local prizepool = PrizePoolCurrency._cleanValue(args.prizepool)
	local prizepoolUsd = PrizePoolCurrency._cleanValue(args.prizepoolusd)
	local currencyRate = tonumber(args.rate)
	local setVariables = Logic.emptyOr(args.setvariables, true)

	if not prizepool and not prizepoolUsd then
		if Namespace.isMain() then
			return (args.prizepool or args.prizepoolUsd or '')
				.. '[[Category:Tournaments with invalid prize pool]]'
		else
			return (args.prizepool or args.prizepoolUsd or '')
		end
	end

	if not date then
		date = NOW
		mw.log('Infobox league: Invalid currency exchange date -> default date (' .. date .. ')')
	elseif date > NOW then
		date = NOW
	end

	if currency == USD and String.isEmpty(prizepoolUsd) then
		return PrizePoolCurrency._errorMessage('Need valid currency')
	elseif currency == USD then
		prizepoolUsd = PrizePoolCurrency._format(prizepoolUsd)
	else
		local errorMessage
		prizepool, prizepoolUsd, currencyRate, errorMessage = PrizePoolCurrency._exchange{
			currency = currency,
			currencyRate = currencyRate,
			date = date,
			prizepool = prizepool,
			prizepoolUsd = prizepoolUsd,
		}
		if errorMessage then
			return PrizePoolCurrency._errorMessage(errorMessage)
		end
	end

	if setVariables then
		if String.isNotEmpty(args.currency) and currencyRate then
			Variables.varDefine(currency .. '_rate', currencyRate)
		end
		if String.isNotEmpty(args.currency) then
			Variables.varDefine('tournament_currency', currency:upper())
		end

		Variables.varDefine('tournament_currency_date', date)
		Variables.varDefine('tournament_currency_text', text)
		Variables.varDefine('tournament_prizepoollocal', prizepool or '')

		local prizepoolUsdValue = string.gsub(prizepoolUsd or '', ',', '')
		Variables.varDefine('tournament_prizepoolusd', prizepoolUsdValue)

		-- legacy compatibility
		Variables.varDefine('tournament_currency_rate', currencyRate or '')
		Variables.varDefine('tournament_prizepool_local', prizepool or '')
		Variables.varDefine('tournament_prizepool_usd', prizepoolUsd or '')
		Variables.varDefine('currency', args.currency and currency or '')
		Variables.varDefine('currency date', date)
		Variables.varDefine('currency rate', currencyRate)
		Variables.varDefine('prizepool', prizepool or '')
		Variables.varDefine('prizepool usd', prizepoolUsd or '')
		Variables.varDefine('tournament_prizepool', prizepoolUsdValue)
	end

	local display = Currency.display(USD, prizepoolUsd, {setVariables = false})
	if String.isNotEmpty(prizepool) then
		display = Currency.display(currency, prizepool, {setVariables = true})
			.. '<br>(≃ ' .. display .. ')'
	end

	return display
end

function PrizePoolCurrency._exchange(props)
	local prizepool = props.prizepool
	local prizepoolUsd = props.prizepoolUsd
	local currencyRate = Currency.getExchangeRate(props)

	if not currencyRate then
		local errorMessage = 'Need valid currency and exchange date or exchange rate'
		return prizepool, prizepoolUsd, currencyRate, errorMessage
	end

	if Logic.isNumeric(prizepool) and currencyRate ~= math.huge then
		prizepoolUsd = tonumber(prizepool) * currencyRate
	end

	if Logic.isNumeric(prizepool) then
		prizepool = PrizePoolCurrency._format(prizepool)
	end
	if Logic.isNumeric(prizepoolUsd) then
		prizepoolUsd = PrizePoolCurrency._format(prizepoolUsd)
	end

	return nil, prizepool, prizepoolUsd, currencyRate
end

function PrizePoolCurrency._format(value)
	return LANG:formatNum(math.floor(value))
end

function PrizePoolCurrency._cleanDate(dateString)
	dateString = string.gsub(dateString, '[^%d.-]', '')

	return string.match(dateString, '%d%d%d%d%-%d%d%-%d%d')
end

function PrizePoolCurrency._cleanValue(valueString)
	return tonumber(string.gsub(valueString or '', '[^%d.?]', '') or '')
end

function PrizePoolCurrency._errorMessage(message)
	local category = ''
	if Namespace.isMain() then
		category = CATEGRORY
	end
	return mw.html.create('strong')
		:addClass('error')
		:wikitext('Error: ')
		:wikitext(mw.text.nowiki(message))
		:wikitext(category)
end

return Class.export(PrizePoolCurrency)
