---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Team = require('Module:Team')
local Tier = require('Module:Tier/Utils')
local FnUtil = require('Module:FnUtil')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local DEFAULT_QUERY_COLUMNS = {
	'match2opponents',
	'winner',
	'pagename',
	'tournament',
	'tickername',
	'icon',
	'icondark',
	'date',
	'dateexact',
	'liquipediatier',
	'liquipediatiertype',
	'publishertier',
	'vod',
	'stream',
	'extradata',
	'parent',
	'finished',
	'bestof',
	'match2id',
	'match2bracketdata',
}
local NONE = 'none'
local INFOBOX_DEFAULT_CLASS = 'fo-nttax-infobox panel'
local INFOBOX_WRAPPER_CLASS = 'fo-nttax-infobox-wrapper'
local DEFAULT_LIMIT = 20
local LIMIT_INCREASE = 20
local DEFAULT_ODER = 'date asc, liquipediatier asc, tournament asc'
local DEFAULT_RECENT_ORDER = 'date desc, liquipediatier asc, tournament asc'
local DEFAULT_LIVE_HOURS = 8
local NOW = os.date('%Y-%m-%d %H:%M', os.time(os.date('!*t') --[[@as osdateparam]]))

--- Extract externally if it grows
---@param matchTickerConfig MatchTickerConfig
---@return unknown # Todo: Add interface for MatchTickerDisplay
local MatchTickerDisplayFactory = function (matchTickerConfig)
	if matchTickerConfig.newStyle then
		return Lua.import('Module:MatchTicker/DisplayComponents/New')
	else
		return Lua.import('Module:MatchTicker/DisplayComponents')
	end
end

---@class MatchTickerConfig
---@field tournaments string[]
---@field limit integer
---@field order string
---@field player string?
---@field teamPages string[]?
---@field hideTournament boolean
---@field maximumLiveHoursOfMatches integer
---@field queryColumns string[]
---@field additionalConditions string
---@field recent boolean
---@field upcoming boolean
---@field ongoing boolean
---@field onlyExact boolean
---@field enteredOpponentOnLeft boolean
---@field queryByParent boolean
---@field showAllTbdMatches boolean
---@field showInfoForEmptyResults boolean
---@field wrapperClasses string[]?
---@field onlyHighlightOnValue string?
---@field tiers string[]?
---@field tierTypes string[]?
---@field newStyle boolean?

---@class MatchTicker
---@operator call(table): MatchTicker
---@field args table
---@field config MatchTickerConfig
---@field matches table[]?
local MatchTicker = Class.new(function(self, args) self:init(args) end)

