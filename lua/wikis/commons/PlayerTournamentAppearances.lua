local Abbreviation = require('Module:Abbreviation')
local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Condition = require('Module:Condition')
local DateExt = require('Module:Date/Ext')
local Flags = require('Module:Flags')
local LeagueIcon = require('Module:LeagueIcon')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local Operator = require('Module:Operator')
local Placement = require('Module:Placement')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')

local FACTION

local Lua = require('Module:Lua')

local Opponent = Lua.import('Module:Opponent/Custom')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local ICON_HEADER_TYPES = {'icons', 'icon'}
local DEFAULT_TIERTYPES = {'General', 'School', ''}

local Appearances = Class.new(function(self, frame) self:init(frame) end)

function Appearances.run(frame)
	return Appearances(frame):create():build()
end

function Appearances:init(frame)
	local args = Arguments.getArgs(frame)

	self.plainArgs = args

	assert(args.series or args.pages or args.conditions, 'Either "series", "pages" or "conditions" input has to be specified')

	self.config = {
		prefix = args.prefix or 'p',
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
		tierTypes = Appearances._readCommaSep(args.tierTypes) or DEFAULT_TIERTYPES,
		tiers = Appearances._readCommaSep(args.tiers),
		startDate = Logic.nilIfEmpty(args.sdate),
		endDate = Logic.nilIfEmpty(args.edate),
		pages = Appearances._readCommaSep(args.pages),
		series = args.series and
			Array.extractValues(Table.filterByKey(args, function(key) return key:find('^series%d-$') end))
			or nil,
	}

	return self
end

function Appearances._readCommaSep(input)
	return input and Array.map(mw.text.split(input, ','), String.trim)
		or nil
end

function Appearances:create()
	self.tournaments = mw.ext.LiquipediaDB.lpdb('tournament', {
			conditions = self.args.conditions or self:_buildConditions(),
			limit = 5000,
			order = 'enddate asc',
			query = 'pagename, name, shortname, icon, icondark',
	})

	if Table.isEmpty(self.tournaments) then
		return self
	end

	local pageNames = Array.map(self.tournaments, Operator.property('pagename'))
	self.players = self:_fetchPlayers(pageNames)

	return self
end

function Appearances:_buildConditions()
	local args = self.args

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('enddate'), Comparator.gt, DateExt.defaultDate)}

	Appearances._buildOrConditionsFromArray(conditions, {'finished', ''}, 'status')
	Appearances._buildOrConditionsFromArray(conditions, args.tiers, 'liquipediatier')
	Appearances._buildOrConditionsFromArray(conditions, args.tierTypes, 'liquipediatiertype')

	if Table.isNotEmpty(args.series) then
		Appearances._buildOrConditionsFromArray(conditions, args.series, 'seriespage', 'extradata_series2', true)
	else
		args.pages = Array.map(args.pages, function(page) return (page:gsub(' ', '_')) end)
		Appearances._buildOrConditionsFromArray(conditions, args.pages, 'pagename')
	end

	if args.startDate then
		conditions:add{ConditionNode(ColumnName('startdate'), Comparator.ge, args.startDate)}
	end

	if args.endDate then
		conditions:add{ConditionNode(ColumnName('enddate'), Comparator.le, args.endDate)}
	end

	return conditions:toString()
end

