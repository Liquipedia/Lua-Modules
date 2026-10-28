---
-- @Liquipedia
-- page=Module:Widget/Table2/ColumnUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Table = Lua.import('Module:Table')
local WidgetUtil = Lua.import('Module:Widget/Util')

local ColumnUtil = {}

local INHERITABLE_PROPS = {
	'align', 'shrink', 'nowrap', 'width', 'minWidth', 'maxWidth',
	'sortType', 'unsortable',
}

-- The inheritable props each column definition sets, so cells only check those
local inheritedPropsByColumn = setmetatable({}, {__mode = 'k'})

---@param columnDef table
---@return string[]
local function getInheritedProps(columnDef)
	local inheritedProps = inheritedPropsByColumn[columnDef]
	if not inheritedProps then
		inheritedProps = {}
		for _, prop in ipairs(INHERITABLE_PROPS) do
			if columnDef[prop] ~= nil then
				table.insert(inheritedProps, prop)
			end
		end
		inheritedPropsByColumn[columnDef] = inheritedProps
	end
	return inheritedProps
end

---Logic.readBool, without the string comparisons for the common unset and boolean values
---@param value (string|number|boolean)?
---@return boolean
local function readBool(value)
	if value == nil or value == false then
		return false
	elseif value == true then
		return true
	end
	return Logic.readBool(value)
end

---Converts a value to an integer, like MathUtil.toInteger
---Integers and nil, the common cases for cell props, skip the string parsing
---@param value any
---@return integer?
function ColumnUtil.toInteger(value)
	if value == nil then
		return nil
	elseif type(value) == 'number' and value % 1 == 0 then
		return value
	end
	return MathUtil.toInteger(value)
end

---Gets the column index for this cell
---@param columnIndexProp integer|string? - explicit column index from props
---@param columnIndexContext integer|string? - implicit column index from context
---@return integer
function ColumnUtil.getColumnIndex(columnIndexProp, columnIndexContext)
	local index = ColumnUtil.toInteger(columnIndexProp) or ColumnUtil.toInteger(columnIndexContext)
	return index or 1
end

---Merges column definition properties with cell properties
---Cell props take precedence over column props
---Adds valid props from columnDef to cellProps (mutates)
---@param cellProps table
---@param columnDef table?
function ColumnUtil.mergeProps(cellProps, columnDef)
	if not columnDef then
		return
	end

	for _, prop in ipairs(getInheritedProps(columnDef)) do
		if cellProps[prop] == nil and columnDef[prop] ~= nil then
			cellProps[prop] = columnDef[prop]
		end
	end

	if columnDef.css then
		cellProps.css = Table.merge(columnDef.css, cellProps.css or {})
	end
	if columnDef.classes then
		cellProps.classes = WidgetUtil.collect(columnDef.classes, cellProps.classes)
	end
	if columnDef.attributes then
		cellProps.attributes = Table.merge(columnDef.attributes, cellProps.attributes or {})
	end
end

---Builds CSS rules for sizing
---@param width string?
---@param minWidth string?
---@param maxWidth string?
---@param existingCss table?
---@return table? css
function ColumnUtil.buildCss(width, minWidth, maxWidth, existingCss)
	if not width and not minWidth and not maxWidth then
		return existingCss
	end

	return Table.merge(existingCss or {}, {
		width = width,
		['min-width'] = minWidth,
		['max-width'] = maxWidth,
	})
end

---Builds data attributes for cell styling (align, nowrap, shrink)
---@param align string?
---@param nowrap (string|number|boolean)?
---@param shrink (string|number|boolean)?
---@param existingAttributes table?
---@return table attributes
function ColumnUtil.buildCellAttributes(align, nowrap, shrink, existingAttributes)
	local attrs = existingAttributes or {}

	if align == 'right' or align == 'center' then
		attrs['data-align'] = align
	end

	if readBool(nowrap) then
		attrs['data-nowrap'] = ''
	end

	if readBool(shrink) then
		attrs['data-shrink'] = ''
	end

	return attrs
end

---Builds HTML attributes for cells and headers
---@param mergedProps table - merged cell/header properties
---@param additionalAttributeBuilders {[string]: function}? - optional callbacks for additional attributes
---@return table attributes
function ColumnUtil.buildAttributes(mergedProps, additionalAttributeBuilders)
	local attributes = mergedProps.attributes or {}

	if mergedProps.colspan then
		attributes.colspan = ColumnUtil.toInteger(mergedProps.colspan) or mergedProps.colspan
	end

	if mergedProps.rowspan then
		attributes.rowspan = ColumnUtil.toInteger(mergedProps.rowspan) or mergedProps.rowspan
	end

	if additionalAttributeBuilders then
		Table.iter.forEachPair(additionalAttributeBuilders, function(key, builder)
			builder(attributes, mergedProps)
		end)
	end

	return attributes
end

return ColumnUtil
