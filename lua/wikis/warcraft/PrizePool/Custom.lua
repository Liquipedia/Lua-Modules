---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')
local Weight = Lua.import('Module:Weight')

local PrizePool = Lua.import('Module:PrizePool')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')

local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local AUTOMATION_START_DATE = '2023-10-16'

-- Template entry point
---@param frame Frame
---@return Html
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)

	-- adjust import settings params
	args.allGroupsUseWdl = Logic.emptyOr(args.allGroupsUseWdl, true)
	args.groupScoreDelimiter = '-'
	-- match2 implemented as of 2023-10-15
	args.import = Logic.nilOr(args.import, DateExt.getContextualDateOrNow() >= AUTOMATION_START_DATE)

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

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@param opponent BasePlacementOpponent
---@return placement
function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.extradata = Table.mergeInto(lpdbData.extradata, {
		seriesnumber = CustomPrizePool._seriesNumber()
	})

	lpdbData.players = Table.copy(lpdbData.opponentplayers or {})

	lpdbData.weight = Weight.calc(
		lpdbData.individualprizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		lpdbData.placement,
		Variables.varDefault('tournament_liquipediatiertype'),
		lpdbData.type
	)

	return lpdbData
end

---@return string
function CustomPrizePool._seriesNumber()
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	return seriesNumber and string.format('%05d', seriesNumber) or ''
end

return CustomPrizePool
