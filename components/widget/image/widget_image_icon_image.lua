---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Image/Icon/Image
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Image = require('Module:Image')
local Lua = require('Module:Lua')

local WidgetIcon = Lua.import('Module:Widget/Image/Icon')

---@class IconImageWidgetParameters
---@field imageLight string?
---@field imageDark string?
---@field link string?
---@field size string?

---@class IconImageWidget: IconWidget
---@operator call(IconImageWidgetParameters): IconImageWidget
---@field props IconImageWidgetParameters
local Icon = Class.new(WidgetIcon)
Icon.defaultProps = {
	link = '',
	size = 'x20px'
}

---@return string?
function Icon:render()
	return Image.display(
		self.props.imageLight,
		self.props.imageDark,
		{
			link = self.props.link,
			size = self.props.size,
		}
	)
end

return Icon
