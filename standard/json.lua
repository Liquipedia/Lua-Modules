---
-- @Liquipedia
-- wiki=commons
-- page=Module:Json
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = {}

local Arguments = require('Module:Arguments')
local FnUtil = require('Module:FnUtil')
local Table = require('Module:Table')

local ERROR_PATTERN = '<span class="scribunto%-error" id="mw%-scribunto%-error%-%d">Lua error%s?i?n?%s?:? (.*)%.</span>'
local JSON_ERROR_PATTERN = 'Module:Json/?d?e?v? at line %d+: Tried to parse Lua error &quot;(.*)&quot;'

---Json-stringifies all arguments from a supplied frame.
---@param frame Frame
---@return string
function Json.fromArgs(frame)
	local args = Arguments.getArgs(frame)
	return Json.stringify(args)
end

---Json-stringifies a given table.
---@param obj table
---@param options? {pretty: boolean?, asArray: boolean?}
---@return string
---@overload fun(obj: any, options: table?): any
function Json.stringify(obj, options)
	if type(obj) ~= 'table' then
		return obj
	end

	options = options or {}

	if options.pretty or options.asArray then
		return mw.text.jsonEncode(obj, options.pretty and mw.text.JSON_PRETTY or nil)
	end

	return mw.ext.LiquipediaDB.lpdb_create_json(obj)
end

---Json-stringifies subtables of a given table.
---@param obj table
---@param pretty boolean?
---@return table
function Json.stringifySubTables(obj, pretty)
	local objectWithStringifiedSubtables = {}
	for key, item in pairs(obj) do
		if type(item) == 'table' then
			objectWithStringifiedSubtables[key] = Json.stringify(item, {pretty = pretty})
		else
			objectWithStringifiedSubtables[key] = item
		end
	end

	return objectWithStringifiedSubtables
end

---Parses a given JSON encoded table to its table representation.
---If the parse fails it returns an empty table.
---Second return value boolean indicates a failed parse.
---@param obj string
---@param options {checkForError: boolean?}?
---@return table, boolean
---@overload fun(obj: any, options: {checkForError: boolean?}?): {}, true
function Json.parse(obj, options)
	options = options or {}
	local parse = function(object) return mw.text.jsonDecode(object, mw.text.JSON_TRY_FIXING) end
	local status, res = pcall(parse, obj);
	if status then
		return res, false
	elseif options.checkForError then
		Json.checkForError(obj)
	end
	mw.log('Error: could not parse Json:')
	mw.logObject(obj)
	mw.log(debug.traceback())
	return {}, true
end

---Parses a given object if it is a string. Else it returns the given object.
---@param obj string
---@param options {checkForError: boolean?}?
---@return table, boolean
---@overload fun(obj: any, options: {checkForError: boolean?}?): any
function Json.parseIfString(obj, options)
	if type(obj) == 'string' then
		return Json.parse(obj, options)
	else
		return obj
	end
end

---Attempts to parse a JSON encoded table. Returns nil if unsuccessful.
---Checks if the given string starts with `'{'` or `'['`
---
---Example: JsonExt.parseIfTable('{"a" = 3}') = {a = 3}
---@param any string
---@param options {checkForError: boolean?}?
---@return table?
---@overload fun(any: any, options: {checkForError: boolean?}?): nil
function Json.parseIfTable(any, options)
	options = options or {}
	if type(any) == 'string' then
		local firstChar = any:sub(1, 1)
		if firstChar == '{' or firstChar == '[' then
			local result, hasError = Json.parse(any, options)
			if not hasError then
				return result
			end
		elseif options.checkForError then
			Json.checkForError(any)
		end
	end
	return nil
end

---Parses a given JSON input from a template call to `Json.stringify()`.
---If the parse fails it returns the original input.
---Second return value boolean indicates a failed parse.
---@param options {checkForError: boolean?}?
---@param any string
---@return table, boolean
---@overload fun(options: {checkForError: boolean?}?, any: any): any, true
---@overload fun(options: string): table, boolean
---@overload fun(options: any): any, true
function Json.parseStringified(options, any)
	if not any and type(options) == 'string' then
		any = options
		options = nil
	end
	local tbl = Json.parseIfTable(any, options)
	if not tbl then
		return any, true
	end
	return Table.mapValues(tbl, FnUtil.curry(Json.parseStringified, options)), false
end

---throws if an lua script error is found in the provided string
---@param str string?
function Json.checkForError(str)
	if type(str) ~= 'string' then return end

	local errorMessage = string.match(str, ERROR_PATTERN)

	if not errorMessage then return end

	error('Tried to parse Lua error "' ..
		errorMessage:gsub(JSON_ERROR_PATTERN, '%1') .. '"')
end

return Json
