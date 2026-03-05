---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')
local Variables = Lua.import('Module:Variables')
local Weight = Lua.import('Module:Weight')

local PrizePool = Lua.import('Module:PrizePool')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}


-- Template entry point
---@param frame Frame
---@return Html
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	local prizePool = PrizePool(args):create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	return prizePool:build()
end

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@param opponent BasePlacementOpponent
---@return placement
function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.weight = Weight.calc(
		lpdbData.prizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		placement.placeStart,
		Variables.varDefault('tournament_type'),
		Variables.varDefault('tournament_liquipediatiertype')

	)

	local participantLower = mw.ustring.lower(lpdbData.participant)

	Variables.varDefine(participantLower .. '_prizepoints', lpdbData.extradata.prizepoints)
	Variables.varDefine(participantLower .. '_prizepoints2', lpdbData.extradata.prizepoints2)
	lpdbData.extradata.location = Variables.varDefault('tournament_location_region', '')
	return lpdbData
end

return CustomPrizePool
