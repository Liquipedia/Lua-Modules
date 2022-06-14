---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Lua = require('Module:Lua')

local PrizePool = Lua.import('Module:PrizePool', {requireDevIfEnabled = true})

local CustomPrizePool = {}

-- Template entry point
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	local prizePool = PrizePool(args):create()

	return prizePool:build()
end

return CustomPrizePool
