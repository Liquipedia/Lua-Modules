---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Weight = require('Module:Weight')

local PrizePool = Lua.import('Module:PrizePool', {requireDevIfEnabled = true})

local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})

local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local PRIZE_TYPE_POINTS = 'POINTS'

-- Template entry point
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)

	-- adjust import settings params
	args.allGroupsUseWdl = Logic.emptyOr(args.allGroupsUseWdl, true)
	args.groupScoreDelimiter = '-'
	-- currently no match2 implemented; enable once it is with the date it goes live as switch date
	args.import = Logic.emptyOr(args.import, false)

	local prizePool = PrizePool(args)

	-- adjust defaults
	prizePool:setConfigDefault('prizeSummary', false)
	prizePool:setConfigDefault('exchangeInfo', false)
	prizePool:setConfigDefault('storeLpdb', Namespace.isMain())
	prizePool:setConfigDefault('syncPlayers', true)
	prizePool:setConfigDefault('resolveRedirect', true)

	prizePool:create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	return prizePool:build()
end

function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.extradata = Table.mergeInto(lpdbData.extradata, {
		 -- to be removed once poinst storage is standardized
		points = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 1),
		points2 = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 2),
		seriesnumber = CustomPrizePool._seriesNumber()
	})

	lpdbData.players = lpdbData.opponentplayers

	lpdbData.weight = Weight.calc(
		lpdbData.individualprizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		lpdbData.placement,
		Variables.varDefault('tournament_liquipediatiertype'),
		lpdbData.type
	)

	return lpdbData
end

function CustomPrizePool._seriesNumber()
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	return seriesNumber and string.format('%05d', seriesNumber) or ''
end

return CustomPrizePool
