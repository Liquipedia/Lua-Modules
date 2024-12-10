---
-- @Liquipedia
-- wiki=fortnite
-- page=Module:GameSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomGameSummary = {}

local Lua = require('Module:Lua')
local Page = require('Module:Page')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local SummaryHelper = Lua.import('Module:MatchSummary/Ffa')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class FortniteMatchGroupUtilGame: MatchGroupUtilGame
---@field stream table

---@param props {bracketId: string, matchId: string, gameIdx: integer}
---@return Html
function CustomGameSummary.getGameByMatchId(props)
	---@class FortniteMatchGroupUtilMatch
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
			CustomGameSummary._createGameDetails(game),
			MatchSummaryWidgets.PointsDistribution{scores = scoringData},
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

return CustomGameSummary
