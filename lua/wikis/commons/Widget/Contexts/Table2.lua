---
-- @Liquipedia
-- page=Module:Widget/Contexts/Table2
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Context = Lua.import('Module:Widget/Context')

return {
	BodyStripe = Class.new(Context),
	ColumnContext = Class.new(Context),
	HeaderRowKind = Class.new(Context),
	Section = Class.new(Context),
}
