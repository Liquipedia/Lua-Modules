---
-- @Liquipedia
-- wiki=commons
-- page=Module:GroupTableLeague/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local GroupTableLeague = require('Module:GroupTableLeague')

local CustomGroupTableLeague = {}

function CustomGroupTableLeague.create(args)
	return GroupTableLeague.create(args)
end

return Class.export(CustomGroupTableLeague)
