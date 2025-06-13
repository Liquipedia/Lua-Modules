---
-- @Liquipedia
-- page=Module:Icon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local IconData = Lua.import('Module:Icon/Data')
local Icon = {}

---@class IconProps
---@field iconName string
---@field color string?
---@field screenReaderHidden boolean?
---@field hover string?
---@field size integer|string|nil
---@field additionalClasses string[]?
---@field attributes table<string, string>?

---@param props IconProps
---@return string?
function Icon.makeIcon(props)
	local icon = IconData[(props.iconName or ''):lower()]
	if not icon then
		return
	end

	local iconHtml = mw.html.create('i')
		:addClass(icon)
		:addClass(props.color)
		:addClass(Logic.isNotEmpty(props.additionalClasses) and table.concat(props.additionalClasses, ' ') or nil)
		:attr('title', props.hover)
		:attr('aria-hidden', props.screenReaderHidden and 'true' or nil)
		:attr(props.attributes and props.attributes or {})

	local size = props.size
	if Table.includes({'2xs', 'xs', 'sm', 'lg', 'xl', '2xl'}, size) then
		iconHtml:addClass('fa-' .. size)
	else
		if Logic.isNumeric(size) then
			size = size .. 'px'
		end
		iconHtml:css('font-size', size)
	end

	return tostring(iconHtml)
end

return Class.export(Icon, {exports = {'makeIcon'}}
)
