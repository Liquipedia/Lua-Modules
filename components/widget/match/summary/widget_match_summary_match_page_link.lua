---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/MatchPageLink
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div, Center = HtmlWidgets.Div, HtmlWidgets.Center
local Link = Lua.import('Module:Widget/Basic/Link')

---@class MatchSummaryMatchPageLink: Widget
---@operator call(table): MatchSummaryMatchPageLink
local MatchSummaryMatchPageLink = Class.new(Widget)

---@return Widget?
function MatchSummaryMatchPageLink:render()
	if not self.props.matchId then
		return
	end

	return Div{classes = {'brkts-popup-mvp'}, css = {['font-size'] = '85%'}, children = Center{children =
		Link{
			link = 'Match:ID_' .. self.props.matchId,
			children = 'Match Page',
			css = {
				display = 'block',
				margin = 'auto',
			},
		}
	}}
end
