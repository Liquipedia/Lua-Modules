---
-- @Liquipedia
-- page=Module:Components/Contexts/Table2
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Context = Lua.import('Module:Components/Context')

return {
	BodyStripe = Context.create(false),
	ColumnContext = Context.create({}),
	HeaderRowKind = Context.create('title'),
	Section = Context.create('head'),
}
