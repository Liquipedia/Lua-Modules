---
-- @Liquipedia
-- wiki=commons
-- page=Module:Json
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local json = {}

local Arguments = require('Module:Arguments')

function json.fromArgs(frame)
	local args = Arguments.getArgs(frame)
	return json.stringify(args)
end

function json.stringify(obj, pretty)
	return mw.text.jsonEncode(obj, pretty == true and mw.text.JSON_PRETTY or nil)
end

function json.parse(obj)
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

function json.parseIfString(obj)
	if type(obj) == 'string' then
		return json.parse(obj)
	else
		return obj
	end
end

--[[
Attempts to parse a JSON encoded table. Returns nil if unsuccessful.

Example:

JsonExt.parseIfTable('{"a" = 3}')
-- Returns {a = 3}

]]
function json.parseIfTable(any)
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

return json
