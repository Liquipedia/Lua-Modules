---
-- @Liquipedia
-- wiki=commons
-- page=Module:Earnings/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local MathUtils = require('Module:Math')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')

local Opponent = require('Module:OpponentLibraries').Opponent

local DEFAULT_DATE = '1970-01-01 00:00:00'

local Earnings = {}

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

	local playerConditions = {
		'[[opponentname::' .. player .. ']]',
		'[[opponentname::' .. playerAsPageName .. ']]',
	}
	for playerIndex = 1, playerPositionLimit do
		table.insert(playerConditions, '[[opponentplayers_' .. prefix .. playerIndex .. '::' .. player .. ']]')
		table.insert(playerConditions, '[[opponentplayers_' .. prefix .. playerIndex .. '::' .. playerAsPageName .. ']]')
	end
	playerConditions = '(' .. table.concat(playerConditions, ' OR ') .. ')'

	return Earnings.calculate(playerConditions, args.year, args.mode, args.perYear, nil, true)
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
-- @playerPositionLimit - (optional) the number for how many params the query should look in LPDB
-- @doNotIncludePlayerEarnings - (optional) boolean to indicate that player earnings should be ignored
function Earnings.calculateForTeam(args)
	args = args or {}
	local teams = args.teams or {}
	table.insert(teams, args.team)

	if Table.isEmpty(teams) then
		return 0
	end

	local playerPositionLimit = tonumber(args.playerPositionLimit) or Earnings.defaultNumberOfStoredPlayersPerMatch
	if playerPositionLimit <= 0 then
		error('"playerPositionLimit" has to be >= 1')
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

	local formatParticipant = function(lpdbField)
		return '([[' .. lpdbField .. '::' ..
			table.concat(queryTeams, ']] OR [[' .. lpdbField .. '::')
			.. ']])'
	end

	if Logic.readBool(args.doNotIncludePlayerEarnings) then
		return Earnings.calculate(formatParticipant('opponentname'), args.year, args.mode, args.perYear)
	end

	local teamConditions = {formatParticipant('opponentname', queryTeams)}
	for playerIndex = 1, playerPositionLimit do
		table.insert(teamConditions, formatParticipant('opponentplayers_p' .. playerIndex .. 'team'))
	end
	teamConditions = '(' .. table.concat(teamConditions, ' OR ') .. ')'

	return Earnings.calculate(teamConditions, args.year, args.mode, args.perYear, queryTeams)
end

---
-- Calculates earnings for this participant in a certain mode
-- @participantCondition - the condition to find the player/team
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
-- @perYear - (optional) query all earnings per year and return the values in a lua table
-- @aliases - players/teams to determine earnings for
function Earnings.calculate(conditions, queryYear, mode, perYear, aliases, isPlayerQuery)
	conditions = Earnings._buildConditions(conditions, queryYear, mode)

	local sums = {}
	local totalEarnings = 0
	local sumUp = function(placement)
		local value = Earnings._determineValue(placement, aliases, isPlayerQuery)
		if perYear then
			local year = string.sub(placement.date, 1, 4)
			if not sums[year] then
				sums[year] = 0
			end
			sums[year] = sums[year] + value
		end

		totalEarnings = totalEarnings + value
	end

	local queryParameters = {
		conditions = conditions,
		query = 'individualprizemoney, prizemoney, opponentplayers, date, mode, opponenttype, opponentname',
	}
	Lpdb.executeMassQuery('placement', queryParameters, sumUp)

	local totalEarningsByYear = {}
	for year, earningsOfYear in pairs(sums) do
		totalEarningsByYear[tonumber(year)] = MathUtils._round(earningsOfYear)
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

function Earnings._determineValue(placement, aliases, isPlayerQuery)
	if isPlayerQuery then
		return tonumber(placement.individualprizemoney)
			or Earnings.divisionFactorPlayer and (placement.prizemoney / Earnings.divisionFactorPlayer(placement.mode))
			or 0
	elseif placement.opponenttype == Opponent.team and Table.includes(aliases, placement.opponentname) then
		return placement.prizemoney
	end

	local indivPrize = tonumber(placement.individualprizemoney)
	if not indivPrize then
		return 0 --???
	end

	local numberOfPlayersFromTeam = 0
	local playerData = Table.filterByKey(placement.opponentplayers or {}, function(key) return key:find('team') end)
	for _, team in pairs(playerData) do
		if Table.includes(aliases, team) then
			numberOfPlayersFromTeam = numberOfPlayersFromTeam + 1
		end
	end

	return indivPrize * numberOfPlayersFromTeam
end

-- legacy for the case of outdated data or misusage of PPT/TC
-- @deprecated
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

return Class.export(Earnings)
