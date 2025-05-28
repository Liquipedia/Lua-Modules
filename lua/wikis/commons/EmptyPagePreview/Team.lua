---
-- @Liquipedia
-- wiki=commons
-- page=Module:EmptyPagePreview/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local FnUtil = Lua.import('Module:FnUtil')
local Game = Lua.import('Module:Game')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Operator = Lua.import('Module:Operator')
local Region = Lua.import('Module:Region')
local Team = Lua.import('Module:Team')
local Table = Lua.import('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local Infobox = Lua.import('Module:Infobox/Team/Custom')
local MatchTable = require('Module:MatchTable/Custom')
local ResultsTable = require('Module:ResultsTable/Custom')
local TransferRef = Lua.import('Module:Transfer/References')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Widget = Lua.import('Module:Widget')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

---@class EmptyTeamPagePreview: Widget
---@operator call(table): EmptyTeamPagePreview
local EmptyTeamPagePreview = Class.new(Widget)

---@return Widget?
function EmptyTeamPagePreview:render()
	if not Namespace.isMain() then
		return
	end

	self.data = self:_fetchData()

	if not self.data.team then return end
	assert(self.data.wiki, 'No wiki provided')

	return HtmlWidgets.Div{
		children = {
			HtmlWidgets.H2{children = {'Overview'}},
			self:_infobox(),
			self:roster(),
			self:_matches(),
			self:_results(),
		},
	}
end

---@return table
function EmptyTeamPagePreview:_fetchData()
	local data = {
		team = Team.queryDB('teampage', mw.title.getCurrentTitle().prefixedText),
	}



	return data
end

---@return string
function EmptyTeamPagePreview:_infobox()
	local data = self.data

	local coaches
	if Logic.isNotEmpty(data.coaches) then
		coaches = HtmlWidgets.Fragment{
			children = Array.interleave(Array.map(data.coaches, function(coach)
				return HtmlWidgets.Fragment{
					children = {
						Flags.Icon{flag = coach.flag},
						'&nbsp;',
						Link{link = coach.link, children = {coach.tag}},
					}
				}
			end), HtmlWidgets.Br{})
		}
	end

	local regionCounts = {}
	local location
	local rosterRegion
	local rosterSize = Table.size(data.nationalities or {})
	for country, countryCount in pairs(data.nationalities or {}) do
		local region = Region.name{country = country}
		if countryCount > (rosterSize / 2) then
			location = country
			rosterRegion = region
			break
		end
		if region then
			regionCounts[region] = (regionCounts[region] or 0) + 1
			if regionCounts[region] > (rosterSize / 2) then
				location = region
				rosterRegion = region
				break
			end
		end
	end
	location = location or 'World'

	local games = self:_fetchGamesFromPlacements()

	local args = {
		location = location or 'World',
		queryEarningsHistorical = data.queryEarningsHistorical,
		doNotIncludePlayerEarnings = data.doNotIncludePlayerEarnings,
		name = Team.name(nil, data.team),
		coaches = coaches,
		region = self:_determineRegionFromPlacements() or rosterRegion,
		wiki = EmptyTeamPagePreview._getWiki(self.props, games),
	}
	-- some wikis (e.g. cs, val) will need this
	Array.forEach(games, function(game)
		args[game] = true
	end)

	return tostring(Infobox.run(args))
end

---@param props table
---@param games string[]
---@return string?
function EmptyTeamPagePreview._getWiki(props, games)
	if Logic.isNotEmpty(props.wiki) then
		return props.wiki
	end
	if Logic.isNotEmpty(props.game) then
		return Game.toIdentifier{game = props.game} or props.game
	end
	if not Logic.readBool(props.getLatestGame) then
		return
	end

	for _, game in ipairs(Array.reverse(Game.listGames({ordered = true}))) do
		if Table.includes(games, game) and (game ~= 'csgocs2') then
			return game
		end
	end
end

---@return string[]
function EmptyTeamPagePreview:_fetchGamesFromPlacements()
	local placements = self:_fetchPlacements{
		query = 'game',
		groupBy = 'game asc',
		additionalConditions = ConditionTree(BooleanOperator.all):add{
			ConditionNode(ColumnName('placement'), Comparator.neq, ''),
			ConditionNode(ColumnName('game'), Comparator.neq, 'csgocs2'), -- needed for cs wiki, has no impact on others
		}
	}

	return Array.map(placements, Operator.property('game'))
end

---@param options {query: string?, groupBy: string?, additionalConditions: ConditionTree?, limit: integer?}?
---@return placement[]
function EmptyTeamPagePreview:_fetchPlacements(options)
	options = options or {}

	local teamPageNameWithoutUnderscores = self.data.team:gsub("^%l", string.upper):gsub('_', ' ')
	local teamPageName = teamPageNameWithoutUnderscores:gsub(' ', '_')

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDateTime),
		ConditionNode(ColumnName('opponentplayers'), Comparator.neq, ''),
		ConditionNode(ColumnName('opponentplayers'), Comparator.neq, '[]'),
		ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.team),
		ConditionNode(ColumnName('liquipediatier'), Comparator.neq, -1),
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('opponentname'), Comparator.eq, teamPageNameWithoutUnderscores),
			ConditionNode(ColumnName('opponentname'), Comparator.eq, teamPageName),
		}
	}

	return mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions:toString(),
		order = 'date desc, startdate desc',
		groupby = options.groupBy,
		query = options.query,
		limit = options.limit or 5000,
	})
