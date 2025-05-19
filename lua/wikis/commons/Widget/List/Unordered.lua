---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/List/Unordered
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local ListWidget = Lua.import('Module:Widget/List')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class UnorderedList: ListWidget
---@operator call(table): UnorderedList
local UnorderedList = Class.new(ListWidget)

---@return WidgetHtml
function UnorderedList:getType()
	return HtmlWidgets.Ul
end

return UnorderedList
