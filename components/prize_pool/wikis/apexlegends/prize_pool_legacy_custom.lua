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
local REMOVE_PLACE = false
-- Template entry point
function CustomLegacyPrizePool.run()
	return PrizePoolLegacy.run(CustomLegacyPrizePool)
end

function CustomLegacyPrizePool.customHeader(newArgs, data, header)
	if Logic.readBool(header.seed) then
		PrizePoolLegacy.assignType(newArgs, 'seed', 'seed')
	end
	REMOVE_PLACE = Logic.readBool(header.removeplace)
	return newArgs
end

function CustomLegacyPrizePool.customSlot(newData, CACHED_DATA, slot)
	if REMOVE_PLACE then
		newData["place"] = nil
	end
	return newData
end
return CustomLegacyPrizePool
