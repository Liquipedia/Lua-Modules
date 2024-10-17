---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Footer/Section
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')

---@class MatchPageFooterSection: Widget
---@operator call(table): MatchPageFooterSection
local MatchPageFooterSection = Class.new(Widget)

---@return Widget[]?
function MatchPageFooterSection:render()
	return Div{
		classes = {'match-bm-match-additional-section'},
		children = {
			Div{classes = {'match-bm-match-additional-section-header'}, children = self.props.header},
			Div{classes = {'match-bm-match-additional-section-body'}, children = self.props.children},
		}
	}
end

return MatchPageFooterSection
