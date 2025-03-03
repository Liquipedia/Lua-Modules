---
-- @Liquipedia
-- wiki=commons
-- page=Module:FilterButtons
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local I18n = require('Module:I18n')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Table = require('Module:Table')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span
local WidgetUtil = Lua.import('Module:Widget/Util')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local FilterButtons = {}

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

---Builds filterbuttons based on config stored in Module:FilterButtons/Config
---Can be used from wikicode
---@return Widget
function FilterButtons.getFromConfig()
	return FilterButtons.get(Lua.import('Module:FilterButtons/Config').categories)
end

---Entrypoint building a set of FilterButtons
---@param categories FilterButtonCategory[]
---@return Widget
function FilterButtons.get(categories)
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
---@return WidgetHtml
function FilterButtons._makeButton(category, value, text)
	return Span{
		classes = {
			'filter-button',
			Table.includes(category.defaultItems, value) and 'filter-button--active' or nil
		},
		attributes = { ['data-filter-on'] = value },
		children = { text }
	}
end

---@param category FilterButtonCategory
---@return Widget
function FilterButtons.getButtonRow(category)
	local transformValueToText = category.transform or FnUtil.identity
	local itemToPropertyValues = category.itemToPropertyValues or FnUtil.identity

	local buttons = Div{
		classes = {'filter-buttons'},
		attributes = {
			['data-filter'] = 'data-filter',
			['data-filter-effect'] = 'fade',
			['data-filter-group'] = 'filterbuttons-' .. category.name,
			['data-filter-default-curated'] = category.featuredByDefault and 'true' or nil,
		},
		children = WidgetUtil.collect(
			Span{
				classes = { 'filter-button', 'filter-button-all' },
				attributes = { ['data-filter-on'] = 'all' },
				children = { I18n.translate('filterbuttons-all') }
			},
			category.hasFeatured and FilterButtons._makeButton(category, 'curated', I18n.translate('filterbuttons-featured')),
			Array.map(category.items or {}, function (value)
				local text = transformValueToText(value)
				local filterValue = itemToPropertyValues(value) or value
				return FilterButtons._makeButton(category, filterValue, text)
			end),
			String.isNotEmpty(category.expandKey) and Div{
				classes = { 'filter-buttons' },
				attributes = {
					['data-filter'] = 'data-filter',
					['data-filter-effect'] ='fade',
					['data-filter-group'] = 'tournaments-list-dropdown-' .. category.expandKey
				},
				children = {
					Span{
						classes = { 'filter-button', 'filter-button-dropdown' },
						attributes = { ['data-filter-on'] = 'dropdown-' .. category.expandKey },
						children = { IconFa{iconName = 'expand'} }
					},
					Span{
						classes = { 'filter-button' },
						css = { display = 'none' },
						attributes = { ['data-filter-on'] = 'all'}
					}
				}
			} or nil
		)
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

return Class.export(FilterButtons)
