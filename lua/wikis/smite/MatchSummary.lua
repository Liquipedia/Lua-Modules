---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MAX_NUM_BANS = 5
local NUM_GODS_PICK = 5

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	local options = {width = '400px', teamStyle = 'bracket', maxBans = MAX_NUM_BANS}
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, options)
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Renderable
function CustomMatchSummary.createGame(game, gameIndex)
	local extradata = game.extradata or {}

	-- TODO: Change to use participant data
	local characterData = {
		MatchSummary.buildCharacterList(extradata, 'team1god', NUM_GODS_PICK),
		MatchSummary.buildCharacterList(extradata, 'team2god', NUM_GODS_PICK),
	}

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.Characters{
				flipped = false,
				characters = characterData[1],
				bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata.team1side or ''),
				date = game.date,
			},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameCenter{children = Logic.nilIfEmpty(game.length) or ('Game ' .. gameIndex)},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.Characters{
				flipped = true,
				characters = characterData[2],
				bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata.team2side or ''),
				date = game.date,
			},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

return CustomMatchSummary
