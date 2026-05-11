---
-- @Liquipedia
-- page=Module:Widget/Contexts/Squad
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Context = Lua.import('Module:Widget/ComponentContext')

return {
	NameSection = Context.create('Name'),
	RoleTitle = Context.create(''),
	---@type ContextDef<string|nil>
	GameTitle = Context.create(nil),
	ColumnVisibility = Context.create({}),
}
