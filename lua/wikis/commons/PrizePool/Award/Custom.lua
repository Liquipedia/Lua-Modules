---
-- @Liquipedia
-- page=Module:PrizePool/Award/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')

local AwardPrizePool = Lua.import('Module:PrizePool/Award')

local CustomAwardPrizePool = {}

local IS_AWARD = true

-- Template entry point
---@param frame Frame
---@return Html
function CustomAwardPrizePool.run(frame)
	local awardsPrizePool = AwardPrizePool(Arguments.getArgs(frame))

	awardsPrizePool:setConfigDefault('prizeSummary', false)
	awardsPrizePool:setConfigDefault('syncPlayers', true)

	return awardsPrizePool:create():build(IS_AWARD)
end

return CustomAwardPrizePool
