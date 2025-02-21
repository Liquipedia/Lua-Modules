--- Triple Comment to Enable our LLS Plugin
local TreeUtil = require('Module:TreeUtil')

describe('TreeUtil.dfs', function()
	it('should traverse a simple tree', function()
		local tree = {
			value = 1,
			children = {
				{ value = 2, children = {} },
				{ value = 3, children = {} }
			}
		}
		local getChildren = function(node) return node.children end
		local result = {}
		for node in TreeUtil.dfs(getChildren, tree) do
			table.insert(result, node.value)
		end
		assert.are.same({1, 2, 3}, result)
	end)

	it('should traverse a tree with multiple levels', function()
		local tree = {
			value = 1,
			children = {
				{ value = 2, children = {
					{ value = 4, children = {} }
				}},
				{ value = 3, children = {
					{ value = 5, children = {} },
					{ value = 6, children = {} }
				}}
			}
		}
		local getChildren = function(node) return node.children end
		local result = {}
		for node in TreeUtil.dfs(getChildren, tree) do
			table.insert(result, node.value)
		end
		assert.are.same({1, 2, 4, 3, 5, 6}, result)
	end)

	it('should handle an empty tree', function()
		local tree = { value = 1, children = {} }
		local getChildren = function(node) return node.children end
		local result = {}
		for node in TreeUtil.dfs(getChildren, tree) do
			table.insert(result, node.value)
		end
		assert.are.same({1}, result)
	end)

	it('should handle a tree with a single node', function()
		local tree = { value = 1, children = {} }
		local getChildren = function(node) return node.children end
		local result = {}
		for node in TreeUtil.dfs(getChildren, tree) do
			table.insert(result, node.value)
		end
		assert.are.same({1}, result)
	end)

	it('should handle circular references', function()
		local node1 = { value = 1, children = {} }
		local node2 = { value = 2, children = {} }
		node1.children = { node2 }
		node2.children = { node1 }
		local getChildren = function(node) return node.children end
		local result = {}
		local visited = {}
		for node in TreeUtil.dfs(getChildren, node1) do
			if visited[node.value] then break end
			visited[node.value] = true
			table.insert(result, node.value)
		end
		assert.are.same({1, 2}, result)
	end)
end)
