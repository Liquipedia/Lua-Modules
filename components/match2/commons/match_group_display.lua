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
local MatchGroupUtil = require('Module:MatchGroup/Util')

local MatchGroupBase = Lua.import('Module:MatchGroup/Base', {requireDevIfEnabled = true})
local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})

local MatchGroupDisplay = {}

--[[
Reads a matchlist input spec, saves it to LPDB, and displays the matchlist.
]]
function MatchGroupDisplay.MatchlistBySpec(args)
	local options, optionsWarnings = MatchGroupBase.readOptions(args, 'matchlist')
	local matches = MatchGroupInput.readMatchlist(options.bracketId, args)
	MatchGroupBase.saveMatchGroup(options.bracketId, matches, options.saveToLpdb)

	local matchlistNode
	if options.show then
		local MatchlistDisplay = require('Module:Brkts/WikiSpecific').getMatchGroupModule('matchlist')
		matchlistNode = MatchlistDisplay.luaGet(mw.getCurrentFrame(), {
			options.bracketId,
			attached = args.attached,
			collapsed = args.collapsed,
			nocollapse = args.nocollapse,
			width = args.width or args.matchWidth,
		}, matches)
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
	local matches, bracketWarnings = MatchGroupInput.readBracket(options.bracketId, args)
	MatchGroupBase.saveMatchGroup(options.bracketId, matches, options.saveToLpdb)

	local bracketNode
	if options.show then
		local BracketDisplay = require('Module:Brkts/WikiSpecific').getMatchGroupModule('bracket')
		bracketNode = BracketDisplay.luaGet(mw.getCurrentFrame(), {
			options.bracketId,
			emptyRoundTitles = args.emptyRoundTitles,
			headerHeight = args.headerHeight,
			hideMatchLine = args.hideMatchLine,
			hideRoundTitles = args.hideRoundTitles,
			matchHeight = args.matchHeight,
			matchWidth = args.matchWidth,
			matchWidthMobile = args.matchWidthMobile,
			opponentHeight = args.opponentHeight,
			qualifiedHeader = args.qualifiedHeader,
		}, matches)
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

	local matches = MatchGroupUtil.fetchMatches(bracketId)
	assert(#matches ~= 0, 'No data found for bracketId=' .. bracketId)
	local matchGroupType = matches[1].bracketData.type

	MatchGroupInput.applyOverrideArgs(matches, args)

	local MatchGroupContainer = require('Module:Brkts/WikiSpecific').getMatchGroupModule(matchGroupType)
	return MatchGroupContainer.luaGet(mw.getCurrentFrame(), args, matches)
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
		MatchGroupBase.enableInstrumentation()
		local result = MatchGroupDisplay_.MatchlistBySpec(args)
		MatchGroupBase.disableInstrumentation()
		return result
	end)
end

-- Entry point of Template:Bracket
function MatchGroupDisplay.TemplateBracket(frame)
	local args = Arguments.getArgs(frame)
	return FeatureFlag.with({dev = Logic.readBoolOrNil(args.dev)}, function()
		local MatchGroupDisplay_ = Lua.import('Module:MatchGroup/Display', {requireDevIfEnabled = true})
		MatchGroupBase.enableInstrumentation()
		local result = MatchGroupDisplay_.BracketBySpec(args)
		MatchGroupBase.disableInstrumentation()
		return result
	end)
end

-- Entry point of Template:ShowBracket
function MatchGroupDisplay.TemplateShowBracket(frame)
	local args = Arguments.getArgs(frame)
	return FeatureFlag.with({dev = Logic.readBoolOrNil(args.dev)}, function()
		local MatchGroupDisplay_ = Lua.import('Module:MatchGroup/Display', {requireDevIfEnabled = true})
		MatchGroupBase.enableInstrumentation()
		local result = MatchGroupDisplay_.MatchGroupById(args)
		MatchGroupBase.disableInstrumentation()
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
function MatchGroupDisplay.luaBracket(frame, args, matches)
	local BracketDisplay = require('Module:Brkts/WikiSpecific').getMatchGroupModule('bracket')
	return tostring(BracketDisplay.luaGet(frame, args, matches)) .. MatchGroupDisplay.deprecatedCategory
end

-- Unused entry point
-- Deprecated
function MatchGroupDisplay.matchlist(frame)
	return MatchGroupDisplay.TemplateMatchlist(frame) .. MatchGroupDisplay.deprecatedCategory
end

-- Deprecated
function MatchGroupDisplay.luaMatchlist(frame, args, matches)
	local MatchlistDisplay = require('Module:Brkts/WikiSpecific').getMatchGroupModule('matchlist')
	return tostring(MatchlistDisplay.luaGet(frame, args, matches)) .. MatchGroupDisplay.deprecatedCategory
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
