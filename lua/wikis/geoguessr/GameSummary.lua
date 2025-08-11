---
-- @Liquipedia
-- page=Module:GameSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomGameSummary = {}

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local SummaryHelper = Lua.import('Module:MatchSummary/Base/Ffa')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')

---@param props {bracketId: string, matchId: string, gameIdx: integer}
---@return Html
function CustomGameSummary.getGameByMatchId(props)
	---@type FFAMatchGroupUtilMatch
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)

	local game = match.games[props.gameIdx]
	assert(game, 'Error Game ID ' .. tostring(props.gameIdx) .. ' not found')

	game.stream = match.stream
	game.extradata.settings = match.extradata.settings

	SummaryHelper.updateGameOpponents(match, game)

	return MatchSummaryWidgets.Tab{
		matchId = match.matchId,
		idx = props.gameIdx,
		children = {
			MatchSummaryWidgets.GameDetails{game = game},
			MatchSummaryWidgets.Mvp(game.extradata.mvp),
			SummaryHelper.standardGame(game),
		},
	}
end

---@param columns table[]
---@param game table
---@return table[]
function CustomGameSummary.adjustGameStandingsColumns(columns, game)
	return Array.map(columns, function(column)
		if column.id == 'kills' then
			column.header = {value = 'Points'}
			column.icon = 'points'
		end
		return column
	end)
end

return CustomGameSummary
