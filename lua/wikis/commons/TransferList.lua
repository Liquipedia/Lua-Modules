---
-- @Liquipedia
-- wiki=commons
-- page=Module:TransferList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate') ---@module 'commons.TeamTemplate'

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local TransferRowDisplay = Lua.import('Module:TransferRow/Display')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local HAS_PLATFORM_ICONS = Lua.moduleExists('Module:Platform/data')
local DEFAULT_VALUES = {
	sort = 'date',
	order = 'desc',
	limit = 300,
}

---@class TransferListConfig
---@field limit integer
---@field sortOrder string
---@field title string?
---@field shown boolean
---@field class string?
---@field showMissingResultsMessage boolean
---@field showTeamName boolean?
---@field conditions TransferListConditionConfig

---@class TransferListConditionConfig
---@field nationalities string[]?
---@field players string[]?
---@field roles1 string[]?
---@field roles2 string[]?
---@field teams string[]?
---@field startDate string?
---@field endDate string?
---@field date string?
---@field tournament string?
---@field positions string[]?
---@field platform string?
---@field onlyNotableTransfers boolean

---@class TransferList: BaseClass
---@field config TransferListConfig
---@field groupedTransfers transfer[][]
---@field teamConditions ConditionTree?
---@field baseConditions ConditionTree
---@field conditions string
local TransferList = Class.new(
	---@param args table
	---@return self
	function(self, args)
		self.config = self:parseArgs(args)
		return self
	end
)

---@param frame Frame
---@return Html
function TransferList.run(frame)
	local args = Arguments.getArgs(frame)
	return TransferList(args):fetch():create()
end

---@param args table
---@return TransferListConfig
function TransferList:parseArgs(args)
	local players = Logic.nilIfEmpty(Array.parseCommaSeparatedString(args.players)) or {args.player}
	local roles = Array.parseCommaSeparatedString(args.role)

	local sortOrder = args.order or DEFAULT_VALUES.order
	local objectNameSortOrder = 'asc'
	if sortOrder:lower() == 'asc' then
		objectNameSortOrder = 'desc'
	end

	return {
		limit = tonumber(args.limit) or DEFAULT_VALUES.limit,
		sortOrder = (args.sort or DEFAULT_VALUES.sort) .. ' ' .. (args.order or DEFAULT_VALUES.order) ..
			', objectname ' .. objectNameSortOrder,
		title = Logic.nilIfEmpty(args.title),
		shown = Logic.nilOr(Logic.readBoolOrNil(args.shown), true),
		class = Logic.nilIfEmpty(args.class),
		showMissingResultsMessage = Logic.readBool(args.form),
		conditions = {
			nationalities = Logic.nilIfEmpty(Array.parseCommaSeparatedString(args.nationality)),
			players = Logic.nilIfEmpty(Array.map(players, mw.ext.TeamLiquidIntegration.resolve_redirect)),
			startDate = Logic.nilIfEmpty(args.sdate),
			endDate = Logic.nilIfEmpty(args.edate),
			date = Logic.nilIfEmpty(args.date),
			roles1 = Logic.nilIfEmpty(Array.extend(roles, Array.parseCommaSeparatedString(args.role1))),
			roles2 = Logic.nilIfEmpty(Array.extend(roles, Array.parseCommaSeparatedString(args.role2))),
			positions = Logic.nilIfEmpty(Array.parseCommaSeparatedString(args.position)),
			platform = Logic.nilIfEmpty(args.platform),
			onlyNotableTransfers = Logic.readBool(args.onlyNotableTransfers),
			teams = Logic.nilIfEmpty(self:_getTeams(args)),
		}
	}
end

---@param args table
---@return string[]
function TransferList:_getTeams(args)
	local teams = Array.parseCommaSeparatedString(args.teams)
	if Logic.isEmpty(teams) then
		teams = Array.extractValues(Table.filterByKey(args, function(key)
			return key:find('^team%d*$') ~= nil
		end))
	end
	if Logic.isEmpty(teams) then
		teams = self:_getTeamsFromTournament(args.page) or {}
	end

	local teamList = {}
	Array.forEach(teams, function(team)
		if not TeamTemplate.exists(team) then
			mw.log('Missing team teamplate: ' .. team)
		end
		Array.extendWith(teamList, TeamTemplate.queryHistoricalNames(team))
	end)

	return teamList
