---
-- @Liquipedia
-- page=Module:Condition
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Condition = {}

-- Abstract class, node of the conditions tree
---@class AbstractConditionNode:BaseClass
local _ConditionNode = Class.new()

---Returns the string representation of this condition node.
function _ConditionNode:__tostring()
	return self:toString()
end

---Returns the string representation of this condition node.
---@protected
---@return string
function _ConditionNode:toString()
	error('_ConditionNode:toString() cannot be called directly and must be overridden.')
end

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
	if not node then
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

---@enum lpdbComparator
local Comparator = {
	equals = {'::'},
	notEquals = {'::!'},
	greaterThan = {'::>'},
	lessThan = {'::<'},
	greaterThanOrEqualTo = {'::>', '::'},
	lessThanOrEqualTo = {'::<', '::'},
}
---@diagnostic disable-next-line: inject-field
Comparator.eq = Comparator.equals
---@diagnostic disable-next-line: inject-field
Comparator.neq = Comparator.notEquals
---@diagnostic disable-next-line: inject-field
Comparator.gt = Comparator.greaterThan
---@diagnostic disable-next-line: inject-field
Comparator.lt = Comparator.lessThan
---@diagnostic disable-next-line: inject-field
Comparator.ge = Comparator.greaterThanOrEqualTo
---@diagnostic disable-next-line: inject-field
Comparator.le = Comparator.lessThanOrEqualTo

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
	assert(
		Table.any(Comparator, function (_, value)
			return self.comparator == value
		end),
		'Invalid comparator for LPDB query condition'
	)
	local conditions = Array.map(self.comparator, function(comp)
		return String.interpolate(
			'[[${name}${comparator}${value}]]',
			{
				name = self.name:toString(),
				comparator = comp,
				value = self.value
			}
		)
	end)

	if #conditions == 1 then return conditions[1] end
	return '(' .. table.concat(conditions, ' OR ') .. ')'
end

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
