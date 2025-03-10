---
-- @Liquipedia
-- wiki=commons
-- page=Module:WantToHelpList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Arguments = require('Module:Arguments')
local Page = require('Module:Page')
local Variables = require('Module:Variables')

local WantToHelpList = {}

local DEFAULT_LIMIT = 3

---Builds the Want to help display.
---Usage e.g. on main page
---@param frame Frame
---@return string
function WantToHelpList.get(frame)
	local args = Arguments.getArgs(frame)
	local limit = tonumber(args.limit) or DEFAULT_LIMIT

	local listItems = {}
	local todos = WantToHelpList._getTodos()

	Variables.varDefine('total_number_of_todos', #todos)

	for idx, item in ipairs(Array.randomize(todos)) do
		table.insert(listItems, '*' .. Page.makeInternalLink(item.name, item.pagename) .. ': ' .. item.information .. '\n')
		if idx == limit then
			break
		end
	end

	return table.concat(listItems)
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
