---
-- @autochess
-- wiki=underlords
-- page=Module:GameSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomGameSummary = {}

local Lua = require('Module:Lua')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local SummaryHelper = Lua.import('Module:MatchSummary/Ffa')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')

---@class AutochessMatchGroupUtilGame: MatchGroupUtilGame
---@field stream table

---@param props {bracketId: string, matchId: string, gameIdx: integer}
---@return Html
function CustomGameSummary.getGameByMatchId(props)
	---@class ApexMatchGroupUtilMatch
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)

	local game = match.games[props.gameIdx]
	assert(game, 'Error Game ID ' .. tostring(props.gameIdx) .. ' not found')

	game.stream = match.stream

	SummaryHelper.updateGameOpponents(game, match.opponents)
	local scoringData = SummaryHelper.createScoringData(match)

	return MatchSummaryWidgets.Tab{
		matchId = match.matchId,
		idx = props.gameIdx,
		children = {
			MatchSummaryWidgets.GameDetails{game = game},
			MatchSummaryWidgets.PointsDistribution{scores = scoringData},
			SummaryHelper.standardGame(game)
		}
	}
end

return CustomGameSummary
