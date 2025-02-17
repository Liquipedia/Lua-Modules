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

local FilterButtons = {}

local DROPDOWN_ARROW = '&#8203;▼&#8203;'

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
---@return Html
function FilterButtons.getFromConfig()
	return FilterButtons.get(Lua.import('Module:FilterButtons/Config').categories)
end

---Entrypoint building a set of FilterButtons
---@param categories FilterButtonCategory[]
---@return Html
function FilterButtons.get(categories)
	Array.forEach(categories, FilterButtons._loadCategories)

	local div = mw.html.create('div')

	for _, category in ipairs(categories) do
		-- Variable used to pass default values on to other modules using these.
		assert(
			Table.isNotEmpty(category.items), category.name .. ': List of items is required, either input or filled during load'
		)
		Variables.varDefine('filterbuttons_defaults_' .. category.name, table.concat(category.defaultItems, ','))
		local buttons = FilterButtons.getButtonRow(category)
		div:node(buttons)
	end

	return div
end

---@param category FilterButtonCategory
function FilterButtons._loadCategories(category)
	if category.load then
		category.load(category)
	end

	if category.order then
		Array.orderInPlaceBy(category.items, category.order)
	end

	category.defaultItems = Logic.emptyOr(category.defaultItems, category.items)
end

---@param category FilterButtonCategory
---@return Html
function FilterButtons.getButtonRow(category)
	local buttons = mw.html.create('div')
		:addClass('filter-buttons')
		:attr('data-filter', 'data-filter')
		:attr('data-filter-effect','fade')
		:attr('data-filter-group', 'filterbuttons-' .. category.name)
		:attr('data-filter-default-curated', category.featuredByDefault and 'true' or nil)
		:tag('span')
			:addClass('filter-button')
			:addClass('filter-button-all')
			:attr('data-filter-on', 'all')
			:wikitext(I18n.translate('filterbuttons-all'))
			:done()

	local makeButton = function(value, text)
		local button = mw.html.create('span')
			:addClass('filter-button')
			:attr('data-filter-on', value)
			:wikitext(text)
		if Table.includes(category.defaultItems, value) then
			button:addClass('filter-button--active')
		end
		buttons:node(button)
	end

	if category.hasFeatured then
		makeButton('curated', I18n.translate('filterbuttons-featured'))
	end

	local transformValueToText = category.transform or FnUtil.identity
	local itemToPropertyValues = category.itemToPropertyValues or FnUtil.identity
	for _, value in ipairs(category.items or {}) do
		local text = transformValueToText(value)
		local filterValue = itemToPropertyValues(value) or value
		makeButton(filterValue, text)
	end

	if String.isNotEmpty(category.expandKey) then
		local dropdownButton = mw.html.create('div')
			:addClass('filter-buttons')
			:attr('data-filter', 'data-filter')
			:attr('data-filter-effect','fade')
			:attr('data-filter-group', 'tournaments-list-dropdown-' .. category.expandKey)
			:node(mw.html.create('span')
				:addClass('filter-button')
				:addClass('filter-button-dropdown')
				:attr('data-filter-on', 'dropdown-' .. category.expandKey)
				:wikitext(DROPDOWN_ARROW))
			:node(mw.html.create('span')
				:addClass('filter-button')
				:css('display','none')
				:attr('data-filter-on', 'all'))

		buttons:node(dropdownButton)
	end

	if category.expandable then
		local section = mw.html.create('div')
			:addClass('filter-category--hidden')
			:attr('data-filter-group', 'tournaments-list-dropdown-' .. category.name)
			:attr('data-filter-category', 'dropdown-' .. category.name)
			:node(buttons)
		return section
	end

	return buttons
end

return Class.export(FilterButtons)
