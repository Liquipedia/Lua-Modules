---
-- @Liquipedia
-- page=Module:Widget/List/Ordered
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local ListWidget = Lua.import('Module:Widget/List')
local Html = Lua.import('Module:Widget/Html')

---@class OrderedList: ListWidget
---@operator call(table): OrderedList
local OrderedList = Class.new(ListWidget)

---@return HtmlComponent
function OrderedList:getType()
	return Html.Ol
end

return OrderedList
