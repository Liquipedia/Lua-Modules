---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local FeatureFlag = require('Module:FeatureFlag')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local WarningBox = require('Module:WarningBox')

local Match = Lua.import('Module:Match', {requireDevIfEnabled = true})
local MatchGroupBase = Lua.import('Module:MatchGroup/Base', {requireDevIfEnabled = true})
local MatchGroupConfig = Lua.loadDataIfExists('Module:MatchGroup/Config')
local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific', {requireDevIfEnabled = true})

--[[
	The core module behind every type of MatchGroup. A MatchGroup is a collection of matches, such as a bracket or
	a matchlist.
]]
local MatchGroup = {}

--[[
	Sets up a MatchList, a list of matches displayed vertically. The matches
	are saved to LPDB.
]]
function MatchGroup.MatchList(args)
	local options, optionsWarnings = MatchGroupBase.readOptions(args, 'matchlist')
	local matches = MatchGroupInput.readMatchlist(options.bracketId, args)
	Match.storeMatchGroup(matches, options)

	local matchlistNode
	if options.show then
		local MatchlistDisplay = Lua.import('Module:MatchGroup/Display/Matchlist', {requireDevIfEnabled = true})
		local MatchlistContainer = WikiSpecific.getMatchGroupContainer('matchlist')
		matchlistNode = MatchlistContainer({
			bracketId = options.bracketId,
			config = MatchlistDisplay.configFromArgs(args),
		})
	end

	local parts = Array.extend(
		{matchlistNode},
		Array.map(optionsWarnings, WarningBox.display)
	)
	return table.concat(Array.map(parts, tostring))
end

--[[
	Sets up a Bracket, a tree structure of matches. The matches are saved to LPDB.
]]
function MatchGroup.Bracket(args)
	local options, optionsWarnings = MatchGroupBase.readOptions(args, 'bracket')
	local matches, bracketWarnings = MatchGroupInput.readBracket(options.bracketId, args, options)
	Match.storeMatchGroup(matches, options)

	local bracketNode
	if options.show then
		local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket', {requireDevIfEnabled = true})
		local BracketContainer = WikiSpecific.getMatchGroupContainer('bracket')
		bracketNode = BracketContainer({
			bracketId = options.bracketId,
			config = BracketDisplay.configFromArgs(args),
		})
	end

	local parts = Array.extend(
		Array.map(optionsWarnings, WarningBox.display),
		Array.map(bracketWarnings, WarningBox.display),
		{bracketNode}
	)
	return table.concat(Array.map(parts, tostring))
end

--[[
	Sets up a SingleMatch. The match is saved to LPDB.
]]
function MatchGroup.SingleMatch(args)
	args.matchid = '0001'
	local options, optionsWarnings = MatchGroupBase.readOptions(args, 'match')
	local matches = MatchGroupInput.readSingleMatch(options.bracketId, args, options)
	Match.storeMatchGroup(matches, options)

	local singleMatchNode
	if options.show then
		local fullMatchId = options.bracketId .. '_' .. args.matchid
		singleMatchNode = MatchGroup._displaySingleMatch(args, fullMatchId)
	end

	local parts = Array.extend(
		{singleMatchNode},
		Array.map(optionsWarnings, WarningBox.display)
	)

	return table.concat(Array.map(parts, tostring))
end

--[[
Displays a matchlist or bracket specified by ID.
]]
function MatchGroup.MatchGroupById(args)
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

	local MatchGroupContainer = WikiSpecific.getMatchGroupContainer(matchGroupType)
	return MatchGroupContainer({
		bracketId = bracketId,
		config = config,
	})
end

--[[
Displays a singleMatch specified by a bracket ID and matchID.
]]
function MatchGroup.MatchByMatchId(args)
	local bracketId = args.id
	local matchId = args.matchid
	assert(bracketId, 'Missing bracket ID')
	assert(matchId, 'Missing match ID')

	matchId = MatchGroupUtil.matchIdFromKey(matchId)

	local matchGroup = MatchGroupUtil.fetchMatchGroup(bracketId)
	local fullMatchId = bracketId .. '_' .. matchId
	local match = matchGroup.matchesById[fullMatchId]

	assert(match, 'Match bracketId= ' .. bracketId .. ' matchId=' .. matchId .. ' not found')

	return MatchGroup._displaySingleMatch(args, fullMatchId)
end

function MatchGroup._displaySingleMatch(args, fullMatchId)
	local SingleMatchDisplay = Lua.import('Module:MatchGroup/Display/SingleMatch', {requireDevIfEnabled = true})
	local SingleMatchContainer = WikiSpecific.getMatchGroupContainer('singleMatch')
	return SingleMatchContainer({
			matchId = fullMatchId,
			config = SingleMatchDisplay.configFromArgs(args),
		})
end


-- Entry point of Template:Matchlist
function MatchGroup.TemplateMatchlist(frame)
	local args = Arguments.getArgs(frame)
	return MatchGroup.MatchList(args)
end

-- Entry point of Template:Bracket
function MatchGroup.TemplateBracket(frame)
	local args = Arguments.getArgs(frame)
	return MatchGroup.Bracket(args)
end

-- Entry point of Template:SingleMatch
function MatchGroup.TemplateSingleMatch(frame)
	local args = Arguments.getArgs(frame)
	return MatchGroup.SingleMatch(args)
end

-- Entry point of Template:ShowSingleMatch
function MatchGroup.TemplateShowSingleMatch(frame)
	local args = Arguments.getArgs(frame)
	return MatchGroup.MatchByMatchId(args)
end

-- Entry point of Template:ShowBracket, Template:DisplayMatchGroup
function MatchGroup.TemplateShowBracket(frame)
	local args = Arguments.getArgs(frame)
	return MatchGroup.MatchGroupById(args)
end

if FeatureFlag.get('perf') then
	MatchGroup.perfConfig = Table.getByPathOrNil(MatchGroupConfig, {'perf'})
	require('Module:Performance/Util').setupEntryPoints(MatchGroup)
end

Lua.autoInvokeEntryPoints(MatchGroup, 'Module:MatchGroup')


MatchGroup.deprecatedCategory = '[[Category:Pages using deprecated Match Group functions]]'

-- Entry point used by Template:Bracket
-- Deprecated
function MatchGroup.bracket(frame)
	return MatchGroup.TemplateBracket(frame) .. MatchGroup.deprecatedCategory
end

-- Deprecated
function MatchGroup.luaBracket(_, args)
	return MatchGroup.TemplateBracket(args) .. MatchGroup.deprecatedCategory
end

-- Entry point used by Template:Matchlist
-- Deprecated
function MatchGroup.matchlist(frame)
	return MatchGroup.TemplateMatchlist(frame) .. MatchGroup.deprecatedCategory
end

-- Deprecated
function MatchGroup.luaMatchlist(_, args)
	return MatchGroup.TemplateMatchlist(args) .. MatchGroup.deprecatedCategory
end

-- Entry point from Template:ShowBracket and direct #invoke
-- Deprecated
function MatchGroup.Display(frame)
	return tostring(MatchGroup.TemplateShowBracket(frame)) .. MatchGroup.deprecatedCategory
end

-- Entry point from direct #invoke
-- Deprecated
function MatchGroup.DisplayDev(frame)
	local args = Arguments.getArgs(frame)
	args.dev = true
	return tostring(MatchGroup.TemplateShowBracket(args)) .. MatchGroup.deprecatedCategory
end

return MatchGroup
