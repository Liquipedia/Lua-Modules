---
-- @Liquipedia
-- wiki=commons
-- page=Module:Flags
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MasterData = mw.loadData('Module:Flags/MasterData')
local Template = require('Module:Template')
local Logic = require('Module:Logic')
local Table = require('Module:Table')
local String = require('Module:StringUtils')
local FnUtil = require('Module:FnUtil')
local Class = require('Module:Class')

local Flags = {}

-- Returns a flag
--[[
supported args are:
flag		- country name, flag code, or alias of the Flag
shouldLink	- boolean that decides if the flag should link or not
		--> set this to true for the flag to link to the according category
		--> else the flag will not link
]]--
function Flags.Icon(args, flagName)
	local shouldLink
	if type(args) == 'string' then
		flagName = args
	elseif type(args) == 'table' then
		shouldLink = args.shouldLink
		if String.isEmpty(flagName) then
			flagName = args.flag
		end
	end
	if String.isEmpty(flagName) then
		return ''
	end
	shouldLink = Logic.readBool(shouldLink)

	local flagKey = Flags._convertToKey(flagName)

	if flagKey then
		local flagData = MasterData.data[flagKey]
		if flagData.flag ~= 'File:Space filler flag.png' then
			local link = ''
			if flagData.name and shouldLink then
				link = 'Category:' .. flagData.name
			end
			return '<span class="flag">[[' .. flagData.flag ..
				'|' .. flagData.name .. '|link=' .. link .. ']]</span>'
		else
			return '<span class="flag">[[' .. flagData.flag .. '|link=]]</span>'
		end
	elseif shouldLink then
		mw.log('Unknown flag: ', flagName)
		return Template.safeExpand(mw.getCurrentFrame(), 'Flag/' .. flagName) .. '[[Category:Pages with unknown flags]]'
	else
		mw.log('Unknown flag: ', flagName)
		return Template.safeExpand(mw.getCurrentFrame(), 'FlagNoLink/' .. flagName) .. '[[Category:Pages with unknown flags]]'
	end
end

-- Returns the localisation of a country or region
--[[
supported args are:
country					- country name, flag code, or alias of the Flag
displayNoError			- boolean that decides if there should be a displayed error if no entry is found
shouldReturnSimpleError	- boolean that decides if displayed error should be simple or detailed
]]--
function Flags.getLocalisation(args)
	args = args or {}
	local country = args.country

	if String.isEmpty(country) then
		return ''
	end

	local displayNoError = Logic.readBool(args.displayNoError)
	local shouldReturnSimpleError = Logic.readBool(args.shouldReturnSimpleError)

	-- clean the entered value
	local countryKey = Flags._convertToKey(country)

	if countryKey then
		local data = MasterData.data[countryKey]
		if String.isNotEmpty(data.localised) then
			return data.localised
		end
	end

	-- Return message if none is found
	mw.log('Unknown localisation entry: ', country)
	local display
	if displayNoError then
		display = ''
	elseif shouldReturnSimpleError then
		display = 'error'
	else
		display = 'Unknown localisation entry "[[lpcommons:Module:Flags/MasterData' ..
			'|' .. country .. ']][[Category:Pages with unknown countries]]'
	end

	return display
end

function Flags.languageIcon(args, langName)
	if type(args) == 'string' then
		langName = args
		args = {}
	elseif String.isEmpty(langName) then
		langName = args.language or args.flag
	end
	if String.isEmpty(langName) then
		return ''
	end
	langName = Flags._convertToLangKey(langName)

	return Flags.Icon(args, langName)
end

-- Converts a country name, flag code, or alias to a standardized country name
function Flags.CountryName(flagName)
	if String.isEmpty(flagName) then
		return ''
	end

	local flagKey = Flags._convertToKey(flagName)

	if flagKey then
		return MasterData.data[flagKey].name
	else
		mw.log('Unknown flag: ', flagName)
		return mw.text.trim(mw.text.split(Template.safeExpand(mw.getCurrentFrame(), 'Flag/' .. flagName), '|', true)[2] or '')
	end
end

-- Converts a country name, flag code, or alias to its iso code
--[[
supported formats are:
alpha2 - returns the lowercase ISO 3166-1 alpha-2 flag code
alpha3 - returns the lowercase ISO 3166-1 alpha-3 flag code

default is alpha2
]]--
function Flags.CountryCode(flagName, format)
	if String.isEmpty(flagName) then
		return ''
	end

	local flagKey = Flags._convertToKey(flagName)

	if flagKey then
		if format == 'alpha3' then
			return Flags._getAlpha3CodesByKey()[flagKey] or Flags._getLanguage3LetterCodesByKey()[flagKey]
		else
			return Flags._getAlpha2CodesByKey()[flagKey] or Flags._getLanguageCodesByKey()[flagKey]
		end
	end
	mw.log('Unknown flag: ', flagName)
	return ''
end

Flags._getAlpha2CodesByKey = FnUtil.memoize(function()
	return Table.map(MasterData.twoLetter, function(key, code) return code, key end)
end)

Flags._getAlpha3CodesByKey = FnUtil.memoize(function()
	return Table.map(MasterData.threeLetter, function(key, code) return code, key end)
end)

Flags._getLanguageCodesByKey = FnUtil.memoize(function()
	return Table.map(MasterData.languageTwoLetter, function(key, code) return code, key end)
end)

Flags._getLanguage3LetterCodesByKey = FnUtil.memoize(function()
	return Table.map(MasterData.languageThreeLetter, function(key, code) return code, key end)
end)


--[[
Converts a country name, flag code, or alias to a canonical key. The key is a
lower case no-space representation of the country name, and is used for other
functions in this module. Returns nil if the input is unrecognized.

Examples:
Flags.readKey('tn') -- returns 'tunisia'
Flags.readKey('tun') -- returns 'tunisia'
Flags.readKey('tunisia') -- returns 'tunisia'
Flags.readKey('Antigua and Barbuda') -- returns 'antiguaandbarbuda'
Flags.readKey('Czech Republic') -- returns 'czechia'
Flags.readKey('Czechoslovakia') -- returns nil
]]
function Flags._convertToKey(flagName)
	flagName = flagName:gsub(' ', ''):lower()

	return MasterData.twoLetter[flagName]
		or MasterData.threeLetter[flagName]
		or MasterData.aliases[flagName]
		or (MasterData.data[flagName] and flagName)
end

function Flags._convertToLangKey(langName)
	return MasterData.languageTwoLetter[langName]
		or MasterData.languageThreeLetter[langName]
		or langName
end

return Class.export(Flags)