function Appearances:_fetchPlayers(pageNames)
	local players = {}

	Lpdb.executeMassQuery('placement', {
		conditions = self:_placementConditions(pageNames),
		limit = 1000,
		order = 'date asc',
		query = 'opponentplayers, opponenttype, pagename, date, placement, opponenttemplate',
	}, function(placement)
		for prefix, playerPage in Table.iter.pairsByPrefix(placement.opponentplayers or {}, self.config.prefix) do
			if not players[playerPage] then
				players[playerPage] = {
					link = playerPage,
					appearances = 0,
					placementSum = 0,
					results = {},
				}
			end

			players[playerPage].appearances = players[playerPage].appearances + 1
			players[playerPage].flag = Logic.emptyOr(placement.opponentplayers[prefix .. 'flag'], players[playerPage].flag)
			players[playerPage].name = Logic.emptyOr(placement.opponentplayers[prefix .. 'dn'], players[playerPage].name)
			players[playerPage].faction = Logic.emptyOr(placement.opponentplayers[prefix .. 'faction'], players[playerPage].faction)
			players[playerPage].results[placement.pagename] = {
				placement = placement.placement,
				date = placement.date,
				team = placement.opponenttype == Opponent.team and placement.opponenttemplate
					or placement.opponentplayers[prefix .. 'template']
					or placement.opponentplayers[prefix .. 'team'],
			}
			local placementParts = mw.text.split(string.lower(placement.placement or ''), '-', true)
			players[playerPage].placementSum = players[playerPage].placementSum + (tonumber(placementParts[1]) or 1000)
		end
	end)

	local playersArray = Array.extractValues(players)

	if self.config.restrictToPlayersParticipatingIn then
		playersArray = Array.filter(playersArray, function(player)
			return player.results[self.config.restrictToPlayersParticipatingIn]
		end)
	end

	table.sort(playersArray, function(a, b)
		if a.appearances ~= b.appearances then
			return a.appearances > b.appearances
		end
		if a.placementSum ~= b.placementSum then
			return a.placementSum < b.placementSum
		end
		return a.link < b.link
	end)

	return playersArray
end

function Appearances:_placementConditions(pageNames)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('opponentplayers'), Comparator.neq, '')}
		:add{ConditionNode(ColumnName('opponentplayers'), Comparator.neq, '[]')}
		:add{ConditionNode(ColumnName('opponentname'), Comparator.neq, 'TBD')}
		:add{ConditionNode(ColumnName('opponentname'), Comparator.neq, 'Definitions')}
		:add{ConditionNode(ColumnName('opponentname'), Comparator.neq, '')}
		:add{ConditionNode(ColumnName('mode'), Comparator.neq, 'award_individual')}

	Appearances._buildOrConditionsFromArray(conditions, pageNames, 'pagename')

	if self.config.restrictToFirstPrizePool then
		conditions:add{ConditionNode(ColumnName('prizepoolindex'), Comparator.eq, 1)}
	end

	return conditions:toString()
end

function Appearances._buildOrConditionsFromArray(parent, arr, key, key2, toUnderScore)
	if Table.isEmpty(arr) then return end

	local orConditions = ConditionTree(BooleanOperator.any)
	for _, value in ipairs(arr) do
		orConditions:add{ConditionNode(ColumnName(key), Comparator.eq, value)}
		if key2 then
			orConditions:add{ConditionNode(ColumnName(key2), Comparator.eq, value)}
		end
		local underScoreValue = value:gsub(' ', '_')
		if toUnderScore then
			orConditions:add{ConditionNode(ColumnName(key), Comparator.eq, underScoreValue)}
		end
		if key2 and toUnderScore then
			orConditions:add{ConditionNode(ColumnName(key2), Comparator.eq, underScoreValue)}
		end
	end

	parent:add(orConditions)
end

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

function Appearances:_header()
	local header = mw.html.create('tr')
		:tag('th'):done()

	if self.config.displayFactionColumn then
		FACTION = require('Module:Faction')
		header:tag('th')
	end

	header
		:tag('th'):wikitext('Player'):done()
		:tag('th'):wikitext(Abbreviation.make{text = 'TA.', title = 'Total appearances'})

	for _, tournament in ipairs(self.tournaments) do
		if self.config.displayIconInsteadOfShortName then
			header:tag('th'):node(LeagueIcon.display{
				icon = tournament.icon,
				iconDark = tournament.icondark,
				link = tournament.pagename,
				name = tournament.name,
				options = {noTemplate = true},
			})
		else
			header:tag('th'):wikitext('[[' .. tournament.pagename .. '|' .. Logic.emptyOr(
				tournament.shortname,
				tournament.name,
				(tournament.pagename:gsub('_', ' '))
			) .. ']]')
		end
	end

	return header
end

function Appearances:_row(playerIndex)
	local player = self.players[playerIndex]

	local row = mw.html.create('tr')
		:tag('td'):wikitext(Flags.Icon{flag = player.flag}):done()

	if self.config.displayFactionColumn then
		row:tag('td'):wikitext(FACTION.Icon{faction = player.faction})
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

function Appearances:_toQuerySubTable(queryTable, key)
	local prefix = 'PTAdev[' .. key .. ']'
	for index, value in ipairs(self.args[key] or {''}) do
		queryTable[prefix .. '[' .. index .. ']'] = value
	end
end

return Appearances
