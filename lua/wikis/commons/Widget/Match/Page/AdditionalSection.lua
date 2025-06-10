---
-- @Liquipedia
-- page=Module:Widget/Match/Page/AdditionalSection
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
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

---@return Widget?
function MatchPageAdditionalSection:render()
	if Logic.isDeepEmpty(self.props.children) then return end
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
