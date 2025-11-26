---
-- @Liquipedia
-- page=Module:TypeUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

---@class TypeUtilBaseType
---@field op string

---@class TypeUtilLiteralType: TypeUtilBaseType
---@field op 'literal'
---@field value any

---@class TypeUtilOptionalType: TypeUtilBaseType
---@field op 'optional'
---@field type TypeUtilType

---@class TypeUtilUnionType: TypeUtilBaseType
---@field op 'union'
---@field types TypeUtilType[]

---Representation of a structural type.
---@class TypeUtilStructType: TypeUtilBaseType
---@field op 'struct'
---@field struct table<string, TypeUtilType?>

---Representation of a table type.
---@class TypeUtilTableType: TypeUtilBaseType
---@field op 'table'
---@field keyType TypeUtilType
---@field valueType TypeUtilType

---Representation of an array type.
---@class TypeUtilArrayType: TypeUtilBaseType
---@field op 'array'
---@field elemType TypeUtilType

---@alias TypeUtilType string|TypeUtilBaseType

---@class TypeUtilTypeError
---@field value any
---@field type TypeUtilType
---@field where TypeUtilNamePart[]

---@class TypeUtilNamePart
---@field type 'base'|'tableKey'|'tableValue'
---@field name string?
---@field key any?

local TypeUtil = {}

---@param value any
---@return TypeUtilLiteralType
function TypeUtil.literal (value)
	return {op = 'literal', value = value}
end

---@param typeSpec TypeUtilBaseType
---@return TypeUtilOptionalType
---@overload fun(typeSpec: string): string
function TypeUtil.optional (typeSpec)
	if type(typeSpec) == 'string' then
		return String.endsWith(typeSpec, '?')
			and typeSpec
			or typeSpec .. '?'
	else
		return {op = 'optional', type = typeSpec}
	end
end

---@param ... TypeUtilType|TypeUtilType[]
---@return TypeUtilUnionType
function TypeUtil.union (...)
	return {op = 'union', types = Array.copy(arg)}
end

---@param ... any|any[]
---@return TypeUtilUnionType
function TypeUtil.literalUnion (...)
	return TypeUtil.union(unpack(
		Array.map(arg, TypeUtil.literal)
	))
end

---@param union TypeUtilUnionType
---@param ... any|any[]
---@return TypeUtilUnionType
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
---@param struct table<string, TypeUtilType>
---@return TypeUtilStructType
function TypeUtil.struct (struct)
	return {op = 'struct', struct = struct}
end

--[[
Adds additional fields to a structural type.
]]
---@param type TypeUtilStructType
---@param struct table<string, TypeUtilType>
---@return TypeUtilStructType
function TypeUtil.extendStruct (type, struct)
	return {op = 'struct', struct = Table.merge(type.struct, struct)}
end

--[[
Table type.
]]
---@param keyType TypeUtilType?
---@param valueType TypeUtilType?
---@return TypeUtilTableType
---@overload fun(): 'table'
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
---@param elemType TypeUtilType
---@return TypeUtilArrayType
---@overload fun(): 'array'
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
---@param value any
---@param typeSpec TypeUtilType
---@return boolean
function TypeUtil.valueIsTypeNoTable (value, typeSpec)
	if type(typeSpec) == 'string' then
		---@cast typeSpec string
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
		elseif String.endsWith(typeSpec, '?') then
			return value == nil or TypeUtil.valueIsTypeNoTable(value, typeSpec:sub(1, -2))
		elseif typeSpec == 'any' then
			return true
		elseif typeSpec == 'never' then
			return false
		end
	elseif type(typeSpec) == 'table' then
		if typeSpec.op == 'literal' then
			---@cast typeSpec TypeUtilLiteralType
			return value == typeSpec.value
		elseif typeSpec.op == 'optional' then
			---@cast typeSpec TypeUtilOptionalType
			return value == nil or TypeUtil.valueIsTypeNoTable(value, typeSpec.type)
		elseif typeSpec.op == 'union' then
			---@cast typeSpec TypeUtilUnionType
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

