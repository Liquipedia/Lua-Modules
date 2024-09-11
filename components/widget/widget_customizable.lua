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
---@return Widget[]?
function Customizable:make(injector)
	if injector == nil then
		return self.children
	end
	return injector:parse(self.id, self.children)
end

return Customizable
