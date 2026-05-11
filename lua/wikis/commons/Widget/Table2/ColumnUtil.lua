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

local INHERITABLE_PROPS = {
	'align', 'shrink', 'nowrap', 'width', 'minWidth', 'maxWidth',
	'sortType', 'unsortable',
}

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
---Adds valid props from columnDef to cellProps (mutates)
---@param cellProps table
---@param columnDef table?
function ColumnUtil.mergeProps(cellProps, columnDef)
	if not columnDef then
		return
	end

	Array.forEach(INHERITABLE_PROPS, function(prop)
		if cellProps[prop] == nil and columnDef[prop] ~= nil then
			cellProps[prop] = columnDef[prop]
		end
	end)

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
---@return table css
function ColumnUtil.buildCss(width, minWidth, maxWidth, existingCss)
	if not width and not minWidth and not maxWidth then
		return existingCss or {}
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

	if Logic.readBool(nowrap) then
		attrs['data-nowrap'] = ''
	end

	if Logic.readBool(shrink) then
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
		attributes.colspan = MathUtil.toInteger(mergedProps.colspan) or mergedProps.colspan
	end

	if mergedProps.rowspan then
		attributes.rowspan = MathUtil.toInteger(mergedProps.rowspan) or mergedProps.rowspan
	end

	if additionalAttributeBuilders then
		Table.iter.forEachPair(additionalAttributeBuilders, function(key, builder)
			builder(attributes, mergedProps)
		end)
	end

	return attributes
end

return ColumnUtil
