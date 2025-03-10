---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Contexts/Squad
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Context = Lua.import('Module:Widget/Context')

return {
	NameSection = Class.new(Context),
	RoleTitle = Class.new(Context),
	InactiveSection = Class.new(Context),
	FormerSection = Class.new(Context),
}
