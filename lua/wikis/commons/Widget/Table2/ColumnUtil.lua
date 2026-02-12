---
-- @Liquipedia
-- page=Module:Widget/Table2/ColumnUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Table = Lua.import('Module:Table')
local WidgetUtil = Lua.import('Module:Widget/Util')

local ColumnUtil = {}

---Gets the column index for this cell
---@param columnIndexProp integer|string? - explicit column index from props
---@param columnIndexContext integer|string? - implicit column index from context
---@return integer
function ColumnUtil.getColumnIndex(columnIndexProp, columnIndexContext)
	local index = MathUtil.toInteger(columnIndexProp) or MathUtil.toInteger(columnIndexContext)
	return index or 1
end

---Merges column definition properties with cell properties
---Cell props take precedence over column props
---@param cellProps table
---@param columnDef table?
---@return table mergedProps
function ColumnUtil.mergeProps(cellProps, columnDef)
	if not columnDef then
		return cellProps
	end

	local merged = Table.copy(cellProps or {})

	local inheritableProps = {
		'align', 'shrink', 'nowrap', 'width', 'minWidth', 'maxWidth',
		'sortType', 'unsortable',
	}

	Array.forEach(inheritableProps, function(prop)
		if merged[prop] == nil and columnDef[prop] ~= nil then
			merged[prop] = columnDef[prop]
		end
	end)

	if columnDef.css then
		merged.css = Table.merge(columnDef.css, merged.css or {})
	end

	if columnDef.classes then
		merged.classes = WidgetUtil.collect(columnDef.classes, merged.classes)
	end

	if columnDef.attributes then
		merged.attributes = Table.merge(columnDef.attributes, merged.attributes or {})
	end

	return merged
end

---Builds CSS rules for sizing
---@param width string?
---@param minWidth string?
---@param maxWidth string?
---@param existingCss table?
---@return table css
function ColumnUtil.buildCss(width, minWidth, maxWidth, existingCss)
	return Table.merge(existingCss or {}, {
		width = width,
		['min-width'] = minWidth,
		['max-width'] = maxWidth,
	})
end

---Builds CSS classes for column styling
---@param align string?
---@param nowrap (string|number|boolean)?
---@param shrink (string|number|boolean)?
---@param existingClasses string[]?
---@return string[] classes
function ColumnUtil.buildClasses(align, nowrap, shrink, existingClasses)
	local classes = {}

	if align == 'right' then
		Array.appendWith(classes, 'table2__cell--right')
	elseif align == 'center' then
		Array.appendWith(classes, 'table2__cell--center')
	else
		Array.appendWith(classes, 'table2__cell--left')
	end

	if Logic.readBool(nowrap) then
		Array.appendWith(classes, 'table2__cell--nowrap')
	end

	if Logic.readBool(shrink) then
		Array.appendWith(classes, 'table2__cell--shrink')
	end

	return Array.extendWith(classes, existingClasses)
end

return ColumnUtil
