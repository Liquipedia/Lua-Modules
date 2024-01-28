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

---@class flagIconArgs
---@field flag string? country name, flag code, or alias of the Flag
---@field shouldLink boolean? decides if the flag should link or not

---Returns a flag
---@param args flagIconArgs?
---@param flagName string?
---@return string
---@overload fun(args: string): string
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
	---@cast flagName -nil
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
				'|36x24px|' .. flagData.name .. '|link=' .. link .. ']]</span>'
		else
			return '<span class="flag">[[' .. flagData.flag .. '|36x24px|link=]]</span>'
		end
	elseif shouldLink then
		mw.log('Unknown flag: ', flagName)
		mw.ext.TeamLiquidIntegration.add_category('Pages with unknown flags')
		return Template.safeExpand(mw.getCurrentFrame(), 'Flag/' .. mw.ustring.lower(flagName))
	else
		mw.log('Unknown flag: ', flagName)
		mw.ext.TeamLiquidIntegration.add_category('Pages with unknown flags')
		return Template.safeExpand(mw.getCurrentFrame(), 'FlagNoLink/' .. mw.ustring.lower(flagName))
	end
end

-- Returns the localisation/country-adjective of a country or region
-- If an invalid country is specified the 2nd return value will return a warning display incl. tracking category
-- examples:
-- Flags.getLocalisation('de') = German
-- Flags.getLocalisation('Germany') = German
-- Flags.getLocalisation('deu') = German
---@param country string? country name, flag code, or alias of the Flag
---@return string?, string?
function Flags.getLocalisation(country)
	if String.isEmpty(country) then
		return
	end
	---@cast country -nil

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
	return nil, 'Unknown localisation entry "[[lpcommons:Module:Flags/MasterData' ..
			'|' .. country .. ']]"[[Category:Pages with unknown countries]]'
end

---@class flagLocalisationArgs
---@field country string? country name, flag code, or alias of the Flag
---@field hideError boolean? decides if there should be a displayed error
---@field simpleError boolean? decides if displayed error should be simple or detailed

---@param args flagLocalisationArgs
---@return string?
function Flags.localisationTemplate(args)
	args = args or {}
	local display, error = Flags.getLocalisation(args.country)

	if not error or Logic.readBool(args.hideError) then
		return display
	end

	if Logic.readBool(args.simpleError) then
		return 'error'
	end

	return error
end

---@class flagLanguageArgs
---@field flag string? country name, flag code, or alias of the Flag
---@field language string? language name
---@field shouldLink boolean? decides if the flag should link or not

---Returns a flag display indicating the language
---@param args flagLanguageArgs?
---@param langName string?
---@return string
---@overload fun(args: string): string
function Flags.languageIcon(args, langName)
	if type(args) == 'string' then
		langName = args
		args = {}
	elseif String.isEmpty(langName) then
		args = args or {}
		langName = args.language or args.flag
	end
	if String.isEmpty(langName) then
		return ''
	end
	---@cast langName -nil
	langName = Flags._convertToLangKey(langName)

	return Flags.Icon(args --[[@as flagIconArgs]], langName)
end

-- Converts a country name, flag code, or alias to a standardized country name
---@param flagName string?
---@return string
function Flags.CountryName(flagName)
	if String.isEmpty(flagName) then
		return ''
	end
	---@cast flagName -nil

	local flagKey = Flags._convertToKey(flagName)

	if flagKey then
		return MasterData.data[flagKey].name
	else
		mw.log('Unknown flag: ', flagName)
		mw.ext.TeamLiquidIntegration.add_category('Pages with unknown flags')
		return mw.text.trim(mw.text.split(mw.text.split(
					Template.safeExpand(mw.getCurrentFrame(), 'Flag/' .. flagName),
					'Category:', true)[2] or '',
						"[%]%|]", false)[1])
	end
end

-- Converts a country name, flag code, or alias to its iso code
--[[
supported formats are:
alpha2 - returns the lowercase ISO 3166-1 alpha-2 flag code
alpha3 - returns the lowercase ISO 3166-1 alpha-3 flag code

default is alpha2
]]--
---@param flagName string?
---@param format 'alpha3'|'alpha2'|nil
---@return string
function Flags.CountryCode(flagName, format)
	if String.isEmpty(flagName) then
		return ''
	end
	---@cast flagName -nil

	local flagKey = Flags._convertToKey(flagName)

	if flagKey then
		if format == 'alpha3' then
			return Flags._getAlpha3CodesByKey()[flagKey] or Flags._getLanguage3LetterCodesByKey()[flagKey]
		else
			flagKey = MasterData.iso31662[flagKey] or flagKey
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
---@param flagName string
---@return string?
function Flags._convertToKey(flagName)
	-- lowercase all unicode
	-- removes all accents and special characters
	local parsedName = mw.ustring.toNFKD(mw.ustring.lower(flagName))
	if not parsedName then
		return
	end
	parsedName = string.gsub(parsedName, '[^%l]', '')

	return MasterData.twoLetter[parsedName]
		or MasterData.threeLetter[parsedName]
		or MasterData.aliases[parsedName]
		or (MasterData.data[parsedName] and parsedName)
end

---@param langName string
---@return string?
function Flags._convertToLangKey(langName)
	return MasterData.languageTwoLetter[langName]
		or MasterData.languageThreeLetter[langName]
		or langName
end

function Flags.isValidFlagInput(flagInput)
	return String.isNotEmpty(Flags._convertToKey(flagInput))
end

return Class.export(Flags)
