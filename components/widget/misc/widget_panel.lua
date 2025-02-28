---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Panel
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Fragment = HtmlWidgets.Fragment
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class Panel: Widget
---@operator call(table): Panel
---@field props table<string, any>
local Panel = Class.new(Widget)

---@return string
function Panel:render()

	local heading = Div{
		classes = { 'panel-box-heading', 'wiki-color-dark', 'wiki-backgroundcolor-light', 'wiki-bordercolor-light' },
		attributes = self.props.heading_attributes,
		children = Array.extend(
			self.props.boxId and {
				Div{
					classes = { 'panel-box-heading-icon' },
					attributes = {
						tabindex = "0",
						['data-component'] =  "panel-box-collapsible-button"
					},
					children = { IconFa{iconName = 'collapse'}, }
				}
			} or nil,
			self.props.heading,
			self.props.headingH2 and HtmlWidgets.H2{children = { self.props.headingH2 }} or nil,
			self.props.headingH3 and HtmlWidgets.H3{children = { self.props.headingH3 }} or nil
		)
	}

	local body = Div{
		classes = Array.extend(
			self.props.boxId and 'panel-box-collapsible-content' or nil,
			Logic.readBool(self.props.padding) and 'panel-box-body' or nil,
			self.props.bodyClass
		),
		css = self.props.bodyStyle,
		attributes = self.props.boxId and {
			['data-component'] = 'panel-box-content'
		} or {},
		children = self.props.body
	}

	return Fragment{children = {
		Div{
			classes = Array.extend('panel-box', 'wiki-bordercolor-light', self.props.classes),
			attributes = Table.merge(
				self.props.boxId and {
					['data-component'] = 'panel-box',
					['data-panel-box-id'] = self.props.boxId
				} or {},
				self.props.attributes
			),
			children = WidgetUtil.collect(
				heading, body
			)
		},
	}}
end

return Panel
