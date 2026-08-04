---
-- @Liquipedia
-- page=Module:Set
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Table = require('Module:Table')

---@class Set<T>: BaseClass
---@operator call(T[]?): Set<T>
---@operator add(Set<T>): Set<T>
---@operator sub(Set<T>): Set<T>
---@field private data table<T, boolean?>
local Set = Class.new(
	function(set,tbl)
		set:_new(tbl)
	end
)

---@private
function Set:_new(tbl)
	self.data = Set._tableToSet(tbl or {})
end

---@param value T
---@private
function Set:_add(value)
	self.data[value] = true
end

---@param value T|Set<T>
---@return Set<T>
function Set:add(value)
	if Class.instanceOf(value, Set) then
		---@cast value Set<any>
		for val in pairs(value) do
			self:_add(val)
		end
	else
		self:_add(value)
	end
	return self
end

---@param value T|Set<T>
---@return Set<T>
---@private
function Set:_addImmutable(value)
	return self:copy():add(value)
end

---@param value T
---@private
function Set:_remove(value)
	self.data[value] = nil
end

---@param value T|Set<T>
---@return Set<T>
function Set:remove(value)
	if Class.instanceOf(value, Set) then
		---@cast value Set<any>
		for val in pairs(value) do
			self:_remove(val)
		end
	else
		self:_remove(value)
	end
	return self
end

---@param value T|Set<T>
---@return Set<T>
---@private
function Set:_removeImmutable(value)
	return self:copy():remove(value)
end

---@return Set<T>
function Set:clear()
	self.data = {}
	return self
end

---@param value T
---@return boolean
function Set:contains(value)
	return self.data[value] or false
end

---@param set Set<T>
---@return boolean
function Set:containsAll(set)
	for val in pairs(set) do
		if not self:contains(val) then
			return false
		end
	end
	return true
end

---@return boolean
function Set:isEmpty()
	return next(self.data) == nil
end

---@return integer
function Set:size()
	return Table.size(self.data)
end

---@return T[]
function Set:toArray()
	local array = {}
	for val in pairs(self) do
		table.insert(array, val)
	end
	return array
end

---@return Set<T>
---@nodiscard
function Set:copy()
	local copy = Set()
	copy.data = Table.copy(self.data)
	return copy
end

---@param other Set<any>
---@return boolean
function Set:equals(other)
	if self:size() ~= other:size() then
		return false
	end
	return self:containsAll(other)
end

---@return string
function Set:toString()
	return '{'.. table.concat(self:toArray(), ', ') .. '}'
end

-- Based on http://lua-users.org/wiki/GeneralizedPairsAndIpairs
---@return fun(tbl: table<T, boolean?>, k: T): T
---@return table<T, boolean?>
---@return nil
---@package
function Set:_iterator()
	local function stateless_iter(tbl, k)
		local v
		k, v = next(tbl, k)
		if nil~=v then return k end -- A normal iterator returns k,v here
	end
	-- Return an iterator function, the table, starting point
	return stateless_iter, self.data, nil
end

---@package
---@generic T
---@param tbl T[]
---@return table<T, boolean?>
function Set._tableToSet(tbl)
	local set = {}
	for _, value in pairs(tbl) do
		set[value] = true
	end
	return set
end

Set.__eq = Set.equals
Set.__tostring = Set.toString
Set.__pairs = Set._iterator
Set.__add = Set._addImmutable
Set.__sub = Set._removeImmutable

return Set
