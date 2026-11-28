---
-- @Liquipedia
-- page=Module:FilterButtons/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')

local FilterButtonsUtil = {}

---Fills in the items and default items of a filter category
---@param category FilterButtonCategory
function FilterButtonsUtil.loadCategory(category)
	-- categories are shared module data mutated below; load once even if rendered multiple times
	if category.loaded then
		return
	end

	if category.load then
		category.load(category)
	end

	if category.order then
		Array.orderInPlaceBy(category.items, category.order)
	end

	local itemToPropertyValues = category.itemToPropertyValues or FnUtil.identity
	category.defaultItems = Array.map(
		Logic.emptyOr(category.defaultItems, category.items) --[[ @as string[] ]],
		itemToPropertyValues
	)
	category.loaded = true
end

return FilterButtonsUtil
