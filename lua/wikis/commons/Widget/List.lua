---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ListWidget: Widget
---@operator call(table): ListWidget
---@field children (string|Widget|Html|nil)|(string|Widget|Html|nil)[]
local ListWidget = Class.new(Widget)

---@return Widget?
function ListWidget:render()
	local children = self.props.children
	if Logic.isEmpty(children) then return end
	return self:getType(){
		children = Array.map(children, function (item)
			return HtmlWidgets.Li{
				children = WidgetUtil.collect(item)
			}
		end)
	}
end

---@return WidgetHtml
function ListWidget:getType()
	error('ListWidget:getType() cannot be called directly and must be overridden.')
end

return ListWidget
