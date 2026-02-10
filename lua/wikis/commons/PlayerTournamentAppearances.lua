---
-- @Liquipedia
-- page=Module:PlayerTournamentAppearances
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Condition = Lua.import('Module:Condition')
local DateExt = Lua.import('Module:Date/Ext')
local Faction = Lua.import('Module:Faction')
local Flags = Lua.import('Module:Flags')
local FnUtil = Lua.import('Module:FnUtil')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local Page = Lua.import('Module:Page')
local Placement = Lua.import('Module:Placement')
local Table = Lua.import('Module:Table')
local Team = Lua.import('Module:Team')
local Tournament = Lua.import('Module:Tournament')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local TournamentTitle = Lua.import('Module:Widget/Tournament/Title')

local ICON_HEADER_TYPES = {'icons', 'icon'}
local DEFAULT_TIERTYPES = {'General', 'School', ''}

---@class PlayerTournamentAppearances: BaseClass
---@operator call(Frame): PlayerTournamentAppearances
---@field tournaments StandardTournament[]
local Appearances = Class.new(function(self, frame) self:init(frame) end)

---@param frame Frame
---@return string|Html
function Appearances.run(frame)
	return Appearances(frame):create():build()
end

---@param frame Frame
---@return self
function Appearances:init(frame)
	local args = Arguments.getArgs(frame)

	self.plainArgs = args

	assert(args.series or args.pages or args.conditions, 'Either "series", "pages" or "conditions" input has to be specified')

	self.config = {
		displayIconInsteadOfShortName = Table.includes(ICON_HEADER_TYPES, args.headerType),
		displayFactionColumn = Logic.readBool(args.displayFactionColumn),
		showPlacementInsteadOfTeam = Logic.readBool(args.showPlacementInsteadOfTeam),
		limit = tonumber(args.limit),
		isFormQuery = Logic.readBool(args.query),
		restrictToPlayersParticipatingIn = args.playerspage,
		restrictToFirstPrizePool = Logic.readBool(args.restrictToFirstPrizePool),
	}

	self.args = {
		conditions = args.conditions,
		tierTypes = Logic.emptyOr(Array.parseCommaSeparatedString(args.tierTypes), DEFAULT_TIERTYPES),
		tiers = Array.parseCommaSeparatedString(args.tiers),
		startDate = Logic.nilIfEmpty(args.sdate),
		endDate = Logic.nilIfEmpty(args.edate),
		pages = Array.parseCommaSeparatedString(args.pages),
		series = args.series and Array.map(
			Array.extractValues(Table.filterByKey(args, function(key) return key:find('^series%d-$') end)),
			Page.pageifyLink
		) or nil,
	}

	return self
end

---@return self
function Appearances:create()
	self.tournaments = Tournament.getAllTournaments(self.args.conditions or self:_buildConditions())

	if Table.isEmpty(self.tournaments) then
		return self
	end

	local pageNames = Array.map(self.tournaments, Operator.property('pageName'))
	self.players = self:_fetchPlayers(pageNames)

	return self
end

---@private
---@return ConditionTree
function Appearances:_buildConditions()
	local args = self.args

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('enddate'), Comparator.gt, DateExt.defaultDate)}

	conditions:add(ConditionUtil.anyOf(ColumnName('status'), {'finished', ''}))
	conditions:add(ConditionUtil.anyOf(ColumnName('liquipediatier'), args.tiers))
	conditions:add(ConditionUtil.anyOf(ColumnName('liquipediatiertype'), args.tierTypes))

	if Table.isNotEmpty(args.series) then
		conditions:add{
			ConditionUtil.anyOf(ColumnName('seriespage'), args.series),
			ConditionUtil.anyOf(ColumnName('series2', 'extradata'), args.series),
		}
	else
		conditions:add(ConditionUtil.anyOf(ColumnName('pagename'), Array.map(args.pages, Page.pageifyLink)))
	end

	if args.startDate then
		conditions:add(ConditionNode(ColumnName('startdate'), Comparator.ge, args.startDate))
	end

	if args.endDate then
		conditions:add(ConditionNode(ColumnName('enddate'), Comparator.le, args.endDate))
	end

	return conditions
end

---@private
---@param pageNames string[]
---@return table[]
function Appearances:_fetchPlayers(pageNames)
	---@type table<string, standardPlayer>
	local players = {}

	Lpdb.executeMassQuery('placement', {
		conditions = self:_placementConditions(pageNames),
		limit = 1000,
		order = 'date asc',
		query = 'opponentplayers, opponenttype, opponentname, parent, date, placement, opponenttemplate',
	}, function(placement)
		local opponent = Opponent.fromLpdbStruct(placement)
		Array.forEach(opponent.players, function (player, playerIndex)
			if Opponent.playerIsTbd(player) then
				return
			end
			local pageName = player.pageName
			---@cast pageName -nil
			if not players[pageName] then
				players[pageName] = player
				player.extradata = player.extradata or {}
				player.extradata.appearances = 0
				player.extradata.placementSum = 0
				player.extradata.results = {}
			end

			local extradata = players[pageName].extradata --[[ @as table ]]

			extradata.appearances = extradata.appearances + 1
			extradata.results[placement.parent] = {
				placement = placement.placement,
				date = placement.date,
				team = placement.opponenttype == Opponent.team and placement.opponenttemplate or player.team
			}
			local rawPlacement = Placement.raw(placement.placement)
			extradata.placementSum = extradata.placementSum + (tonumber(rawPlacement.placement[1]) or 1000)
		end)
	end)

	local playersArray = Array.extractValues(players)

	if self.config.restrictToPlayersParticipatingIn then
		playersArray = Array.filter(playersArray, function(player)
			return player.extradata.results[self.config.restrictToPlayersParticipatingIn]
		end)
	end

	return Array.sortBy(
		playersArray,
		FnUtil.identity,
		---@param a standardPlayer
		---@param b standardPlayer
		---@return boolean
		function (a, b)
			local aData = a.extradata or {}
			local bData = b.extradata or {}
			if aData.appearances ~= bData.appearances then
				return aData.appearances > bData.appearances
			elseif aData.placementSum ~= bData.placementSum then
				return aData.placementSum < bData.placementSum
			end
			return a.pageName < b.pageName
		end
	)
