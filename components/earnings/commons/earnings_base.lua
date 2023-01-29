---
-- @Liquipedia
-- wiki=commons
-- page=Module:Earnings/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Earnings = {}
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local MathUtils = require('Module:Math')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')

local DEFAULT_DATE = '1970-01-01 00:00:00'

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
		.. ' OR [[participantlink::' .. player .. ']] OR [[participantlink::' .. playerAsPageName .. ']]'
	for playerIndex = 1, playerPositionLimit do
		playerConditions = playerConditions .. ' OR [[players_' .. prefix .. playerIndex .. '::' .. player .. ']]'
		playerConditions = playerConditions .. ' OR [[players_' .. prefix .. playerIndex .. '::' .. playerAsPageName .. ']]'
	end
	playerConditions = playerConditions .. ')'

	return Earnings.calculate(playerConditions, args.year, args.mode, args.perYear, Earnings.divisionFactorPlayer, true)
end

---
-- Entry point for teams
-- @team - the team (either pageName or team template) for which the earnings shall be calculated
-- @teams - list of teams
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
-- @queryHistorical - (optional) fetch the pageNames from the subTemplates of the entered team template
-- @noRedirect - (optional) team redirects get not resolved before query (only available if queryHistorical is not used)
-- @perYear - (optional) query all earnings per year and return the values in a lua table
function Earnings.calculateForTeam(args)
	args = args or {}
	local teams = args.teams or {}
	table.insert(teams, args.team)

	if Table.isEmpty(teams) then
		return 0
	end

	local queryTeams = {}
	if Logic.readBool(args.queryHistorical) then
		for _, team in pairs(teams) do
			local historicalNames = Team.queryHistoricalNames(team)

			if not historicalNames then
				return 0
			end

			for _, historicalTeam in pairs(historicalNames) do
				table.insert(queryTeams, historicalTeam)
			end
		end
	elseif not Logic.readBool(args.noRedirect) then
		for index, team in pairs(teams) do
			queryTeams[index] = mw.ext.TeamLiquidIntegration.resolve_redirect(team)
		end
	else
		queryTeams = teams
	end

	local formatParicipant = function(lpdbField, participants)
		return '([[' .. lpdbField .. '::' ..
			table.concat(participants, ']] OR [[' .. lpdbField .. '::')
			.. ']])'
	end
	local teamConditions = '(' .. formatParicipant('participant', queryTeams) .. ' OR '
		.. formatParicipant('extradata_participantteam', queryTeams) .. ' OR '
		.. formatParicipant('participantlink', queryTeams) ..')'
	return Earnings.calculate(teamConditions, args.year, args.mode, args.perYear, Earnings.divisionFactorTeam, false)
end

---Calculates money earned based on given condition parameters
---@param conditions string the condition to find the player/team
---@param year number|string|nil the year to calculate earnings for
---@param mode string? the mode to calculate earnings for
---@param perYear boolean|string|nil query all earnings per year and return the values in a lua table
---@param divisionFactor? fun(mode: string):number divisionFactor function
---@param indivudalEarningsAllowed boolean? can use individual prizemoney field if it exists
function Earnings.calculate(conditions, year, mode, perYear, divisionFactor, indivudalEarningsAllowed)
	conditions = Earnings._buildConditions(conditions, year, mode)

	if Logic.readBool(perYear) then
		return Earnings.calculatePerYear(conditions, divisionFactor, indivudalEarningsAllowed)
	end

	if indivudalEarningsAllowed then
		local individualEarnings = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = conditions,
			query = 'sum::individualprizemoney',
			groupby = 'namespace asc'
		})[1]

		if individualEarnings and individualEarnings.sum_individualprizemoney > 0 then
			return MathUtils._round(individualEarnings.sum_individualprizemoney)
		end
	end

	local lpdbQueryData = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions,
		query = 'mode, sum::prizemoney',
		groupby = 'mode asc'
	})

	local totalEarnings = 0
	for _, item in ipairs(lpdbQueryData) do
		totalEarnings = totalEarnings + Earnings._applyDivisionFactor(item.sum_prizemoney, divisionFactor, item.mode)
	end

	return MathUtils._round(totalEarnings)
end

---
-- customizable in case query has to be changed
-- (e.g. SC2 due to not having a fixed number of players per team)
function Earnings.calculatePerYear(conditions, divisionFactor, indivudalEarningsAllowed)
	local totalEarningsByYear = {}
	local earningsData = {}
	local totalEarnings = 0

	Lpdb.executeMassQuery('placement', {
		conditions = conditions,
		query = 'mode, date, individualprizemoney, prizemoney',
	}, function (item)
		local year = string.sub(item.date, 1, 4)
		local prizeMoney = indivudalEarningsAllowed and tonumber(item.individualprizemoney)
			or Earnings._applyDivisionFactor(tonumber(item.prizemoney), divisionFactor, item.mode) or 0
		earningsData[year] = (earningsData[year] or 0) + prizeMoney
	end)

	for year, earningsOfYear in pairs(earningsData) do
		totalEarningsByYear[tonumber(year)] = MathUtils._round(earningsOfYear)
		totalEarnings = totalEarnings + earningsOfYear
	end

	totalEarnings = MathUtils._round(totalEarnings)

	return totalEarnings, totalEarningsByYear
end

function Earnings._buildConditions(conditions, year, mode)
	conditions = '[[date::!' .. DEFAULT_DATE .. ']] AND [[prizemoney::>0]] AND ' .. conditions
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
	elseif mode == '1v1' or mode == 'individual' or mode == 'award_individual' then
		return 1
	end

	return Earnings.defaultNumberOfPlayersInTeam
end

-- customizable in /Custom
function Earnings.divisionFactorTeam(mode)
	return 1
end

function Earnings._applyDivisionFactor(prizeMoney, divisionFactor, mode)
	if divisionFactor then
		return prizeMoney / divisionFactor(mode)
	end
	return prizeMoney
end

return Class.export(Earnings)
