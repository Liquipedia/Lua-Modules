---
-- @Liquipedia
-- page=Module:GameSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomGameSummary = {}

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local CustomMatchSummary = Lua.import('Module:MatchSummary')
local SummaryHelper = Lua.import('Module:MatchSummary/Base/Ffa')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')

---@param props {bracketId: string, matchId: string, gameIdx: integer}
---@return Html
function CustomGameSummary.getGameByMatchId(props)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId) --[[
		@as FFAMatchGroupUtilMatch]]

	local game = match.games[props.gameIdx]
	assert(game, 'Error Game ID ' .. tostring(props.gameIdx) .. ' not found')

	game.stream = match.stream

	SummaryHelper.updateGameOpponents(match, game)

	return MatchSummaryWidgets.Tab{
		matchId = match.matchId,
		idx = props.gameIdx,
		children = {
			MatchSummaryWidgets.GameDetails{game = game},
			SummaryHelper.standardGame(game, CustomGameSummary)
		}
	}
end

---@param columns table[]
---@param game table
---@return table[]
function CustomGameSummary.adjustGameStandingsColumns(columns, game)
	local customizedColumns = Array.map(columns, function(column)
		if column.id == 'totalPoints' and game.extradata.settings.noscore then
			return
		end

		return column
	end)

	---@param opponent table
	---@return boolean
	local opponnetHasPlayerWithHeroes = function(opponent)
		return Array.any(opponent.players, function(player)
			return Logic.isNotDeepEmpty(player.heroes)
		end)
	end

	return Array.append(customizedColumns, {
		id = 'heroes',
		sortable = false,
		class = 'cell--total-points',
		show = function(currentGame)
			return Array.any(currentGame.opponents, opponnetHasPlayerWithHeroes)
		end,
		header = {
			value = 'Heroes',
		},
		row = {
			value = function (opponent, opponentIndex)
				return CustomMatchSummary.DisplayHeroes(opponent, {hasHeroes = opponnetHasPlayerWithHeroes(opponent)})
			end,
		},
	})
end

return CustomGameSummary
