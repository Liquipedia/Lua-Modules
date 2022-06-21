local Arguments = require('Module:Arguments')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local LocalCurrencyData = mw.loadData('Module:LocalCurrency/Data')

local LocalCurrency = {}

local USD = 'usd'
local USD_TEMPLATE_ALIAS = '1'

function LocalCurrency.template(frame)
	local args = Arguments.getArgs(frame)
	local currencyCode = args.currency or args[1]
	if currencyCode == USD_TEMPLATE_ALIAS then
		currencyCode = USD
	end
	local prizeValue = args.prizepool or args[2]
	return LocalCurrency.display(currencyCode, prizeValue, {setVariables = true})
end

function LocalCurrency.display(currencyCode, prizeValue, options)
	if String.isEmpty(currencyCode) then
		return nil --maybe error here? -> what is preferred?
	end
	currencyCode = currencyCode:lower()
	options = options or {}
	prizeValue = prizeValue or ''

	local localCurrencyData = LocalCurrencyData[currencyCode]

	if options.setVariables then
		Variables.varDefine('localcurrencycode', localCurrencyData.code or '')
		Variables.varDefine('localcurrencysymbol', isAfter and '' or localCurrencyData.symbol or '')
		Variables.varDefine('localcurrencysymbolafter', isAfter and localCurrencyData.symbol or '')
	end

	return localCurrencyData.text.prefix .. prizeValue .. localCurrencyData.text.suffix
end

return LocalCurrency
