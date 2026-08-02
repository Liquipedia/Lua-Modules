---
-- @Liquipedia
-- page=Module:PrizePool/Award/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local AwardPrizePool = Lua.import('Module:PrizePool/Award')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local Namespace = Lua.import('Module:Namespace')
local Opponent = Lua.import('Module:Opponent/Custom')
local Variables = Lua.import('Module:Variables')

---@class StarcraftCustomAwardPrizePoolLpdbInjector: LpdbInjector
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local IS_AWARD = true

-- Template entry point
---@param frame Frame
---@return Widget
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)

	-- set some default values
	args.prizesummary = Logic.emptyOr(args.prizesummary, false)
	args.exchangeinfo = Logic.emptyOr(args.exchangeinfo, false)
	args.storelpdb = Logic.emptyOr(args.storelpdb, Namespace.isMain())
	args.syncPlayers = Logic.emptyOr(args.syncPlayers, true)

	-- fixed setting
	args.resolveRedirect = true

	return AwardPrizePool(args)
		:create()
		:setLpdbInjector(CustomLpdbInjector())
		:build(IS_AWARD)
end

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@param opponent BasePlacementOpponent
---@return placement
function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.extradata.mod = Variables.varDefault('tournament_mod')

	lpdbData.objectName = CustomPrizePool._overwriteObjectName(lpdbData)

	return lpdbData
end

---@param lpdbData placement
---@return string
function CustomPrizePool._overwriteObjectName(lpdbData)
	if lpdbData.opponenttype == Opponent.team then
		local prizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0
		return lpdbData.objectName .. '_' .. prizePoolIndex
	end

	return lpdbData.objectName
end

return CustomPrizePool
