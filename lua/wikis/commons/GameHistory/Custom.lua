---
-- @Liquipedia
-- page=Module:GameHistory/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local GameHistory = Lua.import('Module:GameHistory')

local Custom = {}

function Custom.create(frame)
	return GameHistory.create(frame)
end

return Custom
