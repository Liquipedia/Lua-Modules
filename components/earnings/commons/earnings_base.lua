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
local _MAX_QUERY_LIMIT = 5000

-- customizable in /Custom
Earnings.defaultNumberOfPlayersInTeam = 5

-- customizable in /Custom
Earnings.defaultNumberOfStoredPlayersPerMatch = 10

---
-- Entry point for players and individuals
-- @player - the player/individual for whom the earnings shall be calculated
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
-- @noRedirect - (optional) player redirects get not resolved before query
-- @prefix - (optional) the prefix under which the players are stored in the placements
-- @playerPositionLimit - (optional) the number for how many params the query should look in LPDB
-- @perYear - (optional) query all earnings per year and return the values in a lua table
function Earnings.calculateForPlayer(args)
	args = args or {}
	local player = args.player

	if String.isEmpty(player) then
		return 0
	end
	if not Logic.readBool(args.noRedirect) then
		player = mw.ext.TeamLiquidIntegration.resolve_redirect(player)
	else
		player = player:gsub('_', ' ')
	end

	-- since TeamCards on some wikis store players with underscores and some with spaces
	-- we need to check for both options
	local playerAsPageName = player:gsub(' ', '_')

	local prefix = args.prefix or 'p'

	local playerPositionLimit = tonumber(args.playerPositionLimit) or Earnings.defaultNumberOfStoredPlayersPerMatch
	if playerPositionLimit <= 0 then
		error('"playerPositionLimit" has to be >= 1')
	end

	local playerConditions = '([[participant::' .. player .. ']] OR [[participant::' .. playerAsPageName .. ']]'
	for playerIndex = 1, playerPositionLimit do
		playerConditions = playerConditions .. ' OR [[players_' .. prefix .. playerIndex .. '::' .. player .. ']]'
		playerConditions = playerConditions .. ' OR [[players_' .. prefix .. playerIndex .. '::' .. playerAsPageName .. ']]'
	end
	playerConditions = playerConditions .. ')'

	return Earnings.calculate(playerConditions, args.year, args.mode, args.perYear, Earnings.divisionFactorPlayer)
end

---
-- Entry point for teams
-- @team - the team for which the earnings shall be calculated
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
-- @noRedirect - (optional) player redirects get not resolved before query
-- @perYear - (optional) query all earnings per year and return the values in a lua table
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

	return Earnings.calculate(teamConditions, args.year, args.mode, args.perYear, Earnings.divisionFactorTeam)
end

---
-- Calculates earnings for this participant in a certain mode
-- @participantCondition - the condition to find the player/team
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
-- @perYear - (optional) query all earnings per year and return the values in a lua table
-- @divisionFactor - divisionFactor function
---
-- customizable in case query has to be changed
-- (e.g. SC2 due to not having a fixed number of players per team)
function Earnings.calculate(conditions, year, mode, perYear, divisionFactor)
	conditions = Earnings._buildConditions(conditions, year, mode)

	if Logic.readBool(perYear) then
		return Earnings.calculatePerYear(conditions, divisionFactor)
	end

	local lpdbQueryData = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions,
		query = 'mode, sum::' .. Earnings._divisionFactorSwitch(divisionFactor),
		groupby = 'mode asc'
	})

	local totalEarnings = 0

	for _, item in ipairs(lpdbQueryData) do
		if divisionFactor == nil then
			totalEarnings = totalEarnings + item['sum_individualprizemoney']
		elseif item['sum_prizemoney'] ~= nil then
			local prizeMoney = item['sum_prizemoney']
			totalEarnings = totalEarnings + (prizeMoney / divisionFactor(item['mode']))
		end
	end

	return MathUtils._round(totalEarnings)
end

---
-- customizable in case query has to be changed
-- (e.g. SC2 due to not having a fixed number of players per team)
function Earnings.calculatePerYear(conditions, divisionFactor)
	local totalEarningsByYear = {}
	local earningsData = {}
	local totalEarnings = 0

	local offset = 0
	local count = _MAX_QUERY_LIMIT
	while count == _MAX_QUERY_LIMIT do
		local lpdbQueryData = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = conditions,
			query = 'mode, date, ' .. Earnings._divisionFactorSwitch(divisionFactor),
			limit = _MAX_QUERY_LIMIT,
			offset = offset
		})
		for _, item in pairs(lpdbQueryData) do
			local year = string.sub(item.date, 1, 4)
			local prizeMoney
			if divisionFactor == nil then
				prizeMoney = tonumber(item.individualprizemoney) or 0
			else
				prizeMoney = tonumber(item.prizemoney) or 0
				prizeMoney = prizeMoney / divisionFactor(item['mode'])
			end
			earningsData[year] = (earningsData[year] or 0) + prizeMoney
		end
		count = #lpdbQueryData
		offset = offset + _MAX_QUERY_LIMIT
	end

	for year, earningsOfYear in pairs(earningsData) do
		totalEarningsByYear[tonumber(year)] = MathUtils._round(earningsOfYear)
		totalEarnings = totalEarnings + earningsOfYear
	end

	totalEarnings = MathUtils._round(totalEarnings)

	return totalEarnings, totalEarningsByYear
end

function Earnings._buildConditions(conditions, year, mode)
	conditions = '[[date::!' .. _DEFAULT_DATE .. ']] AND [[prizemoney::>0]] AND ' .. conditions
	if String.isNotEmpty(year) then
		conditions = conditions .. ' AND ([[date_year::'.. year ..']])'
	end

	if String.isNotEmpty(mode) then
		conditions = conditions .. ' AND [[mode::' .. mode .. ']]'
	end

	return conditions
end

---
-- customizable in case it has to be changed
-- (e.g. SC2 due to not having a fixed number of players per team)
function Earnings.divisionFactorPlayer(mode)
	if mode == '4v4' then
		return 4
	elseif mode == '3v3' then
		return 3
	elseif mode == '2v2' then
		return 2
	elseif mode == '1v1' or mode == 'individual' then
		return 1
	end

	return Earnings.defaultNumberOfPlayersInTeam
end

-- customizable in /Custom
function Earnings.divisionFactorTeam(mode)
	return 1
end

function Earnings._divisionFactorSwitch(divisionFactor)
	return divisionFactor == nil and 'individualprizemoney' or 'prizemoney'
end

return Class.export(Earnings)
