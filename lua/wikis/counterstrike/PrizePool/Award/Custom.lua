---
-- @Liquipedia
-- page=Module:PrizePool/Award/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Variables = require('Module:Variables')

local AwardPrizePool = Lua.import('Module:PrizePool/Award')
local LpdbInjector = Lua.import('Module:Lpdb/Injector')

local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomAwardPrizePool = {}

local IS_AWARD = true

local HEADER_DATA = {}

-- Template entry point
---@param frame Frame
---@return Html
function CustomAwardPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	args.localcurrency = args.localcurrency or Variables.varDefault('tournament_currency')

	local awardsPrizePool = AwardPrizePool(args)

	awardsPrizePool:setConfigDefault('prizeSummary', false)
	awardsPrizePool:setConfigDefault('syncPlayers', true)
	awardsPrizePool:setConfigDefault('autoExchange', false)
	awardsPrizePool:setConfigDefault('exchangeInfo', false)

	awardsPrizePool:create()

	awardsPrizePool:setLpdbInjector(CustomLpdbInjector())

	if args['smw mute'] or not Namespace.isMain() or Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then
		awardsPrizePool:setConfig('storeLpdb', false)
	end

	HEADER_DATA.tournamentName = args['tournament name']
	HEADER_DATA.resultName = args['custom-name']

	return awardsPrizePool:build(IS_AWARD)
end

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@param opponent BasePlacementOpponent
---@return placement
function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.extradata.scorename = HEADER_DATA.resultName
	lpdbData.tournament = HEADER_DATA.tournamentName or lpdbData.tournament

	return lpdbData
end

return CustomAwardPrizePool
