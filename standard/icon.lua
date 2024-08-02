---
-- @Liquipedia
-- wiki=commons
-- page=Module:Icon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute

local Class = require('Module:Class')
local IconData = require('Module:Icon/Data')
local Logic = require('Module:Logic')

local Icon = {}

---@class IconProps
---@field iconName string
---@field color string?
---@field screenReaderHidden boolean?
---@field hover string?
---@field size integer|string|nil
---@field additionalClasses string[]?

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
	return tostring(mw.html.create('i')
			:addClass(icon)
			:addClass(props.color)
			:addClass(props.additionalClasses and table.concat(props.additionalClasses, ' ') or nil)
			:attr('title', props.hover)
			:css('font-size', size)
			:attr('aria-hidden', props.screenReaderHidden and 'true' or nil)
	)
end

return Class.export(Icon)
