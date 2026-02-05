---
-- @Liquipedia
-- page=Module:Widget/Table2/TableHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local Table2Section = Lua.import('Module:Widget/Table2/Section')

---@class Table2HeaderProps
---@field children (Widget|Html|string|number|nil)[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?

---@class Table2Header: Widget
---@operator call(Table2HeaderProps): Table2Header
local Table2Header = Class.new(Widget)
Table2Header.defaultProps = {
	classes = {},
}

---@return Widget
function Table2Header:render()
	return Table2Section{
		value = 'head',
		children = self.props.children,
	}
end

return Table2Header
