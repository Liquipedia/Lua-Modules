---
-- @Liquipedia
-- wiki=commons
-- page=Module:Condition
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Array = require('Module:Array')

local Condition = {}

-- Abstract class, node of the conditions tree
local _ConditionNode = Class.new()

--[[
	A tree of conditions, specifying the conditions for an LPDB request

	Can be used recursively, as in, a tree of trees
]]
local ConditionTree = Class.new(_ConditionNode,
	function(self, booleanOperator)
		self.booleanOperator = booleanOperator
		self._nodes = {}
	end
)

function ConditionTree:add(node)
	if node.is_a ~= nil and node:is_a(_ConditionNode) then
		table.insert(self._nodes, node)
	else
		-- List of nodes
		for _, value in pairs(node) do
			table.insert(self._nodes, value)
		end
	end
	return self
end

function ConditionTree:toString()
	assert(self.booleanOperator ~= nil)
	return table.concat(Array.map(self._nodes,
		function(node)
			if node:is_a(ConditionTree) then
				return String.interpolate('(${node})', {node = node:toString()})
			end

			return node:toString()
		end
	), String.interpolate(' ${booleanOperator} ', {booleanOperator = self.booleanOperator}))

end

--[[
	A condition in a ConditionTree
]]
local ConditionNode = Class.new(_ConditionNode,
	function(self, name, comparator, value)
		self.name = name
		self.comparator = comparator
		self.value = value
	end
)

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

local BooleanOperator = {
	all = 'AND',
	any = 'OR',
}

--[[
	Represents a column name in LPDB, including an optional super key
]]
local ColumnName = Class.new(

	-- @param name: name of the column in LPDB
	-- @param superName (optional): The key that the `name` exists in, e.g. if we
	-- want `extradata_player`, the `superName` would be 'extradata', while
	-- the `name` would be 'player"'
	function(self, name, superName)
		self.name = name

		if String.isNotEmpty(superName) then
			self.superName = superName
		end
	end
)

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
