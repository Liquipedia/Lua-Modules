---
-- @Liquipedia
-- wiki=commons
-- page=Module:Earnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Earnings = {}
local MathUtils = require('Module:Math')
local String = require('Module:StringUtils')
local Logic = require('Module:StringUtils')
local Class = require('Module:Class')

local _DEFAULT_DATE = '1970-01-01 00:00:00'

---
-- Entry point for players and individuals
-- @player - the player/individual for whom the earnings shall be calculated
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
-- @noRedirect - (optional) player redirects get not resolved before query
-- @prefix - (optional) the prefix under which the players are stored in the placements
-- @playerNumber - (optional) the number for how many params the query should look in LPDB
function Earnings.calculateForPlayer(args)
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

	local condition = '([[participant::' .. player .. ']]'
	for playerIndex = 1, playerNumber do
		condition = condition .. ' OR [[players_' .. prefix .. playerIndex .. '::' .. player .. ']]' 
	end
	condition = condition .. ')'

	local money = Earnings._calculateIndividualEarnings(condition, args.year, args.mode)

	return MathUtils._round(money)
end

---
-- Entry point for teams
-- @team - the team for which the earnings shall be calculated
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
-- @noRedirect - (optional) player redirects get not resolved before query
function Earnings.calculateForTeam(args)
	local team = args.team
	if String.isEmpty(team) then
		return 0
	end
	if not Logic.readBool(args.noRedirect) then
		team = mw.ext.TeamLiquidIntegration.resolve_redirect(team)
	end

	local conditions = '([[participant::' .. team .. ']] OR [[extradata_participantteam::' .. team .. ']])'
	conditions = Earnings._buildConditions(conditions, args.year, args.mode)

	local lpdbQueryData = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions,
		query = 'sum::prizemoney',
		groupby = 'mode asc'
	})

	if type(lpdbQueryData[1]) == 'table' then
		MathUtils._round(lpdbQueryData[1].sum_prizemoney)
	end
	return 0
end

---
-- Calculates earnings for this participant in a certain mode
-- @participantCondition - the condition to find the player/team
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
function Earnings._calculateIndividualEarnings(participantCondition, year, mode)
	local conditions = Earnings._buildConditions(participantCondition, year, mode)

	local lpdbQueryData = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions,
		query = 'sum::prizemoney, mode',
		groupby = 'mode asc'
	})

	local totalEarnings = 0

	for _, item in ipairs(lpdbQueryData) do
		if item['sum_prizemoney'] ~= nil then
			local prizeMoney = item['sum_prizemoney']
			totalEarnings = totalEarnings + (prizeMoney / Earnings.divisionFactor(item['mode']))
		end
	end

	return totalEarnings
end

function Earnings._buildConditions(conditions, year, mode)
	conditions = '[[date::!' .. _DEFAULT_DATE .. ']] AND [[prizemoney::>0]] AND ' .. conditions
	if String.isNotEmpty(args.year) then
		conditions = conditions .. ' AND ([[date::>' .. args.year .. '-01-01]] OR [[date::' .. args.year .. '-01-01]])'
			.. 'AND ([[date::<' .. args.year .. '-12-31]] OR [[date::' .. args.year .. '-12-31]])'
	end

	if String.isNotEmpty(args.mode) then
		conditions = conditions .. ' AND [[mode::' .. args.mode .. ']]'
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

return Class.export(Earnings)
