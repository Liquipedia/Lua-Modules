---
-- @Liquipedia
-- page=Module:Widget/Image/Icon/Image
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')

---@class IconImageWidgetParameters
---@field imageLight string?
---@field imageDark string?
---@field link string?
---@field alt string?
---@field classes string[]?
---@field border 'border'? # only available if `format: 'frameless'?`
---@field format 'frameless'|'frame'|'thumb'?
---@field size string? # '{width}px'|'x{height}px'|'{width}x{height}px'
---@field horizontalAlignment 'left'|'right'|'center'|'none'?
---@field verticalAlignment 'baseline'|'sub'|'super'|'top'|'text-top'|'middle'|'bottom'|'text-bottom'?
---@field caption string?

local Icon = {}
Icon.defaultProps = {
	link = '',
	size = 'x20px',
	verticalAlignment = 'middle', -- make the implicit mw default explicit
}

---@param props IconImageWidgetParameters
---@return string|string[]?
function Icon.render(props)
	local imageLight = props.imageLight
	local imageDark = props.imageDark
	if Logic.isEmpty(imageLight) or Logic.isEmpty(imageDark) or imageLight == imageDark then
		return Icon._make(props, Logic.emptyOr(imageLight, imageDark))
	end

	return {
		Icon._make(props, imageLight, 'show-when-light-mode'),
		Icon._make(props, imageDark, 'show-when-dark-mode'),
	}
end

---@private
---@param props IconImageWidgetParameters
---@param image string?
---@param themeClass string?
---@return string?
---@overload fun(nil): nil
function Icon._make(props, image, themeClass)
	if Logic.isEmpty(image) then
		return
	end
	local classes = table.concat(Array.extend(props.classes, themeClass), ' ')

	local border = Logic.nilIfEmpty(props.border)
	assert((props.format == 'frameless' or not props.format) or not border,
		'border can only be used for frameless images')

	local parts = Array.extend(
		'File:' .. image,
		border,
		Logic.nilIfEmpty(props.format),
		Logic.isNumeric(props.size) and (props.size .. 'px') or Logic.nilIfEmpty(props.size),
		Logic.nilIfEmpty(props.horizontalAlignment),
		props.verticalAlignment ~= 'middle' and props.verticalAlignment or nil,
		'link=' .. props.link,
		Logic.isNotEmpty(props.alt) and ('alt=' .. props.alt) or nil,
		Logic.isNotEmpty(classes) and ('class=' .. classes) or nil,
		Logic.nilIfEmpty(props.caption)
	)

	return '[[' .. table.concat(parts, '|') .. ']]'
end

return Component.component(Icon.render, Icon.defaultProps)
