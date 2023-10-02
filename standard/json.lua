---
-- @Liquipedia
-- wiki=commons
-- page=Module:Json
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = {}

local Arguments = require('Module:Arguments')

---Json-stringifies all arguments from a supplied frame.
---@param frame Frame
---@return string
function Json.fromArgs(frame)
	local args = Arguments.getArgs(frame)
	return Json.stringify(args)
end

---Json-stringifies a given table.
---@param obj table
---@param pretty boolean?
---@return string
function Json.stringify(obj, pretty)
	return mw.text.jsonEncode(obj, pretty == true and mw.text.JSON_PRETTY or nil)
end

---Json-stringifies subtables of a given table.
---@param obj table
---@param pretty boolean?
---@return table
function Json.stringifySubTables(obj, pretty)
	local objectWithStringifiedSubtables = {}
	for key, item in pairs(obj) do
		if type(item) == 'table' then
			objectWithStringifiedSubtables[key] = Json.stringify(item, pretty)
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

return Json
