---
-- @Liquipedia
-- page=Module:Widget/Contexts/Customizable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local ComponentContext = Lua.import('Module:Widget/ComponentContext')

return {
	---@type ContextDef<WidgetInjector?>
	Customizable = ComponentContext.create(nil),
}
