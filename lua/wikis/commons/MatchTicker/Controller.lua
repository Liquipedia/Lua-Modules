---
-- @Liquipedia
-- page=Module:MatchTicker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Game = Lua.import('Module:Game')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Tier = Lua.import('Module:Tier/Utils')

local Opponent = Lua.import('Module:Opponent/Custom')
local MatchUtil = Lua.import('Module:Match/Util')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local Tournament = Lua.import('Module:Tournament')

local MatchTickerWrapper = Lua.import('Module:Widget/Match/Ticker/Wrapper')

local Condition = Lua.import('Module:Condition')
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
	'game',
	'section',
}
local NONE = 'none'
local INFOBOX_DEFAULT_CLASS = 'fo-nttax-infobox panel'
local INFOBOX_WRAPPER_CLASS = 'fo-nttax-infobox-wrapper'
local DEFAULT_LIMIT = 20
local DEFAULT_ORDER = 'date asc, liquipediatier asc, tournament asc'
local DEFAULT_RECENT_ORDER = 'date desc, liquipediatier asc, tournament asc'
local NOW = os.date('%Y-%m-%d %H:%M', os.time(os.date('!*t') --[[@as osdateparam]]))

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
---@field variant 'vertical' | 'horizontal'
---@field featuredOnly boolean?
---@field displayGameIcons boolean?
---@field header Renderable?

---@class MatchTickerGameData
---@field asGame boolean?
---@field gameIds number[]
---@field map string?
---@field mapDisplayName string?

local MatchTickerController = {}

---@param args table?
---@return Renderable?
function MatchTickerController.makeMatchTicker(args)
	local config = MatchTickerController.parseConfig(args or {})
	local matches = MatchTickerController.fetchMatches(config)
	return MatchTickerWrapper{
		matches = matches,
		header = config.header,
		showInfoForEmptyResults = config.showInfoForEmptyResults,
		wrapperClasses = config.wrapperClasses,
		hideTournament = config.hideTournament,
		displayGameIcons = config.displayGameIcons,
		onlyHighlightOnValue = config.onlyHighlightOnValue,
		variant = config.variant
	}
end

---@private
---@param args table
---@return MatchTickerConfig
function MatchTickerController.parseConfig(args)
	local hasOpponent = Logic.isNotEmpty(args.player or args.team)

	local config = {
		tournaments = Array.extractValues(
			Table.filterByKey(args, function(key)
				return string.find(key, '^tournament%d-$') ~= nil or Logic.isNumeric(key)
		end)),
		queryByParent = Logic.readBool(args.queryByParent),
		limit = tonumber(args.limit) or DEFAULT_LIMIT,
		order = args.order or (Logic.readBool(args.recent) and DEFAULT_RECENT_ORDER or DEFAULT_ORDER),
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
		featuredOnly = Logic.readBool(args.featuredOnly),
		displayGameIcons = Logic.readBool(args.displayGameIcons),
		variant = Logic.readBool(args.entityStyle) and 'horizontal' or 'vertical',
		header = args.header,
	}

	--min 1 of them has to be set; recent can not be set while any of the others is set
	assert(config.ongoing or config.upcoming or (config.recent and
		not (config.upcoming or config.ongoing)),
		'Invalid recent, upcoming, ongoing combination')

	local teamTemplates = args.team and TeamTemplate.queryHistoricalNames(args.team) or nil
	if teamTemplates then
		config.teamPages = Array.flatMap(teamTemplates, function (teamTemplate)
			local teamPage = TeamTemplate.getPageName(teamTemplate)
			---@cast teamPage -nil
			return {
				teamPage,
				teamPage:gsub(' ', '_'),
				String.upperCaseFirst(teamPage),
				String.upperCaseFirst(teamPage:gsub(' ', '_')),
			}
		end)
	end

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

	return config
end

---queries the matches and filters them for unwanted ones
---@private
---@param config MatchTickerConfig
---@return table[]
function MatchTickerController.fetchMatches(config)
	local matches = {}
	Lpdb.executeMassQuery('match2',
		{
			conditions = MatchTickerController.buildQueryConditions(config),
			order = config.order,
			query = table.concat(config.queryColumns, ','),
			limit = DEFAULT_LIMIT,
		},
		function(record)
			record = MatchTickerController.parseMatch(record, config)
			if not MatchTickerController.keepMatch(record, config) then
				return
			end
			for _, match in ipairs(MatchTickerController.expandGamesOfMatch(record, config)) do
				table.insert(matches, match)
			end
			if #matches >= config.limit then
				return false
			end
		end,
		DEFAULT_LIMIT * 20
	)

	if type(matches[1]) ~= 'table' then
		return {}
	end

	matches = MatchTickerController.sortMatches(matches, config)
	matches = Array.sub(matches, 1, config.limit)
	matches = Array.map(matches, function(match) return MatchTickerController.adjustMatch(match, config) end)

	return matches
end

