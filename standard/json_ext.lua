---
-- @Liquipedia
-- wiki=commons
-- page=Module:Json/Ext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = require('Module:Json')

local JsonExt = {}

--[[
Attempts to parse a JSON encoded table. Returns nil if unsuccessful.

Example:

JsonExt.parseIfTable('{"a" = 3}')
-- Returns {a = 3}

]]
function JsonExt.parseIfTable(any)
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

return JsonExt
