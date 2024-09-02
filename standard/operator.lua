---
-- @Liquipedia
-- wiki=commons
-- page=Module:Operator
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')

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
	-- catch nil and tables
	assert(type(item) == 'string' or type(item) == 'number', 'Invalid or missing input to `Operator.property`')

	local pathSegments = mw.text.split(item, '.', true)

	return function(tbl)
		local selected = tbl
		for segmentIndex, pathSegment in ipairs(pathSegments) do
			if type(selected) ~= 'table' and segmentIndex == 1 then
				error('Nil supplied to `Operator.property(' .. item .. ')`')
			elseif type(selected) ~= 'table' then
				local pathUntilHere = Array.sub(pathSegments, 1, segmentIndex - 1)
				error('Could not index "tbl.' .. table.concat(pathUntilHere, '.') .. '"')
			end

			selected = selected[pathSegment] or selected[tonumber(pathSegment)]
		end
		return selected
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
