---
-- @Liquipedia
-- page=Module:Widget/WantToHelpList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Variables = Lua.import('Module:Variables')

local Component = Lua.import('Module:Widget/Component')
local Link = Lua.import('Module:Widget/Basic/Link')
local ListWidgets = Lua.import('Module:Widget/List')

local DEFAULT_LIMIT = 3

---Fetches "Todo" datapoints
---@return datapoint[]
local function getTodos()
	return mw.ext.LiquipediaDB.lpdb('datapoint', {
		limit = 5000,
		conditions = '[[type::todo]]'
	})
end

---@param props {limit: string|integer?}
---@return VNode
local function WantToHelpList(props)
	-- can not use defaultProps due to casting to number
	local limit = tonumber(props.limit) or DEFAULT_LIMIT

	local todos = getTodos()
	Variables.varDefine('total_number_of_todos', #todos)

	todos = Array.sub(Array.randomize(todos), 1, limit)

	return ListWidgets.Unordered{children = Array.map(todos, function(todo)
		return {
			Link{link = todo.pagename, children = {todo.name}},
			': ',
			todo.information,
		}
	end)}
end

return Component.component(WantToHelpList)
