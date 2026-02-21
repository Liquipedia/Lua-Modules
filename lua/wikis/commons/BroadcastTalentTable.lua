---
-- @Liquipedia
-- page=Module:BroadcastTalentTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Game = Lua.import('Module:Game')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Namespace = Lua.import('Module:Namespace')
local Operator = Lua.import('Module:Operator')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tournament = Lua.import('Module:Tournament')

local Tier = Lua.import('Module:Tier/Custom')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local DEFAULT_LIMIT = 500
local DEFAULT_ACHIEVEMENTS_LIMIT = 10
local NONBREAKING_SPACE = '&nbsp;'
local DASH = '&#8211;'
local DEFAULT_ABOUT_LINK = 'Template:Weight/doc'
local ACHIEVEMENTS_SORT_ORDER = 'weight desc, date desc'
local ACHIEVEMENTS_IGNORED_STATUSES = {'cancelled', 'postponed'}
local RESULTS_SORT_ORDER = 'date desc'

---@class EnrichedBroadcast
---@field date string
---@field pagename string
---@field parent string
---@field position string
---@field positions string[]
---@field language string
---@field extradata table

---@class BroadcastTalentTable: BaseClass
---@operator call(table): BroadcastTalentTable
---@field broadcaster string?
---@field aliases string[]
local BroadcastTalentTable = Class.new(function(self, args) self:init(args) end)

---@class BroadcastTalentTableArgs
---@field broadcaster string?
---@field aliases string?
---@field showtiertype string|boolean|nil
---@field year number|string|nil
---@field sdate string?
---@field edate string?
---@field achievements string|boolean|nil
---@field displayGameIcon string|boolean|nil
---@field useTickerNames string|boolean|nil
---@field limit string|number|nil
---@field aboutAchievementsLink string?
---@field onlyHighlightOnValue string?
---@field displayPartnerLists string|boolean|nil

--- Init function for BroadcastTalentTable
---@param args BroadcastTalentTableArgs
---@return self
function BroadcastTalentTable:init(args)
	self:_readArgs(args)

	if self.broadcaster then
		self.tournaments = self:_fetchTournaments()
	end

	return self
end

-- template entry point
---@param frame Frame
---@return Html?
function BroadcastTalentTable.run(frame)
	return BroadcastTalentTable(Arguments.getArgs(frame)):create()
end

---@private
---@param args BroadcastTalentTableArgs
function BroadcastTalentTable:_readArgs(args)
	local isAchievementsTable = Logic.readBool(args.achievements)

	self.args = {
		aboutAchievementsLink = Logic.emptyOr(args.aboutAchievementsLink, DEFAULT_ABOUT_LINK),
		showTierType = Logic.nilOr(Logic.readBoolOrNil(args.showtiertype), true),
		displayGameIcon = Logic.readBool(args.displayGameIcon),
		useTickerNames = Logic.readBool(args.useTickerNames),
		isAchievementsTable = isAchievementsTable,
		year = tonumber(args.year),
		startDate = args.sdate,
		endDate = args.edate,
		limit = tonumber(args.limit) or (isAchievementsTable and DEFAULT_ACHIEVEMENTS_LIMIT) or DEFAULT_LIMIT,
		sortBy = isAchievementsTable and ACHIEVEMENTS_SORT_ORDER or RESULTS_SORT_ORDER,
		onlyHighlightOnValue = args.onlyHighlightOnValue,
		displayPartnerListColumn = Logic.nilOr(Logic.readBoolOrNil(args.displayPartnerLists), true)
	}

	local broadcaster = String.isNotEmpty(args.broadcaster) and args.broadcaster or self:_getBroadcaster()
	self.broadcaster = Page.pageifyLink(broadcaster)

	self.aliases = Array.map(Array.parseCommaSeparatedString(args.aliases), Page.pageifyLink)
	Array.appendWith(self.aliases, self.broadcaster)
end

---@private
---@return string?
function BroadcastTalentTable:_getBroadcaster()
	local title = mw.title.getCurrentTitle()

	if not Namespace.isMain() then
		return
	end

	return title.baseText
end