end

---@param tournamentPage string?
---@return string[]?
function TransferList:_getTeamsFromTournament(tournamentPage)
	if Logic.isEmpty(tournamentPage) then return end
	---@cast tournamentPage -nil
	tournamentPage = tournamentPage:gsub(' ', '_')

	local placements = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = '[[pagename::' .. tournamentPage .. ']] AND '
			.. '[[opponentname::!Tbd]] AND [[opponentname::!TBD]] AND [[opponenttype::' .. Opponent.team .. ']]',
		limit = 500,
		query = 'opponentname'
	})

	if type(placements[1]) ~= 'table' then return nil end

	return Array.map(placements, Operator.property('opponentname'))
end

---@return self
function TransferList:fetch()
	self.conditions = self:_buildConditions()
	local queryData = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = self.conditions,
		limit = self.config.limit,
		order = self.config.sortOrder,
		groupby = 'date desc, toteam desc, fromteam desc, role1 desc',--role2 desc
	})

	local groupedData = {}
	Array.forEach(queryData, function(transfer)
		local transfers = mw.ext.LiquipediaDB.lpdb('transfer', {
			conditions = self:_buildConditions{
				date = transfer.date,
				fromTeam = transfer.fromteam or '',
				toTeam = transfer.toteam or '',
				roles1 = {transfer.role1},
			},
			limit = self.config.limit + 10,
			order = self.config.sortOrder,
		})
		local currentGroup
		local cache = {}
		Array.forEach(transfers, function(transf)
			if
				cache.role2 ~= transf.role2 or
				cache.team1_2 ~= transf.extradata.fromteamsec or
				cache.team2_2 ~= transf.extradata.toteamsec
			then
				cache.role2 = transf.role2
				cache.team1_2 = transfer.extradata.fromteamsec
				cache.team2_2 = transfer.extradata.toteamsec
				Array.appendWith(groupedData, currentGroup)
				currentGroup = {}
			end
			table.insert(currentGroup, transf)
		end)
		Array.appendWith(groupedData, currentGroup)
	end)

	self.groupedTransfers = groupedData

	return self
end

---@param config {date: string, fromTeam: string, toTeam: string, roles1: string[]}?
---@return string
function TransferList:_buildConditions(config)
	config = config or {}

	local conditions = self:_buildBaseConditions()
		:add(self:_buildDateCondition(config.date))
		:add(self:_buildTeamConditions(config.toTeam, config.fromTeam))
		:add(self:_buildOrConditions('role1', config.roles1 or self.config.conditions.roles1))

	return conditions:toString()
end

---@return ConditionTree
function TransferList:_buildBaseConditions()
	local config = self.config.conditions

	self.baseConditions = ConditionTree(BooleanOperator.all)
		:add(self:_buildOrConditions('player', config.players))
		:add(self:_buildOrConditions('nationality', config.nationalities))
		:add(self:_buildOrConditions('role2', config.roles2))
		:add(self:_buildOrConditions('extradata_position', config.positions))

	if config.platform then
		self.baseConditions:add{ConditionNode(ColumnName('extradata_platform'), Comparator.eq, config.platform)}
	end

	if config.onlyNotableTransfers then
		self.baseConditions:add{ConditionNode(ColumnName('extradata_notable'), Comparator.eq, '1')}
	end

	return self.baseConditions
end

---@param date string?
---@return ConditionTree?
function TransferList:_buildDateCondition(date)
	local config = self.config.conditions
	local dateConditions = ConditionTree(BooleanOperator.all)

	date = date or config.date
	if date then
		return dateConditions:add{ConditionNode(ColumnName('date'), Comparator.eq, date)}
	end

	if not config.startDate and not config.endDate then
		return nil
	end

	if config.startDate then
		dateConditions:add(ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('date'), Comparator.gt, config.startDate),
			ConditionNode(ColumnName('date'), Comparator.eq, config.startDate),
		})
	else
		dateConditions:add{ConditionNode(ColumnName('date'), Comparator.gt, DateExt.defaultDate)}
	end

	if config.endDate then
		local endDate = config.endDate .. ' 23:59:59'
		dateConditions:add(ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('date'), Comparator.lt, endDate),
			ConditionNode(ColumnName('date'), Comparator.eq, endDate),
		})
	end

	return dateConditions
