---
-- @Liquipedia
-- wiki=commons
-- page=Module:Icon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute

local IconData = require('Module:Icon/Data')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')

local Icon = {}
local FontAwesomeString =
'<i class="${icon} ${color}" title="${hoverText}" style="font-size:${size}" ${ariaHiddenText}></i>'

---@param args {iconName: string, color: string?, screenReaderHidden: boolean?, hoverText: string?, size: integer|string|nil}
function Icon.makeIcon(args)
	local icon = IconData[(args.iconName or ''):lower()]
	if not icon then
		return
	end

	local aria = args.screenReaderHidden and 'aria-hidden="true"' or nil
	local size = args.size or ''
	if Logic.isNumeric(size) then
		size = size .. 'px'
	end

	return String.interpolate(FontAwesomeString,
		{icon = icon, ariaHiddenText = aria, size = size, hoverText = args.hoverText or '', color = args.color or ''})
end

return Icon
