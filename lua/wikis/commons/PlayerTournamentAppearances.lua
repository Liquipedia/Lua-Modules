---
-- @Liquipedia
-- page=Module:PlayerTournamentAppearances
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Condition = Lua.import('Module:Condition')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local Placement = Lua.import('Module:Placement')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local Table = Lua.import('Module:Table')
local Tournament = Lua.import('Module:Tournament')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local LinkWidget = Lua.import('Module:Widget/Basic/Link')
local TournamentTitle = Lua.import('Module:Widget/Tournament/Title')
local Th = HtmlWidgets.Th
local Tr = HtmlWidgets.Tr
local WidgetUtil = Lua.import('Module:Widget/Util')

local DEFAULT_TIERTYPES = {'General', 'School', ''}
local FORM_NAME = 'Player tournament appearances'

---@class PlayerTournamentAppearances: BaseClass
---@operator call(Frame): PlayerTournamentAppearances
---@field tournaments StandardTournament[]
local Appearances = Class.new(function(self, frame) self:init(frame) end)

---@param frame Frame
---@return string|Widget
function Appearances.run(frame)
	return Appearances(frame):create():build()
end

---@param frame Frame
---@return self
function Appearances:init(frame)
	local args = Arguments.getArgs(frame)

	self.plainArgs = args

	assert(
		args.series or args.pages or args.conditions,
		'Either "series", "pages" or "conditions" input has to be specified'
	)

	self.config = {
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
	self.tournaments = Array.reverse(Tournament.getAllTournaments(self.args.conditions or self:_buildConditions()))

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
		conditions:add(ConditionTree(BooleanOperator.any):add{
			ConditionUtil.anyOf(ColumnName('seriespage'), args.series),
			ConditionUtil.anyOf(ColumnName('series2', 'extradata'), args.series),
		})
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
---@return standardPlayer[]
function Appearances:_fetchPlayers(pageNames)
	---@type table<string, standardPlayer>
	local players = {}

	Lpdb.executeMassQuery('placement', {
		conditions = tostring(self:_placementConditions(pageNames)),
		limit = 1000,
		order = 'date asc',
		query = 'opponentplayers, opponenttype, opponentname, parent, date, placement, opponenttemplate',
	}, function (placement)
		local opponent = Opponent.fromLpdbStruct(placement)
		Array.forEach(opponent.players, function (player)
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

---@return string|Widget
function Appearances:build()
	if not self.players then return 'No results found.' end

	local limit = math.min(self.config.limit or #self.players, #self.players)

	return DataTable{
		classes = {'wikitable-striped'},
		sortable = true,
		css = {['margin-bottom'] = '10px'},
		tableCss = {
			['text-align'] = 'center',
			margin = 0,
		},
		children = WidgetUtil.collect(
			self:_header(),
			Array.map(Array.range(1, limit), FnUtil.curry(Appearances._row, self)),
			(self.config.restrictToPlayersParticipatingIn and not self.config.isFormQuery) and self:_buildQueryLink() or nil
		)
	}
end

---@private
---@return Widget
function Appearances:_header()
	return Tr{children = WidgetUtil.collect(
		Th{},
		Th{children = 'Player'},
		Th{children = HtmlWidgets.Abbr{children = 'TA.', title = 'Total appearances'}},
		Array.map(self.tournaments, function (tournament)
			return Th{children = TournamentTitle{
				tournament = tournament, useShortName = true
			}}
		end)
	)}
end

---@private
---@param playerIndex integer
---@return Html
function Appearances:_row(playerIndex)
	local player = self.players[playerIndex]

	local row = mw.html.create('tr')
		:tag('td'):wikitext(Flags.Icon{flag = player.flag}):done()

	row
		:tag('td'):css('text-align', 'left'):node(PlayerDisplay.InlinePlayer{
			player = player, showFlag = false
		}):done()
		:tag('td'):wikitext(player.extradata.appearances)

	Array.forEach(self.tournaments, function (tournament)
		local result = player.extradata.results[tournament.pageName]
		local cell = row:tag('td')

		if self.config.showPlacementInsteadOfTeam then
			-- Default to empty string to use data-sort-value
			Placement._placement{parent = cell, placement = (result or {}).placement or ''}
		elseif result then
			cell
				:attr('data-sort-value', result.team)
				:node(result.team and OpponentDisplay.InlineTeamContainer{
					template = result.team, date = result.date, style = 'icon'
				} or nil)

			if tonumber(result.placement) == 1 then
				cell:addClass('tournament-highlighted-bg')
			end
		end
	end)

	return row
end

---@private
---@return Widget?
function Appearances:_buildQueryLink()
	if not Page.exists('Form:' .. FORM_NAME) then
		return
	end
	local queryTable = {
		['PTA[series]'] = self.plainArgs.series or '',
		['PTA[pages]'] = table.concat(self.args.pages, ','),
		['PTA[tiers]'] = self.plainArgs.tiers,
		['PTA[limit]'] = self.plainArgs.limit or '',
		['PTA[playerspage]'] = self.plainArgs.playerspage or '',
		['PTA[query]'] = 'true',
		pfRunQueryFormName = FORM_NAME,
		wpRunQuery = 'Run query',
	}

	return Tr{children = Th{
		attributes = {colspan = #self.tournaments + 3},
		css = {['font-size'] = 'small'},
		children = LinkWidget{
			link = tostring(mw.uri.fullUrl('Special:RunQuery/' .. FORM_NAME, queryTable)),
			children = 'Click here to modify this table',
			linktype = 'external',
		}
	}}
end

return Appearances
