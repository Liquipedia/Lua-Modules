---
-- @Liquipedia
-- wiki=commons
-- page=Module:LocalCurrency
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = require('Module:StringUtils')
local Class = require('Module:Class')
local Variables = require('Module:Variables')
local CurrencyData = mw.loadData('Module:LocalCurrency/Data')
local LocalCurrency = {}

function LocalCurrency:getData(currency)
	currency = string.lower(currency or '')
	return CurrencyData[currency] or {}
end

function LocalCurrency:display(currency, prizepool)
	local data = LocalCurrency:getData(currency)
	LocalCurrency:_setVars(data)
	return LocalCurrency:_getDisplay(data, prizepool)
end

function LocalCurrency:displayNoVar(currency, prizepool)
	local data = LocalCurrency:getData(currency)
	return LocalCurrency:_getDisplay(data, prizepool)
end

function LocalCurrency:varsNoDisplay(currency, prizepool)
	local data = LocalCurrency:getData(currency)
	LocalCurrency:_setVars(data)
end

function LocalCurrency:_getDisplay(data, prizepool)
	if data == {} then
		return '[[Category:Pages using invalid currency]]' .. (prizepool or '')
	end

	local display = ''
	if data.symbol and (not data.symbolNoDisplay) then
		display = data.symbol
	end

	if prizepool then
		display = display .. prizepool
	end

	if data.symbolAfter and (not data.symbolNoDisplay) then
		display = display .. data.symbolAfter
	end

	display = display.. '&nbsp;'

	if data.abbr and data.abbrTitle then
		display = display .. LocalCurrency:_makeAbbr(data.abbrTitle, data.abbr)
	end

	if data.append then
		display = display .. data.append
	end

	return display
end

function LocalCurrency:_setVars(data)
	Variables.varDefine('localcurrencysymbol', data.symbol or '')
	Variables.varDefine('localcurrencysymbolafter', data.symbolAfter or '')
	Variables.varDefine('localcurrencycode', data.code or '')
	Variables.varDefine('noncurrency', data.nonCurrency or '')
end

function LocalCurrency:_makeAbbr(abbrTitle, abbr)
	return '<abbr title="' .. abbrTitle .. '">' .. abbr .. '</abbr>'
end

return Class.export(LocalCurrency, {frameOnly = true})
