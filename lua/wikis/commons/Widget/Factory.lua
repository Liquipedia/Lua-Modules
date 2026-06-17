---
-- @Liquipedia
-- page=Module:Widget/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local WidgetFactory = {}

---@param args {widget: string, children: Renderable|Renderable[], [any]:any}
---@return Widget
function WidgetFactory.fromTemplate(args)
	local widgetClass = Table.extract(args, 'widget')
	local WidgetClass = Lua.import('Module:Widget/' .. widgetClass)
	local copiedArgs = Table.copy(args)
	copiedArgs.children = type(copiedArgs.children) == 'table' and copiedArgs.children or {copiedArgs.children}
	return WidgetClass(copiedArgs)
end

return Class.export(WidgetFactory, {exports = {'fromTemplate'}})
