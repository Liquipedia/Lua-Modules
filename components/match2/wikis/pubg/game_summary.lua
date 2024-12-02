---
-- @Liquipedia
-- wiki=pubg
-- page=Module:GameSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomGameSummary = {}

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Table = require('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local SummaryHelper = Lua.import('Module:MatchSummary/Ffa')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class PubgMatchGroupUtilGame: MatchGroupUtilGame
---@field stream table

---@param props {bracketId: string, matchId: string, gameIdx: integer}
---@return Html
function CustomGameSummary.getGameByMatchId(props)
	---@class ApexMatchGroupUtilMatch
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)

	local game = match.games[props.gameIdx]
	assert(game, 'Error Game ID ' .. tostring(props.gameIdx) .. ' not found')

	game.stream = match.stream

	CustomGameSummary._opponents(game, match.opponents)
	local scoringData = SummaryHelper.createScoringData(match)

	return MatchSummaryWidgets.Tab{
		matchId = match.matchId,
		idx = props.gameIdx,
		children = {
			CustomGameSummary._createGameDetails(game),
			MatchSummaryWidgets.PointsDistribution{killScore = scoringData.kill, placementScore = scoringData.placement},
			SummaryHelper.standardGame(game)
		}
	}
end

---@param game table
---@return Widget
function CustomGameSummary._createGameDetails(game)
	return MatchSummaryWidgets.ContentItemContainer{contentClass = 'panel-content__game-schedule',
		items = {
			{
				icon = MatchSummaryWidgets.CountdownIcon{game = game},
				content = MatchSummaryWidgets.GameCountdown{game = game},
			},
			game.map and {
				icon = IconWidget{iconName = 'map'},
				content = HtmlWidgets.Span{children = Page.makeInternalLink(game.map)},
			} or nil,
		}
	}
end

---@param game table
---@param matchOpponents table[]
function CustomGameSummary._opponents(game, matchOpponents)
	-- Add match opponent data to game opponent
	game.opponents = Array.map(game.opponents,
		function(gameOpponent, opponentIdx)
			local matchOpponent = matchOpponents[opponentIdx]
			local newGameOpponent = Table.merge(matchOpponent, gameOpponent)
			-- These values are only allowed to come from Game and not Match
			newGameOpponent.placement = gameOpponent.placement
			newGameOpponent.score = gameOpponent.score
			newGameOpponent.status = gameOpponent.status
			return newGameOpponent
		end
	)

	-- Sort game level based on placement
	Array.sortInPlaceBy(game.opponents, FnUtil.identity, SummaryHelper.placementSortFunction)
end

return CustomGameSummary
