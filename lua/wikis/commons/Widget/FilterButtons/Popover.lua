---
-- @Liquipedia
-- page=Module:Widget/FilterButtons/Popover
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FilterButtonsUtil = Lua.import('Module:FilterButtons/Util')
local FnUtil = Lua.import('Module:FnUtil')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Utils')

local Button = Lua.import('Module:Widget/Basic/Button')
local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local CLASS_NAME = 'filter-popover'
-- Items are laid out in columns of at most this many rows
local MAX_ROWS = 6

local DEFAULT_TITLES = {
	game = 'Game',
	liquipediatier = 'Tier',
	liquipediatiertype = 'Type',
	region = 'Region',
}

local CLEAR_LABEL = 'Clear'
local SELECT_ALL_LABEL = 'Select all'

---@class FilterButtonsPopoverProps
---@field categories FilterButtonCategory[]?
---@field filterGroupPrefix string prefix of the filter groups; must not be shared with other filter buttons on the page
---@field label string?

local defaultProps = {
	label = 'Filter',
}

---Mirrors the display logic in FilterButtons.js: a category with everything selected is unrestricted
---and shown with nothing checked
---@param category FilterButtonCategory
---@param values string[]
---@return table<string, boolean>
local function getInitialCheckedStates(category, values)
	local states = Table.map(values, function (_, value)
		return value, Table.includes(category.defaultItems, value)
	end)
	if Array.all(values, function (value) return states[value] end) then
		return Table.map(states, function (value) return value, false end)
	end
	return states
end

---@param tier string
---@return VNode?
local function TierBadge(tier)
	local identifier = Tier.toIdentifier(tier)
	local tierShort = Tier.toShortName(tier)
	if String.isEmpty(tierShort) then
		return
	end
	local isNumberedTier = type(identifier) == 'number' and identifier >= 1 and identifier <= 5
	return Html.Span{
		classes = {
			CLASS_NAME .. '__tier-badge',
			CLASS_NAME .. '__tier-badge--' .. (isNumberedTier and ('tier' .. identifier) or 'misc'),
		},
		attributes = {['aria-hidden'] = 'true'},
		children = tierShort,
	}
end

