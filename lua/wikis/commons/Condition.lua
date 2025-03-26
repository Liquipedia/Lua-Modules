---
-- @Liquipedia
-- wiki=commons
-- page=Module:Condition
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')

local Condition = {}

-- Abstract class, node of the conditions tree
---@class AbstractConditionNode:BaseClass
local _ConditionNode = Class.new()

---A tree of conditions, specifying the conditions for an LPDB request.
---Can be used recursively, as in, a tree of trees.
---@class ConditionTree:AbstractConditionNode
---@operator call(...): ConditionTree
---@field _nodes ConditionNode[]
---@field booleanOperator lpdbBooleanOperator
local ConditionTree = Class.new(_ConditionNode,
	function(self, booleanOperator)
		self.booleanOperator = booleanOperator
		self._nodes = {}
	end
)

---@param node AbstractConditionNode|AbstractConditionNode[]|nil
---@return self
function ConditionTree:add(node)
	if Logic.isEmpty(node) then
		return self
	elseif Class.instanceOf(node, _ConditionNode) then
		table.insert(self._nodes, node)
	else
		-- List of nodes
		Array.forEach(node, function(subNode)
			self:add(subNode)
		end)
	end
	return self
end

---@return string
function ConditionTree:toString()
	assert(self.booleanOperator ~= nil)
	return table.concat(Array.map(self._nodes,
		function(node)
			if Class.instanceOf(node, ConditionTree) then
				local nodeString = node:toString()
				if Logic.isEmpty(nodeString) then return end
				return String.interpolate('(${node})', {node = nodeString})
			elseif Logic.isEmpty(node) then
				return
			end

			return node:toString()
		end
	), String.interpolate(' ${booleanOperator} ', {booleanOperator = self.booleanOperator}))

end

---A condition in a ConditionTree
---@class ConditionNode:AbstractConditionNode
---@operator call(...): ConditionNode
---@field name ColumnName
---@field comparator lpdbComparator
---@field value string|number
local ConditionNode = Class.new(_ConditionNode,
	function(self, name, comparator, value)
		self.name = name
		self.comparator = comparator
		self.value = value
	end
)

---@return string
function ConditionNode:toString()
	return String.interpolate(
		'[[${name}${comparator}${value}]]',
		{
			name = self.name:toString(),
			comparator = self.comparator,
			value = self.value
		}
	)
end

---@enum lpdbComparator
local Comparator = {
	equals = '::',
	notEquals = '::!',
	greaterThan = '::>',
	lessThan = '::<'
}
Comparator.eq = Comparator.equals
Comparator.neq = Comparator.notEquals
Comparator.gt = Comparator.greaterThan
Comparator.lt = Comparator.lessThan

---@enum lpdbBooleanOperator
local BooleanOperator = {
	all = 'AND',
	any = 'OR',
}

---Represents a column name in LPDB, including an optional super key
---@class ColumnName
---@operator call(...): ColumnName
---@field name string
---@field superName string?
local ColumnName = Class.new(

	--- @param name string name of the column in LPDB
	--- @param superName string? The key that the `name` exists in, e.g. if we
	-- want `extradata_player`, the `superName` would be 'extradata', while
	-- the `name` would be 'player'
	function(self, name, superName)
		self.name = name

		if String.isNotEmpty(superName) then
			self.superName = superName
		end
	end
)

---@return string
function ColumnName:toString()
	if String.isNotEmpty(self.superName) then
		return String.interpolate(
			'${superName}_${name}',
			{superName = self.superName, name = self.name}
		)
	end

	return self.name
end

Condition.Tree = ConditionTree
Condition.Node = ConditionNode
Condition.Comparator = Comparator
Condition.BooleanOperator = BooleanOperator
Condition.ColumnName = ColumnName

return Condition
