---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Image/Icon/Fontawesome
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Icon = require('Module:Icon')
local Lua = require('Module:Lua')

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
