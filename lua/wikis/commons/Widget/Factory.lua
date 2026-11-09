---
-- @Liquipedia
-- page=Module:Widget/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local ArgSchema = Lua.import('Module:ArgSchema')
local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local WidgetFactory = {}

---@param args {widget: string, children: Renderable|Renderable[], [any]:any}
---@return Widget
function WidgetFactory.fromTemplate(args)
	local WidgetClass = Lua.import('Module:Widget/' .. args.widget)
	local props
	if WidgetClass.parameters then
		-- Only the declared parameters, read into their types
		props = ArgSchema.read(WidgetClass.parameters, args)
	else
		props = Table.copy(args)
		props.widget = nil
	end
	props.children = type(args.children) == 'table' and args.children or {args.children}
	return WidgetClass(props)
end

return Class.export(WidgetFactory, {exports = {'fromTemplate'}})
