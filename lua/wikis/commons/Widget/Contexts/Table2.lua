---
-- @Liquipedia
-- page=Module:Widget/Contexts/Table2
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Context = Lua.import('Module:Widget/ComponentContext')

return {
	BodyStripe = Context.create('disabled'),
	ColumnContext = Context.create({}),
	HeaderRowKind = Context.create('title'),
	Section = Context.create('head'),
}
