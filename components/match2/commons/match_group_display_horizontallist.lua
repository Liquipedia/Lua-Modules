---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/Horizontallist
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Date = require('Module:Date/Ext')
local DisplayUtil = require('Module:DisplayUtil')
local FnUtil = require('Module:FnUtil')
local Icon = require('Module:Icon')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local HorizontallistDisplay = {propTypes = {}, types = {}}

local PHASE_ICONS = {
	finished = {iconName = 'concluded', color = 'icon--green'},
	ongoing = {iconName = 'live', color = 'icon--red'},
	upcoming = {iconName = 'upcomingandongoing'},
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
	local config = {
		MatchSummaryContainer = DisplayHelper.DefaultMatchSummaryContainer,
	}
	local list = mw.html.create('ul'):addClass('navigation-tabs__list'):attr('role', 'tablist')

	local sortedBracket = HorizontallistDisplay._sortMatches(props.bracket)
	local selectedMatchIdx = HorizontallistDisplay.findMatchClosestInTime(props.bracketId, sortedBracket)

	for index, header in ipairs(HorizontallistDisplay.computeHeaders(sortedBracket)) do
		local attachedMatch = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, sortedBracket[index][1])
		local nodeProps = {
			header = header,
			index = index,
			status = MatchGroupUtil.computeMatchPhase(attachedMatch),
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
			:attr('data-js-battle-royale-init-tab', selectedMatchIdx - 1) -- Convert to 0-index
			:node(bracketNode)
			:node(matchNode)
end

---@param bracket [string, MatchGroupUtilBracketBracketData][]
---@return integer
function HorizontallistDisplay.findMatchClosestInTime(bracketId, bracket)
	local now = Date.getCurrentTimestamp()
	local liveGames = {} ---@type {matchIdx: integer, distanceToNow: integer}[]
	local otherGames = {} ---@type {matchIdx: integer, distanceToNow: integer}[]
	for matchIdx, matchInfo in ipairs(bracket) do
		local match = MatchGroupUtil.fetchMatchForBracketDisplay(bracketId, matchInfo[1])
		for _, game in ipairs(match.games) do
			local tblToInsertInto = MatchGroupUtil.computeMatchPhase(game) == 'live' and liveGames or otherGames
			local ts = Date.readTimestampOrNil(game.date)
			table.insert(tblToInsertInto, {
				matchIdx = matchIdx,
				distanceToNow = math.abs(now - ts),
			})
		end
	end

	local function sortFunction(g1, g2)
		if g1.distanceToNow == g2.distanceToNow then
			return g1.matchIdx < g2.matchIdx
		end
		return g1.distanceToNow < g2.distanceToNow
	end

	-- Live games are always considered the "closest" if there are any.
	-- Pick the match with the game that's been live the longest.
	if #liveGames > 0 then
		Array.sortInPlaceBy(liveGames, FnUtil.identity, sortFunction)
		return liveGames[#liveGames].matchIdx
	end

	-- If no games are live, we find the one closest to current time by absolute metric
	if #otherGames > 0 then
		Array.sortInPlaceBy(otherGames, FnUtil.identity, sortFunction)
		return otherGames[1].matchIdx
	end

	return 1
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
			local header = headerGroup[1].inheritedHeader or 'Match'
			return DisplayHelper.expandHeader(header)[1]
		end
		return Array.map(headerGroup, function (match, index)
			local header = match.inheritedHeader or 'Match'
			return DisplayHelper.expandHeader(header)[1] .. ' #' .. index
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

	local iconData = PHASE_ICONS[props.status] or {}
	local icon = Icon.makeIcon{
		iconName = iconData.iconName,
		color = iconData.color,
		additionalClasses = {'navigation-tabs__list-item-icon'}
	}

	return mw.html.create('li')
			:node(icon)
			:addClass('navigation-tabs__list-item')
			:attr('data-target-id', 'navigationContent' .. props.index)
			:attr('role', 'tab')
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

	local bracketId = MatchGroupUtil.splitMatchId(props.matchId)
	local matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
		bracketId = bracketId,
		matchId = props.matchId,
	}, require('Module:Error/Display').ErrorDetails)
	matchNode:node(matchSummaryNode)

	return matchNode
end

return Class.export(HorizontallistDisplay)
