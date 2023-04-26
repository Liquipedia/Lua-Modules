---
-- @Liquipedia
-- wiki=commons
-- page=Module:BroadcastTalentTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Game = require('Module:Game')
local HighlightConditions = require('Module:HighlightConditions')
local LeagueIcon = require('Module:LeagueIcon')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Custom')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local DEFAULT_LIMIT = 500
local DEFAULT_ACHIEVEMENTS_LIMIT = 10
local NONBREAKING_SPACE = '&nbsp;'
local DEFAULT_TIERTYPE = 'General'
local DEFAULT_ABOUT_LINK = 'Template:Weight/doc'
local ACHIEVEMENTS_SORT_ORDER = 'weight desc, date desc'
local RESULTS_SORT_ORDER = 'date desc'

--- @class BroadcastTalentTable
local BroadcastTalentTable = Class.new(function(self, ...) self:init(...) end)

--- Init function for BroadcastTalentTable
---@param args {
---		broadcaster: string?,
---		aliases: string?,
---		showtiertype: string|boolean|nil,
---		year: number|string|nil,
---		sdate: string?,
---		edate: string?,
---		achievements: string|boolean|nil,
---		displayGameIcon: string|boolean|nil,
---		limit: string|number|nil,
---		aboutAchievementsLink: string|boolean|nil,
---		onlyHighlightOnValue: string?,
---		displayPartnerLists: string|boolean|nil,
---}
---@return string?
function BroadcastTalentTable:init(args)
	self:_readArgs(args)

	if self.broadcaster then
		self.tournaments = self:_fetchTournaments()
	end

	return self
end

-- template entry point
function BroadcastTalentTable.run(frame)
	return BroadcastTalentTable(Arguments.getArgs(frame)):create()
end

function BroadcastTalentTable:_readArgs(args)
	local isAchievementsTable = Logic.readBool(args.achievements)

	self.args = {
		aboutAchievementsLink = args.aboutAchievementsLink or DEFAULT_ABOUT_LINK,
		showTierType = Logic.nilOr(Logic.readBoolOrNil(args.showtiertype), true),
		displayGameIcon = Logic.readBool(args.displayGameIcon),
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
	self.broadcaster = mw.ext.TeamLiquidIntegration.resolve_redirect(broadcaster):gsub(' ', '_')

	self.aliases = args.aliases and Array.map(mw.text.split(args.aliases:gsub(' ', '_'), ','), String.trim) or {}
	table.insert(self.aliases, self.broadcaster)
end

function BroadcastTalentTable:_getBroadcaster()
	local title = mw.title.getCurrentTitle()

	if not Namespace.isMain() then
		return
	end

	return title.baseText
end

function BroadcastTalentTable:_fetchTournaments()
	local args = self.args

	local conditions = ConditionTree(BooleanOperator.all)

	local broadCasterConditions = ConditionTree(BooleanOperator.any)
	for _, broadcaster in pairs(self.aliases) do
		broadCasterConditions:add{ConditionNode(ColumnName('page'), Comparator.eq, broadcaster)}
	end
	conditions:add(broadCasterConditions)

	if args.year then
		conditions:add{ConditionNode(ColumnName('date_year'), Comparator.eq, args.year)}
	else
		-- mirrors current implementation
		-- should we change it to use <= instead of < ? (same for >)
		if args.startDate then
			conditions:add{ConditionNode(ColumnName('date'), Comparator.gt, args.startDate)}
		end
		if args.endDate then
			conditions:add{ConditionNode(ColumnName('date'), Comparator.lt, args.endDate)}
		end
	end

	-- double the limit for the query due to potentional merging of results further down the line
	local queryLimit = args.limit * 2

	local queryData = mw.ext.LiquipediaDB.lpdb('broadcasters', {
		query = 'pagename, parent, date, extradata, language, position',
		conditions = conditions:toString(),
		order = args.sortBy,
		limit = queryLimit,
	})

	if not queryData[1] then
		return
	end

	local tournaments = {}
	local pageNames = {}
	for _, tournament in pairs(queryData) do
		if not pageNames[tournament.pagename] then
			tournament.positions = {tournament.position}
			table.insert(tournaments, tournament)
			pageNames[tournament.pagename] = tournament
		else
			table.insert(pageNames[tournament.pagename].positions, tournament.position)
		end
	end

	tournaments = Array.sub(tournaments, 1, args.limit)

	if args.isAchievementsTable then
		table.sort(tournaments, function(item1, item2)
			return item1.date == item2.date and item1.pagename < item2.pagename or item1.date < item2.date
		end)
		return {[''] = tournaments}
	end

	local _
	_, tournaments = Array.groupBy(tournaments, function(tournament) return tournament.date:sub(1, 4) end)

	return tournaments
end

--- Creates the display
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

function BroadcastTalentTable._seperator(seperatorTitle)
	return mw.html.create('tr'):addClass('sortbottom'):css('font-weight', 'bold')
		:tag('td'):attr('colspan', 42):wikitext(seperatorTitle):done()
end

function BroadcastTalentTable:_row(tournament)
	local row = mw.html.create('tr')

	tournament = BroadcastTalentTable._fetchTournamentData(tournament)

	if HighlightConditions.tournament(tournament, self.args) then
		row:addClass('tournament-highlighted-bg')
	end

	row
		:tag('td'):wikitext(tournament.date):done()
		:tag('td'):wikitext(self:_tierDisplay(tournament)):done()

	if self.args.displayGameIcon then
		row:tag('td'):node(Game.icon{game = tournament.game})
	end

	row
		:tag('td'):wikitext(LeagueIcon.display{
			icon = tournament.icon,
			iconDark = tournament.icondark,
			series = tournament.series,
			date = tournament.date,
			link = tournament.pagename,
			name = tournament.name,
		}):done()
		:tag('td'):css('text-align', 'left'):wikitext(Page.makeInternalLink({},
			BroadcastTalentTable._tournamentDisplayName(tournament),
			tournament.pagename
		)):done()
		:tag('td'):wikitext(table.concat(tournament.positions, '<br>')):done()

	if not self.args.displayPartnerListColumn then
		return row
	end

	return row:tag('td'):node(self:_partnerList(tournament)):done()
end

function BroadcastTalentTable._fetchTournamentData(tournament)
	local queryData = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. tournament.parent .. ']]',
		query = 'name, tickername, icon, icondark, series, game, '
			.. 'liquipediatier, liquipediatiertype, publishertier, extradata',
	})

	if type(queryData[1]) ~= 'table' then
		return tournament
	end

	queryData[1].tournamentExtradata = queryData[1].extradata

	return Table.merge(queryData[1], tournament)
