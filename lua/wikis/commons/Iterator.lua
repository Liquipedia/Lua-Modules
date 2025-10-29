---
-- @Liquipedia
-- page=Module:Iterator
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Table = Lua.import('Module:Table')

local Iterator = {}

--[[
Applies a function to the elements of an iterator, returning a new iterator.

Example:
function square(ix, x) return ix, x * x end
for ix, x in Iterator.map(square, ipairs({4, 5, 6})) do
	mw.log(ix, x)
end
-- prints
1 16 2 25 3 36
]]
function Iterator.map(f, innerNext, innerState, initialInnerElem)
	local innerElem1 = initialInnerElem
	local function post(arg1, ...)
		innerElem1 = arg1
		if innerElem1 ~= nil then
			return f(arg1, ...)
		else
			return nil
		end
	end
	return function()
		return post(innerNext(innerState, innerElem1))
	end
end

--[[
Applies a function that converts each element in an iterator into an
iterator. The iterator of iterators is flattened into a single big iterator,
which is returned.

Example:
function ipairsSquares(_, x)
	local squares = {}
	for i = 1, x do
		table.insert(squares, i * i)
	end
	return ipairs(squares)
end

for _, sq in Iterator.flatMap(ipairsSquares, ipairs({4, 5, 6})) do
	mw.log(sq)
end
-- prints
1 4 9 16 1 4 9 16 25 1 4 9 16 25 36
]]
function Iterator.flatMap(f, outerNext, outerState, initialOuterElem)
	local outerElem = {initialOuterElem}
	local innerNext, innerState, innerElem1

	local function next()
		if innerElem1 == nil then
			outerElem = Table.pack(outerNext(outerState, outerElem[1]))
			if outerElem[1] == nil then
				return nil
			end
			innerNext, innerState, innerElem1 = f(unpack(outerElem))
		end

		local function post(arg1, ...)
			innerElem1 = arg1
			if arg1 ~= nil then
				return arg1, ...
			else
				return next()
			end
		end

		return post(innerNext(innerState, innerElem1))
	end

	return next
end

return Iterator
