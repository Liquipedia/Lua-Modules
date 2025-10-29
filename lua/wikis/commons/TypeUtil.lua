---
-- @Liquipedia
-- page=Module:TypeUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')

local TypeUtil = {}

function TypeUtil.literal (value)
	return {op = 'literal', value = value}
end

function TypeUtil.optional (typeSpec)
	if type(typeSpec) == 'string' then
		return Lua.import('Module:StringUtils').endsWith(typeSpec, '?')
			and typeSpec
			or typeSpec .. '?'
	else
		return {op = 'optional', type = typeSpec}
	end
end

function TypeUtil.union (...)
	return {op = 'union', types = Array.copy(arg)}
end

function TypeUtil.literalUnion (...)
	return TypeUtil.union(unpack(
		Array.map(arg, TypeUtil.literal)
	))
end

function TypeUtil.extendLiteralUnion (union, ...)
	return {
		op = 'union',
		types = Array.extend(union.types, Array.map(arg, TypeUtil.literal)),
	}
end

--[[
Non-strict structural type for tables. Tables may have additional entries not
in the structural type.
]]
function TypeUtil.struct (struct)
	return {op = 'struct', struct = struct}
end

--[[
Adds additional fields to a structural type.
]]
function TypeUtil.extendStruct (type, struct)
	return {op = 'struct', struct = Table.merge(type.struct, struct)}
end

--[[
Table type.
]]
function TypeUtil.table (keyType, valueType)
	if keyType or valueType then
		return {op = 'table', keyType = keyType or 'any', valueType = valueType or 'any'}
	else
		return 'table'
	end
end

--[[
Type for tables that are arrays. Not strict - arrays may have additional fields
besides numeric indexes, and may have gaps in indexes.
]]
function TypeUtil.array (elemType)
	if elemType then
		return {op = 'array', elemType = elemType}
	else
		return 'array'
	end
end

--[[
Whether a value satisfies a type, ignoring table contents. Table contents are
checked in TypeUtil.getTypeErrors.
]]
function TypeUtil.valueIsTypeNoTable (value, typeSpec)
	if type(typeSpec) == 'string' then
		if typeSpec == 'string'
			or typeSpec == 'number'
			or typeSpec == 'boolean'
			or typeSpec == 'function'
			or typeSpec == 'table'
			or typeSpec == 'nil' then
			return type(value) == typeSpec
		elseif typeSpec == 'pagename' then
			-- A pagename is a string, with first letter capitalized and may not contains spaces
			return type(value) == 'string' and value:find('^%u') and not value:find(' ')
		elseif Lua.import('Module:StringUtils').endsWith(typeSpec, '?') then
			return value == nil or TypeUtil.valueIsTypeNoTable(value, typeSpec:sub(1, -2))
		elseif typeSpec == 'any' then
			return true
		elseif typeSpec == 'never' then
			return false
		end
	elseif type(typeSpec) == 'table' then
		if typeSpec.op == 'literal' then
			return value == typeSpec.value
		elseif typeSpec.op == 'optional' then
			return value == nil or TypeUtil.valueIsTypeNoTable(value, typeSpec.type)
		elseif typeSpec.op == 'union' then
			return Array.any(
				typeSpec.types,
				function(t) return TypeUtil.valueIsTypeNoTable(value, t) end
			)
		elseif typeSpec.op == 'table' or typeSpec.op == 'struct' or typeSpec.op == 'array' then
			return type(value) == 'table'
		end
	end
	return true
end

-- TODO: Provide documentation for these params
function TypeUtil._getTypeErrors (value, typeSpec, nameParts, options, getTypeErrors)
	if not TypeUtil.valueIsTypeNoTable(value, typeSpec) then
		return {
			{value = value, type = typeSpec, where = nameParts}
		}
	end

	if type(typeSpec) == 'table' and options.recurseOnTable then
		if typeSpec.op == 'optional' then
			return value == nil
				and {}
				or getTypeErrors(value, typeSpec.type)

		elseif typeSpec.op == 'union' then
			local errors = {}
			for _, option in ipairs(typeSpec.types) do
				errors = getTypeErrors(value, option)
				if #errors == 0 then break end
			end
			return errors

		elseif typeSpec.op == 'table' then
			for tableKey, tableValue in pairs(value) do
				local errors = Array.extendWith(
					getTypeErrors(tableKey, typeSpec.keyType, {type = 'tableKey', key = tableKey}),
					getTypeErrors(tableValue, typeSpec.valueType, {type = 'tableValue', key = tableKey})
				)
				if #errors > 0 then return errors end
			end
			return {}

		elseif typeSpec.op == 'struct' then
			local errors = {}
			for fieldName, fieldType in pairs(typeSpec.struct) do
				Array.extendWith(
					errors,
					getTypeErrors(value[fieldName], fieldType, {type = 'tableValue', key = fieldName})
				)
			end
			return errors

		elseif typeSpec.op == 'array' then
			for ix, elem in ipairs(value) do
				local errors = getTypeErrors(elem, typeSpec.elemType, {type = 'tableValue', key = ix})
				if #errors > 0 then return errors end
			end
			return {}

		end
	end

	return {}
