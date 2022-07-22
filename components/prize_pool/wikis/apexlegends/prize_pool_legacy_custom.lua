---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local PrizePoolLegacy = Lua.import('Module:PrizePool/Legacy', {requireDevIfEnabled = true})

local CustomLegacyPrizePool = {}

-- Template entry point
function CustomLegacyPrizePool.run()
	return PrizePoolLegacy.run(CustomLegacyPrizePool)
end

function CustomLegacyPrizePool.customHeader(newArgs, data, header)
	if Logic.readBool(header.seed) then
		PrizePoolLegacy.assignType(newArgs, 'seed', 'seed')
	end

	return newArgs
end

return CustomLegacyPrizePool
