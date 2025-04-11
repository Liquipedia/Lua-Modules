---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Footer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPageFooterParameters
---@field comments MatchPageComment[]?
---@field children (string|Html|Widget|nil)|(string|Html|Widget|nil)[]

---@class MatchPageFooter: Widget
---@operator call(MatchPageFooterParameters): MatchPageFooter
---@field props MatchPageFooterParameters
local MatchPageFooter = Class.new(Widget)

---@return Widget[]
function MatchPageFooter:render()
	return WidgetUtil.collect(
		HtmlWidgets.H3{ children = 'Additional Information' },
		Div{
			classes = { 'match-bm-match-additional' },
			children = WidgetUtil.collect(
				Logic.isNotEmpty(self.props.comments) and Div{
					classes = {'match-bm-match-additional-comments'},
					children = self.props.comments
				} or nil,
				self.props.children
			)
		}
	)
end

return MatchPageFooter
