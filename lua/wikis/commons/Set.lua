---
-- @Liquipedia
-- page=Module:Set
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Table = require('Module:Table')

---Implementation of a finite set.
---@class Set<T>: BaseClass
---@operator call(T[]?): Set<T>
---@operator add(Set<T>): Set<T>
---@operator sub(Set<T>): Set<T>
---@field private data table<T, boolean?>
local Set = Class.new(function(set, tbl)
	set:_new(tbl)
end)

---@param tbl T[]?
---@private
function Set:_new(tbl)
	self.data = Set._tableToSet(tbl or {})
end

---@param value T
---@private
function Set:_add(value)
	self.data[value] = true
end

--[[
Adds the specified value to this set.

This function errors if argument is `nil`.
]]
---@param value T
---@return Set<T>
function Set:add(value)
	if value == nil then
		error('Set.add: nil cannot be added to sets')
	end
	self:_add(value)
	return self
end

---Adds all elements from the specified set to this set.
---@param set Set<T>
---@return Set<T>
function Set:addAll(set)
	Table.mergeInto(self.data, set.data)
	return self
end

---@param value T
---@private
function Set:_remove(value)
	self.data[value] = nil
end

--[[
Removes the specified value from this set.

This function is a no-op if argument is `nil`.
]]
---@param value T
---@return Set<T>
function Set:remove(value)
	if value == nil then
		return self
	end
	self:_remove(value)
	return self
end

---Removes all elements in the specified set from this set.
---@param set Set<T>
---@return Set<T>
function Set:removeAll(set)
	for entry in pairs(set.data) do
		self:_remove(entry)
	end
	return self
end

---Removes all elements from this set.
---@return Set<T>
function Set:clear()
	self.data = {}
	return self
end

---Creates and returns the intersection of this set and the specified set.
---@param set Set<T>
---@return Set<T>
function Set:intersection(set)
	local intersection = Set()
	for entry in pairs(self.data) do
		if set:contains(entry) then
			intersection:add(entry)
		end
	end
	return intersection
end

---Creates and returns the union of this set and the specified set.
---@param set Set<T>
---@return Set<T>
function Set:union(set)
	return self:copy():addAll(set)
end

---Creates and returns the set difference of this set and the specified set.
---@param set Set<T>
---@return Set<T>
function Set:difference(set)
	return self:copy():removeAll(set)
end

---Returns `true` if this set contains the specified value.
---@param value T
---@return boolean
function Set:contains(value)
	return self.data[value] or false
end

---@param set Set<T>
---@return boolean
function Set:containsAll(set)
	for val in pairs(set.data) do
		if not self:contains(val) then
			return false
		end
	end
	return true
end

---Returns `true` if this set is empty.
---@return boolean
function Set:isEmpty()
	return next(self.data) == nil
end

---Returns the size of this set.
---@return integer
function Set:size()
	return Table.size(self.data)
end

--[[
Returns the elements of this set as an array.

The order of elements in the returned array is not specified.
]]
---@return T[]
function Set:toArray()
	local array = {}
	for k in pairs(self.data) do
		table.insert(array, k)
	end
	return array
end

---Returns a copy of this set.
---@return Set<T>
---@nodiscard
function Set:copy()
	local copy = Set()
	copy.data = Table.copy(self.data)
	return copy
end

---Returns `true` if this set and the specified set are equal.
---@param other Set<any>
---@return boolean
function Set:equals(other)
	if rawequal(self, other) then
		return true
	elseif self:size() ~= other:size() then
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
		if v ~= nil then
			return k -- A normal iterator returns k,v here
		end
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
Set.__add = Set.union
Set.__sub = Set.difference

return Set
