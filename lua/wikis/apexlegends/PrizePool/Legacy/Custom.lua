---
-- @Liquipedia
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local PrizePoolLegacy = Lua.import('Module:PrizePool/Legacy')

local CustomLegacyPrizePool = {}

-- Template entry point
---@return Html
function CustomLegacyPrizePool.run()
	return PrizePoolLegacy.run(CustomLegacyPrizePool)
end

---@param newArgs table
---@param data table
---@param header table
---@return table
function CustomLegacyPrizePool.customHeader(newArgs, data, header)
	if Logic.readBool(header.seed) then
		PrizePoolLegacy.assignType(newArgs, 'seed', 'seed')
	end

	return newArgs
end

return CustomLegacyPrizePool
