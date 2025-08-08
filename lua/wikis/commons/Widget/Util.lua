---
-- @Liquipedia
-- page=Module:Widget/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local Widget = Lua.import('Module:Widget')

local Util = {}

---@param ... Widget|string|number|Html?
---@return (Widget|string|number|Html)[]
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

---@param widget Widget|string|number|Html?
---@return boolean
function Util.isEmpty(widget)
	if Logic.isEmpty(widget) then
		return true
	end

	if not Class.instanceOf(widget, Widget) then
		return false
	end
	---@cast widget Widget

	return Array.all(widget.children or {}, Util.isEmpty)
end

return Util
