---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')
local Weight = require('Module:Weight')

local PrizePool = Lua.import('Module:PrizePool')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}


-- Template entry point
---@param frame Frame
---@return Html
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	args.localcurrency = args.localcurrency or Variables.varDefault('tournament_currency')

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

	Variables.varDefine(mw.ustring.lower(lpdbData.participant) .. '_prizepoints', lpdbData.extradata.prizepoints)

	return lpdbData
end

return CustomPrizePool
