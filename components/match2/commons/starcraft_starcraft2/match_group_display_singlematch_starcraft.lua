---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/SingleMatch/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local DisplayUtil = require('Module:DisplayUtil')
local Table = require('Module:Table')

local SingleMatchDisplay = Lua.import('Module:MatchGroup/Display/SingleMatch', {requireDevIfEnabled = true})
local StarcraftMatchSummary = Lua.import('Module:MatchSummary/Starcraft', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local StarcraftSingleMatchDisplay = {propTypes = {}}

function StarcraftSingleMatchDisplay.SingleMatchContainer(props)
	local bracketId, _ = MatchGroupUtil.splitMatchId(props.matchId)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(bracketId, props.matchId)

	return match
		and StarcraftSingleMatchDisplay.SingleMatch{
			match = match,
			config = Table.merge(props.config, {
				MatchSummaryContainer = StarcraftMatchSummary.MatchSummaryContainer,
			})
		}
		or ''
end

function StarcraftSingleMatchDisplay.SingleMatch(props)
	local singleMatchNode = SingleMatchDisplay.SingleMatch(props)

	return singleMatchNode
		:addClass(props.match.isFfa and 'ffa-match-summary' or nil)
end

--[[
Display component for a match in a singleMatch. Consists of the match summary.
]]
function SingleMatchDisplay.Match(props)
	DisplayUtil.assertPropTypes(props, SingleMatchDisplay.propTypes.Match)

	local matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
		bracketId = props.match.matchId:match('^(.*)_'), -- everything up to the final '_'
		matchId = props.match.matchId,
		config = {showScore = not props.match.noScore},
	})

	return matchSummaryNode
end

return StarcraftSingleMatchDisplay
