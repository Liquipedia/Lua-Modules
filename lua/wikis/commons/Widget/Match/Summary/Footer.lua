---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Footer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchSummaryFooter: Widget
---@operator call(table): MatchSummaryFooter
local MatchSummaryFooter = Class.new(Widget)

---@return Widget?
function MatchSummaryFooter:render()
	local children = self.props.children
	if Logic.isEmpty(children) then
		return
	end
	return Div{
		classes = {'brkts-popup-footer'},
		children = Div{
			classes = {'brkts-popup-spaced', 'vodlink'},
			children = children
		}
	}
end

return MatchSummaryFooter
