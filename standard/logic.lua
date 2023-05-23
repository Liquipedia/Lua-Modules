---
-- @Liquipedia
-- wiki=commons
-- page=Module:Logic
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = {}

---Returns `val1` if it isn't empty else returns `val2` if that isn't empty, else returns default
---@param val1 table|string|nil
---@param val2 table|string|nil
---@param default any
function Logic.emptyOr(val1, val2, default)
	if not Logic.isEmpty(val1) then
		return val1
	elseif not Logic.isEmpty(val2) then
		return val2
	else
		return default
	end
end

---Returns the first non nil value
---@param ... any?
---@return any?
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

---Checks if a given object (table|string|nil) is empty
---@param val table|string|nil
---@return boolean
function Logic.isEmpty(val)
	if type(val) == 'table' then
		return require('Module:Table').isEmpty(val)
	else
		return val == '' or val == nil
	end
end

---Checks if a given object (table|string|nil) is not empty
---@param val table|string|nil
---@return boolean
function Logic.isNotEmpty(val)
	if type(val) == 'table' then
		return require('Module:Table').isNotEmpty(val)
	else
		return val ~= nil and val ~= ''
	end
end

---Reads a boolean string/number representation to a boolean
---@param val string|number|nil
---@return boolean
function Logic.readBool(val)
	return val == 'true' or val == 't' or val == 'yes' or val == 'y' or val == true or val == '1' or val == 1
end

---Reads a boolean string/number representation to a boolean.
---If the supplied value is nil will return nil
---@param val string|number|nil
---@return boolean?
function Logic.readBoolOrNil(val)
	if Logic.readBool(val) then
		return true
	elseif val == 'false' or val == 'f' or val == 'no' or val == 'n' or val == false or val == '0' or val == 0 then
		return false
	else
		return nil
	end
end

---Throws an error if the supplied value is nil
---@param val any?
---@return any
function Logic.nilThrows(val)
	if val == nil then
		error('Unexpected nil', 2)
	end
	return val
end

---Trys to execute a function.
---If it fails executes a catch function
---@param try function
---@param catch function
---@return any?
function Logic.tryCatch(try, catch)
	local ran, result = pcall(try)
	if not ran then
		catch(result)
	else
		return result
	end
end

---@param f function
---@return any?
function Logic.try(f)
	return require('Module:ResultOrError').try(f)
end

---Checks if a provided value is numeric
---@param val number|string|nil
---@return boolean
function Logic.isNumeric(val)
	return tonumber(val) ~= nil
end

---Determines whether two values are equal. Table values are compared recursively.
---@param x any
---@param y any
---@return boolean
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
