---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local FeatureFlag = require('Module:FeatureFlag')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Match = Lua.import('Module:Match', {requireDevIfEnabled = true})
local MatchGroupBase = Lua.import('Module:MatchGroup/Base', {requireDevIfEnabled = true})
local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local MatchGroupDisplay = {}

--[[
Reads a matchlist input spec, saves it to LPDB, and displays the matchlist.
]]
function MatchGroupDisplay.MatchlistBySpec(args)
	local options, optionsWarnings = MatchGroupBase.readOptions(args, 'matchlist')
	local matches = MatchGroupInput.readMatchlist(options.bracketId, args)
	Match.storeMatchGroup(matches, options)

	local matchlistNode
	if options.show then
		local MatchlistDisplay = Lua.import('Module:MatchGroup/Display/Matchlist', {requireDevIfEnabled = true})
		local MatchlistContainer = require('Module:Brkts/WikiSpecific').getMatchGroupContainer('matchlist')
		matchlistNode = MatchlistContainer({
			bracketId = options.bracketId,
			config = MatchlistDisplay.configFromArgs(args),
		})
	end

	local parts = Array.extend(
		{matchlistNode},
		Array.map(optionsWarnings, MatchGroupDisplay.WarningBox)
	)
	return table.concat(Array.map(parts, tostring))
end

--[[
Reads a bracket input spec, saves it to LPDB, and displays the bracket.
]]
function MatchGroupDisplay.BracketBySpec(args)
	local options, optionsWarnings = MatchGroupBase.readOptions(args, 'bracket')
	local matches, bracketWarnings = MatchGroupInput.readBracket(options.bracketId, args, options)
	Match.storeMatchGroup(matches, options)

	local bracketNode
	if options.show then
		local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket', {requireDevIfEnabled = true})
		local BracketContainer = require('Module:Brkts/WikiSpecific').getMatchGroupContainer('bracket')
		bracketNode = BracketContainer({
			bracketId = options.bracketId,
			config = BracketDisplay.configFromArgs(args),
		})
	end

	local parts = Array.extend(
		Array.map(optionsWarnings, MatchGroupDisplay.WarningBox),
		Array.map(bracketWarnings, MatchGroupDisplay.WarningBox),
		{bracketNode}
	)
	return table.concat(Array.map(parts, tostring))
end

--[[
Displays a matchlist or bracket specified by ID.
]]
function MatchGroupDisplay.MatchGroupById(args)
	local bracketId = args.id or args[1]
	args.id = bracketId
	args[1] = bracketId
	assert(bracketId, 'Missing bracket ID')

	local matches = MatchGroupUtil.fetchMatches(bracketId)
	assert(#matches ~= 0, 'No data found for bracketId=' .. bracketId)
	local matchGroupType = matches[1].bracketData.type

	local config
	if matchGroupType == 'matchlist' then
		local MatchlistDisplay = Lua.import('Module:MatchGroup/Display/Matchlist', {requireDevIfEnabled = true})
		config = MatchlistDisplay.configFromArgs(args)
	else
		local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket', {requireDevIfEnabled = true})
		config = BracketDisplay.configFromArgs(args)
	end

	MatchGroupInput.applyOverrideArgs(matches, args)

	local MatchGroupContainer = require('Module:Brkts/WikiSpecific').getMatchGroupContainer(matchGroupType)
	return MatchGroupContainer({
		bracketId = bracketId,
		config = config,
	})
end

function MatchGroupDisplay.WarningBox(text)
	local div = mw.html.create('div'):addClass('show-when-logged-in navigation-not-searchable ambox-wrapper')
		:addClass('ambox wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red')
	local tbl = mw.html.create('table')
	tbl:tag('tr')
		:tag('td'):addClass('ambox-image'):wikitext('[[File:Emblem-important.svg|40px|link=]]'):done()
		:tag('td'):addClass('ambox-text'):wikitext(text)
	return div:node(tbl)
end

-- Entry point of Template:Matchlist
function MatchGroupDisplay.TemplateMatchlist(frame)
	local args = Arguments.getArgs(frame)
	return FeatureFlag.with({dev = Logic.readBoolOrNil(args.dev)}, function()
		local MatchGroupDisplay_ = Lua.import('Module:MatchGroup/Display', {requireDevIfEnabled = true})
		local MatchGroupBase_ = Lua.import('Module:MatchGroup/Base', {requireDevIfEnabled = true})
		MatchGroupBase_.enableInstrumentation()
		local result = MatchGroupDisplay_.MatchlistBySpec(args)
		MatchGroupBase_.disableInstrumentation()
		return result
	end)
end

-- Entry point of Template:Bracket
function MatchGroupDisplay.TemplateBracket(frame)
	local args = Arguments.getArgs(frame)
	return FeatureFlag.with({dev = Logic.readBoolOrNil(args.dev)}, function()
		local MatchGroupDisplay_ = Lua.import('Module:MatchGroup/Display', {requireDevIfEnabled = true})
		local MatchGroupBase_ = Lua.import('Module:MatchGroup/Base', {requireDevIfEnabled = true})
		MatchGroupBase_.enableInstrumentation()
		local result = MatchGroupDisplay_.BracketBySpec(args)
		MatchGroupBase_.disableInstrumentation()
		return result
	end)
end

-- Entry point of Template:ShowBracket
function MatchGroupDisplay.TemplateShowBracket(frame)
	local args = Arguments.getArgs(frame)
	return FeatureFlag.with({dev = Logic.readBoolOrNil(args.dev)}, function()
		local MatchGroupDisplay_ = Lua.import('Module:MatchGroup/Display', {requireDevIfEnabled = true})
		local MatchGroupBase_ = Lua.import('Module:MatchGroup/Base', {requireDevIfEnabled = true})
		MatchGroupBase_.enableInstrumentation()
		local result = MatchGroupDisplay_.MatchGroupById(args)
		MatchGroupBase_.disableInstrumentation()
		return result
	end)
end

MatchGroupDisplay.deprecatedCategory = '[[Category:Pages using deprecated Match Group functions]]'

-- Unused entry point
-- Deprecated
function MatchGroupDisplay.bracket(frame)
	return MatchGroupDisplay.TemplateBracket(frame) .. MatchGroupDisplay.deprecatedCategory
end

-- Deprecated
function MatchGroupDisplay.luaBracket(_, args)
	return tostring(MatchGroupDisplay.MatchGroupById(args)) .. MatchGroupDisplay.deprecatedCategory
end

-- Unused entry point
-- Deprecated
function MatchGroupDisplay.matchlist(frame)
	return MatchGroupDisplay.TemplateMatchlist(frame) .. MatchGroupDisplay.deprecatedCategory
end

-- Deprecated
function MatchGroupDisplay.luaMatchlist(_, args)
	return tostring(MatchGroupDisplay.MatchGroupById(args)) .. MatchGroupDisplay.deprecatedCategory
end

-- Entry point from Template:ShowBracket and direct #invoke
-- Deprecated
function MatchGroupDisplay.Display(frame)
	return tostring(MatchGroupDisplay.TemplateShowBracket(frame)) .. MatchGroupDisplay.deprecatedCategory
end

-- Entry point from direct #invoke
-- Deprecated
function MatchGroupDisplay.DisplayDev(frame)
	local args = Arguments.getArgs(frame)
	args.dev = true
	return tostring(MatchGroupDisplay.TemplateShowBracket(args)) .. MatchGroupDisplay.deprecatedCategory
end

return MatchGroupDisplay
