---
-- @Liquipedia
-- wiki=commons
-- page=Module:Logic
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = {}

function Logic.emptyOr(val1, val2, default)
	if not Logic.isEmpty(val1) then
		return val1
	elseif not Logic.isEmpty(val2) then
		return val2
	else
		return default
	end
end

function Logic.nilOr(...)
	local args = require('Module:Table').pack(...)
	for i = 1, args.n do
		local arg = args[i]
		local val
		if type(arg) == 'function' then
			val = arg()
		else
			val = arg
		end
		if val ~= nil then
			return val
		end
	end
	return nil
end

function Logic.isEmpty(val)
	if type(val) == 'table' then
		return require('Module:Table').isEmpty(val)
	else
		return val == '' or val == nil
	end
end

function Logic.isNotEmpty(val)
	if type(val) == 'table' then
		return require('Module:Table').isNotEmpty(val)
	else
		return val ~= nil and val ~= ''
	end
end

function Logic.readBool(val)
	return val == 'true' or val == 'yes' or val == true or val == '1' or val == 1
end

function Logic.readBoolOrNil(val)
	if val == 'true' or val == 'yes' or val == true or val == '1' or val == 1 then
		return true
	elseif val == 'false' or val == 'no' or val == false or val == '0' or val == 0 then
		return false
	else
		return nil
	end
end

function Logic.nilThrows(val)
	if val == nil then
		error('Unexpected nil', 2)
	end
	return val
end

function Logic.tryCatch(try, catch)
	local ran, result = pcall(try)
	if not ran then
		catch(result)
	else
		return result
	end
end

function Logic.try(f)
	return require('Module:ResultOrError').try(f)
end

function Logic.isNumeric(val)
	return tonumber(val) ~= nil
end

--[[
Determines whether two values are equal. Table values are compared recursively.
]]
function Logic.deepEquals(x, y)
	if x == y then
		return true
	elseif type(x) == 'table' and type(y) == 'table' then
		return require('Module:Table').deepEquals(x, y)
	else
		return false
	end
end

return Logic
