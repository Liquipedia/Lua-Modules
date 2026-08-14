---
-- @Liquipedia
-- page=Module:MatchGroup/Display/Horizontallist
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Date = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local Html = Lua.import('Module:Widget/Html')
local Builder = Lua.import('Module:Widget/Builder')
local ErrorBoundary = Lua.import('Module:Widget/ErrorBoundary')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

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
---@return VNode
function HorizontallistDisplay.BracketContainer(props)
	return HorizontallistDisplay.Bracket{
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId),
		bracketId = props.bracketId,
		config = props.config,
	}
end

---Display component for a tournament bracket.
---Match data is specified in the input.
---@param props HorizontallistBracket
---@return VNode
function HorizontallistDisplay.Bracket(props)
	local config = {
		MatchSummaryContainer = DisplayHelper.DefaultFfaMatchSummaryContainer,
	}

	local sortedBracket = HorizontallistDisplay._sortMatches(props.bracket)
	local selectedMatchIdx = HorizontallistDisplay.findMatchClosestInTime(props.bracketId, sortedBracket)

	local bracketNode = Html.Div{
		classes = {
			'navigation-tabs',
			-- Do not show the tabs if there is only one match
			#sortedBracket == 1 and 'is--hidden' or nil,
		},
		attributes = {
			['data-js-battle-royale'] = 'navigation',
			role = 'tabpanel',
		},
		children = Html.Ul{
			classes = {'navigation-tabs__list'},
			attributes = {role = 'tablist'},
			children = Array.map(HorizontallistDisplay.computeHeaders(sortedBracket), function (header, index)
				local attachedMatch = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, sortedBracket[index][1])
				local _, matchId = MatchGroupUtil.splitMatchId(attachedMatch.matchId)
				---@cast matchId -nil
				--- If it's a matchList, then matchId is valid as is (also is numeric), otherwise we need to convert it to a key
				local matchKey = Logic.isNumeric(matchId) and matchId or MatchGroupUtil.matchIdToKey(matchId)
				return HorizontallistDisplay.NodeHeader{
					header = header,
					index = index,
					status = MatchGroupUtil.computeMatchPhase(attachedMatch),
					matchId = matchKey,
				}
			end)
		},
	}

	local matchNode = Html.Div{
		classes = {'navigation-content-container'},
		children = Array.map(sortedBracket, function (match, matchIndex)
			local matchProps = {
				MatchSummaryContainer = config.MatchSummaryContainer,
				matchId = match[1],
				index = matchIndex,
			}
			return HorizontallistDisplay.Match(matchProps)
		end)
	}

	 return Html.Div{
		classes = {'brkts-br-wrapper', 'battle-royale'},
		attributes = {
			['data-js-battle-royale-id'] = props.bracketId,
			['data-js-battle-royale-init-tab'] = selectedMatchIdx - 1, -- Convert to 0-index
		},
		children = {
			bracketNode,
			matchNode,
		}
	 }
end

---@param bracketId string
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

	-- Suffix when there multiple matches with the same header, in order to make a distinction between them
	return Array.flatMap(headers, function(headerGroup)
		if #headerGroup == 1 then
			local header = headerGroup[1].inheritedHeader or 'Match'
			return DisplayHelper.expandHeader(header)[1]
		end
		return Array.map(headerGroup, function (match, index)
			local header = match.inheritedHeader or 'Match'
			return DisplayHelper.expandHeader(header)[1] .. ' #' .. index
		end)
	end)
end

--- Display component for the headers of a node in the bracket tree.
--- Draws a row of headers for the match, everything to the left of it, and for the qualification spots.
---@param props {index: integer, header: string, status: 'upcoming'|'ongoing'|'finished', matchId: string}
---@return VNode?
function HorizontallistDisplay.NodeHeader(props)
	if not props.header then
		return nil
	end

	local iconData = PHASE_ICONS[props.status] or {}
	local icon = IconFa{
		iconName = iconData.iconName,
		color = iconData.color,
		additionalClasses = {'navigation-tabs__list-item-icon'}
	}

	return Html.Li{
		classes = {'navigation-tabs__list-item'},
		attributes = {
			['data-target-id'] = 'navigationContent' .. props.index,
			role = 'tab',
			tabindex = '0',
			['data-js-battle-royale'] = 'navigation-tab',
			['data-js-battle-royale-matchid'] = props.matchId,
		},
		children = {
			icon,
			props.header,
		}
	}
end

---Display component for a match
---@param props {matchId: string, index: integer, MatchSummaryContainer: function}
---@return VNode
function HorizontallistDisplay.Match(props)
	local bracketId = MatchGroupUtil.splitMatchId(props.matchId)

	return Html.Div{
		classes = {'navigation-content'},
		attributes = {
			['data-js-battle-royale-content-id'] = 'navigationContent' .. props.index,
		},
		children = ErrorBoundary{
			children = Builder{builder = function ()
				return props.MatchSummaryContainer{
					bracketId = bracketId,
					matchId = props.matchId,
				}
			end},
			fallback = Lua.import('Module:Error/Display').ErrorDetails
		}
	}
end

return HorizontallistDisplay
