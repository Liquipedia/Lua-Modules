---
-- @Liquipedia
-- page=Module:Widget/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')

local Util = {}

function Util.collect(...)
	local elements = Table.pack(...)
	local array = {}
	for index = 1, elements.n do
		local x = elements[index]
		if Array.isArray(x) then
			for _, y in ipairs(x) do
				table.insert(array, y)
			end
		elseif x ~= nil then
			table.insert(array, x)
		end
	end
	return array
end

return Util
