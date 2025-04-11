---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Image/Icon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class IconWidget: Widget
---@operator call(table): IconWidget
local Icon = Class.new(Widget)

---@return (string|Widget)|(string|Widget)[]?
function Icon:render()
	error('Widget/Image/Icon is an interface and should not be instantiated directly')
end

return Icon
