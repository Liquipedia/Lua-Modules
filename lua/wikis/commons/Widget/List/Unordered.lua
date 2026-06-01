---
-- @Liquipedia
-- page=Module:Widget/List/Unordered
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local ListWidget = Lua.import('Module:Widget/List')
local Html = Lua.import('Module:Widget/Html')

---@class UnorderedList: ListWidget
---@operator call(table): UnorderedList
local UnorderedList = Class.new(ListWidget)

---@return HtmlComponent
function UnorderedList:getType()
	return Html.Ul
end

return UnorderedList