end

function BroadcastTalentTable._tournamentDisplayName(tournament)
	local extradata = tournament.extradata or {}
	if Logic.readBool(extradata.showmatch) and String.isNotEmpty(extradata.showmatchname) then
		return extradata.showmatchname
	end

	local displayName = String.isNotEmpty(tournament.tickername) and tournament.tickername
		or String.isNotEmpty(tournament.name) and tournament.name
		or tournament.parent:gsub('_', ' ')

	if not Logic.readBool(extradata.showmatch) then
		return displayName
	end

	return displayName .. ' - Showmatch'
end

function BroadcastTalentTable:_tierDisplay(tournament)
	if Logic.readBool((tournament.extradata or {}).showmatch) then
		return 'Showmatch'
	end

	local tier, tierType, options = Tier.parseFromQueryData(tournament)
	options.link = true
	options.shortIfBoth = true
	options.onlyTierTypeIfBoth = self.args.showTierType and tournament.liquipediatiertype ~= DEFAULT_TIERTYPE

	return Tier.display(tier, tierType, options)
end

function BroadcastTalentTable:_partnerList(tournament)
	local partners = self:_getPartners(tournament)

	if Table.isEmpty(partners) then
		return 'None'
	end

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

function BroadcastTalentTable:_getPartners(tournament)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('parent'), Comparator.eq, tournament.parent),
		}

	local positionConditions = ConditionTree(BooleanOperator.any)
	for _, position in pairs(tournament.positions) do
		positionConditions:add{ConditionNode(ColumnName('position'), Comparator.eq, position)}
	end
	conditions:add(positionConditions)

	for _, caster in pairs(self.aliases) do
		conditions:add{ConditionNode(ColumnName('page'), Comparator.neq, caster)}
	end

	if String.isNotEmpty(tournament.language) then
		conditions:add{ConditionNode(ColumnName('language'), Comparator.eq, tournament.language)}
	end

	local extradata = tournament.extradata or {}
	if Logic.readBool(extradata.showmatch) then
		conditions:add{ConditionNode(ColumnName('extradata_showmatch'), Comparator.eq, 'true')}
		if String.isNotEmpty(extradata.showmatchname) then
			conditions:add{ConditionNode(ColumnName('extradata_showmatchname'), Comparator.eq, extradata.showmatchname)}
		end
	end

	return mw.ext.LiquipediaDB.lpdb('broadcasters', {
		query = 'id, page, flag',
		conditions = conditions:toString(),
		groupBy = 'page asc',
	})
end

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
