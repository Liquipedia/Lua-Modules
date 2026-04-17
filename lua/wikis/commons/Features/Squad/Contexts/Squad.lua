---
-- @Liquipedia
-- page=Module:Widget/Contexts/Squad
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Context = Lua.import('Module:Lib/Component/Context')

return {
	NameSection = Context.create('Name'),
	RoleTitle = Context.create(nil),
	GameTitle = Context.create(nil),
	ColumnVisibility = Context.create(),
}
