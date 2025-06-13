---
-- @Liquipedia
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

---@return Widget[]?
function MatchPageFooter:render()
	local comments = self.props.comments
	local children = self.props.children
	if Logic.isEmpty(comments) and Logic.isEmpty(children) then return end
	return {
		HtmlWidgets.H3{ children = 'Additional Information' },
		Div{
			classes = { 'match-bm-match-additional' },
			children = WidgetUtil.collect(
				Logic.isNotEmpty(comments) and Div{
					classes = {'match-bm-match-additional-comments'},
					children = comments
				} or nil,
				children
			)
		}
	}
end

return MatchPageFooter