end

-- TODO: Provide documentation
function TypeUtil.getTypeErrors (value, typeSpec, depth, maxDepth, nameParts)
	return TypeUtil._getTypeErrors(
		value,
		typeSpec,
		nameParts,
		{recurseOnTable = depth < maxDepth},
		function(v, t, namePart)
			return TypeUtil.getTypeErrors(v, t, depth + 1, maxDepth, Array.append(nameParts, namePart))
		end
	)
end

-- Checks, at runtime, whether a value satisfies a type.
function TypeUtil.checkValue (value, typeSpec, options)
	options = options or {}
	local nameParts = {
		options.name and {type = 'base', name = options.name} or nil
	}

	local maxDepth = options.maxDepth or math.huge

	return Array.map(
		TypeUtil.getTypeErrors(value, typeSpec, 0, maxDepth, nameParts),
		TypeUtil.typeErrorToString
	)
end

-- Checks, at runtime, whether a value satisfies a type, and throws if not.
function TypeUtil.assertValue (value, typeSpec, options)
	local errors = TypeUtil.checkValue(value, typeSpec, options)
	if #errors > 0 then
		error(table.concat(errors, '\n'))
	end
end

function TypeUtil.typeErrorToString (typeError)
	local whereDescription = TypeUtil.whereToDescription(typeError.where)
	return 'Unexpected value'
		.. (whereDescription and ' in ' .. whereDescription or '')
		.. '. Found: '
		.. tostring(typeError.value)
		.. ' Expected: value of type '
		.. TypeUtil.typeToDescription(typeError.type)
end

function TypeUtil.whereToDescription (nameParts)
	local s
	for _, namePart in ipairs(nameParts) do
		if namePart.type == 'base' then
			s = namePart.name
		elseif namePart.type == 'tableKey' then
			s = 'key ' .. tostring(namePart.key) .. (s and ' of ' .. s or '')
		elseif namePart.type == 'tableValue' then
			if s and type(namePart.key) == 'string' and namePart.key:match('^%w+$') then
				s = s .. '.' .. tostring(namePart.key)
			elseif s then
				s = s .. '[' .. TypeUtil.reprValue(namePart.key) .. ']'
			else
				s = 'table entry ' .. TypeUtil.reprValue(namePart.key)
			end
		end
	end
	return s
end

function TypeUtil.reprValue (value)
	if type(value) == 'string' then
		return '\'' .. TypeUtil.escapeSingleQuote(value) .. '\''
	else
		return tostring(value)
	end
end

function TypeUtil.typeToDescription (typeSpec)
	if type(typeSpec) == 'string' then
		return typeSpec
	elseif type(typeSpec) == 'table' then
		if typeSpec.op == 'literal' then
			return type(typeSpec.value) == 'string'
				and TypeUtil.reprValue(typeSpec.value)
				or tostring(typeSpec.value)
		elseif typeSpec.op == 'optional' then
			return 'optional ' .. TypeUtil.typeToDescription(typeSpec.type)
		elseif typeSpec.op == 'union' then
			return table.concat(Array.map(typeSpec.types, TypeUtil.typeToDescription), ' or ')
		elseif typeSpec.op == 'table' then
			return 'table'
		elseif typeSpec.op == 'struct' then
			return 'structural table'
		elseif typeSpec.op == 'array' then
			return 'array table'
		end
	end
end

function TypeUtil.escapeSingleQuote(str)
	return str:gsub('\'', '\\\'')
end

-- checks if the entered value is numeric
function TypeUtil.isNumeric(val)
	return tonumber(val) ~= nil
end

return TypeUtil
