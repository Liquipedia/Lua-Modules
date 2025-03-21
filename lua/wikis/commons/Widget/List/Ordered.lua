---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/List/Ordered
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local ListWidget = Lua.import('Module:Widget/List')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class OrderedList: ListWidget
---@operator call(table): OrderedList
local OrderedList = Class.new(ListWidget)

---@return WidgetHtml
function OrderedList:getType()
	return HtmlWidgets.Ol
end

return OrderedList
