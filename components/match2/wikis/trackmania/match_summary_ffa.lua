---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:MatchSummary/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Lua = require('Module:Lua')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local SummaryHelper = Lua.import('Module:MatchSummary/Base/Ffa')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@param props {bracketId: string, matchId: string}
---@return Widget
function CustomMatchSummary.getByMatchId(props)
	---@class FFAMatchGroupUtilMatch
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	SummaryHelper.updateMatchOpponents(match)
	local scoringData = SummaryHelper.createScoringData(match)

	return HtmlWidgets.Fragment{children = {
		MatchSummaryWidgets.Header{matchId = match.matchId, games = match.games},
		MatchSummaryWidgets.Tab{
			matchId = match.matchId,
			idx = 0,
			children = {
				MatchSummaryWidgets.GamesSchedule{match = match},
				MatchSummaryWidgets.PointsDistribution{scores = scoringData},
				MatchSummaryWidgets.MatchComment{match = match},
				SummaryHelper.standardMatch(match),
			}
		}
	}}
end

return CustomMatchSummary
