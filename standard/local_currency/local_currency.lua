---
-- @Liquipedia
-- wiki=commons
-- page=Module:LocalCurrency
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local LocalCurrencyData = mw.loadData('Module:LocalCurrency/Data')
local Logic = require('Module:Logic')
local Math = require('Module:Math')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local LocalCurrency = {}

local LANG = mw.getContentLanguage()
local NON_BREAKING_SPACE = '&nbsp;'
local USD = 'usd'
local USD_TEMPLATE_ALIAS = '1'

function LocalCurrency.template(frame)
	local args = Arguments.getArgs(frame)
	local currencyCode = args.currency or args[1]
	if currencyCode == USD_TEMPLATE_ALIAS then
		currencyCode = USD
	end
	local prizeValue = args.prizepool or args[2]
	local display = LocalCurrency.display(currencyCode, prizeValue, {setVariables = true})

	-- fallback handling like in the old template
	if not display then
		display = (currencyCode or '?')
			.. (String.isNotEmpty(prizeValue) and (NON_BREAKING_SPACE .. prizeValue) or '')
		Variables.varDefine('noncurrency', 'true')
		Variables.varDefine('localcurrencysymbol', NON_BREAKING_SPACE)
	end

	return display
end

function LocalCurrency.display(currencyCode, prizeValue, options)
	if String.isEmpty(currencyCode) then
		return nil
	end
	options = options or {}

	local localCurrencyData = LocalCurrencyData[currencyCode:lower()]

	if not localCurrencyData then
		return nil
	end

	if options.setVariables then
		Variables.varDefine('localcurrencycode', localCurrencyData.code or '')
		Variables.varDefine(
			'localcurrencysymbol',
			localCurrencyData.isAfter and '' or localCurrencyData.symbol or ''
		)
		Variables.varDefine(
			'localcurrencysymbolafter',
			localCurrencyData.isAfter and localCurrencyData.symbol or ''
		)
	end

	if Logic.isNumeric(prizeValue) and options.formatValue then
		prizeValue = LocalCurrency.formatMoney(prizeValue)
	end

	return localCurrencyData.text.prefix .. (prizeValue or '') .. localCurrencyData.text.suffix
end

function LocalCurrency.formatMoney(value)
	if not Logic.isNumeric(value) then
		return 0
	end

	local roundedValue = Math.round{value, 2}
	local integer, decimal = math.modf(roundedValue)
	if decimal == 0 then
		return LANG:formatNum(integer)
	end
	return LANG:formatNum(integer) .. string.format('%.2f', decimal):sub(2)
end

return LocalCurrency
