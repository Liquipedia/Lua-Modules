---
-- @Liquipedia
-- page=Module:MatchFormatTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('ModuleLua')

local Arguments = Lua.import('ModuleArguments')
local Array = Lua.import('ModuleArray')

local TableWidgets = Lua.import('ModuleWidgetTable2All')

local MatchFormatTable = {}

---@param frame Frame|table
---@return VNode
function MatchFormatTable.run(frame)
  local args = Arguments.getArgs(frame)

	local modeCells = Array.mapIndexes(function(setIndex)
		if not args['setMode' .. setIndex] then return end
		return TableWidgets.Cell{children = args['setMode' .. setIndex]}
	end)
	local bestofCells = Array.mapRange(1, #modeCells, function(setIndex)
		assert(args['setBestof' .. setIndex], 'setBestof' .. setIndex .. '= not specified')
		return TableWidgets.Cell{children = 'Best of ' ..  args['setBestof' .. setIndex]}
	end)
	local headerCells = Array.mapRange(1, #modeCells, function(setIndex)
		return TableWidgets.CellHeader{children = 'Set ' .. setIndex}
	end)

	return TableWidgets.Table{
		title = assert(args.title, 'title= not specified'),
		children = {
			TableWidgets.TableHeader{
				children = TableWidgets.Row{children = headerCells}
			},
			TableWidgets.TableBody{
				children = {
					TableWidgets.Row{children = modeCells},
					TableWidgets.Row{children = bestofCells},
				},
			},
		}
	}
end

return MatchFormatTable
