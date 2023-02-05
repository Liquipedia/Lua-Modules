---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Weight = require('Module:Weight')

local PrizePool = Lua.import('Module:PrizePool', {requireDevIfEnabled = true})

local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})
local SmwInjector = Lua.import('Module:Smw/Injector', {requireDevIfEnabled = true})

local Opponent = require('Module:OpponentLibraries').Opponent

local CustomLpdbInjector = Class.new(LpdbInjector)
local CustomSmwInjector = Class.new(SmwInjector)

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
	prizePool:setConfigDefault('storeSmw', Namespace.isMain())
	prizePool:setConfigDefault('storeLpdb', Namespace.isMain())
	prizePool:setConfigDefault('syncPlayers', true)
	prizePool:setConfigDefault('resolveRedirect', true)

	prizePool:create()

	prizePool:setLpdbInjector(CustomLpdbInjector())
	prizePool:setSmwInjector(CustomSmwInjector())

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

function CustomSmwInjector:adjust(smwEntry, lpdbEntry)
	local extradata = Json.parseIfString(lpdbEntry.extradata) or {}
	-- fix lastvs opponent stuff
	if lpdbEntry.lastvs then
		local lastVs = extradata.vsOpponent or {}
		if lastVs.type == Opponent.solo then
			smwEntry['has last opponent page'] = lastVs.players[1].pageName
			smwEntry['has last opponent'] = lastVs.players[1].displayName
		elseif Opponent.typeIsParty(lastVs.type) then
			smwEntry['has last opponent'] = nil
			for playerIndex, player in ipairs(lastVs.players) do
				smwEntry['has last opponent ' .. playerIndex .. ' page'] = player.pageName
				smwEntry['has last opponent ' .. playerIndex] = player.displayName
			end
		elseif lastVs.type == Opponent.team then
			smwEntry['has last opponent'] = lastVs.name
		end
	end

	return CustomPrizePool._opponentSmwProps(smwEntry, lpdbEntry)
end

function CustomPrizePool._opponentSmwProps(smwEntry, lpdbData)
	if lpdbData.opponenttype == Opponent.team or lpdbData.opponenttype == Opponent.literal then
		return smwEntry
	elseif lpdbData.opponenttype == Opponent.solo then
		local playersData = Json.parseIfString(lpdbData.players) or {}
		smwEntry['has race'] = playersData.p1race
		return smwEntry
	end

	local playersData = Json.parseIfString(lpdbData.players) or {}
	local isArchon = playersData.isArchon
	if isArchon then
		smwEntry['is Archon'] = 'true'
	end

	for prefix, playerPage, playerIndex in Table.iter.pairsByPrefix(playersData, 'p') do
		-- skip first as it is already processed and syntax is different
		if playerIndex ~= 1 then
			smwEntry['has player ' .. playerIndex] = playersData[prefix .. 'dn']
			smwEntry['has player ' .. playerIndex .. ' page'] = playerPage
			smwEntry['has player ' .. playerIndex .. ' flag'] = playersData[prefix .. 'flag']
			smwEntry['has player ' .. playerIndex .. ' team'] = playersData[prefix .. 'team']
			smwEntry['has player ' .. playerIndex .. ' race'] = (not isArchon) and playersData[prefix .. 'race'] or nil
		end
	end

	return smwEntry
end

function CustomPrizePool._seriesNumber()
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	return seriesNumber and string.format('%05d', seriesNumber) or ''
end

return CustomPrizePool
