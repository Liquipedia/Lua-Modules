---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/EmptyPagePreview/Team
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
local Page = Lua.import('Module:Page')
local Region = Lua.import('Module:Region')
local Table = Lua.import('Module:Table')
local Team = Lua.import('Module:Team') -- to be replaced by #5900 / #5649 / ...
local Tournament = Lua.import('Module:Tournament')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local Infobox = Lua.import('Module:Infobox/Team/Custom')
local MatchTable = Lua.import('Module:MatchTable/Custom')
local ResultsTable = Lua.import('Module:ResultsTable/Custom')
local SquadAuto = Lua.import('Module:SquadAuto') -- to be replaced by #5523
local SquadCustom = Lua.import('Module:Squad/Custom')
local SquadUtils = Lua.import('Module:Squad/Utils')
local TransferRef = Lua.import('Module:Transfer/References')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

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

	self.team = Team.queryDB('teampage', mw.title.getCurrentTitle().prefixedText)

	if not self.team then return end

	self.teams = Team.queryHistoricalNames(self.team)

	local rosterFromLastPlacement = Logic.readBool(self.props.rosterFromLastPlacement)

	return HtmlWidgets.Div{
		children = WidgetUtil.collect(
			HtmlWidgets.H2{children = {'Overview'}},
			self:_infobox(),
			rosterFromLastPlacement and self:_rosterFromLastPlacement() or self:_rosterFromTransfers(),
			self:_matches(),
			self:_results(),
			HtmlWidgets.H2{children = {'References'}}
		),
	}
end

