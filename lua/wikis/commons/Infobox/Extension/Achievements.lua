---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Extension/Achievements
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local LeagueIcon = require('Module:LeagueIcon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local TeamTemplate = require('Module:TeamTemplate') ---@module 'commons.TeamTemplate'

local CustomDefaultOptions = Lua.requireIfExists('Module:Infobox/Extension/Achievements/Custom') or {}

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local NON_BREAKING_SPACE = '&nbsp;'
local DEFAULT_PLAYER_LIMIT = 10
local MAX_PARTY_SIZE = 4
local DEFAULT_BASE_CONDITIONS = {
	'[[liquipediatiertype::!Qualifier]]',
	'[[liquipediatiertype::!Charity]]',
	'[[liquipediatier::1]]',
	'[[placement::1]]',
}

local Achievements = {}

---@class AchievementIconsArgs
---@field noTemplate boolean?
---@field onlyForFirstPrizePoolOfPage boolean?
---@field adjustItem? fun(item:table):table
---@field baseConditions string[]?
---@field player string?
---@field onlySolo boolean?
---@field playerLimit integer?

---Entry point for achievements icons in infobox player
---@param args AchievementIconsArgs?
---@return string?
function Achievements.player(args)
	if not Namespace.isMain() then return end
	args = args or {}
	local options = Achievements._readOptions(args)

	local player = args.player or mw.title.getCurrentTitle().text

	local onlySolo = Logic.readBool(args.onlySolo)

	local conditions = table.concat(Array.extend(
		options.baseConditions,
		Achievements._playerConditions(player, onlySolo, args.playerLimit or DEFAULT_PLAYER_LIMIT),
		onlySolo and ('[[opponenttype::' .. Opponent.solo .. ']]') or nil
	), ' AND ')

	return Achievements.display(Achievements._fetchData(conditions), options)
end

---Builds player conditions for query in `Achievements.player`
---@param player string
---@param onlySolo boolean
---@param playerLimit integer
---@return string
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

	return '(' .. table.concat(playerConditions, ' OR ') .. ')'
end

---Entry point for infobox team to fetch both team achievements and solo achievements while on team as sep. icon strings
---@param args AchievementIconsArgs?
---@return string? #Team Achievements icon string
---@return string? #Solo Achievements while on team icon string
function Achievements.teamAndTeamSolo(args)
	if not Namespace.isMain() then return end
	local historicalPages = Achievements._getTeamNames()
	local options = Achievements._readOptions(args)

	return Achievements.display(Achievements._fetchDataForTeam(historicalPages, Opponent.team, options), options),
		Achievements.display(Achievements._fetchDataForTeam(historicalPages, Opponent.solo, options), options)
end

---Entry point for infobox team to fetch both team and player achievements while on team as icon strings
---@param args AchievementIconsArgs?
---@return string? #Team Achievements icon string
function Achievements.teamAll(args)
	if not Namespace.isMain() then return end
	local historicalPages = Achievements._getTeamNames()
	local options = Achievements._readOptions(args)

	return Achievements.display(Achievements._fetchDataForTeam(historicalPages, '!' .. Opponent.literal, options), options)
end

---Entry point for infobox team to fetch solo achievements while on team as icon strings
---@param args AchievementIconsArgs?
---@return string?
function Achievements.teamSolo(args)
	if not Namespace.isMain() then return end
	local options = Achievements._readOptions(args)

	return Achievements.display(Achievements._fetchDataForTeam(
		Achievements._getTeamNames(), Opponent.solo, options), options)
end

---Entry point for infobox team to fetch team achievements as icon strings
---@param args AchievementIconsArgs?
---@return string?
function Achievements.team(args)
	if not Namespace.isMain() then return end
	local options = Achievements._readOptions(args)

	return Achievements.display(Achievements._fetchDataForTeam(
		Achievements._getTeamNames(), Opponent.team, options), options)
end

---Fetches (historical) teamNames (both with underscore and without) of a given team
---@return string[]
function Achievements._getTeamNames()
	local pageName = mw.title.getCurrentTitle().text
	local historicalPages = TeamTemplate.queryHistoricalNames(pageName)
	assert(Logic.isNotEmpty(historicalPages), TeamTemplate.noTeamMessage(pageName))

	return Array.extend(
		Array.map(historicalPages, function(team) return (team:gsub(' ', '_')) end),
		Array.map(historicalPages, function(team) return (team:gsub('_', ' ')) end)
	)
end

---@class AchievementIconsOptions
---@field noTemplate boolean
---@field onlyForFirstPrizePoolOfPage boolean
---@field adjustItem fun(item:table):table
---@field baseConditions string[]

---Read options
---@param args AchievementIconsArgs?
---@return AchievementIconsOptions
function Achievements._readOptions(args)
	args = args or {}

	return {
		noTemplate = Logic.readBool(Logic.nilOr(args.noTemplate, CustomDefaultOptions.noTemplate)),
		onlyForFirstPrizePoolOfPage = Logic.readBool(Logic.nilOr(
			args.onlyForFirstPrizePoolOfPage,
			CustomDefaultOptions.onlyForFirstPrizePoolOfPage
		)),
		adjustItem = args.adjustItem or CustomDefaultOptions.adjustItem or FnUtil.identity,
		baseConditions = args.baseConditions or CustomDefaultOptions.baseConditions or DEFAULT_BASE_CONDITIONS,
	}
end

---@param historicalPages string[]
---@param opponentType OpponentType
---@param options AchievementIconsOptions
---@return table[]
function Achievements._fetchDataForTeam(historicalPages, opponentType, options)
	return Achievements._fetchData(Achievements._buildTeamConditions(historicalPages, opponentType, options))
end

---Builds query conditions for a team
---@param historicalPages string[]
---@param opponentType OpponentType
---@param options AchievementIconsOptions
---@return string
function Achievements._buildTeamConditions(historicalPages, opponentType, options)
	local lpdbKeys = Achievements._getLpdbKeys(opponentType)
	local teamConditions = Array.flatMap(lpdbKeys, function(lpdbKey)
		return Array.map(historicalPages, function(team)
			return '[[' .. lpdbKey .. '::' .. team .. ']]'
		end)
	end)

	local conditions = Array.extend({},
		'(' .. table.concat(teamConditions, ' OR ') .. ')',
		'[[opponenttype::' .. opponentType .. ']]',
		options.baseConditions
	)

	return table.concat(conditions, ' AND ')
end

---@param opponentType OpponentType
---@return string[]
function Achievements._getLpdbKeys(opponentType)
	if opponentType == Opponent.team then
		return {'opponentname'}
	end

	return Array.map(Array.range(1, MAX_PARTY_SIZE), function(opponentIndex)
		return 'opponentplayers_p' .. opponentIndex .. 'team'
	end)
end

---Query data for given conditions
---@param conditions string
---@return {icon:string?,icondark:string?,pagename:string,tournament:string?,date:osdate,prizepoolindex:integer}[]
function Achievements._fetchData(conditions)
	return mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions,
		query = 'icon, icondark, pagename, tournament, date, prizepoolindex',
		order = 'date asc',
		limit = 5000,
	})
