---
-- @Liquipedia
-- page=Module:Widget/Panel
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class PanelParameters
---@field bodyClass string[]?
---@field bodyStyle table<string, any>?
---@field boxId integer?
---@field children (Widget|string|Html|nil)|(Widget|string|Html|nil)[]
---@field classes string[]?
---@field heading string|Html|Widget
---@field headingAttributes table<string, any>?
---@field headingH2 string|Html|Widget?
---@field headingH3 string|Html|Widget?
---@field padding boolean?
---@field panelAttributes table<string, any>?

---@class Panel: Widget
---@operator call(PanelParameters): Panel
---@field props PanelParameters
local Panel = Class.new(Widget)

---@return Widget
function Panel:render()
	local boxId = self.props.boxId
	local attributes = self.props.headingAttributes or {}
	local hasToggle = boxId ~= nil

	if hasToggle then
		attributes = Table.merge(attributes, {
			tabindex = "0",
			['data-component'] =  "panel-box-collapsible-button"
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
			self.props.heading,
			self.props.headingH2 and HtmlWidgets.H2{children = { self.props.headingH2 }} or nil,
			self.props.headingH3 and HtmlWidgets.H3{children = { self.props.headingH3 }} or nil
		)
	}

	local body = Div{
		classes = WidgetUtil.collect(
			hasToggle and 'panel-box-collapsible-content' or nil,
			Logic.readBool(self.props.padding) and 'panel-box-body' or nil,
			self.props.bodyClass
		),
		css = self.props.bodyStyle,
		attributes = hasToggle and {
			['data-component'] = 'panel-box-content'
		} or {},
		children = self.props.children
	}

	return Div{
		classes = WidgetUtil.collect('panel-box', 'wiki-bordercolor-light', self.props.classes),
		attributes = Table.merge(
			hasToggle and {
				['data-component'] = 'panel-box',
				['data-panel-box-id'] = boxId
			} or {},
			self.props.panelAttributes
		),
		children = WidgetUtil.collect(
			heading, body
		)
	}

end

return Panel
