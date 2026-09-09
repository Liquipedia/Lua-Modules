---
-- @Liquipedia
-- page=Module:Widget/EmptyPagePreview/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
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
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Tournament = Lua.import('Module:Tournament')

local Opponent = Lua.import('Module:Opponent/Custom')

local Infobox = Lua.requireIfExists('Module:Infobox/Team/Custom')
local MatchTable = Lua.import('Module:MatchTable/Custom')
local ResultsTable = Lua.import('Module:ResultsTable/Custom')
local SquadAuto = Lua.import('Module:SquadAuto') -- to be replaced by #5523
local SquadCustom = Lua.import('Module:Features/Squad/Custom')
local SquadTypes = Lua.import('Module:Features/Squad/Types')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

---@class EmptyTeamPagePreviewProps
---@field pageName string
---@field rosterFromLastPlacement boolean?
---@field doNotIncludePlayerEarnings boolean?
---@field wiki string?
---@field game string?
---@field getLatestGame boolean?

local Helpers = {}

---@param props EmptyTeamPagePreviewProps
---@return VNode?
local EmptyTeamPagePreview = function(props)
	if not Namespace.isMain() or not Infobox then
		return
	end

	local team = TeamTemplate.getPageName(props.pageName)

	if not team then return end

	local teams = TeamTemplate.queryHistoricalNames(team)

	local rosterFromLastPlacement = Logic.readBool(props.rosterFromLastPlacement)

	return Html.Div{
		children = WidgetUtil.collect(
			Html.H2{children = {'Overview'}},
			Helpers._infobox(props, team, teams),
			rosterFromLastPlacement and Helpers._rosterFromLastPlacement(teams, team) or Helpers._rosterFromTransfers(team),
			Helpers._matches(team),
			Helpers._results(team),
			Html.H2{children = {'References'}}
		),
	}
end

---@private
---@param props EmptyTeamPagePreviewProps
---@param team string
---@param teams string[]
---@return Renderable
function Helpers._infobox(props, team, teams)
	local data = Helpers._getNationalitiesAndCoachesFromLastPlacement(teams)

	local coaches
	if Logic.isNotEmpty(data.coaches) then
		coaches = Html.Fragment{
			children = Array.interleave(Array.map(data.coaches, function(coach)
				return Html.Fragment{
					children = {
						Flags.Icon{flag = coach.flag},
						'&nbsp;',
						Link{link = coach.pageName, children = {coach.displayName}},
					}
				}
			end), Html.Br{})
		}
	end

	local regionCounts = {}
	local location
	local rosterRegion
	local rosterSize = 0
	for _, countryRosterSize in pairs(data.nationalities or {}) do
		rosterSize = rosterSize + countryRosterSize
	end
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

	local games = Helpers._fetchGamesFromPlacements(teams)

	local args = {
		location = location or 'World',
		doNotIncludePlayerEarnings = Logic.readBool(props.doNotIncludePlayerEarnings),
		name = TeamTemplate.getRaw(team).name,
		coaches = coaches,
		region = Helpers._determineRegionFromPlacements(teams) or rosterRegion,
	}
	-- some wikis (e.g. cs, val) will need this
	Array.forEach(games, function(game)
		args[game] = true
	end)

	--- suppress the ranking display on RL to not error there
	args.suppressRanking = true

	return Infobox.run(args)
end

---@param props EmptyTeamPagePreviewProps
---@param games string[]
---@return string?
function Helpers._getWiki(props, games)
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
		if Table.includes(games, game) then
			return game
		end
	end
end

---@private
---@param teams string[]
---@return string[]
function Helpers._fetchGamesFromPlacements(teams)
	local placements = Helpers._fetchPlacements(teams, {
		query = 'game',
		groupBy = 'game asc',
		additionalConditions = ConditionTree(BooleanOperator.all):add{
			ConditionNode(ColumnName('placement'), Comparator.neq, ''),
			ConditionUtil.noneOf(ColumnName('game'), Game.unlistedGames()),
		}
	})

	return Array.map(placements, Operator.property('game'))
end