end

---@return string?
function EmptyTeamPagePreview:_determineRegionFromPlacements()
	local placements = EmptyTeamPagePreview:_fetchPlacements{
		query = 'parent'
	}

	local regions = Array.map(placements, function(placement)
		local tournament = mw.ext.LiquipediaDB.lpdb('tournament', {
			conditions = '[[pagename::' .. placement.parent .. ']]',
			query = 'locations',
			limit = 1,
		})[1]
		if not tournament or type(tournament.locations) ~= 'table' then
			return
		end
		return tournament.locations['region1']
	end)
	local regionGroups = Array.groupBy(regions, FnUtil.identity)
	Array.sortInPlaceBy(regionGroups, function(regionGroup) return Table.size(regionGroup) end)
	return (regionGroups[1] or {})[1]
end

---@return Widget|string
function EmptyTeamPagePreview:roster()
	todo
end

---@return Widget
function EmptyTeamPagePreview:_matches()
	return HtmlWidgets.Fragment{
		children = {
			HtmlWidgets.H4{children = 'Most Recent Matches'},
			tostring(MatchTable.results{
				tableMode = 'team',
				showType = true,
				team = self.data.team,
				limit = 10,
			})
		}
	}
end

---@return Widget|string
function EmptyTeamPagePreview:_results()
	return HtmlWidgets.Fragment{
		children = {
			HtmlWidgets.H4{children = 'Most Recent Matches'},
			tostring(ResultsTable.results({
				team = self.data.team,
				awards = false,
				achievements = true,
				playerResultsOfTeam = false,
				querytype = 'team',
			})
		}
	}
end




local LANG = mw.getContentLanguage()


function QuickviewPage.get(args)
	args = args or {}

	local team = Team.queryDB('teampage', args.pagename)

	if not team then return end

	local data = {}

	local rosterNode = QuickviewPage._Roster(team, data)

	return mw.html.create('div')
		:tag('h2'):wikitext('Overview'):done()
		:node(QuickviewPage._Infobox(team, data))
		:node(rosterNode)
		:node(QuickviewPage._Matches(team))
		:node(QuickviewPage._Results(team))
end

function QuickviewPage._Roster(team, globalData)
	local data = QuickviewPage._fetchPlacements(team, 1)

	local RosterNode
	if data[1] then
		local rosterNode, coaches, nationalities = QuickviewPage._getRoster(data[1], team)
		globalData.nationalities = nationalities
		globalData.coaches = coaches
		RosterNode = mw.html.create('div')
			:addClass('table-responsive')
			:node(rosterNode)
	end

	return mw.html.create()
		:tag('h4'):wikitext('Most Recent Roster'):done()
		:node(RosterNode)
end

function QuickviewPage._getRoster(latestResult, team)
	local rows, hasLeaveDates, hasJoinDates, coaches, nationalities = QuickviewPage._processLatestResult(latestResult, team)

	local headerRow = mw.html.create('tr')
		:css('text-align', 'left')
		:tag('th'):css('width', '100px'):wikitext(Flags.Icon{flag = 'filler'} .. '&nbsp;ID'):done()
		:tag('th'):wikitext('Name'):done()

	if hasJoinDates then
		headerRow:tag('th'):wikitext('Join Date')
	end

	if hasLeaveDates then
		headerRow
			:tag('th'):wikitext('Leave Date'):done()
			:tag('th'):wikitext('New Team')
	end

	return mw.html.create('table')
		:addClass('wikitable wikitable-striped')
		:css('white-space', 'nowrap')
		:tag('tr')--header row 1
			:tag('th')
				:attr('colspan', 5)
				:wikitext('[[' .. latestResult.pagename .. '|' .. latestResult.tournament .. ']]')
				:done()
			:done()
		:node(headerRow)
		:node(rows), coaches, nationalities
end

function QuickviewPage._processLatestResult(latestResult, team)
	local players = {}
	local coaches = {}
	local startDate = latestResult.startdate
	local nationalities = {}

	for prefix, player in Table.iter.pairsByPrefix(latestResult.opponentplayers, 'p') do
		local flag = latestResult.opponentplayers[prefix .. 'flag']
		local displayName = latestResult.opponentplayers[prefix .. 'dn']
		nationalities[flag] = (nationalities[flag] or 0) + 1
		table.insert(players, QuickviewPage._processName(player, 'p', team, startDate, flag, displayName))
	end

	for prefix, coach in Table.iter.pairsByPrefix(latestResult.opponentplayers, 'c') do
		local flag = latestResult.opponentplayers[prefix .. 'flag']
		local displayName = latestResult.opponentplayers[prefix .. 'dn']
		table.insert(coaches, QuickviewPage._processName(coach, 'c', team, startDate, flag, displayName))
	end

	local hasJoinDates = Array.any(players, Operator.property('join')) or Array.any(coaches, Operator.property('join'))
	local hasLeaveDates = Array.any(players, Operator.property('leave')) or Array.any(coaches, Operator.property('leave'))

	local rows = mw.html.create()
	for _, data in ipairs(players) do
		rows:node(QuickviewPage._toRosterRow(data, hasLeaveDates, hasJoinDates))
	end
	for _, data in ipairs(coaches) do
		rows:node(QuickviewPage._toRosterRow(data, hasLeaveDates, hasJoinDates))
	end

	return rows, hasLeaveDates, hasJoinDates, coaches, nationalities
end

function QuickviewPage._processName(name, prefix, team, startDate, flag, displayName)
	local redirectedName = mw.ext.TeamLiquidIntegration.resolve_redirect(name)

	local playerData = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. redirectedName:gsub(' ', '_') .. ']]',
		query = 'name, id',
	})[1] or {}

	if not(playerData.name) then
		playerData = mw.ext.LiquipediaDB.lpdb('squadplayer', {
			conditions = '[[link::' .. redirectedName .. ']]',
			query = 'name, id'
		})[1] or {}
	end

	local role = prefix == 'c' and 'Coach' or ''

	local teams = Team.queryHistoricalNames(team)

	local joinData = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = '[[player::' .. name:gsub('_', ' ') .. ']] AND (([[toteam::' .. table.concat(teams, ']] OR [[toteam::') .. ']]) OR ([[toteam_2::' .. table.concat(teams, ']] OR [[toteam_2::') .. ']])) AND ([[role2::!-]] OR [[role2_2::!-]])',
		order = 'date desc',
		query = 'date, reference',
		limit = 1,
	})[1] or {}

	local leaveData = {}

	if startDate then
    leaveData = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = '[[player::' .. name:gsub('_', ' ') .. ']] AND (([[fromteam::' .. table.concat(teams, ']] OR [[fromteam::') .. ']]) OR ([[fromteam_2::' .. table.concat(teams, ']] OR [[fromteam_2::') .. ']])) AND ([[role1::!-]] OR [[role1_2::!-]]) AND [[date::>' .. startDate .. ']]',
		order = 'date desc',
		query = 'date, toteam, reference',
		limit = 1,
	})[1] or {}
	end

	return {
		isCoach = prefix == 'c',
		link = name,
		tag = playerData.id or displayName,
		flag = flag or 'filler',
		name = playerData.name,
		join = joinData.date and LANG:formatDate('Y-m-d', joinData.date) or nil,
		joinRef = TransferRef.fromStorageData(joinData.reference)[1],
		leave = leaveData.date and LANG:formatDate('Y-m-d', leaveData.date) or nil,
		leaveRef = TransferRef.fromStorageData(leaveData.reference)[1],
		newteam = leaveData.toteam
	}
