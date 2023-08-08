---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Extension/Achievements
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local LeagueIcon = require('Module:LeagueIcon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator/dev')
local String = require('Module:StringUtils')
local Team = require('Module:Team')

local CustomDefaultOptions = Lua.requireIfExists('Module:ThisLinkIsDead') or {}

local Opponent = require('Module:OpponentLibraries').Opponent

local DEFAULT_PLAYER_LIMIT = 10
local DEFAULT_BASE_CONDITIONS = {
	'[[liquipediatiertype::!Qualifier]]',
	'[[liquipediatiertype::!Charity]]',
	'[[liquipediatier::1]]',
	'[[placement::1]]',
}

local Achievements = {}

function Achievements.player(args)
	args = args or {}
	local options = Achievements._readOptions(args)

	local player = args.player or mw.title.getCurrentTitle().text

	local onlySolo = Logic.readBool(Logic.nilOr(args.onlySolo, true))

	local conditions = table.concat(Array.extend(
		options.baseConditions,
		Achievements._playerConditions(player, onlySolo, args.playerLimit or DEFAULT_PLAYER_LIMIT),
		onlySolo and ('[[opponenttype::' .. Opponent.solo .. ']]') or nil
	), ' AND ')

mw.logObject(conditions)

	return Achievements.display(Achievements._fetchData(conditions), options)
end

function Achievements._playerConditions(player, onlySolo, playerLimit)
	player = player:gsub(' ', '_')
	local playerNoUnderScore = player:gsub('_', ' ')

	if onlySolo then
		return '([[opponentname::' .. player .. ']] OR [[opponentname::' .. playerNoUnderScore .. ']])'
	end

	local playerConditions = Array.map(Array.range(1, playerLimit), function(playerIndex)
		local lpdbKey = 'opponentplayers_p' .. playerIndex
		return '[[' .. lpdbKey .. '::' .. player .. ']] OR [[' .. lpdbKey .. '::' .. playerNoUnderScore .. ']]'
	end)

	return '(' .. table.concat(playerConditions) .. ')'
end

function Achievements.teamAndTeamSolo(args)
	local historicalPages = Achievements._getTeamNames()
	local options = Achievements._readOptions(args)

	return Achievements.display(Achievements._fetchDataForTeam(historicalPages, Opponent.team, options), options),
		Achievements.display(Achievements._fetchDataForTeam(historicalPages, Opponent.solo, options), options)
end

function Achievements.teamSolo(args)
	local options = Achievements._readOptions(args)

	return Achievements.display(Achievements._fetchDataForTeam(
		Achievements._getTeamNames(), Opponent.team, options), options)
end

function Achievements.team(args)
	local options = Achievements._readOptions(args)

	return Achievements.display(Achievements._fetchDataForTeam(
		Achievements._getTeamNames(), Opponent.solo, options), options)
end

function Achievements._getTeamNames()
	local pageName = mw.title.getCurrentTitle().text
	local historicalPages = Team.queryHistoricalNames(pageName)
	assert(historicalPages, 'No team template exists for "' .. pageName .. '"')

	return Array.extend(
		Array.map(historicalPages, function(team) return (team:gsub(' ', '_')) end),
		Array.map(historicalPages, function(team) return (team:gsub('_', ' ')) end)
	)
end

function Achievements._readOptions(args)
	args = args or {}

	return {
		noTemplate = Logic.readBool(Logic.nilOr(args.noTemplate, CustomDefaultOptions.noTemplate)),
		onlyForFirstPrizePoolOfPage = Logic.readBool(Logic.nilOr(
			args.onlyForFirstPrizePoolOfPage,
			CustomDefaultOptions.onlyForFirstPrizePoolOfPage
		)),
		adjustItem = args.adjustItem or CustomDefaultOptions.adjustItem or Operator.identity,
		baseConditions = args.baseConditions or CustomDefaultOptions.baseConditions or DEFAULT_BASE_CONDITIONS,
	}
end

function Achievements._fetchDataForTeam(historicalPages, opponentType, options)
	return Achievements._fetchData(Achievements._buildTeamConditions(historicalPages, opponentType, options))
end

function Achievements._buildTeamConditions(historicalPages, opponentType, options)
	local lpdbKey = opponentType == Opponent.team and 'opponentname' or 'opponentplayers_p1team'

	return table.concat(Array.extend(
		options.baseConditions,
		'[[opponenttype::' .. opponentType .. ']]',
		'(' .. table.concat(Array.map(historicalPages, function(team)
			return '[[' .. lpdbKey .. '::' .. team .. ']]'
		end), ' OR ') .. ')'
	), ' AND ')
end

function Achievements._fetchData(conditions)
	return mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions,
		query = 'icon, icondark, pagename, tournament, date, prizepoolindex',
		order = 'date asc',
		limit = 5000,
	})
end

function Achievements.display(data, options)
	--read (default) options in case this function is accessed directly
	options = options or Achievements._readOptions()

	if not data or type(data[1]) ~= 'table' then
		return nil
	end

	table.sort(data, Operator.compareByKey('date', true))

	return String.nilIfEmpty(table.concat(Array.map(data, function(item)
		return Achievements._displayIcon(item, options)
	end)))
end

function Achievements._displayIcon(item, options)
	--in case we get passed data from outside this module make sure we are having data
	--with prizepoolindex 1
	if tonumber(item.prizepoolindex) ~= 1 and options.onlyForFirstPrizePoolOfPage then
		--can not return nil else Array.map breaks off
		return ''
	end

	options.adjustItem(item)

	return LeagueIcon.display{
		icon = item.icon,
		iconDark = item.icondark,
		link = item.pagename,
		name = item.tournament,
		options = {noTemplate = options.noTemplate},
	}
end

return Achievements
