---
-- @Liquipedia
-- page=Module:PowerRankings/Orgs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Page = Lua.import('Module:Page')
local PlayerExt = Lua.import('Module:Player/Ext')
local String = Lua.import('Module:StringUtils')
local Team = Lua.import('Module:Team')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local PowerRankingsData = Lua.import('Module:PowerRankings/Data', {loadData = true})
local DISPLAY_PAGE = 'Fortnite Power Rankings/Organizations'
local TOP_N = 200
local MAX_PLAYERS_PER_ORG = 4
local DEFAULT_WEIGHTS = {count = 0.12, pr = 0.35, cash = 0.45}

local CONTAINER_STYLE = 'display: inline-flex; align-items: center; white-space: nowrap; '
	.. 'line-height: 1; font-size: 1em; vertical-align: middle;'
local FLAG_SPACING = '5px'

local p = {}

local function renderPlayer(name, link)
	if String.isEmpty(name) then
		return ''
	end
	local date = DateExt.toYmdInUtc(DateExt.getContextualDateOrNow())
	local pageNameFromLink, displayNameFromLink = PlayerExt.extractFromLink(name)
	local player = {
		displayName = displayNameFromLink or name,
		pageName = String.nilIfEmpty(link) or pageNameFromLink,
	}
	PlayerExt.syncPlayer(player, {date = date})

	local items = {}
	if String.isNotEmpty(player.flag) then
		local flagIcon = String.nilIfEmpty(Flags.Icon{flag = player.flag, shouldLink = false})
		if flagIcon then
			items[#items + 1] = string.format(
				'<span style="display: inline-flex; align-items: center; margin-right: %s;">%s</span>',
				FLAG_SPACING, flagIcon)
		end
	end
	local nameLink = Link{link = player.pageName, linktype = 'internal', children = player.displayName}
	items[#items + 1] = string.format('<span>%s</span>', tostring(nameLink))

	return string.format('<span style="%s">%s</span>', CONTAINER_STYLE, table.concat(items))
end

local function queryPlayerOrg(name)
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
	return row.team or ''
end

local function wrap(tbl)
	return tostring(mw.html.create('div')
		:addClass('table-responsive')
		:css('overflow-x', 'auto')
		:css('width', '100%')
		:node(tbl))
end

local function themedText(content)
	return '<span class="show-when-light-mode" style="color:#000;">' .. content .. '</span>'
		.. '<span class="show-when-dark-mode" style="color:#fff;">' .. content .. '</span>'
end

local function formatNumber(n)
	local s = tostring(math.floor((tonumber(n) or 0) + 0.5))
	return (s:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', ''))
end

local function resolvePlayerTeams(players)
	local result = {}
	for i, pl in ipairs(players) do
		result[i] = Logic.nilIfEmpty(queryPlayerOrg(pl.link or pl.name))
	end
	return result
end

local function resolveOrgFlags(list)
	local pageByTeam = {}
	local pages = {}
	for _, o in ipairs(list) do
		local ok, raw = pcall(mw.ext.TeamTemplate.raw, o.team)
		if ok and type(raw) == 'table' and Logic.isNotEmpty(raw.page) then
			local page = raw.page:gsub(' ', '_')
			pageByTeam[o.team] = page
			table.insert(pages, page)
		end
	end

	local locByPage = {}
	local CHUNK = 50
	for start = 1, #pages, CHUNK do
		local conditions = ConditionTree(BooleanOperator.any)
		for k = start, math.min(start + CHUNK - 1, #pages) do
			conditions:add{ConditionNode(ColumnName('pagename'), Comparator.eq, pages[k])}
		end
		local rows = mw.ext.LiquipediaDB.lpdb('team', {
			conditions = conditions:toString(),
			query = 'pagename, location',
			limit = 1000,
		}) or {}
		for _, r in ipairs(rows) do
			if Logic.isNotEmpty(r.pagename) then
				locByPage[r.pagename:gsub(' ', '_')] = r.location
			end
		end
	end

	for _, o in ipairs(list) do
		local page = pageByTeam[o.team]
		o.flag = page and Logic.nilIfEmpty(locByPage[page]) or nil
	end
end

local function normalizeName(name)
	return string.lower((name or ''):gsub('[%s_]', ''))
end

local function orgPageKey(team)
	local ok, raw = pcall(mw.ext.TeamTemplate.raw, team)
	local page = (ok and type(raw) == 'table' and Logic.isNotEmpty(raw.page)) and raw.page or team
	return normalizeName(page)
end

local function storeOrgRankings(list)
	for rank, o in ipairs(list) do
		local key = orgPageKey(o.team)
		mw.ext.LiquipediaDB.lpdb_datapoint('FTN_ORG_PR_' .. key, {
			type = 'FTN_ORG_PR',
			name = key,
			information = rank,
			extradata = {score = string.format('%.1f', o.score)},
		})
	end
end

local function tournamentIcon(icon, icondark, page, size)
	if Logic.isEmpty(icon) then return '' end
	icondark = Logic.nilIfEmpty(icondark) or icon
	return '<span class="league-icon-small-image lightmode">[[File:' .. icon .. '|' .. size .. '|link=' .. page .. ']]</span>'
		.. '<span class="league-icon-small-image darkmode">[[File:' .. icondark .. '|' .. size .. '|link=' .. page .. ']]</span>'
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

		for i = 1, 10 do
			local pName = opPlayers['p' .. i]
			if Logic.isNotEmpty(pName) then
				local teamRaw = opPlayers['p' .. i .. 'team']
				if Logic.isEmpty(teamRaw) and opType == 'team' then
					teamRaw = opName
				end
				if Logic.isNotEmpty(teamRaw) then
					local norm = normalizeName(teamRaw)
					earnings[norm] = (earnings[norm] or 0) + indiv
					if isSTierWin and Logic.isNotEmpty(page) then
						winPages[norm] = winPages[norm] or {}
						if not winPages[norm][page] then
							winPages[norm][page] = true
							pageSet[page] = true
						end
					end
				end
			end
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

	local pages = {}
	for page in pairs(pageSet) do table.insert(pages, page) end

	local details = {}
	local CHUNK = 40
	for start = 1, #pages, CHUNK do
		local conditions = ConditionTree(BooleanOperator.any)
		for k = start, math.min(start + CHUNK - 1, #pages) do
			conditions:add{ConditionNode(ColumnName('pagename'), Comparator.eq, pages[k])}
		end
		local rows = mw.ext.LiquipediaDB.lpdb('tournament', {
			conditions = conditions:toString(),
			query = 'pagename, name, icon, icondark',
			limit = 100,
		}) or {}
		for _, t in ipairs(rows) do
			details[t.pagename] = {
				name = Logic.nilIfEmpty(t.name) or t.pagename:gsub('_', ' '),
				icon = t.icon,
				icondark = t.icondark,
			}
		end
	end

	return earnings, winPages, details
end

function p.main(frame)
	local args = Arguments.getArgs(frame)
	local limit = tonumber(args.limit)
	local showMore = Logic.readBool(args.showMore)
	local wrapped = Logic.readBool(args.wrapped)
	local colspan = wrapped and 5 or 8
	local year = tonumber(args.year) or tonumber(os.date('!%Y'))
	local weights = {
		count = tonumber(args.wCount) or DEFAULT_WEIGHTS.count,
		pr = tonumber(args.wPR) or DEFAULT_WEIGHTS.pr,
		cash = tonumber(args.wCash) or DEFAULT_WEIGHTS.cash,
	}
	local weightSum = weights.count + weights.pr + weights.cash

	local players = {}
	for _, pl in ipairs(PowerRankingsData.players or {}) do
		if (tonumber(pl.rank) or 0) <= TOP_N then
			table.insert(players, pl)
		end
	end
	local teams = resolvePlayerTeams(players)

	local byOrg = {}
	for i, pl in ipairs(players) do
		local team = teams[i]
		if team then
			byOrg[team] = byOrg[team] or {}
			table.insert(byOrg[team], {
				name = pl.name,
				link = pl.link,
				points = tonumber(pl.points) or 0,
			})
		end
	end

	local list = {}
	for team, members in pairs(byOrg) do
		table.sort(members, function(a, b) return a.points > b.points end)
		local count = math.min(#members, MAX_PLAYERS_PER_ORG)
		local sum = 0
		for k = 1, count do sum = sum + members[k].points end
		table.insert(list, {
			team = team,
			members = members,
			count = count,
			avgPR = sum / count,
		})
	end

	local teamEarnings, teamWinPages, tournamentDetails = gatherPlacementData(year)
	for _, o in ipairs(list) do
		o.histNames = Team.queryHistoricalNames(o.team) or {o.team}
		local cash = 0
		for _, nm in ipairs(o.histNames) do
			cash = cash + (teamEarnings[normalizeName(nm)] or 0)
		end
		o.cash = cash
	end

	local n = #list
	local function rankNormalize(getValue, field)
		if n <= 1 then
			for _, o in ipairs(list) do o[field] = 1 end
			return
		end
		local sorted = {}
		for _, o in ipairs(list) do table.insert(sorted, o) end
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

	for _, o in ipairs(list) do
		o.score = 100 * (weights.count * o.nCount + weights.pr * o.nPR + weights.cash * o.nCash) / weightSum
	end

	table.sort(list, function(a, b)
		if a.score ~= b.score then return a.score > b.score end
		return a.avgPR > b.avgPR
	end)

	if not wrapped then
		storeOrgRankings(list)
	end

	local display = {}
	for i, o in ipairs(list) do
		if limit and i > limit then break end
		table.insert(display, o)
	end

	if not wrapped then
		for _, o in ipairs(display) do
			local achievements = {}
			local seen = {}
			for _, nm in ipairs(o.histNames) do
				local pagesForTeam = teamWinPages[normalizeName(nm)]
				if pagesForTeam then
					for page in pairs(pagesForTeam) do
						if not seen[page] then
							seen[page] = true
							local d = tournamentDetails[page] or {name = page:gsub('_', ' '), icon = '', icondark = ''}
							table.insert(achievements, {page = page, name = d.name, icon = d.icon, icondark = d.icondark})
						end
					end
				end
			end
			o.achievements = achievements
		end
	end

	resolveOrgFlags(display)

	local tbl = mw.html.create('table')
		:addClass('table2__table wikitable wikitable-striped wikitable-bordered')
		:css('width', '100%')
		:css('border-collapse', 'collapse')

	local title = "'''Fortnite Organization Power Rankings'''"
	if Logic.isNotEmpty(PowerRankingsData.updated) then
		local utc = frame:expandTemplate{title = 'Abbr/UTC'}
		title = title .. "<br><small>''Last Updated: " .. PowerRankingsData.updated .. ' ' .. utc .. "''</small>"
	end
	tbl:tag('tr'):tag('th')
		:attr('colspan', colspan)
		:wikitext(themedText(title))

	local header = tbl:tag('tr')
	header:tag('th'):css('width', '1%'):css('white-space', 'nowrap'):wikitext('Rank')
	header:tag('th'):css('width', '1%'):css('padding', '0 8px'):wikitext('')
	header:tag('th'):css('text-align', 'left'):wikitext('Organization')
	header:tag('th'):css('text-align', 'left'):wikitext('Four Best Players (In Top 200)')
	if not wrapped then
		header:tag('th'):css('text-align', 'center'):wikitext('Recent Achievements')
	end
	header:tag('th'):css('width', '1%'):css('white-space', 'nowrap'):wikitext('Score')
	if not wrapped then
		header:tag('th'):css('width', '1%'):css('white-space', 'nowrap'):wikitext('Average Players PR')
		header:tag('th'):css('width', '1%'):css('white-space', 'nowrap'):wikitext('Earnings (' .. year .. ')')
	end

	for i, o in ipairs(display) do
		local row = tbl:tag('tr')
		row:tag('td'):css('text-align', 'center'):css('white-space', 'nowrap'):wikitext('<b>' .. i .. '</b>')
		local flagCell = Logic.isNotEmpty(o.flag) and Flags.Icon{flag = o.flag, shouldLink = false} or ''
		row:tag('td'):css('text-align', 'center'):css('white-space', 'nowrap'):css('padding', '0 8px'):wikitext(flagCell)
		row:tag('td'):css('text-align', 'left'):css('white-space', 'nowrap'):wikitext(frame:expandTemplate{title = 'Team', args = {o.team}})
		local names = {}
		for k = 1, o.count do
			local m = o.members[k]
			local rendered = renderPlayer(m.name, m.link)
			table.insert(names, '<span style="white-space:nowrap">' .. rendered .. '</span>')
		end
		row:tag('td'):css('text-align', 'left')
			:wikitext(table.concat(names, ', ') .. ' (' .. o.count .. ')')
		if not wrapped then
			local achText = ''
			for _, a in ipairs(o.achievements or {}) do
				achText = achText .. tournamentIcon(a.icon, a.icondark, a.page, '30x30px')
			end
			row:tag('td'):css('text-align', 'center'):wikitext(achText)
		end
		row:tag('td'):css('text-align', 'center'):css('white-space', 'nowrap'):wikitext('<b>' .. string.format('%.1f', o.score) .. '</b>')
		if not wrapped then
			row:tag('td'):css('text-align', 'center'):css('white-space', 'nowrap'):wikitext(formatNumber(o.avgPR))
			row:tag('td'):css('text-align', 'center'):css('white-space', 'nowrap'):wikitext('$' .. formatNumber(o.cash))
		end
	end

	if showMore then
		local footer = Link{
			link = DISPLAY_PAGE,
			linktype = 'internal',
			children = {
				HtmlWidgets.Div{
					children = {'See Rankings Page', Icon.makeIcon{iconName = 'goto'}},
					classes = {'ranking-table__footer-button'},
				},
			},
		}
		tbl:tag('tr'):tag('td')
			:attr('colspan', colspan)
			:wikitext(tostring(footer))
	end

	return wrap(tbl)
end

return p
