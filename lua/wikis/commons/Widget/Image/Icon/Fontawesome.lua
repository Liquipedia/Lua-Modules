---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Image/Icon/Fontawesome
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local I = Lua.import('Module:Widget/Html/All').I
local Icon = Lua.import('Module:Icon')
local WidgetIcon = Lua.import('Module:Widget/Image/Icon')

---@class IconFontawesomeProps
---@field iconName string?
---@field faName string?
---@field faStyle string?
---@field faSize string?
---@field color string?
---@field screenReaderHidden boolean?
---@field hover string?
---@field size integer|string|nil
---@field additionalClasses string[]?
---@field attributes table<string, string>?

---@class IconFontawesomeWidget: IconWidget
---@operator call(IconProps): IconFontawesomeWidget
---@field props IconFontawesomeProps
local FontawesomeIcon = Class.new(WidgetIcon)
FontawesomeIcon.defaultProps = {
	faStyle = 'fas'
}

local CLASS_TEMPLATE = '${style} fa-${icon}'
local CLASS_TEMPLATE_SIZED = CLASS_TEMPLATE .. ' fa-${size}'
local VALID_STYLES = {
	'fas',
	'far',
	'fal',
	'fad',
	'fab'
}
local VALID_SIZES = {
	'xs',
	'sm',
	'lg',
	'1x',
	'2x',
	'3x',
	'4x',
	'5x',
	'6x',
	'7x',
	'8x',
	'9x',
	'10x'
}

---@return WidgetHtml
function FontawesomeIcon:_makeGenericIcon()
	local props = self.props

	if not Table.includes(VALID_STYLES, props.faStyle) then
		error(props.faStyle .. ' is not a valid Font Awesome icon style!')
	end

	if not (Logic.isEmpty(props.faSize) or Table.includes(VALID_SIZES, props.faSize)) then
		error(props.faSize .. ' is not a valid Font Awesome icon size!')
	end

	local size = props.size
	if Logic.isNumeric(size) then
		size = size .. 'px'
	end

	local iconClasses
	if Logic.isNotEmpty(props.faSize) then
		iconClasses = String.interpolate(CLASS_TEMPLATE_SIZED, {
				style = props.faStyle,
				icon = props.faName,
				size = props.faSize
			})
	else
		iconClasses = String.interpolate(CLASS_TEMPLATE, {
				style = props.faStyle,
				icon = props.faName
			})
	end

	return I{
		classes = {
			iconClasses,
			props.additionalClasses,
			props.color,
		},
		attributes = Table.merge(
			props.attributes,
			{
				['title'] = props.hover,
				['aria-hidden'] = props.screenReaderHidden and 'true' or nil,
			}
		),
		css = {
			['font-size'] = size,
		},
	}
end

---@return WidgetHtml|string|nil
function FontawesomeIcon:render()
	if Logic.isNotEmpty(self.props.faName) then
		return self:_makeGenericIcon()
	elseif Logic.isNotEmpty(self.props.iconName) then
		return Icon.makeIcon(self.props)
	end
	return nil
end

return FontawesomeIcon
