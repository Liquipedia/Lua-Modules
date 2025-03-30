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
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local I = Lua.import('Module:Widget/Html/All').I
local Icon = Lua.import('Module:Icon')
local WidgetIcon = Lua.import('Module:Widget/Image/Icon')

---@class IconFontawesomeProps
---@field iconName string?
---@field faName string?
---@field faStyle string?
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

local CLASS_TEMPLATE = '${style} fa-${icon}'
local DEFAULT_STYLE = 'fas'
local VALID_STYLES = {
	'fas',
	'far',
	'fal',
	'fad',
	'fab'
}

---@return WidgetHtml
function FontawesomeIcon:_makeGenericIcon()
	local props = self.props
	local size = props.size
	if Logic.isNumeric(size) then
		size = size .. 'px'
	end
	return I{
		classes = {
			String.interpolate(CLASS_TEMPLATE, {style = Logic.emptyOr(props.faStyle, DEFAULT_STYLE), icon = props.faName}),
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
