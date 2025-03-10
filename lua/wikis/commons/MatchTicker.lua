---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')
local Tier = require('Module:Tier/Utils')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent
local MatchUtil = Lua.import('Module:Match/Util')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local Tournament = Lua.import('Module:Tournament')

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
	'match2games',
}
local NONE = 'none'
local INFOBOX_DEFAULT_CLASS = 'fo-nttax-infobox panel'
local INFOBOX_WRAPPER_CLASS = 'fo-nttax-infobox-wrapper'
local DEFAULT_LIMIT = 20
local DEFAULT_ODER = 'date asc, liquipediatier asc, tournament asc'
local DEFAULT_RECENT_ORDER = 'date desc, liquipediatier asc, tournament asc'
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
---@field regions string[]?
---@field games string[]?
---@field newStyle boolean?
---@field featuredTournamentsOnly boolean?

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
		queryColumns = args.queryColumns or DEFAULT_QUERY_COLUMNS,
		additionalConditions = args.additionalConditions or '',
		recent = Logic.readBool(args.recent),
		upcoming = Logic.readBool(args.upcoming),
		ongoing = Logic.readBool(args.ongoing),
		onlyExact = Logic.readBool(Logic.emptyOr(args.onlyExact, true)),
		enteredOpponentOnLeft = hasOpponent and Logic.readBool(args.enteredOpponentOnLeft or hasOpponent),
		showInfoForEmptyResults = Logic.readBool(args.showInfoForEmptyResults),
		onlyHighlightOnValue = args.onlyHighlightOnValue,
		regions = args.regions and Array.parseCommaSeparatedString(args.regions) or nil,
		tiers = args.tiers and Array.filter(Array.parseCommaSeparatedString(args.tiers), function (tier)
					local identifier = Tier.toIdentifier(tier)
					return type(identifier) == 'number' and Tier.isValid(identifier)
				end) or nil,
		tierTypes = args.tiertypes and Array.map(Array.filter(
					Array.parseCommaSeparatedString(args.tiertypes), FnUtil.curry(Tier.isValid, 1)
				), function(tiertype)
					return select(2, Tier.toValue(1, tiertype))
				end) or nil,
		games = args.games and Array.map(Array.parseCommaSeparatedString(args.games), function (game)
					return Game.toIdentifier{game=game}
				end) or nil,
		newStyle = Logic.readBool(args.newStyle),
		featuredTournamentsOnly = Logic.readBool(args.featuredTournamentsOnly),
	}

	--min 1 of them has to be set; recent can not be set while any of the others is set
	assert(config.ongoing or config.upcoming or (config.recent and
		not (config.upcoming or config.ongoing)),
		'Invalid recent, upcoming, ongoing combination')

	local teamPages = TeamTemplate.queryHistoricalNames(args.team)
	if Logic.isNotEmpty(teamPages) then
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
	if not matches then
		matches = {}
		Lpdb.executeMassQuery('match2',
			{
				conditions = self:buildQueryConditions(),
				order = self.config.order,
				query = table.concat(self.config.queryColumns, ','),
				limit = DEFAULT_LIMIT,
			},
			function(record)
				record = self:parseMatch(record)
				if not self:keepMatch(record) then
					return
				end
				for _, match in ipairs(self:expandGamesOfMatch(record)) do
					table.insert(matches, match)
				end
				if #matches >= self.config.limit then
					return false
				end
			end,
			DEFAULT_LIMIT * 20
		)
	end

	if type(matches[1]) == 'table' then
		matches = self:sortMatches(matches)
		matches = Array.sub(matches, 1, self.config.limit)
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
		tierTypeConditions:add { ConditionNode(ColumnName('liquipediatiertype'), Comparator.eq, 'General') }


		conditions:add(tierTypeConditions)
	end

	if Table.isNotEmpty(config.games) then
		local tierConditions = ConditionTree(BooleanOperator.any)

		Array.forEach(config.games, function(game)
			tierConditions:add { ConditionNode(ColumnName('game'), Comparator.eq, game) }
		end)

		conditions:add(tierConditions)
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
		-- case ongoing and upcoming: no date restriction
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
---@param match table
---@return table
function MatchTicker:parseMatch(match)
	match.opponents = Array.map(match.match2opponents, function(opponent, opponentIndex)
		return MatchGroupUtil.opponentFromRecord(match, opponent, opponentIndex)
	end)
	if self.config.regions or self.config.featuredTournamentsOnly then
		match.tournamentData = MatchTicker.fetchTournament(match.parent)
	end
	return match
