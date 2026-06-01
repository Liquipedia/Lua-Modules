---
-- @Liquipedia
-- page=Module:Widget/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ListWidget: Widget
---@operator call(table): ListWidget
---@field props {children: (Renderable|Renderable[])[]}
local ListWidget = Class.new(Widget)

---@return VNode?
function ListWidget:render()
	local children = self.props.children
	if Logic.isEmpty(children) then return end
	return self:getType(){
		children = Array.map(children, function (item)
			return Html.Li{
				children = WidgetUtil.collect(item)
			}
		end)
	}
end

---@protected
---@return HtmlComponent
function ListWidget:getType()
	error('ListWidget cannot be called directly and must be overridden.')
end

return ListWidget