---@private
---@return table<string, EnrichedBroadcast[]>?
function BroadcastTalentTable:_fetchTournaments()
	local args = self.args

	local conditions = ConditionTree(BooleanOperator.all)

	conditions:add(ConditionUtil.anyOf(ColumnName('page'), self.aliases))

	if args.year then
		conditions:add(ConditionNode(ColumnName('date_year'), Comparator.eq, args.year))
	else
		-- mirrors current implementation
		-- should we change it to use <= instead of < ? (same for >)
		if args.startDate then
			conditions:add(ConditionNode(ColumnName('date'), Comparator.gt, args.startDate))
		end
		if args.endDate then
			conditions:add(ConditionNode(ColumnName('date'), Comparator.lt, args.endDate))
		end
	end

	if args.isAchievementsTable then
		conditions:add(ConditionUtil.noneOf(ColumnName('extradata_status'), ACHIEVEMENTS_IGNORED_STATUSES))
	end

	---@type EnrichedBroadcast[]
	local tournaments = {}

	---@type table<string, EnrichedBroadcast>
	local pageNames = {}

	Lpdb.executeMassQuery('broadcasters', {
		query = 'pagename, parent, date, extradata, language, position',
		conditions = conditions:toString(),
		order = args.sortBy,
	}, function (record)
		if #tournaments == args.limit then
			return false
		end
		---@cast record EnrichedBroadcast
		record.extradata = record.extradata or {}
		if not pageNames[record.pagename] or Logic.readBool(record.extradata.showmatch) then
			record.positions = {record.position}
			table.insert(tournaments, record)
			if not Logic.readBool(record.extradata.showmatch) then
				pageNames[record.pagename] = record
			end
		else
			table.insert(pageNames[record.pagename].positions, record.position)
		end
	end)

	if Logic.isEmpty(tournaments) then
		return
	end

	if args.isAchievementsTable then
		table.sort(tournaments, function(item1, item2)
			return item1.date == item2.date and item1.pagename < item2.pagename or item1.date > item2.date
		end)
		return {[''] = tournaments}
	end

	local _, tournamentsByYear = Array.groupBy(tournaments, function(tournament) return tournament.date:sub(1, 4) end)

	return tournamentsByYear
end

--- Creates the display
---@return Html?
function BroadcastTalentTable:create()
	if not self.tournaments then
		return
	end

	local display = mw.html.create('table')
		:addClass('wikitable wikitable-striped sortable')
		:css('text-align', 'center')
		:node(self:_header())

	for seperatorTitle, sectionData in Table.iter.spairs(self.tournaments, function (_, key1, key2)
		return tonumber(key1) > tonumber(key2) end) do

		if String.isNotEmpty(seperatorTitle) then
			display:node(BroadcastTalentTable._seperator(seperatorTitle))
		end

		for _, tournament in ipairs(sectionData) do
			display:node(self:_row(tournament))
		end
	end

	if self.args.isAchievementsTable then
		display:node(self:_footer())
	end

	return mw.html.create('div')
		:addClass('table-responsive')
		:node(display)
end

---@private
---@return Html
function BroadcastTalentTable:_header()
	local header = mw.html.create('tr')
		:tag('th'):wikitext('Date'):css('width', '120px'):done()
		:tag('th'):wikitext('Tier'):css('width', '50px'):done()
		:tag('th'):wikitext('Tournament')
			:attr('colspan', self.args.displayGameIcon and 3 or 2)
			:css('width', self.args.displayGameIcon and '350px' or '300px'):done()
		:tag('th'):wikitext('Position'):css('width', '130px'):done()

	if not self.args.displayPartnerListColumn then
		return header
	end

	return header:tag('th'):wikitext('Partner List'):css('width', '160px'):done()
end

---@private
---@param seperatorTitle string|number
---@return Html
function BroadcastTalentTable._seperator(seperatorTitle)
	return mw.html.create('tr'):addClass('sortbottom'):css('font-weight', 'bold')
		:tag('td'):attr('colspan', 42):wikitext(seperatorTitle):done()
end

---@private
---@param broadcast EnrichedBroadcast
---@return Html
function BroadcastTalentTable:_row(broadcast)
	local row = mw.html.create('tr')

	local tournament = Tournament.getTournament(broadcast.parent)
	---@cast tournament -nil

	if tournament:isHighlighted(self.args) then
		row:addClass('tournament-highlighted-bg')
	end

	local tierDisplay = Tier.display(tournament.liquipediaTier, tournament.liquipediaTierType, Table.merge(
		tournament.tierOptions,
		{
			link = true,
			shortIfBoth = true,
			onlyTierTypeIfBoth = self.args.showTierType and String.isNotEmpty(tournament.liquipediaTierType)
		}
	))
	local tierSortValue = Tier.toSortValue(tournament.liquipediaTier, tournament.liquipediaTierType)

	row
		:tag('td'):wikitext(broadcast.date):done()
		:tag('td'):wikitext(tierDisplay):attr('data-sort-value', tierSortValue):done()

	if self.args.displayGameIcon then
		row:tag('td'):node(Game.icon{game = tournament.game})
	end

	row
		:tag('td'):wikitext(LeagueIcon.display{
			icon = tournament.icon,
			iconDark = tournament.iconDark,
			series = tournament.series,
			date = broadcast.date,
			link = tournament.pageName,
			name = tournament.fullName,
		}):done()
		:tag('td'):css('text-align', 'left'):wikitext(Page.makeInternalLink({},
			self:_tournamentDisplayName(broadcast, tournament),
			tournament.pageName
		)):done()
		:tag('td'):wikitext(table.concat(broadcast.positions, '<br>')):done()

	if not self.args.displayPartnerListColumn then
		return row
	end

	return row:tag('td'):node(self:_partnerList(broadcast)):done()