end

---@private
---@param pageNames string[]
---@return ConditionTree
function Appearances:_placementConditions(pageNames)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionUtil.noneOf(ColumnName('opponentplayers'), {'', '[]'}),
		ConditionUtil.noneOf(ColumnName('opponentname'), {'TBD', 'Definitions', ''}),
		ConditionNode(ColumnName('mode'), Comparator.neq, 'award_individual'),
		ConditionUtil.anyOf(ColumnName('parent'), pageNames)
	}

	if self.config.restrictToFirstPrizePool then
		conditions:add(ConditionNode(ColumnName('prizepoolindex'), Comparator.eq, 1))
	end

	return conditions
end

---@return string|Html
function Appearances:build()
	if not self.players then return 'No results found.' end

	local display = mw.html.create('table')
		:addClass('wikitable sortable wikitable-striped')
		:css('text-align', 'center')
		:css('margin', '0')
		:node(self:_header())

	local limit = math.min(self.config.limit or #self.players, #self.players)

	for playerIndex = 1, limit do
		display:node(self:_row(playerIndex))
	end

	if self.config.restrictToPlayersParticipatingIn and not self.config.isFormQuery then
		display:node(self:_buildQueryLink())
	end

	return mw.html.create('div')
		:addClass('table-responsive')
		:css('margin-bottom', '10px')
		:node(display)
end

---@private
---@return Html
function Appearances:_header()
	local header = mw.html.create('tr')
		:tag('th'):done()

	if self.config.displayFactionColumn then
		header:tag('th')
	end

	header
		:tag('th'):wikitext('Player'):done()
		:tag('th'):wikitext(Abbreviation.make{text = 'TA.', title = 'Total appearances'})

	for _, tournament in ipairs(self.tournaments) do
		header:tag('th'):node(TournamentTitle{tournament = tournament})
	end

	return header
end

---@private
---@param playerIndex integer
---@return Html
function Appearances:_row(playerIndex)
	local player = self.players[playerIndex]

	local row = mw.html.create('tr')
		:tag('td'):wikitext(Flags.Icon{flag = player.flag}):done()

	if self.config.displayFactionColumn then
		row:tag('td'):wikitext(Faction.Icon{faction = player.faction})
	end

	row
		:tag('td'):css('text-align', 'left'):wikitext('[[' .. player.link .. '|' .. player.name .. ']]'):done()
		:tag('td'):wikitext(player.appearances)

	for _, tournament in ipairs(self.tournaments) do
		local result = player.results[tournament.pagename]
		local cell = row:tag('td')

		if self.config.showPlacementInsteadOfTeam then
			-- Default to empty string to use data-sort-value
			Placement._placement{parent = cell, placement = (result or {}).placement or ''}
		elseif result then
			cell
				:attr('data-sort-value', result.team)
				:wikitext(result.team and Team.icon(nil, result.team, result.date) or nil)

			if tonumber(result.placement) == 1 then
				cell:addClass('tournament-highlighted-bg')
			end
		end
	end

	return row
end

---@private
---@return Html
function Appearances:_buildQueryLink()
	local queryTable = {
		['PTAdev[series]'] = self.plainArgs.series or '',
		['PTAdev[pages]'] = self.plainArgs.pages or '',
		['PTAdev[tiers]'] = self.plainArgs.tiers or '',
		['PTAdev[limit]'] = self.plainArgs.limit or '',
		['PTAdev[playerspage]'] = self.plainArgs.playerspage or '',
		['PTAdev[query]'] = 'true',
	}

	self:_toQuerySubTable(queryTable, 'pages')
	self:_toQuerySubTable(queryTable, 'tiers')

	local queryString = tostring(mw.uri.fullUrl('Special:RunQuery/Player_tournament_appearances')) .. '?pfRunQueryFormName=Player+tournament+appearances&' .. mw.uri.buildQueryString(queryTable) .. '&wpRunQuery=Run+query'

	return mw.html.create('tr')
		:tag('th')
			:attr('colspan', #self.tournaments + 3 + (self.config.displayFactionColumn and 1 or 0))
			:css('font-size', 'small')
			:wikitext('[' .. queryString .. ' Click here to modify this table]')
			:done()
end

---@private
---@param queryTable table
---@param key string
function Appearances:_toQuerySubTable(queryTable, key)
	local prefix = 'PTAdev[' .. key .. ']'
	for index, value in ipairs(self.args[key] or {''}) do
		queryTable[prefix .. '[' .. index .. ']'] = value
	end
end

return Appearances
