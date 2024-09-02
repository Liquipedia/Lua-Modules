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
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local WarningBox = require('Module:WarningBox')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Match = Lua.import('Module:Match')
local MatchGroupBase = Lua.import('Module:MatchGroup/Base')
local MatchGroupConfig = Lua.requireIfExists('Module:MatchGroup/Config', {loadData = true})
local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local ShortenBracket = Lua.import('Module:MatchGroup/ShortenBracket')
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

-- The core module behind every type of MatchGroup. A MatchGroup is a collection of matches, such as a bracket or
-- a matchlist.
local MatchGroup = {}

-- Sets up a MatchList, a list of matches displayed vertically. The matches are saved to LPDB.
---@param args table
---@return string
function MatchGroup.MatchList(args)
	local options, optionsWarnings = MatchGroupBase.readOptions(args, 'matchlist')
	local matches = MatchGroupInput.readMatchlist(options.bracketId, args)
	Match.storeMatchGroup(matches, options)

	local matchlistNode
	if options.show then
		local MatchlistDisplay = Lua.import('Module:MatchGroup/Display/Matchlist')
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

-- Sets up a Bracket, a tree structure of matches. The matches are saved to LPDB.
---@param args table
---@return string
function MatchGroup.Bracket(args)
	local options, optionsWarnings = MatchGroupBase.readOptions(args, 'bracket')
	local matches, bracketWarnings = MatchGroupInput.readBracket(options.bracketId, args, options)
	Match.storeMatchGroup(matches, options)

	local bracketNode
	if options.show then
		local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket')
		local BracketContainer = WikiSpecific.getMatchGroupContainer('bracket')
		bracketNode = BracketContainer({
			bracketId = options.bracketId,
			config = BracketDisplay.configFromArgs(args),
		})
	end

	local parts = Array.extend(
		Array.map(optionsWarnings, WarningBox.display),
		Array.map(bracketWarnings or {}, WarningBox.display),
		{bracketNode}
	)
	return table.concat(Array.map(parts, tostring))
end

--- Sets up a MatchPage, which is a single match displayed on a standalone page. Also known as Standalone and BigMatch.
--- The match is saved to LPDB, but does not contain complete information. The tournament page is the primary source.
---@param args table
---@return Html
function MatchGroup.MatchPage(args)
	local function getBracketIdFromPage()
		local title = mw.title.getCurrentTitle().text

		-- Title format is `ID bracketID matchID`
		local titleParts = mw.text.split(title, ' ')

		-- Return bracketID and matchID
		return titleParts[2], titleParts[3]
	end

	local bracketId, matchId = getBracketIdFromPage()
	bracketId = args.bracketid or bracketId
	matchId = args.matchid or matchId
	local fullMatchId = bracketId .. '_' .. matchId

	local options = {storeMatch1 = false, storeMatch2 = true, storePageVar = true, bracketId = bracketId}
	local matches = MatchGroupInput.readMatchpage(bracketId, matchId, args)
	Match.storeMatchGroup(matches, options)

	local MatchPageContainer = WikiSpecific.getMatchContainer('matchpage')
	return MatchPageContainer{
		matchId = fullMatchId,
	}
end

-- Displays a matchlist or bracket specified by ID.
---@param args table
---@return Html
function MatchGroup.MatchGroupById(args)
	local bracketId = args.id or args[1]
	assert(bracketId, 'Missing bracket ID')

	if args.shortTemplate then
		bracketId = ShortenBracket.adjustMatchesAndBracketId{
			bracketId = bracketId,
			shortTemplate = args.shortTemplate,
		}
	end

	args.id = bracketId
	args[1] = bracketId

	local matches = MatchGroupUtil.fetchMatches(bracketId)
	assert(#matches ~= 0, 'No data found for bracketId=' .. bracketId)

	local matchGroupType = matches[1].bracketData.type

	if Logic.readBool(args.forceMatchList) then
		matchGroupType = 'matchlist'
		Array.forEach(matches, function(match)
			match.bracketData.header = match.bracketData.header
				and DisplayHelper.expandHeader(match.bracketData.header)[1] or nil
		end)
	end

	local config
	if matchGroupType == 'matchlist' then
		local MatchlistDisplay = Lua.import('Module:MatchGroup/Display/Matchlist')
		config = MatchlistDisplay.configFromArgs(args)
	else
		local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket')
		config = BracketDisplay.configFromArgs(args)
	end

	if Logic.readBool(args.suppressDetails) then
		config.matchHasDetails = function() return false end
	end

	Logic.wrapTryOrLog(MatchGroupInput.applyOverrideArgs)(matches, args)

	local MatchGroupContainer = WikiSpecific.getMatchGroupContainer(matchGroupType)
	return MatchGroupContainer({
		bracketId = bracketId,
		config = config,
	})
end

-- Displays a singleMatch specified by a bracket ID and matchID.
---@param args table
---@return Html
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

	local SingleMatchDisplay = Lua.import('Module:MatchGroup/Display/SingleMatch')
	local config = SingleMatchDisplay.configFromArgs(args)

	local MatchGroupContainer = WikiSpecific.getMatchContainer('singleMatch')
	return MatchGroupContainer({
		matchId = fullMatchId,
		config = config,
	})
end

-- Entry point of Template:Matchlist
---@param frame Frame
---@return string
function MatchGroup.TemplateMatchlist(frame)
	local args = Arguments.getArgs(frame)
	return MatchGroup.MatchList(args)
end

-- Entry point of Template:Bracket
---@param frame Frame
---@return string
function MatchGroup.TemplateBracket(frame)
	local args = Arguments.getArgs(frame)
	return MatchGroup.Bracket(args)
end

-- Entry point of Template:MatchPage
---@param frame Frame
---@return Html
function MatchGroup.TemplateMatchPage(frame)
	local args = Arguments.getArgs(frame)
	return MatchGroup.MatchPage(args)
end

-- Entry point of Template:ShowSingleMatch
---@param frame Frame
---@return Html
function MatchGroup.TemplateShowSingleMatch(frame)
	local args = Arguments.getArgs(frame)
	return MatchGroup.MatchByMatchId(args)
end

-- Entry point of Template:ShowBracket, Template:DisplayMatchGroup
---@param frame Frame
---@return Html
function MatchGroup.TemplateShowBracket(frame)
	local args = Arguments.getArgs(frame)
	return MatchGroup.MatchGroupById(args)
end

if FeatureFlag.get('perf') then
	MatchGroup.perfConfig = Table.getByPathOrNil(MatchGroupConfig, {'perf'})
end

Lua.autoInvokeEntryPoints(MatchGroup, 'Module:MatchGroup')

return MatchGroup
