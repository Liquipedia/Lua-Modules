---
-- @Liquipedia
-- page=Module:Widget/Contexts/Customizable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Context = Lua.import('Module:Widget/Context')

-- Customizable backwards compatibility
return {
	LegacyCustomizable = Class.new(Context),
}
