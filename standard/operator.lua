---
-- @Liquipedia
-- wiki=commons
-- page=Module:Operator
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Operator = {}

function Operator.add(a, b)
	return a + b
end

function Operator.sub(a, b)
	return a - b
end

function Operator.mul(a, b)
	return a * b
end

function Operator.div(a, b)
	return a / b
end

function Operator.pow(a, b)
	return math.pow(a, b)
end

function Operator.property(item)
	if string.find(item, '%.') then
		error('Pathing not yet supported in property')
	end
	return function(tbl)
		return tbl[item]
	end
end

function Operator.method(funcName, ...)
	local args = {...}
	return function(obj)
		return obj[funcName](obj, unpack(args))
	end
end

return Operator