end

---@param toTeam string?
---@param fromTeam string?
---@return ConditionTree?
function TransferList:_buildTeamConditions(toTeam, fromTeam)
	if toTeam then
		---if toTeam is set so is fromTeam
		---@cast fromTeam string
		return ConditionTree(BooleanOperator.all)
			:add{ConditionNode(ColumnName('fromteam'), Comparator.eq, fromTeam)}
			:add{ConditionNode(ColumnName('toteam'), Comparator.eq, toTeam)}
	end

	if self.teamConditions then return self.teamConditions end
	if Logic.isEmpty(self.config.conditions.teams) then return end

	self.teamConditions = ConditionTree(BooleanOperator.any)
		:add(self:_buildOrConditions('fromteam', self.config.conditions.teams))
		:add(self:_buildOrConditions('toteam', self.config.conditions.teams))

	return self.teamConditions
end

---@param lpdbField string
---@param data string[]
---@return ConditionTree?
function TransferList:_buildOrConditions(lpdbField, data)
	if Logic.isEmpty(data) then return nil end
	return ConditionTree(BooleanOperator.any)
		:add(Array.map(data, function(item)
			return ConditionNode(ColumnName(lpdbField), Comparator.eq, item)
		end))
end

---@return Html|string?
function TransferList:create()
	local config = self.config
	if config.showMissingResultsMessage and Logic.isDeepEmpty(self.groupedTransfers) then
		return mw.html.create('pre'):wikitext('No results for: ' .. mw.text.nowiki(self.conditions))
	elseif Logic.isDeepEmpty(self.groupedTransfers) then
		return
	end

	local display = mw.html.create('div')
		:addClass('divTable mainpage-transfer Ref')
		:css('text-align', 'center')
		:css('width', '100%')
		:node(self:_buildHeader())

	Array.forEach(self.groupedTransfers, function(rowData)
		display:node(self:_buildRow(rowData))
	end)

	if not config.title then
		-- for whatever reason currently class is only applied in this case ...
		if config.class then
			display:addClass(config.class)
		end
		return mw.html.create('div')
			:node(display)
	end

	return mw.html.create('table')
		:css('margin-top','0px')
		:addClass('wikitable OffSeasonOverview')
		:addClass(config.shown and 'collapsible collapsed' or nil)
		:tag('tr'):tag('th'):attr('colspan', 7):wikitext(config.title):allDone()
		:tag('tr'):tag('td'):css('padding', '0'):node(display):allDone()
end

---@return Html
function TransferList:_buildHeader()
	local headerRow = mw.html.create('div')
		:addClass('divHeaderRow')
		:tag('div'):addClass('divCell Date'):wikitext('Date'):allDone()

	if HAS_PLATFORM_ICONS then
		headerRow:tag('div'):addClass('divCell GameIcon')
	end

	return headerRow
		:tag('div'):addClass('divCell Name'):wikitext('Player'):done()
		:tag('div'):addClass('divCell Team OldTeam'):wikitext('Old'):done()
		:tag('div'):addClass('divCell Icon'):done()
		:tag('div'):addClass('divCell Team NewTeam'):wikitext('New'):done()
		:tag('div'):addClass('divCell Empty')
			:tag('span')
				:addClass('mobile-hide')
				:wikitext(Abbreviation.make('Ref', 'Reference'))
		:allDone()
end

---@param transfers transfer[]
---@return Html?
function TransferList:_buildRow(transfers)
	local firstTransfer = transfers[1]
	if not firstTransfer then
		return
	end

	local showRole = (firstTransfer.role1 ~= 'Substitute' and firstTransfer.role2 ~= 'Substitute') or
		firstTransfer.extradata.icontype ~= 'Substitute' or
		(Logic.isEmpty(firstTransfer.fromteam) and Logic.isEmpty(firstTransfer.toteam))

	if not showRole then
		firstTransfer.role1 = nil
		firstTransfer.role2 = nil
	end

	return TransferRowDisplay(transfers):build()
end

return TransferList
