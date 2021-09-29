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
		return {}, true
	end
end

function json.parseIfString(obj)
	return type(obj) == 'string' and json.parse(obj) or obj
end

return json
