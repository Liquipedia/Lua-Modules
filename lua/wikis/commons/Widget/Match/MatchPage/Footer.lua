---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/MatchPage/Footer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPageFooterParameters
---@field children (string|Html|Widget|nil)|(string|Html|Widget|nil)[]

---@class MatchPageFooter: Widget
---@operator call(MatchPageFooterParameters): MatchPageFooter
---@field props MatchPageFooterParameters
local MatchPageFooter = Class.new(Widget)

---@return Widget[]
function MatchPageFooter:render()
	return {
		HtmlWidgets.H3{ children = 'Additional Information' },
		Div{
			classes = { 'match-bm-match-additional' },
			children = WidgetUtil.collect(self.props.children)
		}
	}
end

return MatchPageFooter
