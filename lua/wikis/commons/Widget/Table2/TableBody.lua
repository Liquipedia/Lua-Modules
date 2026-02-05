---
-- @Liquipedia
-- page=Module:Widget/Table2/TableBody
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local Table2Row = Lua.import('Module:Widget/Table2/Row')
local Table2Section = Lua.import('Module:Widget/Table2/Section')

---@class Table2BodyProps
---@field children (Widget|Html|string|number|nil)[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?
---@field striped (string|number|boolean)?

---@class Table2Body: Widget
---@operator call(Table2BodyProps): Table2Body
local Table2Body = Class.new(Widget)
Table2Body.defaultProps = {
	classes = {},
}

---@return Widget
function Table2Body:render()
	local children = self.props.children
	if Logic.readBool(self.props.striped) then
		children = {}
		for index, child in ipairs(self.props.children or {}) do
			if Class.instanceOf(child, Table2Row) then
				child.props.classes = child.props.classes or {}
				if index % 2 == 0 then
					table.insert(child.props.classes, 'table2__row--striped')
				end
			end
			table.insert(children, child)
		end
	end

	return Table2Section{
		value = 'body',
		children = children,
	}
end

return Table2Body
