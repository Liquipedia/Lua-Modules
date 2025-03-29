---
-- @Liquipedia
-- wiki=commons
-- page=Module:Icon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local IconData = Lua.import('Module:Icon/Data')
local Icon = {}

---@class IconProps
---@field iconName string
---@field color string?
---@field screenReaderHidden boolean?
---@field hover string?
---@field size integer|string|nil
---@field pageLink string?
---@field externalLink string?
---@field additionalClasses string[]?
---@field attributes table<string, string>?

---@param props IconProps
---@return string?
function Icon.makeIcon(props)
	local icon = IconData[(props.iconName or ''):lower()]
	if not icon then
		return
	end

	local size = props.size
	if Logic.isNumeric(size) then
		size = size .. 'px'
	end
	local iconString = tostring(mw.html.create('i')
			:addClass(icon)
			:addClass(props.color)
			:addClass(Logic.isNotEmpty(props.additionalClasses) and table.concat(props.additionalClasses, ' ') or nil)
			:attr('title', props.hover)
			:css('font-size', size)
			:attr('aria-hidden', props.screenReaderHidden and 'true' or nil)
			:attr(props.attributes and props.attributes or {})
	)

	if Logic.isNotEmpty(props.pageLink) then
		return '[[' .. props.pageLink .. '|' .. iconString .. ']]'
	elseif Logic.isNotEmpty(props.externalLink) then
		return '[' .. props.externalLink .. ' ' .. iconString .. ']'
	else
		return iconString
	end
end

return Class.export(Icon)
