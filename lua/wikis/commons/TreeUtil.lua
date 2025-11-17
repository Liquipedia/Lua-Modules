---
-- @Liquipedia
-- page=Module:TreeUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TreeUtil = {}

---@generic V
---@param getChildren fun(V):V[]
---@param start V
---@return fun():V
function TreeUtil.dfs(getChildren, start)
	local stack = {start}
	return function()
		if #stack == 0 then
			return nil
		end
		local node = table.remove(stack)
		local children = getChildren(node)
		for i = #children, 1, -1 do
			table.insert(stack, children[i])
		end
		return node
	end
end

return TreeUtil
