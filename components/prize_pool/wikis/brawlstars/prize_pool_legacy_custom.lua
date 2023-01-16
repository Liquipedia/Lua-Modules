---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local PrizePoolLegacy = Lua.import('Module:PrizePool/Legacy', {requireDevIfEnabled = true})

local CustomLegacyPrizePool = {}

-- Template entry point
function CustomLegacyPrizePool.run()
	return PrizePoolLegacy.run(CustomLegacyPrizePool)
end

function CustomLegacyPrizePool.customSlot(newData, CACHED_DATA, slot)
	-- add wiki var for adding tracking category for cleanup
	-- after cleanup the entire module is to be archived and deleted from the git
	if CACHED_DATA.inputToId.points == 'seed' and Logic.isNumeric(slot.points) then
		Variables.varDefine('hasBadSeedValueCombination', 'true')
	end

	return newData
end

return CustomLegacyPrizePool
