---
-- @Liquipedia
-- wiki=commons
-- page=Module:WantToHelpList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local WantToHelpList = {}

local DEFAULT_LIMIT = 3

function WantToHelpList.get(frame)
	local args = Arguments.getArgs(frame)
	local limit = tonumber(args.limit) or DEFAULT_LIMIT

	local listItems = {}
	local todos = WantToHelpList._getTodos()

	Variables.varDefine('total_number_of_todos', #todos)

	for idx, item in ipairs(Table.randomize(todos)) do
		table.insert(listItems, '*[[' .. item.name .. ']]: ' .. item.information .. '\n')
		if idx == limit then
			break
		end
	end

	return table.concat(listItems)
end

function WantToHelpList._getTodos()
	return mw.ext.LiquipediaDB.lpdb('datapoint', {
		limit = 5000,
		conditions = '[[type::todo]]'
	})
end

return WantToHelpList