---@param args table?
---@return table
function MatchTicker:init(args)
	args = args or {}
	self.args = args

	local hasOpponent = Logic.isNotEmpty(args.player or args.team)

	local config = {
		tournaments = Array.extractValues(
			Table.filterByKey(args, function(key)
				return string.find(key, '^tournament%d-$') ~= nil or Logic.isNumeric(key)
		end)),
		queryByParent = Logic.readBool(args.queryByParent),
		limit = tonumber(args.limit) or DEFAULT_LIMIT,
		order = args.order or (Logic.readBool(args.recent) and DEFAULT_RECENT_ORDER or DEFAULT_ODER),
		player = args.player and mw.ext.TeamLiquidIntegration.resolve_redirect(args.player):gsub(' ', '_') or nil,
		maximumLiveHoursOfMatches = tonumber(args.maximumLiveHoursOfMatches) or DEFAULT_LIVE_HOURS,
		queryColumns = args.queryColumns or DEFAULT_QUERY_COLUMNS,
		additionalConditions = args.additionalConditions or '',
		recent = Logic.readBool(args.recent),
		upcoming = Logic.readBool(args.upcoming),
		ongoing = Logic.readBool(args.ongoing),
		onlyExact = Logic.readBool(Logic.emptyOr(args.onlyExact, true)),
		enteredOpponentOnLeft = hasOpponent and Logic.readBool(args.enteredOpponentOnLeft or hasOpponent),
		showInfoForEmptyResults = Logic.readBool(args.showInfoForEmptyResults),
		onlyHighlightOnValue = args.onlyHighlightOnValue,
		tiers = args.tiers and Array.filter(Array.parseCommaSeparatedString(args.tiers), function (tier)
					local identifier = Tier.toIdentifier(tier)
					return type(identifier) == 'number' and Tier.isValid(identifier)
				end) or nil,
		tierTypes = args.tiertypes and Array.filter(
					Array.parseCommaSeparatedString(args.tiertypes), FnUtil.curry(Tier.isValid, 1)
				) or nil,
		newStyle = Logic.readBool(args.newStyle),
	}

	--min 1 of them has to be set; recent can not be set while any of the others is set
	assert(config.ongoing or config.upcoming or (config.recent and
		not (config.upcoming or config.ongoing)),
		'Invalid recent, upcoming, ongoing combination')

	local teamPages = args.team and Team.queryHistoricalNames(args.team)
		or args.team and {args.team} or nil
	if teamPages then
		Array.extendWith(teamPages,
		Array.map(teamPages, function(team) return (team:gsub(' ', '_')) end),
		Array.map(teamPages, function(team) return mw.getContentLanguage():ucfirst(team) end),
		Array.map(teamPages, function(team) return (mw.getContentLanguage():ucfirst(team):gsub(' ', '_')) end)
		)
	end
	config.teamPages = teamPages

	config.showAllTbdMatches = Logic.readBool(Logic.nilOr(args.showAllTbdMatches,
		Table.isEmpty(config.tournaments)))

	config.hideTournament = Logic.readBool(args.hideTournament or Table.isNotEmpty(config.tournaments))

	local wrapperClasses = type(args.wrapperClasses) == 'table' and args.wrapperClasses
		or args.wrapperClasses == NONE and {}
		or {args.wrapperClasses}

	if Logic.readBool(args.infoboxClass) or Logic.readBool(args.infoboxWrapperClass) then
		table.insert(wrapperClasses, INFOBOX_DEFAULT_CLASS)
	end

	if Logic.readBool(args.infoboxWrapperClass) then
		table.insert(wrapperClasses, INFOBOX_WRAPPER_CLASS)
		local game = args.game and Game.abbreviation{game = args.game}:lower()
		if game then
			table.insert(wrapperClasses, 'infobox-' .. game)
		end
	end
	config.wrapperClasses = wrapperClasses

	MatchTicker.DisplayComponents = MatchTickerDisplayFactory(config)

	self.config = config

	return self
end

---queries the matches and filters them for unwanted ones
---@param matches table?
---@return MatchTicker
function MatchTicker:query(matches)
	matches = matches or mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = self:buildQueryConditions(),
		order = self.config.order,
		query = table.concat(self.config.queryColumns, ','),
		limit = self.config.limit + LIMIT_INCREASE,
	})

	if type(matches[1]) == 'table' then
		matches = Array.sub(self:filterMatches(matches), 1, self.config.limit)
		self.matches = Array.map(matches, function(match) return self:adjustMatch(match) end)
		return self
	end

	return self
end

---@return string
function MatchTicker:buildQueryConditions()
	local config = self.config
	local conditions = ConditionTree(BooleanOperator.all)

	if Table.isNotEmpty(config.tournaments) then
		local tournamentConditions = ConditionTree(BooleanOperator.any)
		local lpdbField = config.queryByParent and 'parent' or 'pagename'

		Array.forEach(config.tournaments, function(tournament)
			tournament = tournament:gsub(' ', '_')
			tournamentConditions:add{ConditionNode(ColumnName(lpdbField), Comparator.eq, tournament)}
		end)

		conditions:add(tournamentConditions)
	end

	if config.player then
		local playerNoUnderScore = config.player:gsub('_', ' ')
		conditions:add(ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('opponent'), Comparator.eq, config.player),
			ConditionNode(ColumnName('opponent'), Comparator.eq, playerNoUnderScore),
			ConditionNode(ColumnName('player'), Comparator.eq, config.player),
			ConditionNode(ColumnName('player'), Comparator.eq, playerNoUnderScore),
		})
	end

	if config.teamPages then
		local teamConditions = ConditionTree(BooleanOperator.any)

		Array.forEach(config.teamPages, function (team)
			teamConditions:add{
				ConditionNode(ColumnName('opponent'), Comparator.eq, team),
			}
		end)

		conditions:add(teamConditions)
	end

	if Table.isNotEmpty(config.tiers) then
		local tierConditions = ConditionTree(BooleanOperator.any)

		Array.forEach(config.tiers, function(tier)
			tierConditions:add { ConditionNode(ColumnName('liquipediatier'), Comparator.eq, tonumber(tier)) }
		end)

		conditions:add(tierConditions)
	end

	if Table.isNotEmpty(config.tierTypes) then
		local tierTypeConditions = ConditionTree(BooleanOperator.any)

		Array.forEach(config.tierTypes, function(tierType)
			tierTypeConditions:add { ConditionNode(ColumnName('liquipediatiertype'), Comparator.eq, tierType) }
		end)

		tierTypeConditions:add { ConditionNode(ColumnName('liquipediatiertype'), Comparator.eq, '') }

		conditions:add(tierTypeConditions)
	end

	conditions:add(self:dateConditions())

	return conditions:toString() .. config.additionalConditions
