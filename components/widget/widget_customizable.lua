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
---@field children Widget[]
local Customizable = Class.new(
	Widget,
	function(self, input)
		self.id = self:assertExistsAndCopy(input.id)
		self.children = input.children
	end
)

---@param injector WidgetInjector?
---@param children string[]
---@return string[]?
function Customizable:make(injector, children)
	return children
end

---@param injector WidgetInjector?
---@return Widget[]?
function Customizable:makeChildren(injector)
	local children = self.children
	if injector == nil then
		return children
	end
	return injector:parse(self.id, children)
end

return Customizable
