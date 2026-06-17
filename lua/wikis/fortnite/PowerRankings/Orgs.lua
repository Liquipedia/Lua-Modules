---
-- @Liquipedia
-- page=Module:PowerRankings/Orgs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local Icon = Lua.import('Module:Icon')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local HtmlWidgets = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local PowerRankingsData = Lua.import('Module:PowerRankings/Data', {loadData = true})
local DISPLAY_PAGE = 'Fortnite Power Rankings/Organizations'
local TOP_N = 200
local MAX_PLAYERS_PER_ORG = 4
local DEFAULT_WEIGHTS = {count = 0.12, pr = 0.35, cash = 0.45}

---@class FortniteRankingsPlayer: standardPlayer
---@field rank integer
---@field points number

---@class FortniteRankingsTeam
---@field team string
---@field pageName string
---@field count integer
---@field score number
---@field earnings number
---@field average number
---@field achievements string[]
---@field players FortniteRankingsPlayer[]
---@field rank integer
---@field flag string?
---@field countRank integer?
---@field averageRank integer?
---@field earningsRank integer?


local PowerRankingsOrgs = {}

---@param frame Frame
---@return Renderable
function PowerRankingsOrgs.main(frame)
	local args = Arguments.getArgs(frame)

	local config = {
		limit = tonumber(args.limit),
		showMore = Logic.readBool(args.showMore),
		wrapped = Logic.readBool(args.wrapped),
		year = tonumber(args.year) or DateExt.getYearOf(),
		weights = {
			count = tonumber(args.wCount) or DEFAULT_WEIGHTS.count,
			pr = tonumber(args.wPR) or DEFAULT_WEIGHTS.pr,
			cash = tonumber(args.wCash) or DEFAULT_WEIGHTS.cash,
		},
		updated = Logic.isNotEmpty(PowerRankingsData.updated)
			and PowerRankingsData.updated .. ' ' .. DateExt.defaultTimezone
			or nil,
	}
	config.weightSum = config.weights.count + config.weights.pr + config.weights.cash

	---@type FortniteRankingsPlayer[]
	local players = Array.map(PowerRankingsData.players or {}, function(player)
		local rank = tonumber(player.rank)
		if not rank or rank > TOP_N then
			return
		end

		local pageName = Page.pageifyLink(player.link or player.name) --[[@as string]]

		return PlayerExt.syncPlayer{
			pageName = pageName,
			displayName = player.name,
			--todo: test if "updated" works, else: team = PlayerExt.syncTeam(pageName),
			team = PlayerExt.syncTeam(pageName, nil, config.updated),
			rank = rank,
			points = tonumber(player.points),
		}
	end)

	local historicalToTeam = {}
	local byTeam = {}
	Array.forEach(players, function(player)
		if not player.team then return end
		local team = historicalToTeam[player.team]
		if not team then
			team = player.team --[[@as string]]
			historicalToTeam[team] = team
			local teamPage = Page.pageifyLink(TeamTemplate.getPageName(team)) --[[@as string]]
			Array.forEach(TeamTemplate.queryHistoricalNames(teamPage), function(t)
				historicalToTeam[t] = team
			end)
			byTeam[team] = {players = {}, team = team, earnings = 0, achievements = {}, pageName = teamPage}
		end
		table.insert(byTeam[team].players, player)
	end)

	for _, team in pairs(byTeam) do
		Array.sortInPlaceBy(team.players, Operator.property('points'))
		team.players = Array.reverse(team.players)
		team.count = math.min(#team.players, MAX_PLAYERS_PER_ORG)
		local points = Array.map(Array.sub(team.players, 1, team.count), Operator.property('points'))
		team.average = MathUtil.sum(points) / team.count
	end

	local achievementsInfo = PowerRankingsOrgs._addPlacementData(byTeam, historicalToTeam, config.year)

	local teams = Array.extractValues(byTeam)
	Array.forEach(teams, function(team)
		team.achievements = Array.unique(team.achievements)
	end)

	PowerRankingsOrgs._determineScore(teams, config.weights, config.weightSum)

	table.sort(teams, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		return a.average > b.average
	end)

	if not config.wrapped then
		PowerRankingsOrgs._store(teams)
	end

	if config.limit then
		teams = Array.sub(teams, 1, config.limit)
	end

	PowerRankingsOrgs._fetchTeamFlags(teams)

	return PowerRankingsOrgs._buildDisplay(teams, achievementsInfo, config)
end

---@param teams FortniteRankingsTeam[]
function PowerRankingsOrgs._fetchTeamFlags(teams)
	local teamByPageName = {}
	Array.forEach(teams, function(team, teamIndex)
		teamByPageName[team.pageName] = teamIndex
	end)

	local pages = Array.extractKeys(teamByPageName)
	local queryResults = mw.ext.LiquipediaDB.lpdb('team', {
		conditions = tostring(ConditionUtil.anyOf(ColumnName('pagename'), pages)),
		query = 'pagename, locations, location',
		limit = 5000,
	})
	Array.forEach(queryResults, function(teamRecord)
		local index = teamByPageName[teamRecord.pagename]
		-- `.location` (deprecated) is needed on fortnite since their input on team infoboxes is bad ...
		teams[index].flag = Logic.emptyOr(teamRecord.locations['country1'], teamRecord.location)
	end)
end

---@param byTeam table<string, {players: FortniteRankingsPlayer[], team: string, earnings: number, achievements: string[]}>
---@param historicalToTeam table<string, string>
---@param year integer
---@return {pageName: string, displayName: string, icon: string?, iconDark: string?}[]
function PowerRankingsOrgs._addPlacementData(byTeam, historicalToTeam, year)
	local placementConditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date_year'), Comparator.eq, tostring(year)),
		ConditionNode(ColumnName('prizemoney'), Comparator.gt, '0'),
	}

	---@type table<string, true>
	local achievements = {}

	Lpdb.executeMassQuery('placement', {
		conditions = tostring(placementConditions),
		query = 'pagename, opponentname, opponenttemplate, opponenttype, opponentplayers, '
			.. 'individualprizemoney, placement, liquipediatier, liquipediatiertype',
		limit = 5000,
	}, function(placement)
		local prize = tonumber(placement.individualprizemoney) or 0
		local isAchievement = tonumber(placement.placement) == 1
			and tonumber(placement.liquipediatier) == 1
			and not Table.includes({'Qualifier', 'Showmatch'}, placement.liquipediatiertype)

		local opponent = Opponent.fromLpdbStruct(placement)
		Array.forEach(opponent.players, function(player)
			local teamTemplate = historicalToTeam[player.team]
			local team = byTeam[teamTemplate]
			if not team then return end
			team.earnings = team.earnings + prize
			if isAchievement then
				achievements[placement.pagename] = true
				table.insert(team.achievements, placement.pagename)
			end
		end)
	end)

	return PowerRankingsOrgs._getTournamentInfo(Array.extractKeys(achievements))
