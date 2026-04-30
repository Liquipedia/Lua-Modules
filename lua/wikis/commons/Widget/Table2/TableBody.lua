---
-- @Liquipedia
-- page=Module:Widget/Table2/TableBody
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local Table2Contexts = Lua.import('Module:Widget/Contexts/Table2')

---@class Table2BodyProps
---@field children Renderable[]?

---@class Table2Body: Widget
---@operator call(Table2BodyProps): Table2Body
---@field props Table2BodyProps
local Table2Body = Class.new(Widget)

---@return Widget
function Table2Body:render()
	return Table2Contexts.Section{
		value = 'body',
		children = self.props.children or {},
	}
end

return Table2Body
