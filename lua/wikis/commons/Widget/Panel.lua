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
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class PanelParameters
---@field bodyClass string[]?
---@field bodyStyle table<string, any>?
---@field boxId integer?
---@field children Renderable|Renderable[]
---@field classes string[]?
---@field heading string|Html|Widget
---@field headingAttributes table<string, any>?
---@field headingH2 string|Html|Widget?
---@field headingH3 string|Html|Widget?
---@field padding boolean?
---@field panelAttributes table<string, any>?

---@param props PanelParameters
---@return Widget
local function Panel(props)
	local boxId = props.boxId
	local attributes = props.headingAttributes or {}
	local hasToggle = boxId ~= nil

	if hasToggle then
		attributes = Table.merge(attributes, {
			tabindex = '0',
			['data-component'] = 'panel-box-collapsible-button'
		})
	end

	local heading = Div{
		classes = { 'panel-box-heading', 'wiki-color-dark', 'wiki-backgroundcolor-light', 'wiki-bordercolor-light' },
		attributes = attributes,
		children = WidgetUtil.collect(
			hasToggle and {
				Div{
					classes = { 'panel-box-heading-icon' },
					children = { IconFa{iconName = 'collapse'}, }
				}
			} or nil,
			props.heading,
			props.headingH2 and Html.H2{children = { props.headingH2 }} or nil,
			props.headingH3 and Html.H3{children = { props.headingH3 }} or nil
		)
	}

	local body = Div{
		classes = WidgetUtil.collect(
			hasToggle and 'panel-box-collapsible-content' or nil,
			'panel-box-body',
			not Logic.readBool(props.padding) and 'panel-box-body--no-padding' or nil,
			props.bodyClass
		),
		css = props.bodyStyle,
		attributes = hasToggle and {
			['data-component'] = 'panel-box-content'
		} or {},
		children = props.children
	}

	return Div{
		classes = WidgetUtil.collect('panel-box', 'wiki-bordercolor-light', props.classes),
		attributes = Table.merge(
			hasToggle and {
				['data-component'] = 'panel-box',
				['data-panel-box-id'] = boxId
			} or {},
			props.panelAttributes
		),
		children = WidgetUtil.collect(
			heading, body
		)
	}

end

return Component.component(Panel)