end

---@param pages string[]
---@return table<string, {pageName: string, displayName: string, icon: string?, iconDark: string?}>
function PowerRankingsOrgs._getTournamentInfo(pages)
	if Logic.isEmpty(pages) then return {} end

	local queryData = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = tostring(ConditionUtil.anyOf(ColumnName('pagename'), pages)),
		query = 'pagename, name, icon, icondark',
		limit = 5000,
	})

	return Table.map(queryData, function(key, tournament)
		return tournament.pagename, {
			pageName = tournament.pagename,
			displayName = Logic.nilIfEmpty(tournament.name) or tournament.pagename:gsub('_', ' '),
			icon = tournament.icon,
			iconDark = tournament.icondark,
		}
	end)
end

---@param teams FortniteRankingsTeam[]
---@param weights {count: number, pr: number, cash: number}
---@param weightSum number
function PowerRankingsOrgs._determineScore(teams, weights, weightSum)
	local numberOfTeams = #teams

	---@param key string
	local function getRankForKey(key)
		if numberOfTeams <= 1 then
			return
		end

		local sorted = Array.sortBy(teams, Operator.property(key))

		local i = 1
		while i <= numberOfTeams do
			local j = i
			while j < numberOfTeams and sorted[j + 1][key] == sorted[i][key] do
				j = j + 1
			end
			local norm = ((i + j) / 2 - 1) / (numberOfTeams - 1)
			for k = i, j do
				sorted[k][key .. 'Rank'] = norm
			end
			i = j + 1
		end
	end

	getRankForKey('count')
	getRankForKey('average')
	getRankForKey('earnings')

	Array.forEach(teams, function(team, teamIndex)
		team.score = 100 * (
			weights.count * (team.countRank or 1) +
			weights.pr * (team.averageRank or 1) +
			weights.cash * (team.earningsRank or 1)
		) / weightSum
	end)
end

---@param teams FortniteRankingsTeam
function PowerRankingsOrgs._store(teams)
	if Lpdb.isStorageDisabled() then return end
	Array.forEach(teams, function(team)
		mw.ext.LiquipediaDB.lpdb_datapoint('FTN_ORG_PR_' .. team.pageName, {
			type = 'FTN_ORG_PR',
			name = team.pageName,
			information = team.rank,
			extradata = {score = MathUtil.formatRounded{value = team.score, precision = 1}},
		})
	end)
end

