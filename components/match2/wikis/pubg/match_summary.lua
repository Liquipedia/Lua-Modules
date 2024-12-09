---
-- @Liquipedia
-- wiki=pubg
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Lua = require('Module:Lua')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local SummaryHelper = Lua.import('Module:MatchSummary/Ffa')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class PubgMatchGroupUtilMatch: MatchGroupUtilMatch
---@field games PubgMatchGroupUtilGame[]

---@param props {bracketId: string, matchId: string}
---@return Widget
function CustomMatchSummary.getByMatchId(props)
	---@class PubgMatchGroupUtilMatch
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	SummaryHelper.updateMatchOpponents(match)
	local scoringData = SummaryHelper.createScoringData(match)

	return HtmlWidgets.Fragment{children = {
		MatchSummaryWidgets.Header{matchId = match.matchId, games = match.games},
		MatchSummaryWidgets.Tab{
			matchId = match.matchId,
			idx = 0,
			children = {
				MatchSummaryWidgets.GamesSchedule{games = match.games},
				MatchSummaryWidgets.PointsDistribution{scores = scoringData},
				SummaryHelper.standardMatch(match),
			}
		}
	}}
end

return CustomMatchSummary
