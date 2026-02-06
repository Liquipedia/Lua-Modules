---
-- @Liquipedia
-- page=Module:Widget/Table2/TableFooter
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local Table2Section = Lua.import('Module:Widget/Table2/Section')

---@class Table2FooterProps
---@field children (Widget|Html|string|number|nil)[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?

---@class Table2Footer: Widget
---@operator call(Table2FooterProps): Table2Footer
local Table2Footer = Class.new(Widget)
Table2Footer.defaultProps = {
	classes = {},
}

---@return Widget
function Table2Footer:render()
	local props = self.props
	return Table2Section{
		value = 'foot',
		children = props.children,
	}
end

return Table2Footer
