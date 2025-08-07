---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local PrizePool = Lua.import('Module:PrizePool')
local PrizePoolPlacement = Lua.import('Module:PrizePool/Placement')

PrizePoolPlacement.specialStatuses = Table.merge(PrizePoolPlacement.specialStatuses, {
	DNS = {
		active = function (args)
			return Logic.readBool(args.dns)
		end,
		display = function ()
			return Abbreviation.make{text = 'DNS', title = 'Did not start'}
		end,
		lpdb = 'DNS',
	},
	DNPQ = {
		active = function (args)
			return Logic.readBool(args.dnpq)
		end,
		display = function ()
			return Abbreviation.make{text = 'DNPQ', title = 'Did not pre-qualify'}
		end,
		lpdb = 'DNPQ',
	},
	DNQ = {
		active = function (args)
			return Logic.readBool(args.dnq)
		end,
		display = function ()
			return Abbreviation.make{text = 'DNQ', title = 'Did not qualify'}
		end,
		lpdb = 'DNQ',
	},
	NC = {
		active = function (args)
			return Logic.readBool(args.nc)
		end,
		display = function ()
			return Abbreviation.make{text = 'NC', title = 'Not classified'}
		end,
		lpdb = 'NC',
	},
})

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local TIER_VALUE = {8, 4, 2}

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
	lpdbData.weight = CustomPrizePool.calculateWeight(
		lpdbData.prizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		placement.placeStart
	)

	local team = lpdbData.participant or ''
	local lpdbPrefix = Variables.varDefault('lpdb_prefix') or ''

	Variables.varDefine('enddate_' .. lpdbPrefix .. team, lpdbData.date)
	Variables.varDefine('ranking' .. lpdbPrefix .. '_' .. (team:lower()) .. '_pointprize', lpdbData.extradata.prizepoints)
	Variables.varDefine('ranking' .. lpdbPrefix .. '_' .. (team:lower()) .. '_pointprize2',
		lpdbData.extradata.prizepoints2)

	return lpdbData
end

---@param prizeMoney number
---@param tier string?
---@param place integer
---@return integer
function CustomPrizePool.calculateWeight(prizeMoney, tier, place)
	if Logic.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier)] or 1

	return tierValue * math.max(prizeMoney, 1) / place
end

return CustomPrizePool
