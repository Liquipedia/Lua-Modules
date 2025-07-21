---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OVERTIME = '[[File:Cooldown_Clock.png|14x14px|link=]]'

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

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			DisplayHelper.MapScore(game.opponents[1], game.status),
			extradata.overtime and CustomMatchSummary._iconDisplay(OVERTIME, 'Overtime') or nil,
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game, {noLink = true})},
			extradata.overtime and CustomMatchSummary._iconDisplay(OVERTIME, 'Overtime') or nil,
			DisplayHelper.MapScore(game.opponents[2], game.status),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param icon string?
---@param hoverText string|number|nil
---@return Html
function CustomMatchSummary._iconDisplay(icon, hoverText)
	return HtmlWidgets.Div{
		classes = {'brkts-popup-spaced'},
		attributes = {title = hoverText},
		children = {icon},
	}
end

return CustomMatchSummary
