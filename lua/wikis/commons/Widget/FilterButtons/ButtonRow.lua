---
-- @Liquipedia
-- page=Module:Widget/FilterButtons/ButtonRow
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local I18n = Lua.import('Module:I18n')
local String = Lua.import('Module:StringUtils')

local Component = Lua.import('Module:Widget/Component')
local FilterButton = Lua.import('Module:Widget/FilterButtons/Button')
local Html = Lua.import('Module:Widget/Html')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class FilterButtonRowParameters
---@field categoryName string
---@field buttons (FilterButton?)[]
---@field expandKey string?
---@field featuredByDefault boolean?
---@field hasFeatured boolean?

local CLASS_NAME = 'filter-buttons'

---@param props FilterButtonRowParameters
---@return VNode
local function FilterButtonRow(props)
	return Html.Div{
		classes = {CLASS_NAME},
		attributes = {
			['data-filter'] = 'data-filter',
			['data-filter-effect'] = 'fade',
			['data-filter-group'] = 'filterbuttons-' .. props.categoryName,
			['data-filter-default-curated'] = props.featuredByDefault and 'true' or nil,
		},
		children = WidgetUtil.collect(
			FilterButton{
				buttonClasses = { 'filter-button-all' },
				value = 'all',
				display = I18n.translate('filterbuttons-all')
			},
			props.hasFeatured and FilterButton{
				value = 'curated',
				display = I18n.translate('filterbuttons-featured')
			},
			props.buttons,
			String.isNotEmpty(props.expandKey) and Html.Div{
				classes = {CLASS_NAME},
				attributes = {
					['data-filter'] = 'data-filter',
					['data-filter-effect'] ='fade',
					['data-filter-group'] = 'tournaments-list-dropdown-' .. props.expandKey
				},
				children = {
					FilterButton{
						buttonClasses = { 'filter-button-dropdown' },
						value = 'dropdown-' .. props.expandKey,
						display = IconFa{iconName = 'expand'}
					},
					FilterButton{
						css = { display = 'none' },
						value = 'all'
					}
				}
			} or nil
		)
	}
end

return Component.component(FilterButtonRow)
