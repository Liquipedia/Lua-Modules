---
-- @Liquipedia
-- wiki=commons
-- page=Module:Currency
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local CurrencyData = mw.loadData('Module:Currency/Data')
local Logic = require('Module:Logic')
local Math = require('Module:Math')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Currency = {}

local LANG = mw.getContentLanguage()
local NON_BREAKING_SPACE = '&nbsp;'
local USD = 'usd'
local USD_TEMPLATE_ALIAS = '1'

function Currency.template(frame)
	local args = Arguments.getArgs(frame)
	local currencyCode = args.currency or args[1]
	if currencyCode == USD_TEMPLATE_ALIAS then
		currencyCode = USD
	end
	local prizeValue = args.prizepool or args[2]
	local display = Currency.display(currencyCode, prizeValue, {setVariables = true})

	-- fallback handling like in the old template
	if not display then
		display = (currencyCode or '?')
			.. (String.isNotEmpty(prizeValue) and (NON_BREAKING_SPACE .. prizeValue) or '')
		Variables.varDefine('noncurrency', 'true')
		Variables.varDefine('localcurrencysymbol', NON_BREAKING_SPACE)
	end

	return display
end

function Currency.display(currencyCode, prizeValue, options)
	options = options or {}

	local currencyData = Currency.raw(currencyCode)

	if not currencyData then
		if currencyCode then
			mw.log('Invalid currency "' .. currencyCode .. '"')
		end
		return nil
	end

	if options.setVariables then
		Variables.varDefine('localcurrencycode', currencyData.code or '')
		Variables.varDefine(
			'localcurrencysymbol',
			currencyData.isAfter and '' or currencyData.symbol or ''
		)
		Variables.varDefine(
			'localcurrencysymbolafter',
			currencyData.isAfter and currencyData.symbol or ''
		)
	end

	if Logic.isNumeric(prizeValue) and options.formatValue then
		prizeValue = Currency.formatMoney(prizeValue)
	end

	return currencyData.text.prefix .. (prizeValue or '') .. currencyData.text.suffix
end

function Currency.raw(currencyCode)
	if String.isEmpty(currencyCode) then
		return nil
	end

	return CurrencyData[currencyCode:lower()]
end

function Currency.formatMoney(value, precision)
	if not Logic.isNumeric(value) then
		return 0
	end
	precision = tonumber(precision) or 2

	local roundedValue = Math.round{value, precision}
	local integer, decimal = math.modf(roundedValue)
	if decimal == 0 then
		return LANG:formatNum(integer)
	end
	return LANG:formatNum(integer) .. string.format('%.' .. precision .. 'f', decimal):sub(2)
end

function Currency.getExchangeRate(props)
	if not props then
		error('No props passed to "Currency.getExchangeRate"')
	end
	local setVariables = Logic.readBool(props.setVariables)
	local currencyRate = tonumber(props.currencyRate)
	if String.isEmpty(props.currency) then
		error('No currency passed to "Currency.getExchangeRate"')
	end
	local currency = props.currency:upper()
	if not currencyRate then
		if not props.date:match('%d%d%d%d%-%d%d%-%d%d') then
			error('Invalid date passed to "Currency.getExchangeRate"')
		end
		currencyRate = mw.ext.CurrencyExchange.currencyexchange(1, currency, USD:upper(), props.date)
	end

	if setVariables and currencyRate and String.isNotEmpty(currencyRate) then
		Variables.varDefine('exchangerate_' .. currency, currencyRate)
	end

	return tonumber(currencyRate)
end

return Currency
