---
-- @Liquipedia
-- page=Module:Set
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local Set = Class.new(
	function(set,tbl)
		set:_new(tbl)
	end
)

function Set:_new(tbl)
	self.data = Set._tableToSet(tbl or {})
end

function Set:_add(value)
	self.data[value] = true
end

function Set:add(value)
	if Class.instanceOf(value, Set) then
		for val in pairs(value) do
			self:_add(val)
		end
	else
		self:_add(value)
	end
	return self
end

function Set:_addImmutable(value)
	return self:copy():add(value)
end

function Set:_remove(value)
	self.data[value] = nil
end

function Set:remove(value)
	if Class.instanceOf(value, Set) then
		for val in pairs(value) do
			self:_remove(val)
		end
	else
		self:_remove(value)
	end
	return self
end

function Set:_removeImmutable(value)
	return self:copy():remove(value)
end

function Set:clear()
	self.data = {}
	return self
end

function Set:contains(value)
	return self.data[value] or false
end

function Set:containsAll(set)
	for val in pairs(set) do
		if not self:contains(val) then
			return false
		end
	end
	return true
end

function Set:isEmpty()
	return next(self.data) == nil
end

function Set:size()
	local count = 0
	for _ in pairs(self) do
		count = count + 1
	end
	return count
end

function Set:toArray()
	local array = {}
	for val in pairs(self) do
		table.insert(array, val)
	end
	return array
end

function Set:copy()
	return Set(self:toArray())
end

function Set:equals(other)
	return self:containsAll(other) and other:containsAll(self)
end

function Set:toString()
	return '{'.. table.concat(self:toArray(), ', ') .. '}'
end

-- Based on http://lua-users.org/wiki/GeneralizedPairsAndIpairs
function Set:_iterator()
	local function stateless_iter(tbl, k)
		local v
		k, v = next(tbl, k)
		if nil~=v then return k end -- A normal iterator returns k,v here
	end
	-- Return an iterator function, the table, starting point
	return stateless_iter, self.data, nil
end

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
