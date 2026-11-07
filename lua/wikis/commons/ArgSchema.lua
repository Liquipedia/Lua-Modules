---
-- @Liquipedia
-- page=Module:ArgSchema
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')

---Declares the parameters of a template once, for reading them and for their documentation.
local ArgSchema = {}

---@alias ArgSchemaType 'string'|'boolean'|'number'|'nonNegativeInteger'|'timestamp'|'json'|'list'

---@class ArgSchemaParameter
---@field name string # A `{placeholder}` reads every numbered variant, e.g. `r{round}status` reads `r1status`, ...
---A name that is only a placeholder, e.g. `{opponent}`, reads the unnamed parameters.
---@field aliases string[]? # Read if the name is not given. Without the placeholder, it applies to `defaultIndex`.
---@field type ArgSchemaType? # Defaults to `string`
---@field read (fun(input: any): any)? # Replaces the read of the type
---@field separator string? # Separator of a `list`, defaults to `,`
---@field default (string|number|boolean)?
---@field example string? # Wikitext of a value, documented when there is no default. Unnamed parameters are
---documented by it, as editors write them.
---@field hidden boolean? # Set by the template, not by editors, so left out of the documentation
---@field condition (fun(context: table): boolean)? # Leaves the parameter out of the documentation of a context
---@field description string|fun(context: table): string # Wikitext

---@class ArgSchemaReadOptions
---@field defaultIndex integer? # The index of an alias without the placeholder

---@type table<ArgSchemaType, {read: fun(input: any, parameter: ArgSchemaParameter): any, expected: string?,
---absent: (fun(): any)?}>
local TYPES = {
	string = {read = FnUtil.identity},
	boolean = {read = Logic.readBoolOrNil, expected = 'a boolean'},
	number = {read = function(input) return tonumber(input) end, expected = 'a number'},
	nonNegativeInteger = {
		read = function(input)
			local value = tonumber(input)
			return value and value >= 0 and value == math.floor(value) and value or nil
		end,
		expected = 'a non-negative integer',
	},
	timestamp = {read = DateExt.readTimestamp},
	json = {read = Json.parseIfString},
	list = {
		read = function(input, parameter)
			return Array.parseCommaSeparatedString(input, parameter.separator)
		end,
		absent = function() return {} end,
	},
}

local PLACEHOLDER = '{%w+}'

---@param input any
---@return boolean
local function isGiven(input)
	return input ~= nil and input ~= ''
end

---@param name string
---@return boolean
local function isIndexed(name)
	return name:find(PLACEHOLDER) ~= nil
end

---@param name string
---@return string
local function toPattern(name)
	local escaped = name:gsub('[%-%.%+%*%?%^%$%%%[%]%(%)]', '%%%0')
	return '^' .. escaped:gsub(PLACEHOLDER, '(%%d+)') .. '$'
end

---@param parameter ArgSchemaParameter
---@return string[]
local function allNames(parameter)
	return Array.extend(parameter.name, parameter.aliases)
end

---@param parameter ArgSchemaParameter
---@param name string|integer # As given
---@param input any
---@return any
local function convert(parameter, name, input)
	if parameter.read then
		return parameter.read(input)
	end
	local readType = TYPES[parameter.type or 'string']
	local value = readType.read(input, parameter)
	assert(value ~= nil or not readType.expected,
		'Invalid ' .. name .. ' input: "' .. tostring(input) .. '" is not ' .. tostring(readType.expected))
	return value
end

---@param parameter ArgSchemaParameter
---@param args table
---@param options ArgSchemaReadOptions
---@return table<integer, any>
local function readIndexed(parameter, args, options)
	local inputs = {}
	Array.forEach(allNames(parameter), function(name)
		if not isIndexed(name) then
			local index = options.defaultIndex
			if index and inputs[index] == nil and isGiven(args[name]) then
				inputs[index] = {name = name, input = args[name]}
			end
			return
		end
		local pattern = toPattern(name)
		for key, input in pairs(args) do
			-- Unnamed parameters have number keys
			local index = tonumber(tostring(key):match(pattern))
			if index and inputs[index] == nil and isGiven(input) then
				inputs[index] = {name = key, input = input}
			end
		end
	end)
	local values = {}
	for index, given in pairs(inputs) do
		values[index] = convert(parameter, given.name, given.input)
	end
	return values
end

---@param parameter ArgSchemaParameter
---@param args table
---@return any
local function readSingle(parameter, args)
	local name = Array.find(allNames(parameter), function(candidate)
		return isGiven(args[candidate])
	end)
	local value
	if name then
		value = convert(parameter, name, args[name])
	end
	if value ~= nil then
		return value
	elseif parameter.default ~= nil then
		return parameter.default
	end
	local absent = not parameter.read and TYPES[parameter.type or 'string'].absent
	return absent and absent() or nil
end

---Reads the parameters from the args, keyed by name. Indexed parameters are read as `table<index, value>`.
---Reading a name that is not declared is an error, so every parameter the code reads is documented.
---Empty inputs count as not given, invalid inputs are an error.
---@param parameters ArgSchemaParameter[]
---@param args table
---@param options ArgSchemaReadOptions?
---@return table<string, any>
function ArgSchema.read(parameters, args, options)
	options = options or {}
	local declared = {}
	local values = {}
	Array.forEach(parameters, function(parameter)
		declared[parameter.name] = true
		if isIndexed(parameter.name) then
			values[parameter.name] = readIndexed(parameter, args, options)
		else
			values[parameter.name] = readSingle(parameter, args)
		end
	end)
	return setmetatable(values, {__index = function(_, name)
		assert(declared[name], 'Parameter "' .. tostring(name) .. '" is not declared')
	end})
end

---Reads the parameters from the args of a template, as Module:Arguments reads them.
---@param parameters ArgSchemaParameter[]
---@param frame Frame|table
---@return table<string, any>
function ArgSchema.readFrame(parameters, frame)
	return ArgSchema.read(parameters, Arguments.getArgs(frame))
end

---The parameters to document in a context.
---@param parameters ArgSchemaParameter[]
---@param context table
---@return ArgSchemaParameter[]
function ArgSchema.applicable(parameters, context)
	return Array.filter(parameters, function(parameter)
		return not parameter.hidden and (parameter.condition == nil or parameter.condition(context))
	end)
end

---@param parameter ArgSchemaParameter
---@param context table
---@return string
function ArgSchema.description(parameter, context)
	if type(parameter.description) == 'function' then
		return parameter.description(context)
	end
	return parameter.description --[[@as string]]
end

---Whether the parameter reads the unnamed parameters, e.g. `{opponent}`.
---@param parameter ArgSchemaParameter
---@return boolean
function ArgSchema.isUnnamed(parameter)
	return parameter.name:find('^' .. PLACEHOLDER .. '$') ~= nil
end

---The names as given on a page, with the placeholder of indexed names as `1`, `2`, ...
---@param parameter ArgSchemaParameter
---@return string[][] # Per name, its variants
function ArgSchema.displayNames(parameter)
	return Array.map(allNames(parameter), function(name)
		if not isIndexed(name) then
			return {name}
		end
		return {(name:gsub(PLACEHOLDER, '1')), (name:gsub(PLACEHOLDER, '2'))}
	end)
end

return ArgSchema
