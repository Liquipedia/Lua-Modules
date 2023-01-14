---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local PrizePool = Lua.import('Module:PrizePool', {requireDevIfEnabled = true})

local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local TBD = 'TBD'

-- Brawlstars is still in the process of tier conversion
-- hence "Monthly" is needed here until that is done
local TIER_VALUE = {16, 8, 4, 2, Monthly = 2}

local TYPE_MODIFIER = {offline = 1, ['offline/online'] = 0.75, ['online/offline'] = 0.75, default = 0.65}

local HEADER_DATA = {}

-- Template entry point
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)

	args.allGroupsUseWdl = true
	args.groupScoreDelimiter = '-'

	local prizePool = PrizePool(args):create()

	HEADER_DATA.tournamentName = args['tournament name']

	prizePool:setLpdbInjector(CustomLpdbInjector())

	if args['smw mute'] or not Namespace.isMain() or Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then
		prizePool:setConfig('storeSmw', false)
		prizePool:setConfig('storeLpdb', false)
	end

	return prizePool:build()
end

function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.weight = CustomPrizePool.calculateWeight(
		lpdbData.prizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		placement.placeStart,
		Variables.varDefault('tournament_type')
	)

	lpdbData.tournament = HEADER_DATA.tournamentName or lpdbData.tournament
	lpdbData.qualified = placement:getPrizeRewardForOpponent(opponent, 'QUALIFIES1') and 1 or 0

	Variables.varDefine(lpdbData.participant:lower() .. '_prizepoints', lpdbData.extradata.prizepoints)

	if lpdbData.opponentname ~= TBD then
		Variables.varDefine('qualified_' .. lpdbData.opponentname, lpdbData.qualified)
	end

	-- legacy stuff still used by other modules
	lpdbData.extradata = Table.merge(lpdbData.extradata or {}, {
		qualified = lpdbData.qualified,
		series = Variables.varDefault('tournament_series'),
	})

	return lpdbData
end

---Calculates sorting weight based on a number of inputs
---@param prizeMoney number
---@param tier string?
---@param place integer
---@param type string
---@return integer
function CustomPrizePool.calculateWeight(prizeMoney, tier, place, type)
	if String.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier)] or 1

	return tierValue * math.max(prizeMoney, 0.1) * (TYPE_MODIFIER[type:lower()] or TYPE_MODIFIER.default) / place
end

return CustomPrizePool
