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

---@class IconFontawesomeProps: IconProps
---@field faName string?
---@field faStyle string?
---@field faSize string?

---@class IconFontawesomeWidget: IconWidget
---@operator call(IconProps): IconFontawesomeWidget
---@field props IconFontawesomeProps
local FontawesomeIcon = Class.new(WidgetIcon)
FontawesomeIcon.defaultProps = {
	faStyle = 'fas'
}

local CLASS_TEMPLATE = '${style} fa-${icon}'
local CLASS_TEMPLATE_SIZE = 'fa-${size}'
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

	assert(Table.includes(VALID_STYLES, props.faStyle), props.faStyle .. ' is not a valid Font Awesome icon style!')

	assert(Logic.isEmpty(props.faSize) or Table.includes(VALID_SIZES, props.faSize),
		props.faSize .. ' is not a valid Font Awesome icon size!')

	local size = props.size
	if Logic.isNumeric(size) then
		size = size .. 'px'
	end

	local iconClasses = {
		String.interpolate(CLASS_TEMPLATE, {
			style = props.faStyle,
			icon = props.faName,
		})
	}
	if Logic.isNotEmpty(props.faSize) then
		Array.appendWith(iconClasses, String.interpolate(CLASS_TEMPLATE_SIZE, {
			size = props.faSize
		})
	end

	return I{
		classes = Array.extendWith(
			iconClasses,
			props.additionalClasses,
			props.color
		),
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
