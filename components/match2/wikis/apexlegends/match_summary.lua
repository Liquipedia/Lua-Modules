---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local SummaryHelper = Lua.import('Module:MatchSummary/Ffa')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class ApexMatchGroupUtilMatch: MatchGroupUtilMatch
---@field games ApexMatchGroupUtilGame[]

---@param props {bracketId: string, matchId: string}
---@return Widget
function CustomMatchSummary.getByMatchId(props)
	---@class ApexMatchGroupUtilMatch
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	match.matchPointThreshold = Table.extract(match.extradata.scoring, 'matchPointThreshold')
	CustomMatchSummary._opponents(match)
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

function CustomMatchSummary._opponents(match)
	-- Add games opponent data to the match opponent
	Array.forEach(match.opponents, function (opponent, idx)
		opponent.games = Array.map(match.games, function (game)
			return game.opponents[idx]
		end)
	end)

	if match.matchPointThreshold then
		Array.forEach(match.opponents, function(opponent)
			local matchPointReachedIn
			local sum = opponent.extradata.startingpoints or 0
			for gameIdx, game in ipairs(opponent.games) do
				if sum >= match.matchPointThreshold then
					matchPointReachedIn = gameIdx
					break
				end
				sum = sum + (game.score or 0)
			end
			opponent.matchPointReachedIn = matchPointReachedIn
		end)
	end

	-- Sort match level based on final placement & score
	Array.sortInPlaceBy(match.opponents, FnUtil.identity, SummaryHelper.placementSortFunction)

	-- Set the status of the current placement
	Array.forEach(match.opponents, function(opponent, idx)
		opponent.placementStatus = match.extradata.status[idx]
	end)
end

return CustomMatchSummary