---@private
---@param teams string[]
---@param options {query: string?, groupBy: string?, additionalConditions: ConditionTree?, limit: integer?}?
---@return placement[]
function Helpers._fetchPlacements(teams, options)
	options = options or {}

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDateTime),
		ConditionNode(ColumnName('opponentplayers'), Comparator.neq, ''),
		ConditionNode(ColumnName('opponentplayers'), Comparator.neq, '[]'),
		ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.team),
		ConditionNode(ColumnName('liquipediatier'), Comparator.neq, -1),
		ConditionUtil.anyOf(ColumnName('opponenttemplate'), teams)
	}

	return mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = tostring(conditions),
		order = 'date desc, startdate desc',
		groupby = options.groupBy,
		query = options.query,
		limit = options.limit or 5000,
	})
end

---@private
---@param teams string[]
---@return string?
function Helpers._determineRegionFromPlacements(teams)
	local placements = Helpers._fetchPlacements(teams, {query = 'parent'})

	local regions = Array.map(placements, function(placement)
		local tournament = Tournament.getTournament(placement.parent) or {}
		return tournament.region
	end)
	local regionGroups = Array.groupBy(regions, FnUtil.identity)
	Array.sortInPlaceBy(regionGroups, function(regionGroup) return - Table.size(regionGroup) end)
	return (regionGroups[1] or {})[1]
end

---@private
---@param team string
---@return Renderable[]
function Helpers._rosterFromTransfers(team)
	return WidgetUtil.collect(
		Html.H3{children = 'Roster'},
		Html.H4{children = 'Active'},
		SquadAuto.active{
			team = team,
			roles = 'None,Loan,Substitute,Trial,Stand-in,Uncontracted', -- copied from commons template
			type = 'Player_active',
		},
		Html.H4{children = 'Inactive'},
		SquadAuto.inactive{
			team = team,
			type = 'Player_inactive',
		},
		Html.H4{children = 'Former'},
		SquadAuto.former{
			team = team,
			roles = 'None,Loan,Substitute,Inactive,Trial,Stand-in,Uncontracted', -- copied from commons template
			type = 'Player_former',
		},
		Html.H3{children = 'Active Organization'},
		SquadAuto.active{
			team = team,
			not_roles = 'None,Loan,Substitute,Inactive,Trial,Stand-in,Uncontracted', -- copied from commons template
			type = 'Organization_active',
			title = 'Organization',
			position = 'Position',
		}
	)
end

---@private
---@param team string
---@return Renderable[]
function Helpers._matches(team)
	return {
		Html.H3{children = 'Most Recent Matches'},
		MatchTable.results{
			tableMode = 'team',
			showType = true,
			team = team,
			limit = 10,
		}
	}
end

---@private
---@param team string
---@return Renderable[]
function Helpers._results(team)
	return {
		Html.H3{children = 'Achievements'},
		ResultsTable.results{
			team = team,
			showType = true,
			gameIcons = true,
			awards = false,
			achievements = true,
			playerResultsOfTeam = false,
			querytype = 'team',
		}
	}
end

---@private
---@param teams string[]
---@return {coaches: {flag: string?, displayName: string, pageName: string}[], nationalities: table<string, integer>}
function Helpers._getNationalitiesAndCoachesFromLastPlacement(teams)
	local data = Helpers._getPlayersAndCoachesFromLastPlacement(teams)
	local nationalities = {}

	Array.forEach(data.players, function(player)
		local flag = player.flag
		if not flag then return end
		nationalities[flag] = (nationalities[flag] or 0) + 1
	end)

	return {coaches = data.coaches, nationalities = nationalities}
end

