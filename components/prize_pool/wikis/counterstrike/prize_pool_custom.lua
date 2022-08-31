---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Opponent = require('Module:Opponent')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local PrizePool = Lua.import('Module:PrizePool', {requireDevIfEnabled = true})

local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local TIER_VALUE = {10, 6, 4, 2}
local TYPE_MODIFIER = {offline = 1, ['offline/online'] = 0.75, ['online/offline'] = 0.75, default = 0.65}

local HEADER_DATA = {}

-- Template entry point
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)

	-- Turn off automations
	args.prizesummary = false
	args.autousd = false
	args.exchangeInfo = false

	local prizePool = PrizePool(args):create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	if args['smw mute'] or not Namespace.isMain() or Logic.readBool(Variables.varDefault('disable_SMW_storage')) then
		prizePool:setConfig('storeSmw', false)
		prizePool:setConfig('storeLpdb', false)
	end

	HEADER_DATA.tournamentName = args['tournament name']
	HEADER_DATA.resultName = args['custom-name']

	if Logic.readBool(args.qualifier) then
		mw.ext.LiquipediaDB.lpdb_tournament('tournament_'.. Variables.varDefault('tournament_name', ''), {
			extradata = mw.ext.LiquipediaDB.lpdb_create_json{
				prizepoollocal = Variables.varDefault('prizepoollocal', ''),
				startdate_raw = Variables.varDefault('raw_sdate', ''),
				enddate_raw = Variables.varDefault('raw_edate', ''),
				qualifier = '1', -- This is the new field, rest are just what Infobox League sets
			}
		})
	end

	return prizePool:build()
end

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

	if (lpdbData.wdl or ''):len() > 10 then
		lpdbData.extradata.groupscore = lpdbData.wdl
		Variables.varDefine('groupscore_' .. lpdbData.participant, lpdbData.wdl)
		lpdbData.wdl = 'custom'
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
		lpdbData.qualified = placement:getPrizeRewardForOpponent(opponent, "QUALIFIES1") and 1 or 0
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
	if String.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier)] or 1

	return tierValue * math.max(prizeMoney, 0.1) * (TYPE_MODIFIER[type:lower()] or TYPE_MODIFIER.default) / place
end

return CustomPrizePool
