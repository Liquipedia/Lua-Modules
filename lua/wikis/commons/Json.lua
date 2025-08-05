---
-- @Liquipedia
-- page=Module:Json
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = {}

local Arguments = require('Module:Arguments')
local Table = require('Module:Table')

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
---@return table, boolean
---@overload fun(obj: any): {}, true
function Json.parse(obj)
	local parse = function(object) return mw.text.jsonDecode(object, mw.text.JSON_TRY_FIXING) end
	local status, res = pcall(parse, obj);
	if status then
		return res, false
	else
		mw.log('Error: could not parse Json:')
		mw.logObject(obj)
		mw.log(debug.traceback())
		return {}, true
	end
end

---Parses a given object if it is a string. Else it returns the given object.
---@param obj string
---@return table, boolean
---@overload fun(obj: any): any
function Json.parseIfString(obj)
	if type(obj) == 'string' then
		return Json.parse(obj)
	else
		return obj
	end
end

---Attempts to parse a JSON encoded table. Returns nil if unsuccessful.
---Checks if the given string starts with `'{'` or `'['`
---
---Example: JsonExt.parseIfTable('{"a" = 3}') = {a = 3}
---@param any string
---@return table?
---@overload fun(any: any): nil
function Json.parseIfTable(any)
	if type(any) == 'string' then
		local firstChar = any:sub(1, 1)
		if firstChar == '{' or firstChar == '[' then
			local result, hasError = Json.parse(any)
			if not hasError then
				return result
			end
		end
	end
	return nil
end

---Parses a given JSON input from a template call to `Json.stringify()`.
---If the parse fails it returns the original input.
---Second return value boolean indicates a failed parse.
---@param any string
---@return table, boolean
---@overload fun(any: any): any, true
function Json.parseStringified(any)
	local tbl = Json.parseIfTable(any)
	if not tbl then
		return any, true
	end
	return Table.mapValues(tbl, Json.parseStringified), false
end

return Json