---@param filterGroupPrefix string
---@param category FilterButtonCategory
---@return VNode
local function FilterCategory(filterGroupPrefix, category)
	assert(
		Table.isNotEmpty(category.items),
		category.name .. ': List of items is required, either input or filled during load'
	)
	local transformValueToText = category.transform or FnUtil.identity
	local itemToPropertyValues = category.itemToPropertyValues or FnUtil.identity
	local groupName = filterGroupPrefix .. '-' .. category.name
	local title = category.title or DEFAULT_TITLES[category.name] or String.upperCaseFirst(category.name)
	local isTierCategory = category.name == 'liquipediatier'

	local values = Array.map(category.items, function (item)
		return itemToPropertyValues(item) or item
	end)
	local checkedStates = getInitialCheckedStates(category, values)
	local checkedCount = #Array.filter(values, function (value) return checkedStates[value] end)
	local columns = math.ceil(#values / MAX_ROWS)

	local items = Array.map(category.items, function (item, index)
		local value = values[index]
		return Html.Div{
			classes = {CLASS_NAME .. '__item'},
			attributes = {
				['data-filter-on'] = value,
				['data-filter-default'] = tostring(Table.includes(category.defaultItems, value)),
				role = 'checkbox',
				['aria-checked'] = tostring(checkedStates[value]),
			},
			children = {
				Html.Span{
					classes = {CLASS_NAME .. '__checkbox'},
					children = IconFa{iconName = 'correct', screenReaderHidden = true},
				},
				Html.Span{
					classes = {CLASS_NAME .. '__item-label'},
					children = transformValueToText(item),
				},
				isTierCategory and TierBadge(item) or nil,
			},
		}
	end)

	return Html.Div{
		classes = {
			CLASS_NAME .. '__category',
			columns > 1 and (CLASS_NAME .. '__category--multi-column') or nil,
		},
		children = {
			Html.Div{
				classes = {CLASS_NAME .. '__category-header'},
				children = {
					Html.Span{
						classes = {CLASS_NAME .. '__category-title'},
						children = title,
					},
					Html.Span{
						classes = {
							CLASS_NAME .. '__category-count',
							checkedCount == 0 and (CLASS_NAME .. '__category-count--empty') or nil,
						},
						attributes = {['data-filter-popover-category-count'] = groupName},
						children = checkedCount,
					},
					Html.Span{
						classes = {CLASS_NAME .. '__category-action'},
						attributes = {
							['data-filter-popover-toggle-all'] = groupName,
							['data-label-clear'] = CLEAR_LABEL,
							['data-label-select-all'] = SELECT_ALL_LABEL,
							role = 'button',
							tabindex = '0',
						},
						children = checkedCount > 0 and CLEAR_LABEL or SELECT_ALL_LABEL,
					},
				},
			},
			Html.Div{
				classes = {CLASS_NAME .. '__items'},
				css = columns > 1 and {['--filter-popover-columns'] = columns} or nil,
				attributes = {
					['data-filter'] = 'data-filter',
					['data-filter-staged'] = '',
					['data-filter-effect'] = 'fade',
					['data-filter-group'] = groupName,
				},
				children = items,
			},
		},
	}
end

---@param action 'reset'|'cancel'|'apply'
---@param variant 'ghost'|'secondary'|'primary'
---@param children Renderable|Renderable[]
---@return VNode
local function FooterButton(action, variant, children)
	return Button{
		classes = {CLASS_NAME .. '__button', CLASS_NAME .. '__button--' .. action},
		variant = variant,
		size = 'sm',
		attributes = {['data-filter-popover-action'] = action},
		children = children,
	}
end

---Filter buttons displayed as checkboxes in a popover. Changes are only applied once confirmed.
---The interactivity is provided by FilterButtons.js.
---@param props FilterButtonsPopoverProps
---@return VNode
local function FilterButtonsPopover(props)
	local categories = props.categories or Lua.import('Module:FilterButtons/Config').categories
	local filterGroupPrefix = props.filterGroupPrefix
	assert(String.isNotEmpty(filterGroupPrefix), 'FilterButtonsPopover: filterGroupPrefix is required')

	Array.forEach(categories, FilterButtonsUtil.loadCategory)

	return Html.Div{
		classes = {CLASS_NAME},
		attributes = {['data-filter-popover'] = ''},
		children = {
			-- Replaced with a <button> by FilterButtons.js, as the parser does not allow them.
			-- The `button` class opts out of the skin's default styling of <button> elements.
			Html.Div{
				classes = {CLASS_NAME .. '__toggle', 'button'},
				attributes = {['data-filter-popover-toggle'] = ''},
				children = {
					Html.Span{
						classes = {CLASS_NAME .. '__toggle-label'},
						children = {
							props.label,
							Html.Span{
								classes = {CLASS_NAME .. '__toggle-count'},
								attributes = {['data-filter-popover-count'] = ''},
							},
						},
					},
					IconFa{iconName = 'expand', screenReaderHidden = true},
				},
			},
			Html.Div{
				classes = {CLASS_NAME .. '__panel'},
				attributes = {
					role = 'dialog',
					['aria-label'] = props.label,
				},
				children = {
					Html.Div{
						classes = {CLASS_NAME .. '__categories'},
						children = Array.map(categories, FnUtil.curry(FilterCategory, filterGroupPrefix)),
					},
					Html.Div{
						classes = {CLASS_NAME .. '__footer'},
						children = {
							FooterButton('reset', 'ghost', 'Reset'),
							Html.Div{
								classes = {CLASS_NAME .. '__footer-end'},
								children = {
									FooterButton('cancel', 'secondary', 'Cancel'),
									FooterButton('apply', 'primary', 'Apply'),
								},
							},
						},
					},
				},
			},
		},
	}
end

return Component.component(FilterButtonsPopover, defaultProps)
