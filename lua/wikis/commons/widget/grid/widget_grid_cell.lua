---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Grid/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
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
---@operator call(table): GridCell
---@field props table<string, any>
local GridCell = Class.new(Widget)

---@param width string
---@return string[]
function GridCell:_getCellClasses(width)
	local widthPrefix = ''
	if width ~= 'xs' then
		if self.props[width] == 'default' then
			widthPrefix = width
		else
			widthPrefix = width .. '-'
		end
	end
	if self.props[width] == 'ignore' then
		return {'lp-d-' .. widthPrefix .. 'contents'}
	elseif self.props[width] == 'default' then
		return {'lp-d-' .. widthPrefix .. '-block', 'lp-col-' .. widthPrefix}
	else
		return {'lp-d-' .. widthPrefix .. 'block', 'lp-col-' .. widthPrefix .. self.props[width]}
	end
end

---@return Widget
function GridCell:render()
	local cellClasses = { 'lp-col' }
	Array.forEach(GRID_WIDTHS, function (width)
		if self.props[width] then
			Array.extendWith(cellClasses, self:_getCellClasses(width))
		end
		if self.props['order-' .. width] then
			local width_prefix = width ~= 'xs' and width .. '-' or ''
			Array.appendWith(
				cellClasses, 'lp-order-' .. width_prefix .. self.props['order-' .. width]
			)
		end
		Array.forEach(GRID_DIRECTIONS, function (direction)
			if self.props['m' .. direction .. '-' .. width] then
				local width_prefix = width ~= 'xs' and width .. '-' or ''
				Array.appendWith(
					cellClasses,
					'm' .. direction .. '-' .. width_prefix .. self.props['m' .. direction .. '-' .. width]
				)
			end
		end)
	end)

	if Array.all(GRID_WIDTHS, function (width)
		return self.props[width] == nil
	end) and not Logic.readBool(self.props.noDefault) then
		Array.appendWith(cellClasses, 'lp-col-12')
	end

	return Div{
		classes = cellClasses,
		children = self.props.cellContent
	}
end

return GridCell