end

---@private
---@param broadcast EnrichedBroadcast
---@param tournament StandardTournament
---@return string
function BroadcastTalentTable:_tournamentDisplayName(broadcast, tournament)
	local extradata = broadcast.extradata or {}
	if Logic.readBool(extradata.showmatch) and String.isNotEmpty(extradata.showmatchname) then
		return extradata.showmatchname
	end

	local displayName = self.args.useTickerNames and tournament.displayName or tournament.fullName

	if not Logic.readBool(extradata.showmatch) then
		return displayName
	end

	return displayName .. ' - Showmatch'
end

---@private
---@param tournament table
---@return Html|string
function BroadcastTalentTable:_partnerList(tournament)
	local partners = self:_getPartners(tournament)

	if Table.isEmpty(partners) then
		return DASH
	end

	partners = BroadcastTalentTable._removeDuplicatePartners(partners)
	Array.sortInPlaceBy(partners, Operator.property('page'))

	local list = mw.html.create('ul')
	for _, partner in ipairs(partners) do
		list:tag('li'):wikitext(Flags.Icon{flag = partner.flag} .. NONBREAKING_SPACE
			.. Page.makeInternalLink({}, partner.id, partner.page))
	end

	return mw.html.create('div')
		:addClass('NavFrame collapsible broadcast-talent-partner-list-frame collapsed')
		:tag('div'):addClass('NavHead'):addClass('transparent-bg'):done()
		:tag('div'):addClass('NavContent broadcast-talent-partner-list'):node(list):done()
end

---@private
---@param broadcast EnrichedBroadcast
---@return {id: string, page: string, flag: string}[]
function BroadcastTalentTable:_getPartners(broadcast)
	local conditions = ConditionTree(BooleanOperator.all):add(
		ConditionNode(ColumnName('parent'), Comparator.eq, broadcast.parent)
	)

	conditions:add(ConditionUtil.anyOf(ColumnName('position'), broadcast.positions))

	conditions:add(ConditionUtil.noneOf(ColumnName('page'), self.aliases))

	if String.isNotEmpty(broadcast.language) then
		conditions:add(ConditionNode(ColumnName('language'), Comparator.eq, broadcast.language))
	end

	local extradata = broadcast.extradata or {}
	if Logic.readBool(extradata.showmatch) then
		conditions:add(ConditionNode(ColumnName('extradata_showmatch'), Comparator.eq, 'true'))
		if String.isNotEmpty(extradata.showmatchname) then
			conditions:add(ConditionNode(ColumnName('extradata_showmatchname'), Comparator.eq, extradata.showmatchname))
		end
	end

	return mw.ext.LiquipediaDB.lpdb('broadcasters', {
		query = 'id, page, flag',
		conditions = tostring(conditions),
	})
end

---@private
---@param partners table
---@return {id: string, page: string, flag: string}[]
function BroadcastTalentTable._removeDuplicatePartners(partners)
	local uniquePartners = Table.map(partners, function(_, partner) return partner.page, partner end)

	return Array.extractValues(uniquePartners)
end

---@private
---@return Html
function BroadcastTalentTable:_footer()
	local footer = mw.html.create('small')
		:tag('span')
			:css('float', 'left'):css('padding-left', '20px'):css('font-style', 'italic')
			:wikitext(Page.makeInternalLink({}, 'About achievements', self.args.aboutAchievementsLink))
			:done()
		:tag('b')
			:wikitext(Page.makeInternalLink({},
				'Broadcasts from any Tournament',
				self.broadcaster .. '/Broadcasts#Detailed Broadcasts'
			)):done()
		:done()

	return mw.html.create('tr')
		:tag('th'):attr('colspan', 42)
		:node(footer)
end

return BroadcastTalentTable