end

---@return ConditionTree
function MatchTicker:dateConditions()
	local config = self.config

	local dateConditions = ConditionTree(BooleanOperator.all)

	if config.onlyExact then
		dateConditions:add{ConditionNode(ColumnName('dateexact'), Comparator.eq, 1)}
	end

	if config.recent then
		return dateConditions:add({
			ConditionNode(ColumnName('finished'), Comparator.eq, 1),
			ConditionNode(ColumnName('date'), Comparator.lt, NOW),
		})
	end

	dateConditions:add{ConditionNode(ColumnName('finished'), Comparator.eq, 0)}

	if config.ongoing then
		local secondsLive = config.maximumLiveHoursOfMatches * 3600
		local timeStamp = os.date('%Y-%m-%d %H:%M', os.time(os.date('!*t') --[[@as osdateparam]]) - secondsLive)

		dateConditions:add{ConditionNode(ColumnName('date'), Comparator.gt, timeStamp)}

		if config.upcoming then return dateConditions end

		return dateConditions:add{
			ConditionTree(BooleanOperator.any):add{
				ConditionNode(ColumnName('date'), Comparator.lt, NOW),
				ConditionNode(ColumnName('date'), Comparator.eq, NOW),
			}
		}
	end

	--case upcoming
	return dateConditions:add{ConditionNode(ColumnName('date'), Comparator.gt, NOW)}
end

---Overwritable per wiki decision
---@param matches table[]
---@return table[]
function MatchTicker:filterMatches(matches)
	--remove matches with empty/BYE opponents
	matches = Array.filter(matches, function(match)
		return not Array.any(match.match2opponents, Opponent.isBye)
	end)

	if self.config.showAllTbdMatches then
		return matches
	end

	local previousMatchWasTbd
	Array.forEach(matches, function(match)
		local isTbdMatch = Array.all(match.match2opponents, function(opponent)
			return Opponent.isEmpty(opponent) or Opponent.isTbd(opponent)
		end)
		if isTbdMatch and previousMatchWasTbd then
			match.isTbdMatch = true
		elseif isTbdMatch then
			previousMatchWasTbd = true
		else
			previousMatchWasTbd = false
		end
	end)

	return Array.filter(matches, function(match) return not match.isTbdMatch end)
end

function MatchTicker:adjustMatch(match)
	if not self.config.enteredOpponentOnLeft or #match.match2opponents ~= 2 then
		return match
	end

	local opponentNames = Array.extend({self.config.player}, self.config.teamPages)
	if
		--check for the name value
		Table.includes(opponentNames, (match.match2opponents[2].name:gsub(' ', '_')))
		--check inside match2players too for the player value
		or self.config.player and Table.any(match.match2opponents[2].match2players, function(_, playerData)
			return (playerData.name or ''):gsub(' ', '_') == self.config.player end)
	then
		return MatchTicker.switchOpponents(match)
	end

	return match
end

function MatchTicker.switchOpponents(match)
	local winner = tonumber(match.winner) or 0
	match.winner = winner == 1 and 2
		or winner == 2 and 1
		or match.winner

	match.match2opponents[1], match.match2opponents[2] = match.match2opponents[2], match.match2opponents[1]

	return match
end

---@param header MatchTickerHeader?
---@return Html
function MatchTicker:create(header)
	if not self.matches and not self.config.showInfoForEmptyResults then
		return mw.html.create()
	end

	local wrapper = mw.html.create('div')

	for _, class in pairs(self.config.wrapperClasses) do
		wrapper:addClass(class)
	end

	if header then
		wrapper:node(header:create())
	end

	if not self.matches then
		return wrapper:css('text-align', 'center'):wikitext('No Results found.')
	end

	for _, match in ipairs(self.matches or {}) do
		wrapper:node(MatchTicker.DisplayComponents.Match{config = self.config, match = match}:create())
	end

	return wrapper
end

return MatchTicker
