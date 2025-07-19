---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget?
function CustomMatchSummary.createGame(date, game, gameIndex)
	if not game.map then
		return
	end
	local extradata = game.extradata or {}

	local function makeTeamSection(opponentIndex)
		return {
			DisplayHelper.MapScore(game.opponents[opponentIndex], game.status),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
			MatchSummaryWidgets.GameCenter{children = {
				DisplayHelper.Map(game),
				Logic.readBool(extradata.ot) and ' - OT' or nil,
				Logic.isNotEmpty(extradata.otlength) and '(' .. extradata.otlength .. ')' or nil
			}},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

return CustomMatchSummary
