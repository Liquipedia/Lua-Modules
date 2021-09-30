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

local Flags = {}

-- Template functions (legacy)
function Flags.Flag(frame)
	return Flags._Flag(frame.args[1])
end
function Flags.FlagNoLink(frame)
	return Flags._FlagNoLink(frame.args[1])
end

--legacy functions
function Flags._Flag(name)
	return Flags.Icon(name)
end
function Flags._FlagNoLink(name)
	return Flags.Icon({flag = name, noLink = true})
end
function Flags._CountryName(name)
	return Flags.CountryName(name)
end
function Flags.flag(name)
	return Flags.Icon(name)
end
function Flags.flagNoLink(name)
	return Flags.Icon({flag = name, noLink = true})
end

-- Returns a flag
--[[
supported args are:
flag	- name, flag code, or alias of the Flag
noLink	- boolean that decides if the flag should link or not
		--> set this to true for the flag to not link
		--> else the flag will link to the according category
]]--
function Flags.Icon(args, flagName)
	local noLink
	if type(args) == 'string' then
		flagName = args
	elseif type(args) == 'table' then
		noLink = args.noLink
		if String.isEmpty(flagName) then
			flagName = args.flag
		end
	end
	if String.isEmpty(flagName) then
		return ''
	end
	noLink = Logic.readBool(noLink)

	local flagKey = Flags._convertToKey(flagName)

	if flagKey then
		local flagData = MasterData.data[flagKey]
		if flagData.flag ~= 'File:Space filler flag.png' then
			local link = ''
			if flagData.name and not noLink then
				link = 'Category:' .. flagData.name
			end
			return '<span class="flag">[[' .. flagData.flag ..
				'|' .. flagData.name .. '|link=' .. link .. ']]</span>'
		else
			return '<span class="flag">[[' .. flagData.flag .. '|link=]]</span>'
		end
	elseif noLink then
		mw.log('Unknown flag: ', flagName)
		return Template.safeExpand(mw.getCurrentFrame(), 'FlagNoLink/' .. flagName) .. '[[Category:Pages with unknown flags]]'
	else
		mw.log('Unknown flag: ', flagName)
		return Template.safeExpand(mw.getCurrentFrame(), 'Flag/' .. flagName) .. '[[Category:Pages with unknown flags]]'
	end
end

-- Converts a country name, flag code, or alias to a standardized country name
-- AFTER THE SWITCH TO USING 'Module:Class' switch the following 7 lines to
-->>	function Flags.CountryName(flagName)
function Flags.CountryName(frame)
	local flagName
	if type(frame) ~= 'string' then
		flagName = frame.args[1]
	else
		flagName = frame
	end

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
function Flags.countryCode(flagName, format)
	if String.isEmpty(flagName) then
		return ''
	end

	local flagKey = Flags._convertToKey(flagName)

	if flagKey then
		if format == 'alpha3' then
			return Flags._getAlpha3CodesByKey()[flagKey]
		else
			return Flags._getAlpha2CodesByKey()[flagKey]
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

return Flags
