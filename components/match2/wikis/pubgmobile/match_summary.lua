---
-- @Liquipedia
-- wiki=pubgmobile
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local SummaryHelper = Lua.import('Module:MatchSummary/Ffa')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class PubgmMatchGroupUtilMatch: MatchGroupUtilMatch
---@field games ApexMatchGroupUtilGame[]

---@param props {bracketId: string, matchId: string}
---@return Widget
function CustomMatchSummary.getByMatchId(props)
	---@class ApexMatchGroupUtilMatch
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	CustomMatchSummary._opponents(match)
	local scoringData = SummaryHelper.createScoringData(match)

	return HtmlWidgets.Fragment{children = {
		MatchSummaryWidgets.Header{matchId = match.matchId, games = match.games},
		MatchSummaryWidgets.Tab{
			matchId = match.matchId,
			idx = 0,
			children = {
				CustomMatchSummary._createSchedule(match),
				MatchSummaryWidgets.PointsDistribution{killScore = scoringData.kill, placementScore = scoringData.placement},
				SummaryHelper.standardMatch(match),
			}
		}
	}}
end

---@param match table
function CustomMatchSummary._opponents(match)
	-- Add games opponent data to the match opponent
	Array.forEach(match.opponents, function (opponent, idx)
		opponent.games = Array.map(match.games, function (game)
			return game.opponents[idx]
		end)
	end)

	-- Sort match level based on final placement & score
	Array.sortInPlaceBy(match.opponents, FnUtil.identity, SummaryHelper.placementSortFunction)

	-- Set the status of the current placement
	Array.forEach(match.opponents, function(opponent, idx)
		opponent.placementStatus = match.extradata.status[idx]
	end)
end

---@param match table
---@return Widget
function CustomMatchSummary._createSchedule(match)
	return MatchSummaryWidgets.ContentItemContainer{collapsed = true, collapsible = true, title = 'Schedule', children = {
		HtmlWidgets.Ul{
			classes = {'panel-content__game-schedule'},
			children = Array.map(match.games, function (game, idx)
				return HtmlWidgets.Li{
					children = {
						HtmlWidgets.Span{
							children = MatchSummaryWidgets.CountdownIcon{
								game = game,
								additionalClasses = {'panel-content__game-schedule__icon'}
							},
						},
						HtmlWidgets.Span{
							classes = {'panel-content__game-schedule__title'},
							children = 'Game ' .. idx .. ':',
						},
						HtmlWidgets.Div{
							classes = {'panel-content__game-schedule__container'},
							children = SummaryHelper.gameCountdown(game),
						},
					},
				}
			end)
		}
	}}
end

return CustomMatchSummary
