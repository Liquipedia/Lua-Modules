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

---@class IconArgs
---@field iconName string
---@field color string?
---@field screenReaderHidden boolean?
---@field hover string?
---@field size integer|string|nil

---@param args IconArgs
---@return string?
function Icon.makeIcon(args)
	local icon = IconData[(args.iconName or ''):lower()]
	if not icon then
		return
	end

	local size = args.size
	if Logic.isNumeric(size) then
		size = size .. 'px'
	end
	return tostring(mw.html.create('i')
			:addClass(icon)
			:addClass(args.color)
			:attr('title', args.hover)
			:css('font-size', size)
			:attr('aria-hidden', args.screenReaderHidden and 'true' or nil)
	)
end

return Class.export(Icon)
