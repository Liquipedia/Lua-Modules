---
-- @Liquipedia
-- wiki=commons
-- page=Module:CrossTableLeague/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local CrossTableLeague = Lua.import('Module:CrossTableLeague/Base', {requireDevIfEnabled = true})

local CustomCrossTableLeague = {}

---@param args table?
---@return Html?
function CustomCrossTableLeague.run(args)
	return CrossTableLeague():read(args):query():create()
end

return Class.export(CustomCrossTableLeague)
