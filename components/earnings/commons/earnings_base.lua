---
-- @Liquipedia
-- wiki=commons
-- page=Module:Earnings/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Earnings = {}
local MathUtils = require('Module:Math')
local String = require('Module:StringUtils')
local Logic = require('Module:Logic')
local Class = require('Module:Class')

local _DEFAULT_DATE = '1970-01-01 00:00:00'
local _FIRST_DAY_OF_YEAR = '-01-01'
local _LAST_DAY_OF_YEAR = '-12-31'

---
-- Entry point for players and individuals
-- @player - the player/individual for whom the earnings shall be calculated
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
-- @noRedirect - (optional) player redirects get not resolved before query
-- @prefix - (optional) the prefix under which the players are stored in the placements
-- @playerNumber - (optional) the number for how many params the query should look in LPDB
-- @startYear - (optional) query yearly earning starting with that year and return the values in a lua table
function Earnings.calculateForPlayer(args)
	args = args or {}
	local player = args.player

	if String.isEmpty(player) then
		return 0
	end
	if not Logic.readBool(args.noRedirect) then
		player = mw.ext.TeamLiquidIntegration.resolve_redirect(player)
	end

	local prefix = args.prefix or 'p'

	local playerNumber = tonumber(args.playerNumber) or 10
	if playerNumber <=0 then
		error('"playerNumber" has to be >= 1')
	end

	local playerConditions = '([[participant::' .. player .. ']]'
	for playerIndex = 1, playerNumber do
		playerConditions = playerConditions .. ' OR [[players_' .. prefix .. playerIndex .. '::' .. player .. ']]'
	end
	playerConditions = playerConditions .. ')'

	return Earnings._calculate(playerConditions, args.year, args.mode, args.startYear, Earnings.divisionFactor)
end

---
-- Entry point for teams
-- @team - the team for which the earnings shall be calculated
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
-- @noRedirect - (optional) player redirects get not resolved before query
-- @startYear - (optional) query yearly earning starting with that year and return the values in a lua table
function Earnings.calculateForTeam(args)
	args = args or {}
	local team = args.team

	if String.isEmpty(team) then
		return 0
	end
	if not Logic.readBool(args.noRedirect) then
		team = mw.ext.TeamLiquidIntegration.resolve_redirect(team)
	end

	local teamConditions = '([[participant::' .. team .. ']] OR [[extradata_participantteam::' .. team .. ']])'

	return Earnings._calculate(teamConditions, args.year, args.mode, args.startYear, Earnings._divisionFactorOne)
end

---
-- Calculates earnings for this participant in a certain mode
-- @participantCondition - the condition to find the player/team
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
function Earnings._calculate(conditions, year, mode, startYear, divisionFactor)
	conditions = Earnings._buildConditions(conditions, year, mode, startYear)

	if String.isNotEmpty(startYear) then
		return Earnings._calculatePerYear(conditions, divisionFactor)
	end

	local lpdbQueryData = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions,
		query = 'sum::prizemoney, mode',
		groupby = 'mode asc'
	})

	local totalEarnings = 0

	for _, item in ipairs(lpdbQueryData) do
		if item['sum_prizemoney'] ~= nil then
			local prizeMoney = item['sum_prizemoney']
			totalEarnings = totalEarnings + (prizeMoney / divisionFactor(item['mode']))
		end
	end

	return MathUtils._round(totalEarnings, 2)
end

function Earnings._calculatePerYear(conditions, divisionFactor)
	local totalEarningsOfYear = {}
	local totalEarnings = {}
	totalEarnings.total = 0

	local offset = 0
	local count = 5000
	while count == 5000 do
		local lpdbQueryData = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = conditions,
			query = 'prizemoney, mode, date',
			limit = 5000,
			offset = offset
		})
		for _, item in pairs(lpdbQueryData) do
			local prizeMoney = tonumber(item.prizemoney) or 0
			local year = string.sub(item.date, 1, 4)
			prizeMoney = prizeMoney / divisionFactor(item['mode'])
			totalEarningsOfYear[year] = (totalEarningsOfYear[year] or 0) + prizeMoney
		end
		count = #lpdbQueryData
		offset = offset + 5000
	end

	for year, earningsOfYear in pairs(totalEarningsOfYear) do
		totalEarnings[tonumber(year)] = MathUtils._round(earningsOfYear, 2)
		totalEarnings.total = totalEarnings.total + earningsOfYear
	end
	totalEarnings.total = MathUtils._round(totalEarnings.total, 2)

	return totalEarnings
end

function Earnings._buildConditions(conditions, year, mode, startYear)
	conditions = '[[date::!' .. _DEFAULT_DATE .. ']] AND [[prizemoney::>0]] AND ' .. conditions
	if String.isNotEmpty(startYear) then
		conditions = conditions .. ' AND (' ..
			'[[date::>' .. startYear .. _FIRST_DAY_OF_YEAR .. ']] ' ..
			'OR [[date::' .. startYear .. _FIRST_DAY_OF_YEAR .. ']])'
	elseif String.isNotEmpty(year) then
		conditions = conditions .. ' AND (' ..
			'[[date::>' .. year .. _FIRST_DAY_OF_YEAR .. ']] ' ..
			'OR [[date::' .. year .. _FIRST_DAY_OF_YEAR .. ']]' ..
			') AND (' ..
			'[[date::<' .. year .. _LAST_DAY_OF_YEAR .. ']] ' ..
			'OR [[date::' .. year .. _LAST_DAY_OF_YEAR .. ']])'
	end

	if String.isNotEmpty(mode) then
		conditions = conditions .. ' AND [[mode::' .. mode .. ']]'
	end

	return conditions
end

-- overwritable in /Custom
local _DEFAULT_NUMBER_OF_PLAYERS_IN_TEAM = 5

-- overwritable in /Custom
function Earnings.divisionFactor(mode)
	if mode == '4v4' then
		return 4
	elseif mode == '3v3' then
		return 3
	elseif mode == '2v2' then
		return 2
	elseif mode == '1v1' or mode == 'individual' then
		return 1
	end

	return _DEFAULT_NUMBER_OF_PLAYERS_IN_TEAM
end

function Earnings._divisionFactorOne()
	return 1
end

return Class.export(Earnings)
