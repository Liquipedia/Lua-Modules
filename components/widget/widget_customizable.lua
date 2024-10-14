---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Customizable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class CustomizableWidget: Widget
---@operator call({id: string, children: Widget[]}): CustomizableWidget
---@field id string
local Customizable = Class.new(
	Widget,
	function(self, input)
		self.id = self:assertExistsAndCopy(input.id)
	end
)

---@param children string[]
---@return string
function Customizable:make(children)
	return table.concat(children)
end

---@param injector WidgetInjector?
---@return Widget[]?
function Customizable:makeChildren(injector)
	if injector == nil then
		return self.props.children
	end
	return injector:parse(self.id, self.props.children)
end

return Customizable
