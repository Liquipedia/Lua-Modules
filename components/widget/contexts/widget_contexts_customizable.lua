---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Contexts/Customizable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Context = Lua.import('Module:Widget/Context')

-- Customizable backwards compatibility
return {
	LegacyCustomizable = Class.new(Context),
}
