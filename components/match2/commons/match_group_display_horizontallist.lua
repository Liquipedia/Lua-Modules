---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/Horizontallist
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

local HorizontallistDisplay = {propTypes = {}, types = {}}

---@class HorizontallistConfig
---@field forceShortName boolean
---@field MatchSummaryContainer function
---@field OpponentEntry function

---@class HorizontallistConfigOptions
---@field forceShortName boolean?

---@class HorizontallistProps
---@field bracketId string
---@field config HorizontallistConfigOptions?

---@class HorizontallistBracket
---@field bracket MatchGroupUtilMatchGroup
---@field config HorizontallistConfigOptions?

---@param args table
---@return HorizontallistConfigOptions
function HorizontallistDisplay.configFromArgs(args)
	return {
		forceShortName = Logic.readBoolOrNil(args.forceShortName),
	}
end

HorizontallistDisplay.types.BracketConfig = TypeUtil.struct({
	MatchSummaryContainer = 'function',
	OpponentEntry = 'function',
	forceShortName = 'boolean',
})
HorizontallistDisplay.types.BracketConfigOptions = TypeUtil.struct(
	Table.mapValues(HorizontallistDisplay.types.BracketConfig.struct, TypeUtil.optional)
)

HorizontallistDisplay.propTypes.BracketContainer = {
	bracketId = 'string',
	config = TypeUtil.optional(HorizontallistDisplay.types.BracketConfigOptions),
}

---Display component for a tournament bracket. The bracket is specified by ID.
---The component fetches the match data from LPDB or page variables.
---@param props HorizontallistProps
---@return Html
function HorizontallistDisplay.BracketContainer(props)
	DisplayUtil.assertPropTypes(props, HorizontallistDisplay.propTypes.BracketContainer)
	return HorizontallistDisplay.Bracket({
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId),
		config = props.config,
	})
end

HorizontallistDisplay.propTypes.Bracket = {
	bracket = MatchGroupUtil.types.MatchGroup,
	config = TypeUtil.optional(HorizontallistDisplay.types.BracketConfigOptions),
}

---Display component for a tournament bracket.
---Match data is specified in the input.
---@param props HorizontallistBracket
---@return Html
function HorizontallistDisplay.Bracket(props)
	DisplayUtil.assertPropTypes(props, HorizontallistDisplay.propTypes.Bracket)

	local defaultConfig = DisplayHelper.getGlobalConfig()
	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = DisplayHelper.DefaultMatchSummaryContainer,
		OpponentEntry = OpponentDisplay.BracketOpponentEntry,
		forceShortName = propsConfig.forceShortName or defaultConfig.forceShortName,
	}
	local list = mw.html.create('ul'):addClass('navigation-tabs__list'):attr('role', 'tablist')

	for headerIndex, header in ipairs(HorizontallistDisplay.computeHeaders(props.bracket, config)) do
		local nodeProps = {
			config = config,
			header = header,
			index = headerIndex,
		}
		list:node(HorizontallistDisplay.NodeHeader(nodeProps))
	end

	local bracketNode = mw.html.create('div')
			:addClass('navigation-tabs')
			:attr('data-js-battle-royale', 'navigation-tabs')
			:attr('role', 'tabpanel')
			:node(list)

	local matchNode = mw.html.create('div'):addClass('navigation-content-container')
	for matchIndex, match in ipairs(HorizontallistDisplay._sortMatches(props.bracket)) do
		local matchProps = {
			MatchSummaryContainer = config.MatchSummaryContainer,
			OpponentEntry = config.OpponentEntry,
			forceShortName = config.forceShortName,
			match = match[2],
			matchId = match[1],
			index = matchIndex,
		}
		matchNode:node(HorizontallistDisplay.Match(matchProps))
	end

	return mw.html.create('div'):addClass('brkts-br-wrapper'):node(bracketNode):node(matchNode)
end

---@param bracket MatchGroupUtilMatchGroup
---@return MatchGroupUtilMatchGroup
function HorizontallistDisplay._sortMatches(bracket)
	local matchOrder = function(match1, match2)
		if not match1[2].coordinates then
			return match1[2].matchIndex < match2[2].matchIndex
		end
		if match1[2].coordinates.roundIndex == match2[2].coordinates.roundIndex then
			return match1[2].coordinates.matchIndexInRound < match2[2].coordinates.matchIndexInRound
		end
		return match1[2].coordinates.roundIndex < match2[2].coordinates.roundIndex
	end

	return Array.sortBy(Table.entries(bracket.bracketDatasById), FnUtil.identity, matchOrder)
end

---@param bracket MatchGroupUtilMatchGroup
---@param config HorizontallistConfig
---@return string[]
function HorizontallistDisplay.computeHeaders(bracket, config)
	-- Group by inheritedHeader
	local headers = Array.groupAdjacentBy(
		Array.map(HorizontallistDisplay._sortMatches(bracket), Operator.property(2)),
		Operator.property('inheritedHeader')
	)

	-- Suffix when there multiple matches with the same header, in order to make a distiction between them
	headers = Array.map(headers, function(headerGroup)
		if #headerGroup == 1 then
			return DisplayHelper.expandHeader(headerGroup[1].inheritedHeader)[1]
		end
		return Array.map(headerGroup, function (match, index)
			return DisplayHelper.expandHeader(match.inheritedHeader)[1] .. ' #' .. index
		end)
	end)

	return Array.flatten(headers)
end

HorizontallistDisplay.propTypes.NodeHeader = {
	config = HorizontallistDisplay.types.BracketConfig,
	layoutsByMatchId = TypeUtil.table('string', HorizontallistDisplay.types.Layout),
	matchId = 'string',
	matchesById = TypeUtil.table('string', MatchGroupUtil.types.Match),
}

--- Display component for the headers of a node in the bracket tree.
--- Draws a row of headers for the match, everything to the left of it, and for the qualification spots.
---@param props table #TODO
---@return Html?
function HorizontallistDisplay.NodeHeader(props)
	DisplayUtil.assertPropTypes(props, HorizontallistDisplay.propTypes.NodeHeader)
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
			:attr('data-js-battle-royale', 'navigation-tab')
			:wikitext(props.header)
end

HorizontallistDisplay.propTypes.Match = {
	OpponentEntry = 'function',
	MatchSummaryContainer = 'function',
	match = MatchGroupUtil.types.Match,
	matchId = 'string',
	forceShortName = 'boolean',
	matchHasDetails = 'function',
}

---Display component for a match
---@param props table #TODO
---@return Html
function HorizontallistDisplay.Match(props)
	DisplayUtil.assertPropTypes(props, HorizontallistDisplay.propTypes.Match)
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

return Class.export(HorizontallistDisplay)
