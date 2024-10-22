---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/Core
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')
local WarningBox = require('Module:WarningBox')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Fragment = HtmlWidgets.Fragment

---@class Infobox: Widget
---@operator call(table): Infobox
---@field props table
local Infobox = Class.new(Widget)

---@return string
function Infobox:render()
	local firstInfobox = not Variables.varDefault('has_infobox')
	Variables.varDefine('has_infobox', 'true')

	local adbox = Div{classes = {'fo-nttax-infobox-adbox'}, children = {mw.getCurrentFrame():preprocess('<adbox />')}}
	local content = Div{classes = {'fo-nttax-infobox'}, children = self.props.children}
	local bottomContent = Div{children = self.props.bottomContent}

	return Fragment{children = {
		Div{
			classes = {
				'fo-nttax-infobox-wrapper',
				'infobox-' .. self.props.gameName:lower(),
				self.props.forceDarkMode and 'infobox-darkmodeforced' or nil,
			},
			children = WidgetUtil.collect(
				content,
				firstInfobox and adbox or nil,
				bottomContent
			)
		},
		WarningBox.displayAll(self.props.warnings),
	}}
end

return Infobox
