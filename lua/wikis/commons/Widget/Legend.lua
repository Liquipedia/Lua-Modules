---
-- @Liquipedia
-- page=Module:Widget/Legend
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local ChevronToggle = Lua.import('Module:Widget/Participants/Team/ChevronToggle')
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local WidgetUtil = Lua.import('Module:Widget/Util')

local LABEL_COLORS = {'byeup', 'seedup', 'up', 'stayup', 'stay', 'staydown', 'down'}

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
		children = WidgetUtil.collect(
			self:_createColorSection()
		)
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

---@private
---@return Widget?
function LegendWidget:_createColorSection()
	local sectionData = Json.parseIfString(self.props.color)
	if Logic.isEmpty(sectionData) then
		return
	end
	return HtmlWidgets.Div{
		classes = {'legend-section'},
		children = Array.map(LABEL_COLORS, function (labelColor)
			local labelText = sectionData[labelColor]
			if Logic.isEmpty(labelText) then
				return
			end
			return HtmlWidgets.Div{
				classes = {'legend-item'},
				children = {
					HtmlWidgets.Span{
						classes = {labelColor .. '-text'},
						children = '&#9679;'
					},
					HtmlWidgets.Span{children = labelText}
				}
			}
		end)
	}
end

return LegendWidget