---@param teams FortniteRankingsTeam[]
---@param achievementsInfo table<string, {pageName: string, displayName: string, icon: string?, iconDark: string?}>
---@param config {wrapped: boolean, updated: string?, year: integer, showMore: integer}
---@return Renderable
function PowerRankingsOrgs._buildDisplay(teams, achievementsInfo, config)
	local columns = WidgetUtil.collect(
		{align = 'center'},
		{align = 'center'},
		{align = 'left'},
		{align = 'left'},
		not config.wrapped and {align = 'center'} or nil,
		{align = 'center'},
		not config.wrapped and {align = 'center'} or nil,
		not config.wrapped and {align = 'center'} or nil
	)

	local rows = Array.map(teams, function(team, rank)
		return PowerRankingsOrgs._buildRow(rank, team, config.wrapped, achievementsInfo)
	end)

	return TableWidgets.Table{
		title = PowerRankingsOrgs._buildTitle(config.updated),
		sortable = false,
		columns = columns,
		footer = config.showMore and Link{
			link = DISPLAY_PAGE,
			linktype = 'internal',
			children = {
				HtmlWidgets.Div{
					children = {'See Rankings Page', Icon.makeIcon{iconName = 'goto'}},
					classes = {'ranking-table__footer-button'},
				},
			},
		} or nil,
		css = {width = '100%'},
		children = {
			TableWidgets.TableHeader{children = {PowerRankingsOrgs._buildHeader(config.wrapped, config.year)}},
			TableWidgets.TableBody{children = rows},
		},
	}
end

---@param updated string?
---@return Renderable
function PowerRankingsOrgs._buildTitle(updated)
	return HtmlWidgets.Div{children = WidgetUtil.collect(
		HtmlWidgets.B{children = 'Fortnite Organization Power Rankings'},
		Logic.isNotEmpty(updated) and HtmlWidgets.Span{
			css = {['font-weight'] = 'normal'},
			children = {HtmlWidgets.Br{}, 'Last updated: ', updated},
		} or nil
	)}
end

---@param wrapped boolean
---@param year integer
---@return Renderable
function PowerRankingsOrgs._buildHeader(wrapped, year)
	return TableWidgets.Row{children = WidgetUtil.collect(
		TableWidgets.CellHeader{children = 'Rank'},
		TableWidgets.CellHeader{children = ''},
		TableWidgets.CellHeader{children = 'Organization'},
		TableWidgets.CellHeader{children = 'Four Best Players (In Top ' .. TOP_N .. ')'},
		not wrapped and TableWidgets.CellHeader{children = 'Recent Achievements'} or nil,
		TableWidgets.CellHeader{children = 'Score'},
		not wrapped and TableWidgets.CellHeader{children = 'Average Players PR'} or nil,
		not wrapped and TableWidgets.CellHeader{children = 'Earnings (' .. year .. ')'} or nil
	)}
end

---@param rank integer
---@param team FortniteRankingsTeam
---@param wrapped boolean
---@param achievementsInfo table<string, {pageName: string, displayName: string, icon: string?, iconDark: string?}>
---@return VNode<Table2RowProps>
function PowerRankingsOrgs._buildRow(rank, team, wrapped, achievementsInfo)
	local flagCell = Logic.isNotEmpty(team.flag) and Flags.Icon{flag = team.flag, shouldLink = false} or ''
	local memberDisplays = Array.map(Array.sub(team.players, 1, team.count), function(player)
		return PlayerDisplay.InlinePlayer{player = player}
	end)
	local membersText = Array.append(
		Array.interleave(memberDisplays, ', '),
		' (' .. team.count .. ')'
	)

	local achievements = Array.map(team.achievements or {}, function(achievement)
		local info = achievementsInfo[achievement]
		if not info then
			return
		end
		return LeagueIcon.display{
			icon = info.icon,
			iconDark = info.iconDark,
			link = info.pageName,
			name = info.displayName,
			size = 30,
			options = {noTemplate = true},
		}
	end)

	return TableWidgets.Row{children = WidgetUtil.collect(
		TableWidgets.Cell{children = HtmlWidgets.B{children = rank}},
		TableWidgets.Cell{children = flagCell},
		TableWidgets.Cell{children = OpponentDisplay.BlockOpponent{
			opponent = {type = Opponent.team, template = team.team, extradata = {}},
		}},
		TableWidgets.Cell{children = membersText},
		not wrapped and TableWidgets.Cell{children = achievements} or nil,
		TableWidgets.Cell{children = HtmlWidgets.B{children = MathUtil.formatRounded{value = team.score, precision = 1}}},
		not wrapped and TableWidgets.Cell{children = Currency.formatMoney(team.average, 0)} or nil,
		not wrapped and TableWidgets.Cell{children = '$' .. Currency.formatMoney(team.earnings, 0)} or nil
	)}
end

return PowerRankingsOrgs
