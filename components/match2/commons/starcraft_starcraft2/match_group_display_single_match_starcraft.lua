---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/SingleMatch/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local DisplayUtil = require('Module:DisplayUtil')
local Table = require('Module:Table')

local SingleMatchDisplay = Lua.import('Module:MatchGroup/Display/SingleMatch')
local StarcraftMatchSummary = Lua.import('Module:MatchSummary/Starcraft')
local StarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Starcraft')

local StarcraftSingleMatchDisplay = Class.new(SingleMatchDisplay)

---@param props {matchId: string, config: SingleMatchConfigOptions}
---@return Html
function StarcraftSingleMatchDisplay.SingleMatchContainer(props)
	local bracketId, _ = StarcraftMatchGroupUtil.splitMatchId(props.matchId)

	assert(bracketId, 'Missing or invalid matchId')

	local match = StarcraftMatchGroupUtil.fetchMatchForBracketDisplay(bracketId, props.matchId)

	return match
		and StarcraftSingleMatchDisplay.SingleMatch{
			match = match,
			config = Table.merge(props.config, {
				MatchSummaryContainer = StarcraftMatchSummary.MatchSummaryContainer,
			})
		}
		or ''
end

---@param props {config: SingleMatchConfigOptions, match: StarcraftMatchGroupUtilMatch}
---@return Html
function StarcraftSingleMatchDisplay.SingleMatch(props)
	local singleMatchNode = SingleMatchDisplay.SingleMatch(props)

	return singleMatchNode
		:addClass(props.match.isFfa and 'ffa-match-summary' or nil)
end

---Display component for a match in a singleMatch. Consists of the match summary.
---@param props {MatchSummaryContainer: function, match: StarcraftMatchGroupUtilMatch}
---@return Html
function StarcraftSingleMatchDisplay.Match(props)
	local bracketId = StarcraftMatchGroupUtil.splitMatchId(props.match.matchId)
	return DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
		bracketId = bracketId,
		matchId = props.match.matchId,
		config = {showScore = not props.match.noScore},
	}, require('Module:Error/Display').ErrorDetails)
end

return StarcraftSingleMatchDisplay