---@private
---@param teams string[]
---@return {coaches: {flag: string?, displayName: string, pageName: string, name: string?}[],
---players: {flag: string?, displayName: string, pageName: string, name: string?}[], startDate: string?}
function Helpers._getPlayersAndCoachesFromLastPlacement(teams)
	local latestResult = Helpers._fetchPlacements(teams, {limit = 1})[1]
	if not latestResult then return {coaches = {}, players = {}} end

	local parsePerson = function (prefix)
		local person = Page.pageifyLink(latestResult.opponentplayers[prefix])
		---@type player|squadplayer
		local personObject = mw.ext.LiquipediaDB.lpdb('player', {
			conditions = tostring(ConditionNode(ColumnName('pagename'), Comparator.eq, person)),
			query = 'name, id, nationality',
		})[1] or {}

		if Logic.isEmpty(personObject) then
			personObject = mw.ext.LiquipediaDB.lpdb('squadplayer', {
			conditions = tostring(ConditionNode(ColumnName('link'), Comparator.eq, person)),
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

---@private
---@param teams string[]
---@param team string
---@return Renderable[]
function Helpers._rosterFromLastPlacement(teams, team)
	local data = Helpers._getPlayersAndCoachesFromLastPlacement(teams)

	local backFillPerson = FnUtil.curry(FnUtil.curry(FnUtil.curry(Helpers._backFillForSquad, teams), team), data.startDate)

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
		Html.H3{children = 'Most Recent Roster'},
		hasFormer and Html.H4{children = 'Active'} or nil,
		SquadCustom.runAuto(activePlayers, SquadTypes.SquadStatus.ACTIVE, SquadTypes.SquadType.PLAYER),
		hasFormer and {
			Html.H4{children = 'Former'},
			SquadCustom.runAuto(formerPlayers, SquadTypes.SquadStatus.FORMER, SquadTypes.SquadType.PLAYER),
		} or nil,
		hasCoaches and {
			Html.H3{children = 'Active Organization'},
			SquadCustom.runAuto(activeCoaches, SquadTypes.SquadStatus.ACTIVE, SquadTypes.SquadType.STAFF),
		} or nil
	)
end

---@private
---@param teams string[]
---@param team string
---@param startDate string?
---@param personData {flag: string?, displayName: string, pageName: string, name: string?}
---@return table?
function Helpers._backFillForSquad(teams, team, startDate, personData)
	local pageName = personData.pageName
	if not pageName then
		return
	end

	local pageNameWithSpaces = pageName:gsub('_', ' ')
	local personCondition = ConditionUtil.anyOf(ColumnName('player'), {pageName, pageNameWithSpaces})

	---@param direction 'to'|'from'
	---@return ConditionTree
	local makeTeamConditions = function(direction)
		return ConditionTree(BooleanOperator.any):add{
			ConditionUtil.anyOf(ColumnName(direction .. 'teamtemplate'), teams),
			ConditionUtil.anyOf(ColumnName(direction .. 'teamsectemplate', 'extradata'), teams),
		}
	end

	local joinConditions = ConditionTree(BooleanOperator.all):add{
		personCondition,
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('role2'), Comparator.neq, '-'),
			ConditionNode(ColumnName('role2sec', 'extradata'), Comparator.neq, '-'),
		},
		makeTeamConditions('to'),
	}

	local joinData = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = tostring(joinConditions),
		order = 'date desc',
		query = 'date, reference, extradata, role2',
		limit = 1,
	})[1] or {extradata = {}}

	local leaveData = {extradata = {}}
	if startDate then
		local leaveConditions = ConditionTree(BooleanOperator.all):add{
			personCondition,
			ConditionNode(ColumnName('date'), Comparator.gt, startDate),
			ConditionTree(BooleanOperator.any):add{
				ConditionNode(ColumnName('role1'), Comparator.neq, '-'),
				ConditionNode(ColumnName('role1sec', 'extradata'), Comparator.neq, '-'),
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
		thisTeam = {
			team = team,
			role = joinData.role2,
		},
		newTeam = {team = leaveData.toteam},
		oldTeam = {team = joinData.fromteam},
		joindate = joinData.date or '',
		joindatedisplay = joinData.extradata.displaydate,
		joindateRef = joinData.reference,
		leavedate = leaveData.date or '',
		leavedatedisplay = leaveData.extradata.displaydate,
		leavedateRef = leaveData.reference,
		faction = leaveData.extradata.faction,
	}
end

return Component.component(EmptyTeamPagePreview, {pageName = mw.title.getCurrentTitle().prefixedText})
