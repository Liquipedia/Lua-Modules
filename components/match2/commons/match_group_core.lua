---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Core
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
local Core = {}

--[[
Reads a matchlist input spec, saves it to LPDB, and displays the matchlist.
]]
function Core.MatchlistBySpec(args)
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
Reads a bracket input spec, saves it to LPDB, and displays the bracket.
]]
function Core.BracketBySpec(args)
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
Displays a matchlist or bracket specified by ID.
]]
function Core.MatchGroupById(args)
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
function Core.MatchByMatchId(args)
	local bracketId = args.id
	local matchId = args.matchid
	assert(bracketId, 'Missing bracket ID')
	assert(matchId, 'Missing match ID')

	matchId = MatchGroupUtil.matchIdFromKey(matchId)

	local matchGroup = MatchGroupUtil.fetchMatchGroup(bracketId)
	local fullMatchId = bracketId .. '_' .. matchId
	local match = matchGroup.matchesById[fullMatchId]

	assert(match, 'Match bracketId= ' .. bracketId .. ' matchId=' .. matchId .. ' not found')

	local SingleMatchDisplay = Lua.import('Module:MatchGroup/Display/SingleMatch', {requireDevIfEnabled = true})
	local config = SingleMatchDisplay.configFromArgs(args)

	local MatchGroupContainer = WikiSpecific.getMatchContainer('singleMatch')
	return MatchGroupContainer({
		matchId = fullMatchId,
		config = config,
	})
end


-- Entry point of Template:Matchlist
function Core.TemplateMatchlist(frame)
	local args = Arguments.getArgs(frame)
	return Core.MatchlistBySpec(args)
end

-- Entry point of Template:Bracket
function Core.TemplateBracket(frame)
	local args = Arguments.getArgs(frame)
	return Core.BracketBySpec(args)
end

-- Entry point of Template:ShowSingleMatch
function Core.TemplateShowSingleMatch(frame)
	local args = Arguments.getArgs(frame)
	return Core.MatchByMatchId(args)
end

-- Entry point of Template:ShowBracket, Template:DisplayMatchGroup
function Core.TemplateShowBracket(frame)
	local args = Arguments.getArgs(frame)
	return Core.MatchGroupById(args)
end

if FeatureFlag.get('perf') then
	Core.perfConfig = Table.getByPathOrNil(MatchGroupConfig, {'perf'})
	require('Module:Performance/Util').setupEntryPoints(Core)
end

Lua.autoInvokeEntryPoints(Core, 'Module:MatchGroup/Display')


Core.deprecatedCategory = '[[Category:Pages using deprecated Match Group functions]]'

-- Unused entry point
-- Deprecated
function Core.bracket(frame)
	return Core.TemplateBracket(frame) .. Core.deprecatedCategory
end

-- Deprecated
function Core.luaBracket(_, args)
	return tostring(Core.MatchGroupById(args)) .. Core.deprecatedCategory
end

-- Unused entry point
-- Deprecated
function Core.matchlist(frame)
	return Core.TemplateMatchlist(frame) .. Core.deprecatedCategory
end

-- Deprecated
function Core.luaMatchlist(_, args)
	return tostring(Core.MatchGroupById(args)) .. Core.deprecatedCategory
end

-- Entry point from Template:ShowBracket and direct #invoke
-- Deprecated
function Core.Display(frame)
	return tostring(Core.TemplateShowBracket(frame)) .. Core.deprecatedCategory
end

-- Entry point from direct #invoke
-- Deprecated
function Core.DisplayDev(frame)
	local args = Arguments.getArgs(frame)
	args.dev = true
	return tostring(Core.TemplateShowBracket(args)) .. Core.deprecatedCategory
end

return Core
