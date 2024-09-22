---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Icon/Image
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Image = require('Module:Image')
local Lua = require('Module:Lua')

local WidgetIcon = Lua.import('Module:Widget/Icon')

---@class IconImageWidgetParameters: WidgetParameters
---@field imageLight string?
---@field imageDark string?
---@field link string?

---@class IconImageWidget: IconWidget
---@operator call(IconImageWidgetParameters): IconImageWidget
---@field props IconImageWidgetParameters
local Icon = Class.new(
	WidgetIcon,
	function(self, input)
		self.props = input
	end
)

---@param children string[]
---@return string?
function Icon:make(children)
	return Image.display(
		self.props.imageLight,
		self.props.imageDark,
		{
			link = self.props.link or '',
			size = 'x20px',
		}
	)
end

return Icon
