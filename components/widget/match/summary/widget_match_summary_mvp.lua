---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Mvp
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div, Span, Fragment = HtmlWidgets.Div, HtmlWidgets.Span, HtmlWidgets.Fragment
local Link = Lua.import('Module:Widget/Basic/Link')

---@class MatchSummaryMVP: Widget
---@operator call(table): MatchSummaryMVP
local MatchSummaryMVP = Class.new(Widget)

---@return Widget?
function MatchSummaryMVP:render()
	if self.props.players == nil or #self.props.players == 0 then
		return nil
	end
	local points = tonumber(self.props.points)
	local players = Array.map(self.props.players, function(inputPlayer)
		local player = type(inputPlayer) ~= 'table' and {name = inputPlayer, displayname = inputPlayer} or inputPlayer

		return Fragment{children = {
			Link{link = player.name, children = player.displayname},
			player.comment and ' (' .. player.comment .. ')' or nil
		}}
	end)
	return Div{
		classes = {'brkts-popup-footer', 'brkts-popup-mvp'},
		children = {Span{
			children = WidgetUtil.collect(
				#players > 1 and 'MVPs: ' or 'MVP: ',
				Array.interleave(players, ', '),
				points and points > 1 and ' (' .. points .. ' pts)' or nil
			),
		}},
	}
end

return MatchSummaryMVP
