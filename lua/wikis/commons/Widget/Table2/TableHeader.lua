---
-- @Liquipedia
-- page=Module:Widget/Table2/TableHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local Table2Row = Lua.import('Module:Widget/Table2/Row')
local Table2Section = Lua.import('Module:Widget/Table2/Section')
local Table2HeaderRowKind = Lua.import('Module:Widget/Table2/HeaderRowKind')

---@class Table2HeaderProps
---@field children (Widget|Html|string|number|nil)[]?

---@class Table2Header: Widget
---@operator call(Table2HeaderProps): Table2Header
local Table2Header = Class.new(Widget)
Table2Header.defaultProps = {}

---@return Widget
function Table2Header:render()
	local props = self.props
	local children = {}
	local rowCount = 0
	for _, child in ipairs(props.children or {}) do
		if Class.instanceOf(child, Table2Row) then
			rowCount = rowCount + 1
			local kind = rowCount == 1 and 'title' or 'columns'
			child = Table2HeaderRowKind{
				value = kind,
				children = {child},
			}
		end
		table.insert(children, child)
	end

	return Table2Section{
		value = 'head',
		children = children,
	}
end

return Table2Header
