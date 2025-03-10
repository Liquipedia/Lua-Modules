---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/FilterButtons/ButtonRow
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local I18n = require('Module:I18n')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Widget = Lua.import('Module:Widget')
local FilterButton = Lua.import('Module:Widget/FilterButtons/Button')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class FilterButtonRowParameters
---@field categoryName string
---@field buttons (FilterButton?)[]
---@field expandKey string?
---@field featuredByDefault boolean?
---@field hasFeatured boolean?

local CLASS_NAME = 'filter-buttons'

---@class FilterButtonRow: Widget
---@operator call(table): FilterButtonRow
---@field props FilterButtonRowParameters
local FilterButtonRow = Class.new(Widget)

---@return Widget
function FilterButtonRow:render()
	return HtmlWidgets.Div{
		classes = {CLASS_NAME},
		attributes = {
			['data-filter'] = 'data-filter',
			['data-filter-effect'] = 'fade',
			['data-filter-group'] = 'filterbuttons-' .. self.props.categoryName,
			['data-filter-default-curated'] = self.props.featuredByDefault and 'true' or nil,
		},
		children = WidgetUtil.collect(
			FilterButton{
				buttonClasses = { 'filter-button-all' },
				value = 'all',
				display = I18n.translate('filterbuttons-all')
			},
			self.props.hasFeatured and FilterButton{
				value = 'curated',
				display = I18n.translate('filterbuttons-featured')
			},
			self.props.buttons,
			String.isNotEmpty(self.props.expandKey) and HtmlWidgets.Div{
				classes = {CLASS_NAME},
				attributes = {
					['data-filter'] = 'data-filter',
					['data-filter-effect'] ='fade',
					['data-filter-group'] = 'tournaments-list-dropdown-' .. self.props.expandKey
				},
				children = {
					FilterButton{
						buttonClasses = { 'filter-button-dropdown' },
						value = 'dropdown-' .. self.props.expandKey,
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

return FilterButtonRow
