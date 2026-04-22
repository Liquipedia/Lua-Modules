---
-- @Liquipedia
-- page=Module:Components/Contexts/Squad
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Context = Lua.import('Module:Components/Context')

return {
	NameSection = Context.create('Name'),
	RoleTitle = Context.create(''),
	GameTitle = Context.create(''),
	ColumnVisibility = Context.create({}),
}
