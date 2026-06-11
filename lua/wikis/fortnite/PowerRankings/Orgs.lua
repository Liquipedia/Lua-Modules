---
-- @Liquipedia
-- page=Module:PowerRankings/Orgs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MathUtil = Lua.import('Module:MathUtil')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')
local Team = Lua.import('Module:Team')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Variables = Lua.import('Module:Variables')

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
local MAX_PLAYERS_PER_PLACEMENT = 10
local DEFAULT_WEIGHTS = {count = 0.12, pr = 0.35, cash = 0.45}

local PowerRankingsOrgs = {}

local function normalizeName(name)
	return string.lower((name or ''):gsub('[%s_]', ''))
end

local function resolvePrimaryTeam(name)
	if Logic.isEmpty(name) then
		return ''
	end
	local conditions = ConditionTree(BooleanOperator.any):add{
		ConditionNode(ColumnName('pagename'), Comparator.eq, Page.pageifyLink(name)),
		ConditionNode(ColumnName('id'), Comparator.eq, name),
	}
	local row = mw.ext.LiquipediaDB.lpdb('player', {
		query = 'team',
		conditions = conditions:toString(),
		limit = 1,
	})[1] or {}
	local primary = Logic.nilIfEmpty(row.team)
	if primary then
		return primary
	end
	return PlayerExt.syncTeam(Page.pageifyLink(name)) or ''
end

local function formatNumber(value)
	return mw.getContentLanguage():formatNum(MathUtil.round(tonumber(value) or 0))
end

local function orgPageKey(team)
	local raw = TeamTemplate.getRawOrNil(team)
	local page = raw and Logic.nilIfEmpty(raw.page) or team
	return normalizeName(page)
end

local function storeOrgRankings(list)
	if Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then
		return
	end
	Array.forEach(list, function(o, rank)
		local key = orgPageKey(o.team)
		mw.ext.LiquipediaDB.lpdb_datapoint('FTN_ORG_PR_' .. key, {
			type = 'FTN_ORG_PR',
			name = key,
			information = rank,
			extradata = {score = MathUtil.formatRounded{value = o.score, precision = 1}},
		})
	end)
end

local function tournamentIcon(icon, icondark, page, size)
	if Logic.isEmpty(icon) then return '' end
	icondark = Logic.nilIfEmpty(icondark) or icon
	local function modeSpan(mode, image)
		return string.format(
			'<span class="league-icon-small-image %s">[[File:%s|%s|link=%s]]</span>',
			mode, image, size, page)
	end
	return modeSpan('lightmode', icon) .. modeSpan('darkmode', icondark)
end

local function gatherPlacementData(year)
	local earnings = {}
	local winPages = {}
	local pageSet = {}

	local function process(item)
		local indiv = tonumber(item.individualprizemoney) or 0
		local page = item.pagename
		local isSTierWin = item.placement == '1'
			and (item.liquipediatier == '1' or item.liquipediatier == 'S-Tier')
			and item.liquipediatiertype ~= 'Qualifier'
			and item.liquipediatiertype ~= 'Showmatch'
		local opPlayers = item.opponentplayers or {}
		local opType = item.opponenttype
		local opName = item.opponentname

		local function processPlayer(i)
			if Logic.isEmpty(opPlayers['p' .. i]) then
				return
			end
			local teamRaw = opPlayers['p' .. i .. 'team']
			if Logic.isEmpty(teamRaw) and opType == 'team' then
				teamRaw = opName
			end
			if Logic.isEmpty(teamRaw) then
				return
			end
			local norm = normalizeName(teamRaw)
			earnings[norm] = (earnings[norm] or 0) + indiv
			if not (isSTierWin and Logic.isNotEmpty(page)) then
				return
			end
			winPages[norm] = winPages[norm] or {}
			if winPages[norm][page] then
				return
			end
			winPages[norm][page] = true
			pageSet[page] = page
		end

		for i = 1, MAX_PLAYERS_PER_PLACEMENT do
			processPlayer(i)
		end
	end

	local placementConditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date_year'), Comparator.eq, tostring(year)),
		ConditionNode(ColumnName('prizemoney'), Comparator.gt, '0'),
	}

	Lpdb.executeMassQuery('placement', {
		conditions = placementConditions:toString(),
		query = 'pagename, opponentname, opponenttype, opponentplayers, '
			.. 'individualprizemoney, placement, liquipediatier, liquipediatiertype',
		limit = 5000,
	}, process)

	local pages = Array.extractValues(pageSet)

	local details = {}
	if Logic.isNotEmpty(pages) then
		local tournamentRows = mw.ext.LiquipediaDB.lpdb('tournament', {
			conditions = ConditionUtil.anyOf(ColumnName('pagename'), pages):toString(),
			query = 'pagename, name, icon, icondark',
			limit = 100,
		}) or {}
		Array.forEach(tournamentRows, function(tournamentRow)
			details[tournamentRow.pagename] = {
				name = Logic.nilIfEmpty(tournamentRow.name) or tournamentRow.pagename:gsub('_', ' '),
				icon = tournamentRow.icon,
				icondark = tournamentRow.icondark,
			}
		end)
	end

	return earnings, winPages, details
