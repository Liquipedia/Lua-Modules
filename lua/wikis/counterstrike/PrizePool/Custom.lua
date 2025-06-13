---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Json = require('Module:Json')
local Namespace = require('Module:Namespace')
local Variables = require('Module:Variables')

local PrizePool = Lua.import('Module:PrizePool')
local Opponent = Lua.import('Module:Opponent')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local TIER_VALUE = {10, 6, 4, 2, 1, 2}
local TYPE_MODIFIER = {offline = 1, ['offline/online'] = 0.75, ['online/offline'] = 0.75, default = 0.65}

local HEADER_DATA = {}

-- Template entry point
---@param frame Frame
---@return Html
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)

	local prizePool = PrizePool(args)

	-- Turn off automations
	prizePool:setConfigDefault('prizeSummary', false)
	prizePool:setConfigDefault('autoExchange', false)
	prizePool:setConfigDefault('exchangeInfo', false)

	prizePool:create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	if args['smw mute'] or not Namespace.isMain() or Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then
		prizePool:setConfig('storeLpdb', false)
	end

	HEADER_DATA.tournamentName = args['tournamentName']
	HEADER_DATA.resultName = args['resultName']

	Variables.varDefine('prizepool_resultName', HEADER_DATA.resultName)

	if Logic.readBool(args.qualifier) then
		local extradata = Json.parseIfTable(Variables.varDefault('tournament_extradata')) or {}
		extradata.qualifier = '1' -- This is the new field, rest are just what Infobox League sets
		mw.ext.LiquipediaDB.lpdb_tournament('tournament_'.. Variables.varDefault('tournament_name', ''), {
			extradata = mw.ext.LiquipediaDB.lpdb_create_json(extradata)
		})
	end

	return prizePool:build()
end

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@param opponent BasePlacementOpponent
---@return placement
function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	if not placement.specialStatuses.DQ.active(placement.args) then
		lpdbData.weight = CustomPrizePool.calculateWeight(
			lpdbData.prizemoney,
			Variables.varDefault('tournament_liquipediatier'),
			placement.placeStart,
			Variables.varDefault('tournament_type', '')
		)
	end

	Variables.varDefine('prizepoints_' .. lpdbData.participant, lpdbData.extradata.prizepoints)
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
	lpdbData.publishertier = Variables.varDefault('tournament_valve_tier', '')

	if placement.args.forceQualified ~= nil then
		lpdbData.qualified = Logic.readBool(placement.args.forceQualified) and 1 or 0
	else
		lpdbData.qualified = placement:getPrizeRewardForOpponent(opponent, 'QUALIFIES1') and 1 or 0
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
---@return integer
function CustomPrizePool.calculateWeight(prizeMoney, tier, place, type)
	if Logic.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier)] or 1

	return tierValue * math.max(prizeMoney, 0.1) * (TYPE_MODIFIER[type:lower()] or TYPE_MODIFIER.default) /
		(prizeMoney > 0 and place or 1)
end

return CustomPrizePool