end

---Build the display
---@param data {icon:string?,icondark:string?,pagename:string,tournament:string?,date:osdate,prizepoolindex:integer}[]
---@param options AchievementIconsOptions?
---@return string?
function Achievements.display(data, options)
	--read (default) options in case this function is accessed directly
	options = options or Achievements._readOptions()

	if not data or type(data[1]) ~= 'table' then
		return nil
	end

	Array.sortInPlaceBy(data, Operator.property('date'))

	return String.nilIfEmpty(table.concat(Array.map(data, function(item)
		return Achievements._displayIcon(item, options)
	end), NON_BREAKING_SPACE))
end

---Build the icon for a single entry
---@param item {icon:string?,icondark:string?,pagename:string,tournament:string?,date:osdate,prizepoolindex:integer}
---@param options AchievementIconsOptions
---@return string
function Achievements._displayIcon(item, options)
	if tonumber(item.prizepoolindex) ~= 1 and options.onlyForFirstPrizePoolOfPage then
		--can not return nil else Array.map breaks off
		return ''
	end

	options.adjustItem(item)

	return LeagueIcon.display{
		icon = Logic.emptyOr(item.icon, 'Gold.png'),
		iconDark = item.icondark,
		link = item.pagename,
		name = item.tournament,
		options = {noTemplate = options.noTemplate},
	}
end

return Achievements