end

local function resolveOrgFlags(list)
	local pageByTeam = {}
	local pages = {}
	Array.forEach(list, function(o)
		local raw = TeamTemplate.getRawOrNil(o.team)
		if raw and Logic.isNotEmpty(raw.page) then
			local page = raw.page:gsub(' ', '_')
			pageByTeam[o.team] = page
			table.insert(pages, page)
		end
	end)

	local locByPage = {}
	if Logic.isNotEmpty(pages) then
		local teamRows = mw.ext.LiquipediaDB.lpdb('team', {
			conditions = ConditionUtil.anyOf(ColumnName('pagename'), pages):toString(),
			query = 'pagename, location',
			limit = 1000,
		}) or {}
		Array.forEach(teamRows, function(teamRow)
			if Logic.isNotEmpty(teamRow.pagename) then
				locByPage[teamRow.pagename] = teamRow.location
			end
		end)
	end

	Array.forEach(list, function(o)
		local page = pageByTeam[o.team]
		o.flag = page and Logic.nilIfEmpty(locByPage[page]) or nil
	end)
end

---@param updated string?
---@return Widget
local function buildTitle(updated)
	return HtmlWidgets.Div{children = WidgetUtil.collect(
		HtmlWidgets.B{children = 'Fortnite Organization Power Rankings'},
		Logic.isNotEmpty(updated) and HtmlWidgets.Span{
			css = {['font-weight'] = 'normal'},
			children = {HtmlWidgets.Br{}, 'Last Updated: ', updated},
		} or nil
	)}
end

---@return Widget
local function buildFooter()
	return Link{
		link = DISPLAY_PAGE,
		linktype = 'internal',
		children = {
			HtmlWidgets.Div{
				children = {'See Rankings Page', Icon.makeIcon{iconName = 'goto'}},
				classes = {'ranking-table__footer-button'},
			},
		},
	}
end

---@param wrapped boolean
---@param year integer
---@return Widget
local function buildHeader(wrapped, year)
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
---@param o table
---@param wrapped boolean
---@return Widget
local function buildRow(rank, o, wrapped)
	local flagCell = Logic.isNotEmpty(o.flag) and Flags.Icon{flag = o.flag, shouldLink = false} or ''
	local memberDisplays = Array.map(Array.sub(o.members, 1, o.count), function(m)
		local player = {displayName = m.name, pageName = Logic.nilIfEmpty(m.link) or m.name}
		PlayerExt.syncPlayer(player)
		return tostring(PlayerDisplay.InlinePlayer{player = player})
	end)
	local membersText = table.concat(memberDisplays, ', ') .. ' (' .. o.count .. ')'
	local achievementsText = table.concat(Array.map(o.achievements or {}, function(a)
		return tournamentIcon(a.icon, a.icondark, a.page, '30x30px')
	end))

	return TableWidgets.Row{children = WidgetUtil.collect(
		TableWidgets.Cell{children = HtmlWidgets.B{children = rank}},
		TableWidgets.Cell{children = flagCell},
		TableWidgets.Cell{children = OpponentDisplay.BlockOpponent{
			opponent = {type = Opponent.team, template = o.team},
		}},
		TableWidgets.Cell{children = membersText},
		not wrapped and TableWidgets.Cell{children = achievementsText} or nil,
		TableWidgets.Cell{children = HtmlWidgets.B{children = MathUtil.formatRounded{value = o.score, precision = 1}}},
		not wrapped and TableWidgets.Cell{children = formatNumber(o.avgPR)} or nil,
		not wrapped and TableWidgets.Cell{children = '$' .. formatNumber(o.cash)} or nil
	)}
end

