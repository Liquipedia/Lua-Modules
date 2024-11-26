---
-- @Liquipedia
-- wiki=pubgmobile
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
local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local SummaryHelper = Lua.import('Module:MatchSummary/Ffa')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class PubgmMatchGroupUtilGame: MatchGroupUtilGame
---@field stream table

local GAME_STANDINGS_COLUMNS = {
	{
		sortable = true,
		sortType = 'rank',
		class = 'cell--rank',
		icon = 'rank',
		header = {
			value = 'Rank',
		},
		sortVal = {
			value = function (opponent, idx)
				if opponent.placement == -1 or opponent.status ~= 'S' then
					return idx
				end
				return opponent.placement
			end,
		},
		row = {
			value = function (opponent, idx)
				local place = opponent.placement ~= -1 and opponent.placement or idx
				local placementDisplay
				if opponent.status and opponent.status ~= 'S' then
					placementDisplay = '-'
				else
					placementDisplay = tostring(MatchSummaryWidgets.RankRange{rankStart = place})
				end
				return HtmlWidgets.Fragment{children = {
					MatchSummaryWidgets.Trophy{place = place, additionalClasses = {'panel-table__cell-icon'}},
					HtmlWidgets.Span{children = placementDisplay},
				}}
			end,
		},
	},
	{
		sortable = true,
		sortType = 'team',
		class = 'cell--team',
		icon = 'team',
		header = {
			value = 'Team',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.name
			end,
		},
		row = {
			value = function (opponent, idx)
				return OpponentDisplay.BlockOpponent{
					opponent = opponent,
					showLink = true,
					overflow = 'ellipsis',
					teamStyle = 'hybrid',
				}
			end,
		},
	},
	{
		sortable = true,
		sortType = 'total-points',
		class = 'cell--total-points',
		icon = 'points',
		header = {
			value = 'Total Points',
			mobileValue = 'Pts.',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.score
			end,
		},
		row = {
			value = function (opponent, idx)
				return opponent.score
			end,
		},
	},
	{
		sortable = true,
		sortType = 'placements',
		class = 'cell--placements',
		icon = 'placement',
		header = {
			value = 'Placement Points',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.scoreBreakdown.placePoints
			end,
		},
		row = {
			value = function (opponent, idx)
				return opponent.scoreBreakdown.placePoints
			end,
		},
	},
	{
		sortable = true,
		sortType = 'kills',
		class = 'cell--kills',
		icon = 'kills',
		header = {
			value = 'Kill Points',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.scoreBreakdown.killPoints
			end,
		},
		row = {
			value = function (opponent, idx)
				return opponent.scoreBreakdown.killPoints
			end,
		},
	},
}
---@param props {bracketId: string, matchId: string, gameIdx: integer}
---@return Html
function CustomGameSummary.getGameByMatchId(props)
	---@class ApexMatchGroupUtilMatch
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)

	local game = match.games[props.gameIdx]
	assert(game, 'Error Game ID ' .. tostring(props.gameIdx) .. ' not found')

	game.stream = match.stream

	CustomGameSummary._opponents(match)
	local scoringData = SummaryHelper.createScoringData(match)

	return MatchSummaryWidgets.Tab{
		matchId = match.matchId,
		idx = props.gameIdx,
		children = {
			CustomGameSummary._createGameDetails(game),
			MatchSummaryWidgets.PointsDistribution{killScore = scoringData.kill, placementScore = scoringData.placement},
			CustomGameSummary._createGameStandings(game)
		}
	}
end

---@param game table
---@return Widget
function CustomGameSummary._createGameDetails(game)
	return MatchSummaryWidgets.ContentItemContainer{children = {
		HtmlWidgets.Ul{
			classes = {'panel-content__game-schedule'},
			children = {
				HtmlWidgets.Li{children =
					HtmlWidgets.Div{
						classes = {'panel-content__game-schedule__container'},
						children = {
							MatchSummaryWidgets.CountdownIcon{game = game, additionalClasses = {'panel-content__game-schedule__icon'}},
							SummaryHelper.gameCountdown(game),
						},
					},
				},
				game.map and HtmlWidgets.Li{children = {
					IconWidget{iconName = 'map', additionalClasses = {'panel-content__game-schedule__icon'}},
					HtmlWidgets.Span{children = Page.makeInternalLink(game.map)},
				}}} or nil,
			}
		}
	}
end

---@param game table
---@return Html
function CustomGameSummary._createGameStandings(game)
	local rows = Array.map(game.opponents, function (opponent, index)
		local children = Array.map(GAME_STANDINGS_COLUMNS, function(column)
			if column.show and not column.show(game) then
				return
			end
			return MatchSummaryWidgets.TableRowCell{
				class = column.class,
				sortable = column.sortable,
				sortType = column.sortType,
				sortValue = column.sortVal and column.sortVal.value(opponent, index) or nil,
				value = column.row.value(opponent, index),
			}
		end)
		return MatchSummaryWidgets.TableRow{children = children}
	end)

	return MatchSummaryWidgets.Table{children = {
		MatchSummaryWidgets.TableHeader{children = Array.map(GAME_STANDINGS_COLUMNS, function(column)
			if column.show and not column.show(game) then
				return
			end
			return MatchSummaryWidgets.TableHeaderCell{
				class = column.class,
				icon = column.icon,
				mobileValue = column.header.mobileValue,
				sortable = column.sortable,
				sortType = column.sortType,
				value = column.header.value,
			}
		end)},
		unpack(rows)
	}}
end

function CustomGameSummary._opponents(match)
	-- Add match opponent data to game opponent
	Array.forEach(match.games, function (game)
		game.opponents = Array.map(game.opponents,
			function(gameOpponent, opponentIdx)
				local matchOpponent = match.opponents[opponentIdx]
				local newGameOpponent = Table.merge(matchOpponent, gameOpponent)
				-- These values are only allowed to come from Game and not Match
				newGameOpponent.placement = gameOpponent.placement
				newGameOpponent.score = gameOpponent.score
				newGameOpponent.status = gameOpponent.status
				return newGameOpponent
			end
		)
	end)

	-- Sort game level based on placement
	Array.forEach(match.games, function (game)
		Array.sortInPlaceBy(game.opponents, FnUtil.identity, SummaryHelper.placementSortFunction)
	end)
end

return CustomGameSummary