end

function QuickviewPage._toRosterRow(data, hasLeaveDates, hasJoinDates)
	local row = mw.html.create('tr')

	local idNode = row:tag('td')
			:wikitext(Flags.Icon{flag = data.flag} .. '&nbsp;<b>[[' .. data.link .. '|' .. data.tag .. ']]</b>')
	if data.isCoach then
		idNode:wikitext(' <small><i>(Coach)</i></small>')
	end

	row:tag('td'):wikitext(data.name)

	if hasJoinDates then
        local joinInfo = data.join and (data.join .. ' ') or ''
		if data.joinRef and data.joinRef.refType == 'web source' and Logic.isNotEmpty(data.joinRef.link) then
			joinInfo = mw.ustring.format('%s<sup>[%s]</sup>', joinInfo, data.joinRef.link)
		end
        row:tag('td')
            :css('font-style', 'italic')
            :wikitext(joinInfo)
    end

    if hasLeaveDates then
        local leaveInfo = data.leave and (data.leave .. ' ') or ''
		if data.leaveRef and data.leaveRef.refType == 'web source' and Logic.isNotEmpty(data.leaveRef.link) then
			leaveInfo = mw.ustring.format('%s<sup>[%s]</sup>', leaveInfo, data.leaveRef.link)
		end
        row:tag('td')
            :css('font-style', 'italic')
            :wikitext(leaveInfo)

        		row:tag('td'):wikitext(Logic.isNotEmpty(data.newteam) and Team.queryDB('team', data.newteam) or '')
	end

	return row
end

return EmptyTeamPagePreview