---@param frame Frame
---@return Widget
function PowerRankingsOrgs.main(frame)
	local args = Arguments.getArgs(frame)
	local limit = tonumber(args.limit)
	local showMore = Logic.readBool(args.showMore)
	local wrapped = Logic.readBool(args.wrapped)
	local year = tonumber(args.year) or DateExt.getYearOf(DateExt.getContextualDateOrNow())
	local weights = {
		count = tonumber(args.wCount) or DEFAULT_WEIGHTS.count,
		pr = tonumber(args.wPR) or DEFAULT_WEIGHTS.pr,
		cash = tonumber(args.wCash) or DEFAULT_WEIGHTS.cash,
	}
	local weightSum = weights.count + weights.pr + weights.cash

	local updated
	if Logic.isNotEmpty(PowerRankingsData.updated) then
		updated = PowerRankingsData.updated .. ' ' .. DateExt.defaultTimezone
	end

	local players = Array.filter(PowerRankingsData.players or {}, function(pl)
		return (tonumber(pl.rank) or 0) <= TOP_N
	end)

	local byOrg = {}
	Array.forEach(players, function(pl)
		local team = Logic.nilIfEmpty(resolvePrimaryTeam(pl.link or pl.name))
		if not team then
			return
		end
		byOrg[team] = byOrg[team] or {}
		table.insert(byOrg[team], {name = pl.name, link = pl.link, points = tonumber(pl.points) or 0})
	end)

	local list = {}
	for team, members in pairs(byOrg) do
		table.sort(members, function(a, b) return a.points > b.points end)
		local count = math.min(#members, MAX_PLAYERS_PER_ORG)
		local topPoints = Array.map(Array.sub(members, 1, count), function(m) return m.points end)
		table.insert(list, {
			team = team,
			members = members,
			count = count,
			avgPR = MathUtil.sum(topPoints) / count,
		})
	end

	local teamEarnings, teamWinPages, tournamentDetails = gatherPlacementData(year)
	Array.forEach(list, function(o)
		o.histNames = Team.queryHistoricalNames(o.team)
		if Logic.isEmpty(o.histNames) then
			o.histNames = {o.team}
		end
		o.cash = Array.reduce(o.histNames, function(total, nm)
			return total + (teamEarnings[normalizeName(nm)] or 0)
		end, 0)
	end)

	local n = #list
	local function rankNormalize(getValue, field)
		if n <= 1 then
			Array.forEach(list, function(o) o[field] = 1 end)
			return
		end
		local sorted = Table.copy(list)
		table.sort(sorted, function(a, b) return getValue(a) < getValue(b) end)
		local i = 1
		while i <= n do
			local j = i
			while j < n and getValue(sorted[j + 1]) == getValue(sorted[i]) do j = j + 1 end
			local norm = ((i + j) / 2 - 1) / (n - 1)
			for k = i, j do sorted[k][field] = norm end
			i = j + 1
		end
	end

	rankNormalize(function(o) return o.count end, 'nCount')
	rankNormalize(function(o) return o.avgPR end, 'nPR')
	rankNormalize(function(o) return o.cash end, 'nCash')

	Array.forEach(list, function(o)
		o.score = 100 * (weights.count * o.nCount + weights.pr * o.nPR + weights.cash * o.nCash) / weightSum
	end)

	table.sort(list, function(a, b)
		if a.score ~= b.score then return a.score > b.score end
		return a.avgPR > b.avgPR
	end)

	if not wrapped then
		storeOrgRankings(list)
	end

	local display = limit and Array.sub(list, 1, limit) or list

	if not wrapped then
		Array.forEach(display, function(o)
			local achievements = {}
			local seen = {}
			Array.forEach(o.histNames, function(nm)
				local pagesForTeam = teamWinPages[normalizeName(nm)]
				if not pagesForTeam then
					return
				end
				for page in pairs(pagesForTeam) do
					if not seen[page] then
						seen[page] = true
						local d = tournamentDetails[page] or {name = page:gsub('_', ' '), icon = '', icondark = ''}
						table.insert(achievements, {page = page, name = d.name, icon = d.icon, icondark = d.icondark})
					end
				end
			end)
			o.achievements = achievements
		end)
	end

	resolveOrgFlags(display)

	local columns = WidgetUtil.collect(
		{align = 'center'},
		{align = 'center'},
		{align = 'left'},
		{align = 'left'},
		not wrapped and {align = 'center'} or nil,
		{align = 'center'},
		not wrapped and {align = 'center'} or nil,
		not wrapped and {align = 'center'} or nil
	)

	local rows = Array.map(display, function(o, rank)
		return buildRow(rank, o, wrapped)
	end)

	return TableWidgets.Table{
		title = buildTitle(updated),
		sortable = false,
		columns = columns,
		footer = showMore and buildFooter() or nil,
		css = {width = '100%'},
		children = {
			TableWidgets.TableHeader{children = {buildHeader(wrapped, year)}},
			TableWidgets.TableBody{children = rows},
		},
	}
end

return PowerRankingsOrgs
