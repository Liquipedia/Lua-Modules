---
-- @Liquipedia
-- page=Module:Widget/Legend
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local ChevronToggle = Lua.import('Module:Widget/Participants/Team/ChevronToggle')
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local Html = Lua.import('Module:Widget/Html')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local LabelWidget = Lua.import('Module:Widget/Basic/Label')
local WidgetUtil = Lua.import('Module:Widget/Util')

local LABEL_COLORS = {'byeup', 'seedup', 'up', 'stayup', 'stay', 'staydown', 'down'}

---@class LegendComponent
local LegendComponent = {}

--TODO: pass defaultProps directly to Component.component
LegendComponent.defaultProps = {
	title = 'Legend',
	showConfirmed = true,
	showUndecided = true,
}

---@param props table
---@return Widget
function LegendComponent.render(props)
	return GeneralCollapsible{
		shouldCollapse = true,
		collapseAreaClasses = {},
		classes = {'legend'},
		titleWidget = LegendComponent._createHeader(props),
		children = WidgetUtil.collect(
			LegendComponent._createColorSection(props),
			LegendComponent._createPointsSection(props),
			LegendComponent._createNumberSection(props)
		)
	}
end

---@private
---@return VNode
function LegendComponent._createHeader(props)
	return Html.Div{
		classes = {'legend-header'},
		attributes = {['data-collapsible-click-region'] = 'true'},
		children = {
			Html.Div{children = {
				Icon{iconName = 'general-info'},
				Html.Span{children = {Logic.emptyOr(props.title, LegendComponent.defaultProps.title)}}
			}},
			ChevronToggle{}
		}
	}
end

---@private
---@return VNode?
function LegendComponent._createColorSection(props)
	local sectionData = Json.parseIfString(props.color)
	if Logic.isEmpty(sectionData) then
		return
	end
	local labels = Array.map(LABEL_COLORS, function (labelColor)
		local labelText = sectionData[labelColor]
		if Logic.isEmpty(labelText) then
			return
		end
		return Html.Div{
			classes = {'legend-item'},
			children = {
				Html.Span{
					classes = {labelColor .. '-text'},
					children = {'&#9679;'}
				},
				Html.Span{children = labelText}
			}
		}
	end)

	if Logic.isEmpty(labels) then
		return
	end

	return Html.Div{
		classes = {'legend-section'},
		children = labels
	}
end

---@private
---@return VNode?
function LegendComponent._createPointsSection(props)
	local sectionData = Json.parseIfString(props.points)
	if not sectionData then
		return
	end
	local pointsText = sectionData[1] or sectionData.points
	if Logic.isEmpty(pointsText) then
		return
	end
	return Html.Div{
		classes = {'legend-section'},
		children = Html.Div{
			classes = {'legend-item'},
			children = {
				Html.Span{
					css = {['font-weight'] = 'bold'},
					children = {'Pts'}
				},
				Html.Span{children = pointsText}
			}
		}
	}
end

---@private
---@return VNode?
function LegendComponent._createNumberSection(props)
	if not Logic.readBool(props.showNumberSection) then
		return
	end

	local labels = WidgetUtil.collect(
		Logic.nilOr(
			Logic.readBoolOrNil(props.showConfirmed),
			LegendComponent.defaultProps.showConfirmed
		) and Html.Div{
			classes = {'legend-item'},
			children = {
				LabelWidget{
					labelScheme = 'placement',
					labelType = 'legend-confirmed',
					children = 1
				},
				Html.Span{children = {'Placement confirmed'}}
			}
		} or nil,
		Logic.readBool(props.showMinimum) and Html.Div{
			classes = {'legend-item'},
			children = {
				LabelWidget{
					labelScheme = 'placement',
					labelType = 'legend-minimum',
					children = 1
				},
				Html.Span{children = {'Minimum placement reached'}}
			}
		} or nil,
		Logic.nilOr(
			Logic.readBoolOrNil(props.showUndecided),
			LegendComponent.defaultProps.showUndecided
		) and Html.Div{
			classes = {'legend-item'},
			children = {
				LabelWidget{
					labelScheme = 'placement',
					labelType = 'legend-undecided',
					children = 1
				},
				Html.Span{children = {'Placement undecided'}}
			}
		} or nil
	)

	if Logic.isEmpty(labels) then
		return
	end

	return Html.Div{
		classes = {'legend-section'},
		children = labels
	}
end

return Component.component(LegendComponent.render)
