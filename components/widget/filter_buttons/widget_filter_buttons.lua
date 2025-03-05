---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/FilterButtons
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')
local Table = require('Module:Table')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local FilterButton = Lua.import('Module:Widget/FilterButtons/Button')
local FilterButtonRow = Lua.import('Module:Widget/FilterButtons/ButtonRow')
local Widget = Lua.import('Module:Widget')

---@class FilterButtons: Widget
---@operator call(table): FilterButtons
local FilterButtons = Class.new(Widget)

---@class FilterButtonCategory
---@field name string
---@field property string
---@field items string[]?
---@field defaultItems string[]?
---@field defaultItem string?
---@field itemToPropertyValues? fun(item: string): string?
---@field itemIsValid? fun(item: string): boolean
---@field transform? fun(item: string): string?
---@field expandKey string?
---@field expandable boolean?
---@field order? fun(a: string, b: string): boolean
---@field load? fun(cat: FilterButtonCategory)
---@field hasFeatured boolean?
---@field featuredByDefault boolean?

---@return Widget
function FilterButtons:render()
	---@type FilterButtonCategory[]
	local categories = self.props.categories or Lua.import('Module:FilterButtons/Config').categories

	Array.forEach(categories, FilterButtons._loadCategories)

	return Div{
		children = Array.map(categories, function (category)
			-- Variable used to pass default values on to other modules using these.
			assert(
				Table.isNotEmpty(category.items), category.name .. ': List of items is required, either input or filled during load'
			)
			Variables.varDefine('filterbuttons_defaults_' .. category.name, table.concat(category.defaultItems, ','))
			return FilterButtons.getButtonRow(category)
		end)
	}
end

---@param category FilterButtonCategory
function FilterButtons._loadCategories(category)
	if category.load then
		category.load(category)
	end

	if category.order then
		Array.orderInPlaceBy(category.items, category.order)
	end

	local itemToPropertyValues = category.itemToPropertyValues or FnUtil.identity
	category.defaultItems = Array.map(Logic.emptyOr(category.defaultItems, category.items), itemToPropertyValues)
end

---@param category FilterButtonCategory
---@param value string?
---@param text string?
---@return FilterButton
function FilterButtons._makeButton(category, value, text)
	return FilterButton{
		active = Table.includes(category.defaultItems, value),
		value = value,
		display = text
	}
end

---@param category FilterButtonCategory
---@return Widget
function FilterButtons.getButtonRow(category)
	local transformValueToText = category.transform or FnUtil.identity
	local itemToPropertyValues = category.itemToPropertyValues or FnUtil.identity
	local makeButton = FnUtil.curry(FilterButtons._makeButton, category)

	local buttons = FilterButtonRow{
		categoryName = category.name,
		featuredByDefault = category.featuredByDefault,
		hasFeatured = category.hasFeatured,
		buttons = Array.map(category.items or {}, function (value)
			local text = transformValueToText(value)
			local filterValue = itemToPropertyValues(value) or value
			return makeButton(filterValue, text)
		end),
		expandKey = category.expandKey
	}

	if category.expandable then
		return Div{
			classes = { 'filter-category--hidden' },
			attributes = {
				['data-filter-group'] = 'tournaments-list-dropdown-' .. category.name,
				['data-filter-category'] = 'dropdown-' .. category.name
			},
			children = { buttons }
		}
	end

	return buttons
end

return FilterButtons
