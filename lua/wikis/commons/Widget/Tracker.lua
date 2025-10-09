---
-- @Liquipedia
-- page=Module:Widget/Tracker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class TrackerWidget: Widget
---@operator call(table): TrackerWidget
local TrackerWidget = Class.new(Widget)
TrackerWidget.defaultProps = {
}

---@return Widget
function TrackerWidget:render()
	return Div{attributes = {['data-tracking-id'] = self.props.trackingId, children = self.props.children}}
end

return TrackerWidget
