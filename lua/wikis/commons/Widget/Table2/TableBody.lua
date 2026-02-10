---
-- @Liquipedia
-- page=Module:Widget/Table2/TableBody
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local Table2Section = Lua.import('Module:Widget/Table2/Section')

---@class Table2BodyProps
---@field children (Widget|Html|string|number|nil)[]?

---@class Table2Body: Widget
---@operator call(Table2BodyProps): Table2Body
local Table2Body = Class.new(Widget)
Table2Body.defaultProps = {}

---@return Widget
function Table2Body:render()
	local props = self.props
	return Table2Section{
		value = 'body',
		children = props.children,
	}
end

return Table2Body
