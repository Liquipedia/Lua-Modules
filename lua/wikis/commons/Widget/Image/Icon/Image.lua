---
-- @Liquipedia
-- page=Module:Widget/Image/Icon/Image
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Image = Lua.import('Module:Image')
local Table = Lua.import('Module:Table')

local WidgetIcon = Lua.import('Module:Widget/Image/Icon')

---@class IconImageWidgetParameters: ImageOptions
---@field imageLight string?
---@field imageDark string?

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
		Table.extract(self.props, 'imageLight'),
		Table.extract(self.props, 'imageDark'),
		self.props
	)
end

return Icon
