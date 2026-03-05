---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GameWinLossIndicator
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

local ICONS = {
	win = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text'},
	draw = Icon.makeIcon{iconName = 'draw', color = 'bright-sun-text'},
	loss = Icon.makeIcon{iconName = 'loss', color = 'cinnabar-text'},
	empty = '[[File:NoCheck.png|link=|14px]]',
}

---@class MatchSummaryGameWinLossIndicator: Widget
---@operator call(table): MatchSummaryGameWinLossIndicator
local MatchSummaryGameWinLossIndicator = Class.new(Widget)

---@return Widget
function MatchSummaryGameWinLossIndicator:render()
	local winner = self.props.winner

	local icon
	if winner == self.props.opponentIndex then
		icon = ICONS.win
	elseif winner == 0 then
		icon = ICONS.draw
	elseif Logic.isNotEmpty(winner) then
		icon = ICONS.loss
	else
		icon = ICONS.empty
	end

	return Div{
		classes = {'brkts-popup-spaced brkts-popup-winloss-icon'},
		children = {icon},
	}
end

return MatchSummaryGameWinLossIndicator
