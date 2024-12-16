---
-- @Liquipedia
-- wiki=commons
-- page=Module:MainPageLayout
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Grid = require('Module:Grid')
local Lua = require('Module:Lua')
local Template = require('Module:Template')

local Layouts = Lua.import('Module:MainPageLayout/data')

local MainPageLayout = {}

function MainPageLayout.make(frame)
	local args = Arguments.getArgs(frame)

	local layout = Layouts[args.layout or 'main']
	return table.concat(MainPageLayout._makeCells(layout))
end

function MainPageLayout._makeCells(cells)
	local frame = mw.getCurrentFrame()
	local output = {}

	table.insert(output, Grid._start_grid{})
	for _, column in ipairs(cells) do
		local cellContent = {}
		for _, item in ipairs(column.children) do
			local content = {}
			if item.content then
				if item.content.noPanel then
					table.insert(content, frame:preprocess(item.content.body))
				else
					table.insert(content, Template.safeExpand(frame, 'panel', {
						['body'] = frame:preprocess(item.content.body),
						['box-id'] = item.content.boxid,
						['padding'] = tostring(item.content.padding),
						['heading'] = item.content.heading,
					}))
				end
			end
			if item.children then
				Array.extendWith(content, MainPageLayout._makeCells(item.children))
			end
			table.insert(cellContent, tostring(Grid._cell{table.concat(content), ['order-xs'] = item.mobileOrder}))
		end
		table.insert(output, tostring(Grid._cell{table.concat(cellContent), lg = column.size, xs = 'ignore', sm = 'ignore'}))
	end
	table.insert(output, Grid._end_grid{})
	return output
end

return MainPageLayout
