---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/MatchPage/AdditionalSection
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPageAdditionalSectionParameters
---@field header string
---@field bodyClasses string[]?
---@field children (string|Html|Widget|nil)|(string|Html|Widget|nil)[]

---@class MatchPageAdditionalSection: Widget
---@operator call(MatchPageAdditionalSectionParameters): MatchPageAdditionalSection
---@field props MatchPageAdditionalSectionParameters
local MatchPageAdditionalSection = Class.new(Widget)

---@return Widget
function MatchPageAdditionalSection:render()
	return Div{
		classes = { 'match-bm-match-additional-section' },
		children = {
			Div{
				classes = { 'match-bm-match-additional-section-header' },
				children = { self.props.header }
			},
			Div{
				classes = Array.extend({'match-bm-match-additional-section-body'}, self.props.bodyClasses),
				children = WidgetUtil.collect(self.props.children)
			},
		}
	}
end

return MatchPageAdditionalSection
