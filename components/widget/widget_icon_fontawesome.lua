---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Icon/Fontawesome
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Icon = require('Module:Icon')
local Lua = require('Module:Lua')

local WidgetIcon = Lua.import('Module:Widget/Icon')

---@class IconFontawesomeWidget: IconWidget
---@operator call(IconProps): IconFontawesomeWidget
---@field props IconProps
local FontawesomeIcon = Class.new(
	WidgetIcon,
	function(self, input)
		self.props = input
	end
)

---@param children string[]
---@return string?
function FontawesomeIcon:make(children)
	return Icon.makeIcon(self.props)
end

return FontawesomeIcon
