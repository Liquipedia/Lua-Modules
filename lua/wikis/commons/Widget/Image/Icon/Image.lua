---
-- @Liquipedia
-- page=Module:Widget/Image/Icon/Image
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Image = Lua.import('Module:Image')

local WidgetIcon = Lua.import('Module:Widget/Image/Icon')

---@class IconImageWidgetParameters
---@field imageLight string?
---@field imageDark string?
---@field link string?
---@field size string?
---@field caption string?
---@field alt string?
---@field alignment string?

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
			caption = self.props.caption,
			alt = self.props.alt,
			alignment = self.props.alignment,
		}
	)
end

return Icon
