---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Icon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class IconWidget: Widget
---@operator call(WidgetParameters): IconWidget
local Icon = Class.new(
	Widget,
	function(self, input)
	end
)

---@param children string[]
---@return string?
function Icon:make(children)
	error('Widget/Icon is an interface and should not be instantiated directly')
end

return Icon
