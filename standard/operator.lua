---
-- @Liquipedia
-- wiki=commons
-- page=Module:Operator
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Operator = {}

---Uses the __add metamethod (a + b)
---@param a number
---@param b number
---@return number
function Operator.add(a, b)
	return a + b
end

---Uses the __sub metamethod (a - b)
---@param a number
---@param b number
---@return number
function Operator.sub(a, b)
	return a - b
end

---Uses the __mul metamethod (a * b)
---@param a number
---@param b number
---@return number
function Operator.mul(a, b)
	return a * b
end

---Uses the __div metamethod (a / b)
---@param a number
---@param b number
---@return number
function Operator.div(a, b)
	return a / b
end

---Uses the __pow metamethod (a ^ b)
---@param a number
---@param b number
---@return number
function Operator.pow(a, b)
	return a ^ b
end

---Uses the __eq metamethod (a == b)
---@param a any
---@param b any
---@return any
function Operator.eq(a, b)
	return a == b
end

--- Uses the __eq metamethod with negated result (a ~= b)
---@param a any
---@param b any
---@return any
function Operator.neq(a, b)
	return a ~= b
end

---@param item string|number
---@return fun(tbl: table): any
function Operator.property(item)
	if string.find(item, '%.') then
		error('Pathing not yet supported in property')
	end
	return function(tbl)
		return tbl[item]
	end
end

---@param funcName string|number
---@param ... any
---@return fun(obj: any, ...): any
function Operator.method(funcName, ...)
	local args = {...}
	return function(obj)
		return obj[funcName](obj, unpack(args))
	end
end

return Operator
