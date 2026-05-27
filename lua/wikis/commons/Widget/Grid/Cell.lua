---
-- @Liquipedia
-- page=Module:Widget/Grid/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

local GRID_WIDTHS = {
	'xs',
	'sm',
	'md',
	'lg',
	'xl',
	'xxl',
	'xxxl'
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

---@param width string
---@return string[]
local function getCellClasses(props, width)
	local widthPrefix = ''
	if width ~= 'xs' then
		if props[width] == 'default' then
			widthPrefix = width
		else
			widthPrefix = width .. '-'
		end
	end
	if props[width] == 'ignore' then
		return {'lp-d-' .. widthPrefix .. 'contents'}
	elseif props[width] == 'default' then
		return {'lp-d-' .. widthPrefix .. '-block', 'lp-col-' .. widthPrefix}
	else
		return {'lp-d-' .. widthPrefix .. 'block', 'lp-col-' .. widthPrefix .. props[width]}
	end
end

---@param props table
---@return VNode
function GridCell(props)
	local cellClasses = { 'lp-col' }
	Array.forEach(GRID_WIDTHS, function (width)
		if props[width] then
			Array.extendWith(cellClasses, getCellClasses(props, width))
		end
		if props['order-' .. width] then
			local width_prefix = width ~= 'xs' and width .. '-' or ''
			Array.appendWith(
				cellClasses, 'lp-order-' .. width_prefix .. props['order-' .. width]
			)
		end
		Array.forEach(GRID_DIRECTIONS, function (direction)
			if props['m' .. direction .. '-' .. width] then
				local width_prefix = width ~= 'xs' and width .. '-' or ''
				Array.appendWith(
					cellClasses,
					'm' .. direction .. '-' .. width_prefix .. props['m' .. direction .. '-' .. width]
				)
			end
		end)
	end)

	if Array.all(GRID_WIDTHS, function (width)
		return props[width] == nil
	end) and not Logic.readBool(props.noDefault) then
		Array.appendWith(cellClasses, 'lp-col-12')
	end

	return Html.Div{
		classes = cellClasses,
		children = props.cellContent
	}
end

return Component.component(GridCell)
