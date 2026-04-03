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

---@class IconImageWidgetParameters:
---@field imageLight string?
---@field imageDark string?
---@field link string
---@field alt string?
---@field class string?
---@field border 'border'? # only available if `format: 'frameless'?`
---@field format 'frameless'|'frame'|'thumb'?
---@field size string? # '{width}px'|'x{height}px'|'{width}x{height}px'
---@field horizontalAlignment 'left'|'right'|'center'|'none'?
---@field verticalAlignment 'baseline'|'sub'|'super'|'top'|'text-top'|'middle'|'bottom'|'text-bottom'?
---@field caption string?
---@field alignment string? # legacy for during conversion

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
	-- legacy, only for conversion outside of git ...
	self.props.horizontalAlignment = self.props.horizontalAlignment or self.props.alignment

	local imageLight = self.props.imageLight
	local imageDark = self.props.imageDark
	if Logic.isEmpty(imageLight) or Logic.isEmpty(imageDark) or imageLight == imageDark then
		return self:_make(Logic.nilIfEmpty(imageLight) or Logic.nilIfEmpty(imageDark))
	end

	return self:_make(imageLight, 'show-when-light-mode')
		.. self:_make(imageDark, 'show-when-dark-mode')
end

---@param image string?
---@param themeClass string?
---@return string
---@overload fun(nil): nil
function Icon:_make(image, themeClass)
	if not image then
		return
	end
	local class = table.concat(Array.append({Logic.nilIfEmpty(self.props.class)}, themeClass), ' ')

	local border = Logic.nilIfEmpty(self.props.border)
	assert((self.props.format == 'frameless' or not self.props.format) or not border,
		'border can only be used for frameless images')

	local parts = Array.append({},
		'File:' .. image,
		Logic.nilIfEmpty(self.props.border),
		Logic.nilIfEmpty(self.props.format),
		Logic.isNumeric(self.props.size) and (self.props.size .. 'px') or Logic.nilIfEmpty(self.props.size),
		Logic.nilIfEmpty(self.props.horizontalAlignment),
		self.props.verticalAlignment ~= 'middle' and self.props.verticalAlignment or nil,
		'link=' .. self.props.link,
		Logic.isNotEmpty(self.props.alt) and ('alt=' .. self.props.alt) or nil,
		Logic.isNotEmpty(class) and ('class=' .. class) or nil,
		Logic.nilIfEmpty(self.props.caption)
	)

	return '[[' .. table.concat(parts, '|') .. ']]'
end

return Icon
