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
local NUM_CHAMPIONS_PICK = 5

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '420px', maxBans = MAX_NUM_BANS})
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Renderable?
function CustomMatchSummary.createGame(date, game, gameIndex)
	local extradata = game.extradata or {}

	-- TODO: Change to use participant data
	local characterData = {
		MatchSummary.buildCharacterList(extradata, 'team1champion', NUM_CHAMPIONS_PICK),
		MatchSummary.buildCharacterList(extradata, 'team2champion', NUM_CHAMPIONS_PICK),
	}

	if Logic.isEmpty(game.length) and Logic.isEmpty(game.winner) and Logic.isDeepEmpty(characterData) then
		return nil
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.Characters{
				flipped = false,
				characters = characterData[1],
				bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata.team1side or ''),
			},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameCenter{children = Logic.nilIfEmpty(game.length) or ('Game ' .. gameIndex)},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.Characters{
				flipped = true,
				characters = characterData[2],
				bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata.team2side or ''),
			},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

return CustomMatchSummary
