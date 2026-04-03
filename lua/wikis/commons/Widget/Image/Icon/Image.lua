---
-- @Liquipedia
-- page=Module:Widget/Image/Icon/Image
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local WidgetIcon = Lua.import('Module:Widget/Image/Icon')

---@class IconImageWidgetParameters: IconImageWidgetParameters
---@field imageLight string?
---@field imageDark string?
---@field link string
---@field alt string?
---@field class string?
---@field format 'border'|'frameless'|'border|frameless'|'frame'|'thumb'?
---@field size string? # '{width}px'|'x{height}px'|'{width}x{height}px'
---@field horizontalAlignment 'left'|'right'|'center'|'none'?
---@field verticalAlignment 'baseline'|'sub'|'super'|'top'|text-top'|'middle'|'bottom'|'text-bottom'

---@class IconImageWidget: IconWidget
---@operator call(IconImageWidgetParameters): IconImageWidget
---@field props IconImageWidgetParameters
local Icon = Class.new(WidgetIcon)
Icon.defaultProps = {
	link = '',
	size = 'x20px',
	verticalAlignment = 'middle', -- make the implicit mw default explicit
}

---@return string?
function Icon:render()
	local imageLight = self.props.imageLight
	local imageDark = self.props.imageDark
	if Logic.isEmpty(imageLight) or Logic.isEmpty(imageDark) or imageLight == imageDark then
		return self:_make(Logic.nilIfEmpty(imageLight) or imageDark)
	end

	return Image._make(imageLight, 'show-when-light-mode')
		.. Image._make(imageDark, 'show-when-dark-mode')
end

return Icon
