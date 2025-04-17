---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Image/Icon/Fontawesome
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Icon = Lua.import('Module:Icon')
local WidgetIcon = Lua.import('Module:Widget/Image/Icon')

---@class IconFontawesomeWidget: IconWidget
---@operator call(IconProps): IconFontawesomeWidget
---@field props IconProps
local FontawesomeIcon = Class.new(WidgetIcon)

---@return Html?
function FontawesomeIcon:render()
	return Icon.makeIconHtml(self.props)
end

return FontawesomeIcon
