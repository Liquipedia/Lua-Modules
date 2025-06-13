---
-- @Liquipedia
-- page=Module:Currency
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Arguments = require('Module:Arguments')
local CurrencyData = mw.loadData('Module:Currency/Data')
local Info = mw.loadData('Module:Info')
local Logic = require('Module:Logic')
local Math = require('Module:MathUtil')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Currency = {}

local LANG = mw.getContentLanguage()
local NON_BREAKING_SPACE = '&nbsp;'
local USD = 'usd'
local USD_TEMPLATE_ALIAS = '1'
local DEFAULT_ROUND_PRECISION = 2
local DASH = '-'

---@param frame Frame
---@return string
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
			.. (Logic.isNotEmpty(prizeValue) and (NON_BREAKING_SPACE .. prizeValue) or '')
		Variables.varDefine('noncurrency', 'true')
		Variables.varDefine('localcurrencysymbol', NON_BREAKING_SPACE)
	end

	return display
end

---@class currencyDisplayOptions
---@field dashIfZero boolean?
---@field displaySymbol boolean?
---@field displayCurrencyCode boolean?
---@field forceRoundPrecision boolean?
---@field formatPrecision integer?
---@field formatValue boolean?
---@field setVariables boolean?
---@field useHtmlStyling boolean?

---@param currencyCode string?
---@param prizeValue string|number|nil
---@param options currencyDisplayOptions?
---@return string?
function Currency.display(currencyCode, prizeValue, options)
	options = options or {}
	options.displaySymbol = Logic.emptyOr(options.displaySymbol, true)
	options.displayCurrencyCode = Logic.emptyOr(options.displayCurrencyCode, true)
	options.useHtmlStyling = Logic.emptyOr(options.useHtmlStyling, true)

	if options.dashIfZero and tonumber(prizeValue) == 0 then
		return DASH
	end

	local currencyData = Currency.raw(currencyCode)

	if not currencyData then
		if String.isNotEmpty(currencyCode) then
			mw.log('Invalid currency "' .. currencyCode .. '"')
		end
		return nil
	end

	local spaceString = options.useHtmlStyling and NON_BREAKING_SPACE or ' '

	local currencyPrefix = ''
	if currencyData.symbol.text and not currencyData.symbol.isAfter then
		currencyPrefix = currencyData.symbol.text .. (currencyData.symbol.hasSpace and spaceString or '')
	end
	local currencySuffix = ''
	if currencyData.symbol.text and currencyData.symbol.isAfter then
		currencySuffix = (currencyData.symbol.hasSpace and spaceString or '') .. currencyData.symbol.text
	end

	if options.setVariables then
		Variables.varDefine('localcurrencycode', currencyData.code or '')
		Variables.varDefine('localcurrencysymbol', currencyPrefix)
		Variables.varDefine('localcurrencysymbolafter', currencySuffix)
	end

	if options.displayCurrencyCode and currencyData.symbol.text == currencyData.code then
		options.displaySymbol = false
	end

	local prizeDisplay = ''
	if options.displaySymbol then
		prizeDisplay = prizeDisplay .. currencyPrefix
	end
	if prizeValue then
		if Logic.isNumeric(prizeValue) and options.formatValue then
			prizeValue = Currency.formatMoney(prizeValue, options.formatPrecision, options.forceRoundPrecision, false)
		end
		prizeDisplay = prizeDisplay .. prizeValue
	end
	if options.displaySymbol then
		prizeDisplay = prizeDisplay .. currencySuffix
	end
	if options.displayCurrencyCode then
		local currencyCodeDisplay = not options.useHtmlStyling and currencyData.code
			or Abbreviation.make{text = currencyData.code, title = currencyData.name}
		prizeDisplay = prizeDisplay .. (String.isNotEmpty(prizeDisplay) and spaceString or '') .. currencyCodeDisplay
	end

	return prizeDisplay
end

---@param currencyCode string?
---@return {code: string, name: string, symbol: {hasSpace: boolean?, isAfter: boolean?, text: string}}?
function Currency.raw(currencyCode)
	if String.isEmpty(currencyCode) then
		return nil
	end
	---@cast currencyCode -nil

	return CurrencyData[currencyCode:lower()]
end

---@param value string|number|nil
---@param precision integer?
---@param forceRoundPrecision boolean?
---@param dashIfZero boolean?
---@return string|number
function Currency.formatMoney(value, precision, forceRoundPrecision, dashIfZero)
	dashIfZero = Logic.nilOr(Logic.readBoolOrNil(dashIfZero), true)
	if not Logic.isNumeric(value) or (tonumber(value) == 0 and not forceRoundPrecision) then
		return dashIfZero and DASH or 0
	end
	---@cast value number

	precision = tonumber(precision) or Info.defaultRoundPrecision or DEFAULT_ROUND_PRECISION

	local roundedValue = Math.round(value, precision)
	local integer, decimal = math.modf(roundedValue)

	if precision <= 0 or decimal == 0 and not forceRoundPrecision then
		return LANG:formatNum(integer)
	end

	return LANG:formatNum(integer) .. string.format('%.' .. precision .. 'f', decimal):sub(2)
end

---@param props {currency: string, currencyRate: string|number|nil, date: string?, setVariables: boolean?}
---@return number?
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

	if setVariables and currencyRate and Logic.isNotEmpty(currencyRate) then
		Variables.varDefine('exchangerate_' .. currency, currencyRate)
	end

	return tonumber(currencyRate)
end

return Currency
