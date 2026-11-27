---
-- @Liquipedia
-- page=Module:Widget/Panel
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class PanelParameters
---@field bodyClass string[]?
---@field bodyStyle HtmlStyleProps?
---@field boxId integer?
---@field children Renderable|Renderable[]
---@field classes string[]?
---@field heading Renderable|Renderable[]
---@field headingAttributes table<string, any>?
---@field headingH2 Renderable|Renderable[]?
---@field headingH3 Renderable|Renderable[]?
---@field padding boolean?
---@field panelAttributes table<string, any>?

---@param props PanelParameters
---@return VNode
local function Panel(props)
	local boxId = props.boxId
	local hasToggle = boxId ~= nil

	local heading = Div{
		classes = { 'panel-box-heading', 'wiki-color-dark', 'wiki-backgroundcolor-light', 'wiki-bordercolor-light' },
		attributes = hasToggle
			and Table.merge(props.headingAttributes, {['data-collapsible-click-region'] = 'true'})
			or props.headingAttributes,
		children = WidgetUtil.collect(
			hasToggle and {
				Div{
					classes = { 'panel-box-heading-icon' },
					children = { IconFa{iconName = 'collapse'}, }
				}
			} or nil,
			props.heading,
			props.headingH2 and Html.H2{children = props.headingH2} or nil,
			props.headingH3 and Html.H3{children = props.headingH3} or nil
		)
	}

	local bodyClasses = WidgetUtil.collect(
		'panel-box-body',
		not Logic.readBool(props.padding) and 'panel-box-body--no-padding' or nil,
		props.bodyClass
	)
	local panelClasses = WidgetUtil.collect('panel-box', 'wiki-bordercolor-light', props.classes)

	if hasToggle then
		return GeneralCollapsible{
			classes = panelClasses,
			attributes = Table.mergeInto(
				{['data-collapsible-storage-key'] = 'panel-box-' .. boxId},
				props.panelAttributes
			),
			titleWidget = heading,
			collapseAreaClasses = bodyClasses,
			collapseAreaCss = props.bodyStyle,
			children = props.children,
		}
	end

	return Div{
		classes = panelClasses,
		attributes = props.panelAttributes,
		children = {
			heading,
			Div{
				classes = bodyClasses,
				css = props.bodyStyle,
				children = props.children,
			},
		}
	}
end

return Component.component(Panel)