end

local previousMatchWasTbd
---Overwritable per wiki decision
---@param match table
---@return boolean
function MatchTicker:keepMatch(match)
	-- Remove matches with wrong region
	if self.config.regions then
		if not match.tournamentData then
			return false
		end
		if not Table.includes(self.config.regions, match.tournamentData.region) then
			return false
		end
	end

	if self.config.featuredTournamentsOnly then
		if not match.tournamentData then
			return false
		end
		if not match.tournamentData.featured then
			return false
		end
	end

	--remove matches with empty/BYE opponents
	if Array.any(match.opponents, Opponent.isBye) then
		return false
	end

	if not self.config.showAllTbdMatches then
		local isTbdMatch = Array.all(match.opponents, function(opponent)
			return Opponent.isEmpty(opponent) or Opponent.isTbd(opponent)
		end)
		local toss = isTbdMatch and previousMatchWasTbd
		if isTbdMatch then
			previousMatchWasTbd = true
		else
			previousMatchWasTbd = false
		end

		if toss == true then
			return false
		end
	end

	return true
end

---Overwritable per wiki decision
---@param match table
---@return table[]
function MatchTicker:expandGamesOfMatch(match)
	local config = self.config
	if not match.match2games or #match.match2games < 2 then
		return {match}
	end

	if Array.all(match.match2games, function(game) return game.date == match.date end) then
		return {match}
	end

	return Array.map(match.match2games, function(game, gameIndex)
		if config.recent and Logic.isEmpty(game.winner) then
			return
		end
		if (config.upcoming or config.ongoing) and Logic.isNotEmpty(game.winner) then
			return
		end
		if not game.date then
			return
		end
		if not config.upcoming and NOW < game.date then
			return
		end
		if not (config.ongoing or config.recent) and NOW >= game.date then
			return
		end

		local gameMatch = Table.copy(match)
		gameMatch.match2games = nil
		gameMatch.asGame = true
		gameMatch.asGameIdx = gameIndex

		gameMatch.winner = game.winner
		gameMatch.date = game.date
		gameMatch.map = game.map
		gameMatch.vod = Logic.nilIfEmpty(game.vod) or match.vod
		gameMatch.opponents = Array.map(match.opponents, function(opponent, opponentIndex)
			return MatchUtil.enrichGameOpponentFromMatchOpponent(opponent, game.opponents[opponentIndex])
		end)
		return gameMatch
	end)
end

---Overwritable per wiki decision
---@param matches table[]
---@return table[]
function MatchTicker:sortMatches(matches)
	local reverse = self.config.recent and true or false
	return Array.sortBy(matches, FnUtil.identity, function (a, b)
		if a.date ~= b.date then
			if reverse then
				return a.date > b.date
			end
			return b.date > a.date
		end
		if a.match2id ~= b.match2id then
			return a.match2id < b.match2id
		end
		return (a.asGameIdx or 0) < (b.asGameIdx or 0)
	end)
end

--- Will only switch if enteredOpponentOnLeft is enabled AND there are exactly 2 opponents
---@param match table
---@return table
function MatchTicker:adjustMatch(match)
	if not self.config.enteredOpponentOnLeft or #match.opponents ~= 2 then
		return match
	end

	local opponentNames = Array.extend({self.config.player}, self.config.teamPages)
	if
		--check for the name value
		Table.includes(opponentNames, ((match.opponents[2].name or ''):gsub(' ', '_')))
		--check inside match2players too for the player value
		or self.config.player and Table.any(match.opponents[2].players, function(_, playerData)
			return (playerData.pageName or ''):gsub(' ', '_') == self.config.player end)
	then
		return MatchTicker.switchOpponents(match)
	end

	return match
end

--- Will only switch if there are exactly 2 opponents
---@param match table
---@return table
function MatchTicker.switchOpponents(match)
	if #match.opponents ~= 2 then
		return match
	end
	local winner = tonumber(match.winner) or 0
	match.winner = winner == 1 and 2
		or winner == 2 and 1
		or match.winner

	match.match2opponents[1], match.match2opponents[2] = match.match2opponents[2], match.match2opponents[1]
	match.opponents[1], match.opponents[2] = match.opponents[2], match.opponents[1]

	return match
end

--- Fetches region of a tournament
---@param tournamentPage string
---@return StandardTournament?
MatchTicker.fetchTournament = FnUtil.memoize(function(tournamentPage)
	return Tournament.getTournament(tournamentPage)
end)

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
