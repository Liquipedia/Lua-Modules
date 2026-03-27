---
-- @Liquipedia
-- page=Module:Widget/Legend
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local ChevronToggle = Lua.import('Module:Widget/Participants/Team/ChevronToggle')
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class LegendWidget: Widget
---@operator call(table): LegendWidget
local LegendWidget = Class.new(Widget)

---@return Renderable|Renderable[]?
function LegendWidget:render()
	return GeneralCollapsible{
		shouldCollapse = true,
		collapseAreaClasses = {},
		classes = {'legend'},
		titleWidget = self:_createHeader(),
		children = Array.mapIndexes(function (index)
			local sectionContent = self.props['section' .. index]
			if Logic.isEmpty(sectionContent) then
				return
			end
			return HtmlWidgets.Div{
				classes = {'legend-section'},
				children = self.props['section' .. index]
			}
		end)
	}
end

---@private
---@return Widget
function LegendWidget:_createHeader()
	return HtmlWidgets.Div{
		classes = {'legend-header'},
		attributes = {['data-collapsible-click-region'] = 'true'},
		children = {
			HtmlWidgets.Div{
				classes = {},
				children = {
					Icon{iconName = 'general-info'},
					' Legend'
				}
			},
			ChevronToggle{}
		}
	}
end

return LegendWidget

