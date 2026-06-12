---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MAX_NUM_BANS = 1

---@class OverwatchCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

local OverwatchMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent{
	createGameOverview = CustomMatchSummary.createGameOverview,
	createGameOpponentView = CustomMatchSummary.createGameOpponentView
}

---@param args table
---@return Widget
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param match MatchGroupUtilMatch
---@return Widget[]
function CustomMatchSummary.createBody(match)
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)

	return WidgetUtil.collect(
		MatchSummaryWidgets.GamesContainer{
			children = Array.map(match.games, function (game, gameIndex)
				if Logic.isEmpty(game.map) then
					return
				end
				return OverwatchMatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)
end

---@param props MatchSummaryGameRowProps
---@return string
function CustomMatchSummary.createGameOverview(props)
	return DisplayHelper.MapAndMode(props.game)
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return Renderable
function CustomMatchSummary.createGameOpponentView(props, opponentIndex)
	local game = props.game
	local opponentCopy = Table.deepCopy(game.opponents[opponentIndex])
	if opponentCopy.score and game.mode == 'Push' then
		opponentCopy.score = opponentCopy.score .. 'm'
	end

	return DisplayHelper.MapScore(opponentCopy, game.status)
end

return CustomMatchSummary
