---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/MatchComment
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Break = Lua.import('Module:Widget/Match/Summary/Break')

---@class MatchSummaryMatchMatchComment: Widget
---@operator call(table): MatchSummaryMatchMatchComment
local MatchSummaryMatchMatchComment = Class.new(Widget)

---@return Widget?
function MatchSummaryMatchMatchComment:render()
	if Logic.isEmpty(self.props.children) then
		return
	end

	return HtmlWidgets.Div{
		classes = {'brkts-popup-comment'},
		css = {['font-size'] = '85%', ['white-space'] = 'normal'},
		children = Array.flatMap(self.props.children, function (child)
			return {child, Break{}}
		end)
	}
end

return MatchSummaryMatchMatchComment
