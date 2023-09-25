---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/BracketAsList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local BracketListDisplay = {propTypes = {}, types = {}}

function BracketListDisplay.configFromArgs(args)
	return {
		forceShortName = Logic.readBoolOrNil(args.forceShortName),
		opponentHeight = tonumber(args.opponentHeight),
	}
end

BracketListDisplay.types.BracketConfig = TypeUtil.struct({
	MatchSummaryContainer = 'function',
	OpponentEntry = 'function',
	forceShortName = 'boolean',
})
BracketListDisplay.types.BracketConfigOptions = TypeUtil.struct(
	Table.mapValues(BracketListDisplay.types.BracketConfig.struct, TypeUtil.optional)
)

BracketListDisplay.propTypes.BracketContainer = {
	bracketId = 'string',
	config = TypeUtil.optional(BracketListDisplay.types.BracketConfigOptions),
}

--[[
Display component for a tournament bracket. The bracket is specified by ID.
The component fetches the match data from LPDB or page variables.
]]
function BracketListDisplay.BracketContainer(props)
	DisplayUtil.assertPropTypes(props, BracketListDisplay.propTypes.BracketContainer)
	return BracketListDisplay.Bracket({
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId),
		config = props.config,
	})
end

BracketListDisplay.propTypes.Bracket = {
	bracket = MatchGroupUtil.types.MatchGroup,
	config = TypeUtil.optional(BracketListDisplay.types.BracketConfigOptions),
}

--[[
Display component for a tournament bracket. Match data is specified in the
input.
]]
function BracketListDisplay.Bracket(props)
	DisplayUtil.assertPropTypes(props, BracketListDisplay.propTypes.Bracket)

	local defaultConfig = DisplayHelper.getGlobalConfig()
	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
		OpponentEntry = propsConfig.OpponentEntry or OpponentDisplay.BracketOpponentEntry,
		forceShortName = propsConfig.forceShortName or defaultConfig.forceShortName,
	}
	local list = mw.html.create('ul'):addClass('navigation-tabs__list'):attr('role', 'tablist')

	for idx, header in ipairs(BracketListDisplay.computeHeaders(props.bracket, config)) do
		local nodeProps = {
			config = config,
			header = header,
			index = idx,
		}
		list:node(BracketListDisplay.NodeHeader(nodeProps))
	end
	local bracketNode = mw.html.create('div'):addClass('navigation-tabs'):attr('role', 'tabpanel'):node(list)

	local matchNode = mw.html.create('div'):addClass('navigation-content-container')
	for idx, match in ipairs(BracketListDisplay._sortMatches(props.bracket)) do
		local matchProps = {
			MatchSummaryContainer = config.MatchSummaryContainer,
			OpponentEntry = config.OpponentEntry,
			forceShortName = config.forceShortName,
			match = match[2],
			matchId = match[1],
			index = idx,
		}
		matchNode:node(BracketListDisplay.Match(matchProps))
	end

	return mw.html.create('div'):addClass('brkts-br-wrapper'):node(bracketNode):node(matchNode)
end

function BracketListDisplay._sortMatches(bracket)
	local matchOrder = function(match1, match2)
		if not match1[2].coordinates then
			return match1[2].matchId < match2[2].matchId
		end
		if match1[2].coordinates.roundIndex == match2[2].coordinates.roundIndex then
			return match1[2].coordinates.matchIndexInRound < match2[2].coordinates.matchIndexInRound
		end
		return match1[2].coordinates.roundIndex < match2[2].coordinates.roundIndex
	end

	mw.logObject(bracket)
	return Array.sortBy(Table.entries(bracket.bracketDatasById or bracket.matchesById), FnUtil.identity, matchOrder)
end

function BracketListDisplay.computeHeaders(bracket, config)
	-- Group by inheritedHeader
	local headers = Array.groupAdjacentBy(
		Array.map(BracketListDisplay._sortMatches(bracket), Operator.property(2)),
		Operator.property('inheritedHeader')
	)

	-- Suffix headers with multiple match with indication which match is it
	headers = Array.map(headers, function(headerGroup)
		mw.logObject(headerGroup)
		if #headerGroup == 1 then
			return DisplayHelper.expandHeader(headerGroup[1].inheritedHeader or headerGroup[1].bracketData.header)[1]
		end
		return Array.map(headerGroup, function (match, index)
			return DisplayHelper.expandHeader(match.inheritedHeader or match.bracketData.header)[1] .. ' #' .. index
		end)
	end)

	return Array.flatten(headers)
end

BracketListDisplay.propTypes.NodeHeader = {
	config = BracketListDisplay.types.BracketConfig,
	layoutsByMatchId = TypeUtil.table('string', BracketListDisplay.types.Layout),
	matchId = 'string',
	matchesById = TypeUtil.table('string', MatchGroupUtil.types.Match),
}

--[[
Display component for the headers of a node in the bracket tree. Draws a row of
headers for the match, everything to the left of it, and for the qualification
spots.
]]
function BracketListDisplay.NodeHeader(props)
	DisplayUtil.assertPropTypes(props, BracketListDisplay.propTypes.NodeHeader)
	if not props.header then
		return nil
	end

	local isSelected = props.index == 1

	return mw.html.create('li')
			:addClass('navigation-tabs__list-item')
			:addClass(isSelected and 'tab--active' or nil)
			:attr('role', 'tab')
			:attr('aria-selected', tostring(isSelected))
			:attr('aria-controls', 'panel' .. props.index)
			:attr('tabindex', '0')
			:wikitext(props.header)
end

BracketListDisplay.propTypes.Match = {
	OpponentEntry = 'function',
	MatchSummaryContainer = 'function',
	match = MatchGroupUtil.types.Match,
	matchId = 'string',
	forceShortName = 'boolean',
	matchHasDetails = 'function',
}

--[[
Display component for a match
]]
function BracketListDisplay.Match(props)
	DisplayUtil.assertPropTypes(props, BracketListDisplay.propTypes.Match)
	local matchNode = mw.html.create('div')
			:addClass('navigation-content')
			:attr('id', 'navigationContent' .. props.index)
			:addClass(props.index > 1 and 'is--hidden' or nil)

	local matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
		bracketId = props.matchId:match('^(.*)_'), -- everything up to the final '_'
		matchId = props.matchId,
	})
	matchNode:node(matchSummaryNode)

	return matchNode
end

return Class.export(BracketListDisplay)
