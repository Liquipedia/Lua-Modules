---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Html = Lua.import('Module:Widget/Html')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OVERTIME = '[[File:Cooldown_Clock.png|14x14px|link=]]'

local CustomMatchSummary = {}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Renderable?
function CustomMatchSummary.createGame(game, gameIndex)
	if not game.map then
		return
	end
	local extradata = game.extradata or {}

	local function makeOpponentSection(opponentIndex)
		return {
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
			DisplayHelper.MapScore(game.opponents[opponentIndex], game.status),
			extradata.overtime and CustomMatchSummary._iconDisplay(OVERTIME, 'Overtime') or nil,
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeOpponentSection(1)},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game, {noLink = true})},
			MatchSummaryWidgets.GameTeamWrapper{children = makeOpponentSection(2), flipped = true},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param icon string?
---@param hoverText string|number|nil
---@return Html
function CustomMatchSummary._iconDisplay(icon, hoverText)
	return Html.Div{
		classes = {'brkts-popup-spaced'},
		attributes = {title = hoverText},
		children = {icon},
	}
end

return CustomMatchSummary
