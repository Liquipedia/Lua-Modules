---
-- @Liquipedia
-- wiki=commons
-- page=Module:Earnings/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local MathUtils = require('Module:MathUtil')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate') ---@module 'commons.TeamTemplate'

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local Earnings = {}

-- customizable in /Custom
Earnings.defaultNumberOfStoredPlayersPerMatch = 10

---@class playerEarningsArgs
---@field player string the player/individual for whom the earnings shall be calculated
---@field year number? the year to calculate earnings for
---@field mode string? the mode to calculate earnings for
---@field noRedirect boolean? player redirects get not resolved before query
---@field prefix string? the prefix under which the players are stored in the placements
---@field playerPositionLimit integer? the number for how many params the query should look in LPDB
---@field perYear boolean? query all earnings per year and return the values in a lua table

---
-- Entry point for players and individuals
---@param args playerEarningsArgs
---@return number, {[integer]: number?}?
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
	local playerConditionString = '(' .. table.concat(playerConditions, ' OR ') .. ')'

	return Earnings.calculate(playerConditionString, args.year, args.mode, args.perYear, nil, true)
end

---@class teamEarningsArgs
---@field team string the team (either pageName or team template) for which the earnings shall be calculated
---@field teams string[]? list of teams
---@field year number? the year to calculate earnings for
---@field mode string? the mode to calculate earnings for
---@field queryHistorical boolean? fetch the pageNames from the subTemplates of the entered team template
---@field noRedirect boolean? team redirects get not resolved before query (only available if queryHistorical not used)
---@field prefix string? the prefix under which the players are stored in the placements
---@field playerPositionLimit integer? the number for how many params the query should look in LPDB
---@field perYear boolean? query all earnings per year and return the values in a lua table
---@field doNotIncludePlayerEarnings boolean? boolean to indicate that player earnings should be ignored

---
-- Entry point for teams
---@param args teamEarningsArgs
---@return number, {[integer]: number?}?
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
			local historicalNames = TeamTemplate.queryHistoricalNames(team)

			if Logic.isEmpty(historicalNames) then
				return 0
			end

			Array.extendWith(queryTeams, Array.map(historicalNames, String.upperCaseFirst))
		end
	elseif not Logic.readBool(args.noRedirect) then
		queryTeams = Array.map(teams, mw.ext.TeamLiquidIntegration.resolve_redirect)
	else
		queryTeams = Array.map(teams, String.upperCaseFirst)
	end

	local formatParticipant = function(lpdbField)
		return '([[' .. lpdbField .. '::' ..
			table.concat(queryTeams, ']] OR [[' .. lpdbField .. '::')
			.. ']])'
	end

	if Logic.readBool(args.doNotIncludePlayerEarnings) then
		return Earnings.calculate(formatParticipant('opponentname'), args.year, args.mode, args.perYear, queryTeams)
	end

	local teamConditions = {formatParticipant('opponentname')}

	for playerIndex = 1, playerPositionLimit do
		table.insert(teamConditions, formatParticipant('opponentplayers_p' .. playerIndex .. 'team'))
	end
	local teamConditionString = '(' .. table.concat(teamConditions, ' OR ') .. ')'

	return Earnings.calculate(teamConditionString, args.year, args.mode, args.perYear, queryTeams)
end

---
-- Calculates earnings for this participant in a certain mode
---@param conditions string the condition to find the player/team
---@param queryYear number? the year to calculate earnings for
---@param mode string? the mode to calculate earnings for
---@param perYear boolean? query all earnings per year and return the values in a lua table
---@param aliases string[]? players/teams to determine earnings for
---@param isPlayerQuery true? if this is a player query or not
---@return number, {[integer]: number?}?
function Earnings.calculate(conditions, queryYear, mode, perYear, aliases, isPlayerQuery)
	conditions = Earnings._buildConditions(conditions, queryYear, mode)

	local earningsByYear = {}
	local totalEarnings = 0
	local sumUp = function(placement)
		local value = Earnings._determineValue(placement, aliases, isPlayerQuery)
		if perYear then
			local year = tonumber(string.sub(placement.date, 1, 4))
			---@cast year -nil
			earningsByYear[year] = (earningsByYear[year] or 0) + value
		end

		totalEarnings = totalEarnings + value
	end

	local queryParameters = {
		conditions = conditions,
		query = 'individualprizemoney, prizemoney, opponentplayers, date, opponenttype, opponentname',
	}
	Lpdb.executeMassQuery('placement', queryParameters, sumUp)

	totalEarnings = MathUtils.round(totalEarnings)

	if not perYear then
		return totalEarnings
	end

	earningsByYear = Table.mapValues(earningsByYear, MathUtils.round)

	return totalEarnings, earningsByYear
end

---Creates query conditions depending on year and mode
---@param conditions string
---@param year number?
---@param mode string?
---@return string
function Earnings._buildConditions(conditions, year, mode)
	conditions = '[[date::!' .. DateExt.defaultDateTime .. ']] AND [[prizemoney::>0]] AND ' .. conditions
	if Logic.isNotEmpty(year) then
		conditions = conditions .. ' AND ([[date_year::' .. year .. ']])'
	end

	if String.isNotEmpty(mode) then
		conditions = conditions .. ' AND [[mode::' .. mode .. ']]'
	end

	return conditions
end

---Determines the prize value earned from a placement
---@param placement table
---@param aliases string[]
---@param isPlayerQuery boolean?
---@return number
---@overload fun(placement: table, aliases: nil, isPlayerQuery: true): number
function Earnings._determineValue(placement, aliases, isPlayerQuery)
	local indivPrize = tonumber(placement.individualprizemoney)

	if isPlayerQuery then
		return indivPrize or 0
	elseif placement.opponenttype == Opponent.team and Table.includes(aliases, placement.opponentname) then
		return placement.prizemoney
	end

	if not indivPrize then
		return 0
	end

	-- calcualte the number of players on the team that are part of the placement
	-- so we can get the real value of earnings for the team from their players from this placement
	local playerData = Table.filterByKey(placement.opponentplayers or {}, function(key) return key:find('team') end)

	return indivPrize * Table.size(Table.filter(playerData, function(team) return Table.includes(aliases, team) end))
end

return Class.export(Earnings)
