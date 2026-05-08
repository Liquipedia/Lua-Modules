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
local LabelWidget = Lua.import('Module:Widget/Basic/Label')
local WidgetUtil = Lua.import('Module:Widget/Util')

local LABEL_COLORS = {'byeup', 'seedup', 'up', 'stayup', 'stay', 'staydown', 'down'}

---@class LegendWidget: Widget
---@operator call(table): LegendWidget
local LegendWidget = Class.new(Widget)
LegendWidget.defaultProps = {
	title = 'Legend',
	showConfirmed = true,
	showUndecided = true,
}

---@return Renderable|Renderable[]?
function LegendWidget:render()
	return GeneralCollapsible{
		shouldCollapse = true,
		collapseAreaClasses = {},
		classes = {'legend'},
		titleWidget = self:_createHeader(),
		children = WidgetUtil.collect(
			self:_createColorSection(),
			self:_createPointsSection(),
			self:_createNumberSection()
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
			HtmlWidgets.Div{children = {
				Icon{iconName = 'general-info'},
				HtmlWidgets.Span{children = self.props.title}
			}},
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
	local labels = Array.map(LABEL_COLORS, function (labelColor)
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

	if Logic.isEmpty(labels) then
		return
	end

	return HtmlWidgets.Div{
		classes = {'legend-section'},
		children = labels
	}
end

---@private
---@return Widget?
function LegendWidget:_createPointsSection()
	local sectionData = Json.parseIfString(self.props.points)
	if not sectionData then
		return
	end
	local pointsText = sectionData[1] or sectionData.points
	if Logic.isEmpty(pointsText) then
		return
	end
	return HtmlWidgets.Div{
		classes = {'legend-section'},
		children = HtmlWidgets.Div{
			classes = {'legend-item'},
			children = {
				HtmlWidgets.Span{
					css = {['font-weight'] = 'bold'},
					children = 'Pts'
				},
				HtmlWidgets.Span{children = pointsText}
			}
		}
	}
end

---@private
---@return Widget?
function LegendWidget:_createNumberSection()
	local props = self.props
	if not Logic.readBool(props.showNumberSection) then
		return
	end

	local labels = WidgetUtil.collect(
		Logic.readBool(props.showConfirmed) and HtmlWidgets.Div{
			classes = {'legend-item'},
			children = {
				LabelWidget{
					labelScheme = 'placement',
					labelType = 'legend-confirmed',
					children = 1
				},
				HtmlWidgets.Span{children = 'Placement confirmed'}
			}
		} or nil,
		Logic.readBool(props.showMinimum) and HtmlWidgets.Div{
			classes = {'legend-item'},
			children = {
				LabelWidget{
					labelScheme = 'placement',
					labelType = 'legend-minimum',
					children = 1
				},
				HtmlWidgets.Span{children = 'Minimum placement reached'}
			}
		} or nil,
		Logic.readBool(props.showUndecided) and HtmlWidgets.Div{
			classes = {'legend-item'},
			children = {
				LabelWidget{
					labelScheme = 'placement',
					labelType = 'legend-undecided',
					children = 1
				},
				HtmlWidgets.Span{children = 'Placement undecided'}
			}
		} or nil
	)

	if Logic.isEmpty(labels) then
		return
	end

	return HtmlWidgets.Div{
		classes = {'legend-section'},
		children = labels
	}
end

return LegendWidget

