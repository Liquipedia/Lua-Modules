---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Panel
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class Panel: Widget
---@operator call(table): Panel
---@field props table<string, any>
local Panel = Class.new(Widget)

---@return Widget
function Panel:render()
	local boxId = self.props.boxId

	local heading = Div{
		classes = { 'panel-box-heading', 'wiki-color-dark', 'wiki-backgroundcolor-light', 'wiki-bordercolor-light' },
		attributes = self.props.headingAttributes,
		children = WidgetUtil.collect(
			boxId and {
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
		classes = WidgetUtil.collect(
			boxId and 'panel-box-collapsible-content' or nil,
			Logic.readBool(self.props.padding) and 'panel-box-body' or nil,
			self.props.bodyClass
		),
		css = self.props.bodyStyle,
		attributes = boxId and {
			['data-component'] = 'panel-box-content'
		} or {},
		children = self.props.children
	}

	return Div{
		classes = WidgetUtil.collect('panel-box', 'wiki-bordercolor-light', self.props.classes),
		attributes = Table.merge(
			boxId and {
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