---@private
---@param value any
---@param typeSpec TypeUtilType
---@param nameParts TypeUtilNamePart[]
---@param options {recurseOnTable: boolean}
---@param getTypeErrors fun(v: any, t: TypeUtilType, namePart: TypeUtilNamePart?): TypeUtilTypeError[]
---@return TypeUtilTypeError[]
function TypeUtil._getTypeErrors (value, typeSpec, nameParts, options, getTypeErrors)
	if not TypeUtil.valueIsTypeNoTable(value, typeSpec) then
		return {
			{value = value, type = typeSpec, where = nameParts}
		}
	end

	if type(typeSpec) == 'table' and options.recurseOnTable then
		if typeSpec.op == 'optional' then
			---@cast typeSpec TypeUtilOptionalType
			return value == nil
				and {}
				or getTypeErrors(value, typeSpec.type)

		elseif typeSpec.op == 'union' then
			---@cast typeSpec TypeUtilUnionType
			local errors = {}
			for _, option in ipairs(typeSpec.types) do
				errors = getTypeErrors(value, option)
				if #errors == 0 then break end
			end
			return errors

		elseif typeSpec.op == 'table' then
			---@cast typeSpec TypeUtilTableType
			for tableKey, tableValue in pairs(value) do
				local errors = Array.extendWith(
					getTypeErrors(tableKey, typeSpec.keyType, {type = 'tableKey', key = tableKey}),
					getTypeErrors(tableValue, typeSpec.valueType, {type = 'tableValue', key = tableKey})
				)
				if #errors > 0 then return errors end
			end
			return {}

		elseif typeSpec.op == 'struct' then
			---@cast typeSpec TypeUtilStructType
			local errors = {}
			for fieldName, fieldType in pairs(typeSpec.struct) do
				Array.extendWith(
					errors,
					getTypeErrors(value[fieldName], fieldType, {type = 'tableValue', key = fieldName})
				)
			end
			return errors

		elseif typeSpec.op == 'array' then
			---@cast typeSpec TypeUtilArrayType
			for ix, elem in ipairs(value) do
				local errors = getTypeErrors(elem, typeSpec.elemType, {type = 'tableValue', key = ix})
				if #errors > 0 then return errors end
			end
			return {}

		end
	end

	return {}
end

---@param value any
---@param typeSpec TypeUtilType
---@param depth integer
---@param maxDepth integer
---@param nameParts TypeUtilNamePart[]
---@return TypeUtilTypeError[]
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

---Checks, at runtime, whether a value satisfies a type.
---@param value any
---@param typeSpec TypeUtilType
---@param options {name: string?, maxDepth: integer?}?
---@return string[]
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

---Checks, at runtime, whether a value satisfies a type, and throws if not.
---@param value any
---@param typeSpec TypeUtilType
---@param options {name: string?, maxDepth: integer?}?
function TypeUtil.assertValue (value, typeSpec, options)
	local errors = TypeUtil.checkValue(value, typeSpec, options)
	if #errors > 0 then
		error(table.concat(errors, '\n'))
	end
end

---@param typeError TypeUtilTypeError
---@return string
function TypeUtil.typeErrorToString (typeError)
	local whereDescription = TypeUtil.whereToDescription(typeError.where)
	return 'Unexpected value'
		.. (whereDescription and ' in ' .. whereDescription or '')
		.. '. Found: '
		.. tostring(typeError.value)
		.. ' Expected: value of type '
		.. TypeUtil.typeToDescription(typeError.type)
end

---@param nameParts TypeUtilNamePart[]
---@return string?
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

---@param value any
---@return string
function TypeUtil.reprValue (value)
	if type(value) == 'string' then
		return '\'' .. TypeUtil.escapeSingleQuote(value) .. '\''
	else
		return tostring(value)
	end
end

---@param typeSpec TypeUtilType
---@return string?
function TypeUtil.typeToDescription (typeSpec)
	if type(typeSpec) == 'string' then
		return typeSpec
	elseif type(typeSpec) == 'table' then
		if typeSpec.op == 'literal' then
			---@cast typeSpec TypeUtilLiteralType
			return type(typeSpec.value) == 'string'
				and TypeUtil.reprValue(typeSpec.value)
				or tostring(typeSpec.value)
		elseif typeSpec.op == 'optional' then
			---@cast typeSpec TypeUtilOptionalType
			return 'optional ' .. TypeUtil.typeToDescription(typeSpec.type)
		elseif typeSpec.op == 'union' then
			---@cast typeSpec TypeUtilUnionType
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

---@param str string
---@return string
function TypeUtil.escapeSingleQuote(str)
	return (str:gsub('\'', '\\\''))
end

-- checks if the entered value is numeric
---@param val any
---@return boolean
---@overload fun(val: number): true
function TypeUtil.isNumeric(val)
	return tonumber(val) ~= nil
end

return TypeUtil
