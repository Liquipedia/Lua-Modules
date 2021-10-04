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
		local val = type(arg) == 'function' and arg() or arg
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

function Logic.readBool(val)
	return val == 'true' or val == true or val == '1' or val == 1
end

function Logic.readBoolOrNil(val)
	if val == 'true' or val == true or val == '1' or val == 1 then
		return true
	elseif val == 'false' or val == false or val == '0' or val == 0 then
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

return Logic
