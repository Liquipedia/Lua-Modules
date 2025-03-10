---
-- @Liquipedia
-- wiki=commons
-- page=Module:Logic
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = {}

---Returns `val1` if it isn't empty else returns `val2` if that isn't empty, else returns default
---@generic A, B, C
---@param val1 A?
---@param val2 B?
---@param default C?
---@return A|B|C|nil
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
---@overload fun(val: any):false
function Logic.isEmpty(val)
	if type(val) == 'table' then
		local Table = require('Module:Table')
		return Table.isEmpty(val)
	else
		return val == '' or val == nil
	end
end

---Checks if a given object (table|string|nil) is not empty
---@param val table|string|nil
---@return boolean
---@overload fun(val: any):true
function Logic.isNotEmpty(val)
	if type(val) == 'table' then
		local Table = require('Module:Table')
		return Table.isNotEmpty(val)
	else
		return val ~= nil and val ~= ''
	end
end

---@generic V
---@param val V?
---@return V?
function Logic.nilIfEmpty(val)
	return Logic.isNotEmpty(val) and val or nil
end


---Checks if a given object (table|string|nil) is deep empty
---i.e. is empty itself or only contains objects that are deep empty
---@param val table|string|nil
---@return boolean
---@overload fun(val: any):false
function Logic.isDeepEmpty(val)
	local Table = require('Module:Table')
	return Logic.isEmpty(val) or type(val) == 'table' and
		Table.all(val, function(key, item) return Logic.isDeepEmpty(item) end)
end

---Inverse of `Logic.isDeepEmpty`
---@param val table|string|nil
---@return boolean
---@overload fun(val: any):true
function Logic.isNotDeepEmpty(val)
	return not Logic.isDeepEmpty(val)
end

---Check if the input is a representation of a boolean
---@param val string|number|boolean|nil
---@return boolean
function Logic.readBool(val)
	return val == 'true' or val == 't' or val == 'yes' or val == 'y' or val == true or val == '1' or val == 1
end

---Reads a boolean string/number representation to a boolean.
---If the supplied value is nil will return nil
---@param val string|number|boolean|nil
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

---@param f fun(): any
---@return RoEResult|RoEError
function Logic.try(f)
	local ResultOrError = require('Module:ResultOrError')
	return ResultOrError.try(f)
end

---Returns the result of a function if successful. Otherwise it returns the result of the second function.
---If the first function fails, its error is logged to the console and stashed away for display.
---@generic T
---@param f fun(): T
---@param other? fun(error: Error): any
---@param makeError? fun(error: Error): Error function that allows customizing Error instance being logged and stashed.
---@return T
function Logic.tryOrElseLog(f, other, makeError)
	return Logic.try(f)
		:catch(function(error)
			local Error = require('Module:Error')
			if not Error.isError(error) then
				error = Error(error)
			end

			error.header = 'Error occured while calling a function: (caught by Logic.tryOrElseLog)'
			if makeError then
				error = makeError(error)
			end

			require('Module:Error/Ext').logAndStash(error)

			if other then
				return other(error)
			end
		end)
		:get()
end

---Returns the result of a function if successful. Otherwise it returns nil.
---If the first function fails, its error is logged to the console and stashed away for display.
---@generic F:function
---@param f F
---@param makeError? fun(error: Error): Error function that allows customizing Error instance being logged and stashed.
---@return F
function Logic.wrapTryOrLog(f, makeError)
	return function(...)
		--Need to pack the vararg, so it can be passed to the inner function
		local args = require('Module:Table').pack(...)
		return Logic.tryOrElseLog(function() return f(unpack(args)) end, nil, makeError)
	end
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
		local Table = require('Module:Table')
		return Table.deepEquals(x, y)
	else
		return false
	end
end

return Logic
