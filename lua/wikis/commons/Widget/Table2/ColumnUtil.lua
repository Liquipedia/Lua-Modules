---
-- @Liquipedia
-- page=Module:Widget/Table2/ColumnUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local WidgetUtil = Lua.import('Module:Widget/Util')

local ColumnUtil = {}

---Validates that shrink and width are not both specified
---@param columnDef table
---@return boolean valid
---@return string|nil errorMsg
function ColumnUtil.validateColumnDef(columnDef)
	if Logic.readBool(columnDef.shrink) and columnDef.width then
		return false, 'Column definition cannot have both shrink and width properties'
	end
	return true, nil
end

---Gets the column index for this cell
---@param columnIndexProp integer|string|nil - explicit column index from props
---@param columnIndexContext integer|string|nil - implicit column index from context
---@return integer
function ColumnUtil.getColumnIndex(columnIndexProp, columnIndexContext)
	local index = tonumber(columnIndexProp) or tonumber(columnIndexContext)
	return index or 1
end

---Merges column definition properties with cell properties
---Cell props take precedence over column props
---@param cellProps table
---@param columnDef table|nil
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
---@param width string|nil
---@param minWidth string|nil
---@param maxWidth string|nil
---@param existingCss table|nil
---@return table css
function ColumnUtil.buildCss(width, minWidth, maxWidth, existingCss)
	local css = Table.copy(existingCss or {})

	if width then
		css['width'] = width
	end

	if minWidth then
		css['min-width'] = minWidth
	end

	if maxWidth then
		css['max-width'] = maxWidth
	end

	return css
end

---Builds CSS classes for column styling
---@param align string|nil
---@param nowrap boolean|nil
---@param shrink boolean|nil
---@param existingClasses string[]|nil
---@return string[] classes
function ColumnUtil.buildClasses(align, nowrap, shrink, existingClasses)
	local classes = Table.copy(existingClasses or {})

	if align == 'right' then
		table.insert(classes, 'table2__cell--right')
	elseif align == 'center' then
		table.insert(classes, 'table2__cell--center')
	else
		table.insert(classes, 'table2__cell--left')
	end

	if Logic.readBool(nowrap) then
		table.insert(classes, 'table2__cell--nowrap')
	end

	if Logic.readBool(shrink) then
		table.insert(classes, 'table2__cell--shrink')
	end

	return classes
end

return ColumnUtil
