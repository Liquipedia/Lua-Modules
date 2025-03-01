---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Grid/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

local GRID_WIDTHS = {
	'xs',
	'sm',
	'md',
	'lg',
	'xl',
	'xxl'
}

local GRID_DIRECTIONS = {
	'',
	'x',
	'y',
	'l',
	'r',
	't',
	'b'
}

---@class GridCell: Widget
---@operator call(table): Panel
---@field props table<string, any>
local GridCell = Class.new(Widget)

---@return Widget
function GridCell:render()
	local addedSpecificClass = false

	local cellClasses = { 'lp-col' }
	for _, width in ipairs( GRID_WIDTHS ) do
		if self.props[ width ] then
			addedSpecificClass = true
			local widthPrefix = ''
			if width == 'xs' then
				addedSpecificClass = true
			elseif self.props[ width ] == 'default' then
				widthPrefix = width
			else
				widthPrefix = width .. '-'
			end
			if self.props[ width ] == 'ignore' then
				Array.extendWith(cellClasses, {'lp-d-' .. widthPrefix .. 'contents'})
			elseif self.props.width == 'default' then
				Array.extendWith(cellClasses, {'lp-d-' .. widthPrefix .. '-block', 'lp-col-' .. widthPrefix})
			else
				Array.extendWith(cellClasses, {'lp-d-' .. widthPrefix .. 'block', 'lp-col-' .. widthPrefix .. self.props[ width ]})
			end
		end
		if self.props[ 'order-' .. width ] then
			local width_prefix = width ~= 'xs' and width .. '-' or ''
			Array.extendWith(cellClasses, {'lp-order-' .. width_prefix .. self.props[ 'order-' .. width ]})
		end
		for _, direction in ipairs( GRID_DIRECTIONS ) do
			if self.props[ 'm' .. direction .. '-' .. width ] then
				local width_prefix = width ~= 'xs' and width .. '-' or ''
				Array.extendWith(cellClasses, {'m' .. direction .. '-' .. width_prefix .. self.props[ 'm' .. direction .. '-' .. width ]})
			end
		end
	end

	if not addedSpecificClass and not self.props.noDefault then
		Array.extendWith(cellClasses, 'lp-col-12')
	end

	return Div{
		classes = cellClasses,
		children = self.props.cellContent
	}
end

return GridCell
