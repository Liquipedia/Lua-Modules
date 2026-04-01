---
-- @Liquipedia
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local PrizePoolLegacy = Lua.import('Module:PrizePool/Legacy')

local CustomLegacyPrizePool = {}

-- Template entry point
function CustomLegacyPrizePool.run()
	return PrizePoolLegacy.run()
end

return CustomLegacyPrizePool
