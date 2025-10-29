---
-- @Liquipedia
-- page=Module:Widget/Image/Icon/Fontawesome
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Icon = Lua.import('Module:Icon')
local WidgetIcon = Lua.import('Module:Widget/Image/Icon')

---@class IconFontawesomeWidget: IconWidget
---@operator call(IconProps): IconFontawesomeWidget
---@field props IconProps
local FontawesomeIcon = Class.new(WidgetIcon)

---@return string?
function FontawesomeIcon:render()
	return Icon.makeIcon(self.props)
end

return FontawesomeIcon
