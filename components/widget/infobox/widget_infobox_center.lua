---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/Center
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class CentereWidget: Widget
---@operator call(table): CentereWidget
---@field classes string[]
local Center = Class.new(Widget)

---@return Widget?
function Center:render()
	if Table.isEmpty(self.props.children) then
		return nil
	end
	return HtmlWidgets.Div{children = {HtmlWidgets.Div{
		classes = WidgetUtil.collect('infobox-center', self.props.classes),
		children = self.props.children
	}}}
end

return Center
