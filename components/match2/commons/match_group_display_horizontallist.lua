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
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local HorizontallistDisplay = {propTypes = {}, types = {}}

local STATUS_ICONS = {
	finished = Icon.makeIcon{iconName = 'concluded', color = 'icon--green', size = 'initial'},
	live = Icon.makeIcon{iconName = 'live', color = 'icon--red', size = 'initial'},
	upcoming = Icon.makeIcon{iconName = 'upcomingandongoing', size = 'initial'},
}

---@class HorizontallistConfig
---@field MatchSummaryContainer function

---@class HorizontallistConfigOptions

---@class HorizontallistProps
---@field bracketId string
---@field config HorizontallistConfigOptions?

---@class HorizontallistBracket
---@field bracket MatchGroupUtilMatchGroup
---@field config HorizontallistConfigOptions?
---@field bracketId string

---@param args table
---@return HorizontallistConfigOptions
function HorizontallistDisplay.configFromArgs(args)
	return {}
end

---Display component for a tournament bracket. The bracket is specified by ID.
---The component fetches the match data from LPDB or page variables.
---@param props HorizontallistProps
---@return Html
function HorizontallistDisplay.BracketContainer(props)
	return HorizontallistDisplay.Bracket({
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId),
		bracketId = props.bracketId,
		config = props.config,
	})
end

---Display component for a tournament bracket.
---Match data is specified in the input.
---@param props HorizontallistBracket
---@return Html
function HorizontallistDisplay.Bracket(props)
	local defaultConfig = DisplayHelper.getGlobalConfig()
	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = DisplayHelper.DefaultMatchSummaryContainer,
	}
	local list = mw.html.create('ul'):addClass('navigation-tabs__list'):attr('role', 'tablist')

	local sortedBracket = HorizontallistDisplay._sortMatches(props.bracket)

	for index, header in ipairs(HorizontallistDisplay.computeHeaders(sortedBracket)) do
		local nodeProps = {
			header = header,
			index = index,
			status = MatchGroupUtil.calculateMatchPhase(MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, sortedBracket[index][1])),
		}
		list:node(HorizontallistDisplay.NodeHeader(nodeProps))
	end

	local bracketNode = mw.html.create('div')
			:addClass('navigation-tabs')
			:attr('data-js-battle-royale', 'navigation')
			:attr('role', 'tabpanel')
			:node(list)

	local matchNode = mw.html.create('div'):addClass('navigation-content-container')
	for matchIndex, match in ipairs(sortedBracket) do
		local matchProps = {
			MatchSummaryContainer = config.MatchSummaryContainer,
			matchId = match[1],
			index = matchIndex,
		}
		matchNode:node(HorizontallistDisplay.Match(matchProps))
	end

	return mw.html.create('div')
			:addClass('brkts-br-wrapper battle-royale')
			:attr('data-js-battle-royale-id', props.bracketId)
			:node(bracketNode)
			:node(matchNode)
end

---@param bracket MatchGroupUtilMatchGroup
---@return [string, MatchGroupUtilBracketBracketData][]
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

---@param sortedBracket [string, MatchGroupUtilBracketBracketData][]
---@return string[]
function HorizontallistDisplay.computeHeaders(sortedBracket)
	-- Group by inheritedHeader
	local headers = Array.groupAdjacentBy(
		Array.map(sortedBracket, Operator.property(2)),
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

--- Display component for the headers of a node in the bracket tree.
--- Draws a row of headers for the match, everything to the left of it, and for the qualification spots.
---@param props {index: integer, header: string, status: 'upcoming'|'live'|'finished'|nil}
---@return Html?
function HorizontallistDisplay.NodeHeader(props)
	if not props.header then
		return nil
	end

	local isSelected = props.index == 1

	return mw.html.create('li')
			:node(mw.html.create('span'):addClass('navigation-tabs__list-item-icon'):node(STATUS_ICONS[props.status]))
			:addClass('navigation-tabs__list-item')
			:attr('data-target-id', 'navigationContent' .. props.index)
			:attr('role', 'tab')
			:attr('aria-selected', tostring(isSelected))
			:attr('aria-controls', 'panel' .. props.index)
			:attr('tabindex', '0')
			:attr('data-js-battle-royale', 'navigation-tab')
			:wikitext(props.header)
end

---Display component for a match
---@param props {matchId: string, index: integer, MatchSummaryContainer: function}
---@return Html
function HorizontallistDisplay.Match(props)
	local matchNode = mw.html.create('div')
			:addClass('navigation-content')
			:attr('data-js-battle-royale-content-id', 'navigationContent' .. props.index)

	local matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
		bracketId = props.matchId:match('^(.*)_'), -- everything up to the final '_'
		matchId = props.matchId,
	})
	matchNode:node(matchSummaryNode)

	return matchNode
end

return Class.export(HorizontallistDisplay)
