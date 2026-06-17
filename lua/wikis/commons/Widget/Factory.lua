---
-- @Liquipedia
-- page=Module:Widget/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local WidgetFactory = {}

---@param args {widget: string, children: Renderable|Renderable[], [any]:any}
---@return Widget
function WidgetFactory.fromTemplate(args)
	local widgetClass = Table.extract(args, 'widget')
	assert(String.isNotEmpty(widgetClass), 'WidgetFactory: widget must be specified')
	local WidgetClass = Lua.import('Module:Widget/' .. widgetClass)
	local copiedArgs = Table.mapValues(args, function (arg)
		if type(arg) == 'table' then
			return arg
		end
		return tonumber(arg) or arg
	end)
	return WidgetClass(copiedArgs)
end

return Class.export(WidgetFactory, {exports = {'fromTemplate'}})
