local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Table = require('Module:Table')

local FilterButtons = {}

local DROPDOWN_ARROW = '&#8203;▼&#8203;'

---@class FilterButtonCategory
---@field name string
---@field query string?
---@field items string[]?
---@field defaultItems string[]?
---@field transform? fun(item: string): string
---@field expandKey string?
---@field expandable boolean?
---@field order? fun(a: string, b: string): boolean
---@field load? fun(cat: FilterButtonCategory): FilterButtonCategory

---Builds filterbuttons based on config stored in Module:FilterButtons/Config
---Can be used from wikicode
---@return Html
function FilterButtons.getFromConfig()
	return FilterButtons.get(require('Module:FilterButtons/Config').categories)
end

---Entrypoint building a set of FilterButtons
---@param categories FilterButtonCategory[]
---@return Html
function FilterButtons.get(categories)
	Array.mapValues(categories, FilterButtons._loadCategory)

	local div = mw.html.create('div')

	for index, category in ipairs(categories) do
		-- Variable used to pass default values on to other modules using these.
		Variables.varDefine('filterbuttons_defaults_' .. category.name, table.concat(category.defaultItems, ','))
		div:node(FilterButtons.getButtonRow(category))
	end

	return div
end

---@param category FilterButtonCategory
---@return FilterButtonCategory
function FilterButtons._loadCategory(category)
	if category.load then
		category = category.load(category)
		return category
	end

	if category.order then
		Array.orderInPlaceBy(category.items, category.order)
	end

	category.defaultItems = Logic.emptyOr(category.defaultItems, category.items)

	return category
end

---@param category FilterButtonCategory
---@return Html
function FilterButtons.getButtonRow(category)
	local buttons = mw.html.create('div')
		:addClass('filter-buttons')
		:attr('data-filter', 'data-filter')
		:attr('data-filter-effect','fade')
		:attr('data-filter-group', 'filterbuttons-' .. category.name)
		:tag('span')
			:addClass('filter-button')
			:addClass('filter-button-all')
			:attr('data-filter-on', 'all')
			:wikitext('All')
			:done()

	for _, value in ipairs(category.items or {}) do
		local text = category.transform and category.transform(value) or value
		local button = mw.html.create('span')
			:addClass('filter-button')
			:css('font-size','10pt')
			:css('flex-grow','1')
			:css('max-width','33%')
			:css('text-overflow','ellipsis')
			:css('overflow','hidden')
			:css('text-align','center')
			:css('padding', '2px')
			:attr('data-filter-on', value)
			:wikitext(text)
		if Table.includes(category.defaultItems, value) then
			button:addClass('filter-button--active')
		end
		buttons:node(button)
	end

	if String.isNotEmpty(category.expandKey) then
		local dropdownButton = mw.html.create('div')
			:addClass('filter-buttons')
			:addClass('filter-buttons-dropdown')
			:attr('data-filter', 'data-filter')
			:attr('data-filter-effect','fade')
			:attr('data-filter-group', 'tournaments-list-dropdown-' .. category.expandKey)
			:node(mw.html.create('span')
				:addClass('filter-button')
				:css('font-size','8pt')
				:css('padding-left','2px')
				:css('padding-right','2px')
				:attr('data-filter-on', 'dropdown-' .. category.expandKey)
				:wikitext(DROPDOWN_ARROW))
		buttons:node(dropdownButton)
	end

	if category.expandable then
		local section = mw.html.create('div')
			:addClass('filter-category--hidden')
			:attr('data-filter-group', 'tournaments-list-dropdown-' .. category.name)
			:attr('data-filter-category', 'dropdown-' .. category.name)
			:css('margin-top','-8px')
			:node(buttons)
		return section
	end

	return buttons
end

return Class.export(FilterButtons)
