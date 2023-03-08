---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool/Award/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Lua = require('Module:Lua')

local AwardPrizePool = Lua.import('Module:PrizePool/Award', {requireDevIfEnabled = true})

local CustomAwardPrizePool = {}

-- Template entry point
function CustomAwardPrizePool.run(frame)
	return AwardPrizePool(Arguments.getArgs(frame)):create():build()
end

return CustomAwardPrizePool