---@return Html
function EmptyTeamPagePreview:_infobox()
	local data = self:_getNationalitiesAndCoachesFromLastPlacement()

	local coaches
	if Logic.isNotEmpty(data.coaches) then
		coaches = HtmlWidgets.Fragment{
			children = Array.interleave(Array.map(data.coaches, function(coach)
				return HtmlWidgets.Fragment{
					children = {
						Flags.Icon{flag = coach.flag},
						'&nbsp;',
						Link{link = coach.pageName, children = {coach.displayName}},
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
		queryEarningsHistorical = Logic.nilOr(Logic.readBoolOrNil(self.props.queryEarningsHistorical), true),
		doNotIncludePlayerEarnings = Logic.nilOr(Logic.readBoolOrNil(self.props.doNotIncludePlayerEarnings), true),
		name = Team.name(nil, self.team),
		coaches = coaches,
		region = self:_determineRegionFromPlacements() or rosterRegion,
		wiki = EmptyTeamPagePreview._getWiki(self.props, games),
	}
	-- some wikis (e.g. cs, val) will need this
	Array.forEach(games, function(game)
		args[game] = true
	end)

	return Infobox.run(args)
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

	local teamPageNameWithoutUnderscores = self.team:gsub("^%l", string.upper):gsub('_', ' ')
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
		conditions = tostring(conditions),
		order = 'date desc, startdate desc',
		groupby = options.groupBy,
		query = options.query,
		limit = options.limit or 5000,
	})
end

---@return string?
function EmptyTeamPagePreview:_determineRegionFromPlacements()
	local placements = self:_fetchPlacements{
		query = 'parent'
	}

	local regions = Array.map(placements, function(placement)
		local tournament = Tournament.getTournament(placement.parent) or {}
		return tournament.region
	end)
	local regionGroups = Array.groupBy(regions, FnUtil.identity)
	Array.sortInPlaceBy(regionGroups, function(regionGroup) return Table.size(regionGroup) end)
	return (regionGroups[1] or {})[1]
end

---@return Widget[]
function EmptyTeamPagePreview:_rosterFromTransfers()
	return WidgetUtil.collect(
		HtmlWidgets.H3{children = 'Roster'},
		HtmlWidgets.H4{children = 'Active'},
		SquadAuto.active{
			team = self.team,
			roles = 'None,Loan,Substitute,Trial,Stand-in,Uncontracted', -- copied from commons template
			type = 'Player_active',
		},
		HtmlWidgets.H4{children = 'Inactive'},
		SquadAuto.inactive{
			team = self.team,
			type = 'Player_inactive',
		},
		HtmlWidgets.H4{children = 'Former'},
		SquadAuto.former{
			team = self.team,
			roles = 'None,Loan,Substitute,Inactive,Trial,Stand-in,Uncontracted', -- copied from commons template
			type = 'Player_former',
		},
		HtmlWidgets.H3{children = 'Active Organization'},
		SquadAuto.active{
			team = self.team,
			not_roles = 'None,Loan,Substitute,Inactive,Trial,Stand-in,Uncontracted', -- copied from commons template
			type = 'Organization_active',
			title = 'Organization',
			position = 'Position',
		}
	)
end

---@return (Widget|Html)[]
function EmptyTeamPagePreview:_matches()
	return {
		HtmlWidgets.H3{children = 'Most Recent Matches'},
		MatchTable.results{
			tableMode = 'team',
			showType = true,
			team = self.team,
			limit = 10,
		}
	}
end

---@return (Widget|Html)[]
function EmptyTeamPagePreview:_results()
	return {
		HtmlWidgets.H3{children = 'Notable Results'},
		ResultsTable.results{
			team = self.team,
			awards = false,
			achievements = true,
			playerResultsOfTeam = false,
			querytype = 'team',
		}
	}
end

---@return {coaches: {flag: string?, displayName: string, pageName: string}[], nationalities: table<string, integer>}
function EmptyTeamPagePreview:_getNationalitiesAndCoachesFromLastPlacement()
	local data = self:_getPlayersAndCoachesFromLastPlacement()
	local nationalities = {}

	Array.forEach(data.players, function(player)
		local flag = player.flag
		if not flag then return end
		nationalities[flag] = (nationalities[flag] or 0) + 1
	end)

	return {coaches = data.coaches, nationalities = nationalities}
end

---@return {coaches: {flag: string?, displayName: string, pageName: string, name: string?}[],
---players: {flag: string?, displayName: string, pageName: string, name: string?}[], startDate: string?}
function EmptyTeamPagePreview:_getPlayersAndCoachesFromLastPlacement()
	local latestResult = self:_fetchPlacements{limit = 1}[1]
	if not latestResult then return {coaches = {}, nationalities = {}} end

	local parsePerson = function (prefix)
		local person = Page.pageifyLink(latestResult.opponentplayers[prefix])
		---@type player|squadplayer
		local personObject = mw.ext.LiquipediaDB.lpdb('player', {
			conditions = tostring(ConditionNode(ColumnName('pagename'), Comparator.eq, person)),
			query = 'name, id, nationality',
		})[1] or {}

		if Logic.isEmpty(personObject) then
			personObject = mw.ext.LiquipediaDB.lpdb('squadplayer', {
			conditions = '[[link::' .. person .. ']]',
			query = 'name, id, nationality'
		})[1] or {}
		end

		return {
			flag = latestResult.opponentplayers[prefix .. 'flag'] or personObject.nationality,
			displayName = latestResult.opponentplayers[prefix .. 'dn']
				or personObject.id
				or latestResult.opponentplayers[prefix],
			pageName = person,
			name = personObject.name,
		}
	end

	local players = {}
	for prefix in Table.iter.pairsByPrefix(latestResult.opponentplayers, 'p') do
		table.insert(players, parsePerson(prefix))
	end

	local coaches = {}
	for prefix in Table.iter.pairsByPrefix(latestResult.opponentplayers, 'c') do
		table.insert(coaches, parsePerson(prefix))
	end

	return {coaches = coaches, players = players, startDate = latestResult.startdate}
end

---@return Widget[]
function EmptyTeamPagePreview:_rosterFromLastPlacement()
	local data = self:_getPlayersAndCoachesFromLastPlacement()

	local backFillPerson = FnUtil.curry(FnUtil.curry(EmptyTeamPagePreview._backFillForSquad, self), data.startDate)

	local players = Array.map(data.players, backFillPerson)
	local coaches = Array.map(data.coaches, backFillPerson)

	local activePlayers = Array.filter(players, function(player)
		return Logic.isEmpty(player.leavedate)
	end)
	local formerPlayers = Array.filter(players, function(player)
		return Logic.isNotEmpty(player.leavedate)
	end)
	local activeCoaches = Array.filter(coaches, function(coach)
		return Logic.isEmpty(coach.leavedate)
	end)

	local hasFormer = Logic.isNotEmpty(formerPlayers)
	local hasCoaches = Logic.isNotEmpty(activeCoaches)

	return WidgetUtil.collect(
		HtmlWidgets.H3{children = 'Most Recent Roster'},
		hasFormer and HtmlWidgets.H4{children = 'Active'} or nil,
		SquadCustom.runAuto(activePlayers, SquadUtils.SquadStatus.ACTIVE, SquadUtils.SquadType.PLAYER),
		hasFormer and HtmlWidgets.H4{children = 'Former'} or nil,
		hasFormer and SquadCustom.runAuto(formerPlayers, SquadUtils.SquadStatus.FORMER, SquadUtils.SquadType.PLAYER) or nil,
		hasCoaches and HtmlWidgets.H3{children = 'Active Organization'} or nil,
		hasCoaches and SquadCustom.runAuto(activeCoaches, SquadUtils.SquadStatus.ACTIVE, SquadUtils.SquadType.STAFF) or nil
	)
end

---@param startDate string?
---@param personData {flag: string?, displayName: string, pageName: string, name: string?}
---@return table
function EmptyTeamPagePreview:_backFillForSquad(startDate, personData)
	local teams = self.teams

	local pageName = personData.pageName
	local pageNameWithSpaces = pageName:gsub('_', ' ')
	local personCondition = ConditionTree(BooleanOperator.any):add{
		ConditionNode(ColumnName('player'), Comparator.eq, pageName),
		ConditionNode(ColumnName('player'), Comparator.eq, pageNameWithSpaces),
	}

	---@param direction 'to'|'from'
	---@return ConditionTree
	local makeTeamConditions = function(direction)
		return ConditionTree(BooleanOperator.any):add{
			Array.map(teams, function(team)
				return ConditionNode(ColumnName(direction .. 'team'), Comparator.eq, team)
			end),
			Array.map(teams, function(team)
				return ConditionNode(ColumnName(direction .. 'team_2'), Comparator.eq, team)
			end),
		}
	end

	local joinConditions = ConditionTree(BooleanOperator.all):add{
		personCondition,
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('role2'), Comparator.neq, '-'),
			ConditionNode(ColumnName('role2_2'), Comparator.neq, '-'),
		},
		makeTeamConditions('to'),
	}

	local joinData = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = tostring(joinConditions),
		order = 'date desc',
		query = 'date, reference, extradata',
		limit = 1,
	})[1] or {extradata = {}}

	local leaveData = {extradata = {}}
	if startDate then
		local leaveConditions = ConditionTree(BooleanOperator.all):add{
			personCondition,
			ConditionNode(ColumnName('date'), Comparator.gt, startDate),
			ConditionTree(BooleanOperator.any):add{
				ConditionNode(ColumnName('role1'), Comparator.neq, '-'),
				ConditionNode(ColumnName('role1_2'), Comparator.neq, '-'),
			},
			makeTeamConditions('from'),
		}
		leaveData = mw.ext.LiquipediaDB.lpdb('transfer', {
			conditions = tostring(leaveConditions),
			order = 'date desc',
			query = 'date, toteam, reference, extradata',
			limit = 1,
		})[1] or {extradata = {}}
	end

	return {
		name = personData.name,
		flag = personData.flag,
		id = personData.displayName,
		page = personData.pageName,
		thisTeam = {team = self.team},
		newTeam = {team = leaveData.toteam},
		joindate = joinData.date or '',
		joindatedisplay = joinData.extradata.displaydate,
		joindateRef = TransferRef.fromStorageData(joinData.reference)[1] or '',
		leavedate = leaveData.date or '',
		leavedatedisplay = leaveData.extradata.displaydate,
		leavedateRef = TransferRef.fromStorageData(leaveData.reference)[1] or '',
		faction = leaveData.extradata.faction,
	}
end

return EmptyTeamPagePreview
