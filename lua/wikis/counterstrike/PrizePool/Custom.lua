---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Json = Lua.import('Module:Json')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Namespace = Lua.import('Module:Namespace')
local Tier = Lua.import('Module:Tier/Utils')
local Variables = Lua.import('Module:Variables')

local PrizePool = Lua.import('Module:PrizePool')
local Opponent = Lua.import('Module:Opponent')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local TIER_VALUE = {10, 6, 4, 2}
local TYPE_MODIFIER = {offline = 1, ['offline/online'] = 0.75, ['online/offline'] = 0.75, default = 0.65}

local HEADER_DATA = {}

-- Template entry point
---@param frame Frame
---@return Widget
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)

	local prizePool = PrizePool(args)

	-- Turn off automations
	prizePool:setConfigDefault('prizeSummary', false)
	prizePool:setConfigDefault('autoExchange', false)
	prizePool:setConfigDefault('exchangeInfo', false)

	prizePool:create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	if not Namespace.isMain() or Lpdb.isStorageDisabled() then
		prizePool:setConfig('storeLpdb', false)
	end

	HEADER_DATA.tournamentName = args['tournamentName']
	HEADER_DATA.resultName = args['resultName']

	Variables.varDefine('prizepool_resultName', HEADER_DATA.resultName)

	if Logic.readBool(args.qualifier) then
		local extradata = Json.parseIfTable(Variables.varDefault('tournament_extradata')) or {}
		extradata.qualifier = '1' -- This is the new field, rest are just what Infobox League sets
		mw.ext.LiquipediaDB.lpdb_tournament('tournament_'.. Variables.varDefault('tournament_name', ''), {
			extradata = Json.stringify(extradata)
		})
	end

	return prizePool:build()
end

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@param opponent BasePlacementOpponent
---@return placement
function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.publishertier = Variables.varDefault('tournament_valve_tier', '')
	if not placement.specialStatuses.DQ.active(placement.args) then
		lpdbData.weight = CustomPrizePool.calculateWeight(
			lpdbData.prizemoney,
			Variables.varDefault('tournament_liquipediatier'),
			placement.placeStart,
			Variables.varDefault('tournament_type', ''),
			HighlightConditions.tournament(lpdbData, {onlyHighlightOnValue = 'Major Championship'})
		)
	end

	Variables.varDefine('prizepoints_' .. lpdbData.participant, lpdbData.extradata.prizepoints)
	Variables.varDefine('prizepoints2_' .. lpdbData.participant, lpdbData.extradata.prizepoints2)
	Variables.varDefine('enddate_' .. lpdbData.participant, lpdbData.date)
	Variables.varDefine('placement_' .. lpdbData.participant, lpdbData.placement)

	if (lpdbData.groupscore or ''):len() > 10 then
		lpdbData.extradata.groupscore = lpdbData.groupscore
		Variables.varDefine('groupscore_' .. lpdbData.participant, lpdbData.groupscore)
		lpdbData.groupscore = 'custom'
	end

	if opponent.additionalData.LASTVS and opponent.additionalData.LASTVS.type == Opponent.solo then
		lpdbData.extradata.lastvsflag = opponent.additionalData.LASTVS.players[1].flag
	end

	lpdbData.extradata.scorename = HEADER_DATA.resultName
	lpdbData.tournament = HEADER_DATA.tournamentName or lpdbData.tournament

	if placement.args.forceQualified ~= nil then
		lpdbData.qualified = Logic.readBool(placement.args.forceQualified) and 1 or 0
	end

	if lpdbData.opponenttype == Opponent.solo then
		lpdbData.extradata.participantteam = lpdbData.players.p1team
	end

	return lpdbData
end

---Calculates sorting weight based on a number of inputs
---@param prizeMoney number
---@param tier string?
---@param place integer
---@param type string
---@param isHighlighted boolean
---@return integer
function CustomPrizePool.calculateWeight(prizeMoney, tier, place, type, isHighlighted)
	if Logic.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[Tier.toNumber(tier)] or 1

	return tierValue * math.max(prizeMoney, 0.1) * (isHighlighted and 2 or 1) *
		(TYPE_MODIFIER[type:lower()] or TYPE_MODIFIER.default) / (prizeMoney > 0 and place or 1)
end

return CustomPrizePool
