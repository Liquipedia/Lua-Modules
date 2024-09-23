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
	HeaderName = Class.new(Context),
	Role = Class.new(Context),
	Inactive = Class.new(Context),
	Former = Class.new(Context),
}