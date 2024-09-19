---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Customizable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class CustomizableWidget: Widget
---@operator call({id: string, children: Widget[], injector:WidgetInjector?}): CustomizableWidget
---@field id string
---@field children Widget[]
---@field injector WidgetInjector?
local Customizable = Class.new(
	Widget,
	function(self, input)
		self.id = self:assertExistsAndCopy(input.id)
		self.injector = input.injector
	end
)

---@return string
function Customizable:make()
	local children = self.children
	if self.injector ~= nil then
		children = self.injector:parse(self.id, children) or {}
	end
	return table.concat(Array.map(children, tostring))
end

return Customizable