---@private
---@param config MatchTickerConfig
---@return string
function MatchTickerController.buildQueryConditions(config)
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

	conditions:add(MatchTickerController.dateConditions(config))

	return conditions:toString() .. config.additionalConditions
end

---@private
---@param config MatchTickerConfig
---@return ConditionTree
function MatchTickerController.dateConditions(config)
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

---@private
---@param match table
---@param config MatchTickerConfig
---@return table
function MatchTickerController.parseMatch(match, config)
	match.opponents = Array.map(match.match2opponents, function(opponent, opponentIndex)
		return MatchGroupUtil.opponentFromRecord(match, opponent, opponentIndex)
	end)
	if config.regions or config.featuredOnly then
		match.tournamentData = MatchTickerController.fetchTournament(match.parent)
	end
	return match
end

local previousMatchWasTbd = false
---@private
---@param match table
---@param config MatchTickerConfig
---@return boolean
function MatchTickerController.keepMatch(match, config)
	if match.extradata and match.extradata.hidden then
		return false
	end
	-- Remove matches with wrong region
	if config.regions then
		if not match.tournamentData then
			return false
		end
		if not Table.includes(config.regions, match.tournamentData.region) then
			return false
		end
	end

	if config.featuredOnly then
		local matchIsInFeaturedTournament = match.tournamentData and match.tournamentData.featured
		local matchIsFeatured = match.extradata and match.extradata.featured
		if not matchIsInFeaturedTournament and not matchIsFeatured then
			return false
		end
	end

	--remove matches with empty/BYE opponents
	if Array.any(match.opponents, Opponent.isBye) then
		return false
	end

	if not config.showAllTbdMatches then
		local isTbdMatch = Array.all(match.opponents, function(opponent)
			return Opponent.isEmpty(opponent) or Opponent.isTbd(opponent)
		end)
		local throwAway = isTbdMatch and previousMatchWasTbd
		previousMatchWasTbd = isTbdMatch

		return not throwAway
	end

	return true
end

---@private
---@param match table
---@param config MatchTickerConfig
---@return table[]
function MatchTickerController.expandGamesOfMatch(match, config)
	if not match.match2games or #match.match2games < 2 then
		return {match}
	end

	if Array.all(match.match2games, function(game) return game.date == match.date end) then
		return {match}
	end

	local expandedGames = Array.map(match.match2games, function(game, gameIndex)
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
		gameMatch.match2games = {}
		gameMatch.asGame = true
		gameMatch.asGameIndexes = {gameIndex}

		gameMatch.winner = game.winner
		gameMatch.date = game.date
		gameMatch.map = game.map
		gameMatch.vod = Logic.nilIfEmpty(game.vod) or match.vod
		gameMatch.opponents = Array.map(match.match2opponents, function(opponent, opponentIndex)
			return MatchUtil.enrichGameOpponentFromMatchOpponent(opponent, game.opponents[opponentIndex])
		end)
		gameMatch.match2opponents = gameMatch.opponents
		gameMatch.extradata = Table.merge(gameMatch.extradata, game.extradata)
		return gameMatch
	end)

	return Array.map(Array.groupAdjacentBy(expandedGames, Operator.property('date')), function (gameGroup)
		if #gameGroup > 1 then
			local lastIndexes = gameGroup[#gameGroup].asGameIndexes
			table.insert(gameGroup[1].asGameIndexes, lastIndexes[#lastIndexes])
		end

		return gameGroup[1]
	end)
end

---@private
---@param matches table[]
---@param config MatchTickerConfig
---@return table[]
function MatchTickerController.sortMatches(matches, config)
	local reverse = config.recent and true or false
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
		return ((a.asGameIndexes or {})[1] or 0) < ((b.asGameIndexes or {})[1] or 0)
	end)
end

--- Will only switch if enteredOpponentOnLeft is enabled AND there are exactly 2 opponents
---@private
---@param match table
---@param config MatchTickerConfig
---@return table
function MatchTickerController.adjustMatch(match, config)
	if not config.enteredOpponentOnLeft or #match.opponents ~= 2 then
		return match
	end

	local opponentNames = Array.extend({config.player}, config.teamPages)
	if
		--check for the name value
		Table.includes(opponentNames, ((match.opponents[2].name or ''):gsub(' ', '_')))
		--check inside match2players too for the player value
		or config.player and Table.any(match.opponents[2].players, function(_, playerData)
			return (playerData.pageName or ''):gsub(' ', '_') == config.player end)
	then
		return MatchTickerController.switchOpponents(match)
	end

	return match
end

--- Will only switch if there are exactly 2 opponents
---@private
---@param match table
---@return table
function MatchTickerController.switchOpponents(match)
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
---@private
---@param tournamentPage string
---@return StandardTournament?
MatchTickerController.fetchTournament = FnUtil.memoize(function(tournamentPage)
	return Tournament.getTournament(tournamentPage)
end)

return MatchTickerController
