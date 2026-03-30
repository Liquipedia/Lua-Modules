---
-- @Liquipedia
-- page=Module:Widget/Table2/TableHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local Table2Row = Lua.import('Module:Widget/Table2/Row')
local Table2Contexts = Lua.import('Module:Widget/Contexts/Table2')

---@class Table2HeaderProps
---@field children Renderable[]?

---@class Table2Header: Widget
---@operator call(Table2HeaderProps): Table2Header
---@field props Table2HeaderProps
local Table2Header = Class.new(Widget)

---@return Widget
function Table2Header:render()
	local props = self.props
	local rowCount = 0
	local children = Array.map(props.children or {}, function(child)
		if Class.instanceOf(child, Table2Row) then
			rowCount = rowCount + 1
			local kind = rowCount == 1 and 'title' or 'columns'
			child = Table2Contexts.HeaderRowKind{
				value = kind,
				children = {child},
			}
		end
		return child
	end)

	return Table2Contexts.Section{
		value = 'head',
		children = children,
	}
end

return Table2Header
