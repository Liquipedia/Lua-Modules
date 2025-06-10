---
-- @Liquipedia
-- page=Module:Widget/WantToHelpList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Variables = Lua.import('Module:Variables')

local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidget = Lua.import('Module:Widget/Html/All')
local Widget = Lua.import('Module:Widget')

---@class WantToHelpList: Widget
---@operator call(table): WantToHelpList
local WantToHelpList = Class.new(Widget)

local DEFAULT_LIMIT = 3

---@return Widget[]
function WantToHelpList:render()
	-- can not use defaultProps due to casting to number
	local limit = tonumber(self.props.limit) or DEFAULT_LIMIT

	local todos = WantToHelpList._getTodos()
	Variables.varDefine('total_number_of_todos', #todos)

	todos = Array.sub(Array.randomize(todos), 1, limit)

	return HtmlWidget.Ul{children = Array.map(todos, function(todo)
		return HtmlWidget.Li{
			children = {
				Link{link = todo.pagename, children = {todo.name}},
				': ',
				todo.information,
			}
		}
	end)}
end

---Fetches "Todo" datapoints
---@return table
function WantToHelpList._getTodos()
	return mw.ext.LiquipediaDB.lpdb('datapoint', {
		limit = 5000,
		conditions = '[[type::todo]]'
	})
end

return WantToHelpList
