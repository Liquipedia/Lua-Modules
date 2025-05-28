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
local Team = Lua.import('Module:Team') -- to be replaced by #5900 / #5649 / ...
local Table = Lua.import('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local Infobox = Lua.import('Module:Infobox/Team/Custom')
local MatchTable = Lua.import('Module:MatchTable/Custom')
local ResultsTable = Lua.import('Module:ResultsTable/Custom')
local SquadAuto = Lua.import('Module:SquadAuto') -- to be replaced by #5523

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

	self.team = Team.queryDB('teampage', mw.title.getCurrentTitle().prefixedText)

	if not self.team then return end

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

---@return string
function EmptyTeamPagePreview:_infobox()
	local data = self:_getNationalitiesAndCoaches()

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

---@return Widget
function EmptyTeamPagePreview:roster()
	-- the old ones use roster of last placement instead ...
	-- maybe have to switch back
	return HtmlWidgets.Fragment{
		children = {
			HtmlWidgets.H3{children = 'Roster'},
			HtmlWidgets.H4{children = 'Active'},
			tostring(SquadAuto.active{
				team = self.team,
				roles = 'None,Loan,Substitute,Trial,Stand-in,Uncontracted', -- copied from commons template
				type = 'Player_active',
			}),
			HtmlWidgets.H4{children = 'Inactive'},
			tostring(SquadAuto.inactive{
				team = self.team,
				type = 'Player_inactive',
			}),
			HtmlWidgets.H4{children = 'Former'},
			tostring(SquadAuto.active{
				team = self.team,
				roles = 'None,Loan,Substitute,Inactive,Trial,Stand-in,Uncontracted', -- copied from commons template
				type = 'Player_former',
			}),
			HtmlWidgets.H3{children = 'Active Organization'},
			tostring(SquadAuto.active{
				team = self.team,
				not_roles = 'None,Loan,Substitute,Inactive,Trial,Stand-in,Uncontracted', -- copied from commons template
				type = 'Organization_active',
				title = 'Organization',
				position = 'Position',
			}),
		}
	}
end

---@return Widget
function EmptyTeamPagePreview:_matches()
	return HtmlWidgets.Fragment{
		children = {
			HtmlWidgets.H3{children = 'Most Recent Matches'},
			tostring(MatchTable.results{
				tableMode = 'team',
				showType = true,
				team = self.team,
				limit = 10,
			})
		}
	}
end

---@return Widget
function EmptyTeamPagePreview:_results()
	return HtmlWidgets.Fragment{
		children = {
			HtmlWidgets.H3{children = 'Notable Results'},
			tostring(ResultsTable.results{
				team = self.team,
				awards = false,
				achievements = true,
				playerResultsOfTeam = false,
				querytype = 'team',
			})
		}
	}
end

---@return {coaches: {flag: string?, pageName: string?, displayName: string?}[], nationalities: table<string, integer>}
function EmptyTeamPagePreview:_getNationalitiesAndCoaches()
	local latestResult = self:_fetchPlacements{limit = 1}[1]
	if not latestResult then return {coaches = {}, nationalities = {}} end

	local nationalities = {}
	for prefix in Table.iter.pairsByPrefix(latestResult.opponentplayers, 'p') do
		local flag = latestResult.opponentplayers[prefix .. 'flag']
		nationalities[flag] = (nationalities[flag] or 0) + 1
	end

	local coaches = {}
	for prefix, coach in Table.iter.pairsByPrefix(latestResult.opponentplayers, 'c') do
		table.insert(coaches, {
			flag = latestResult.opponentplayers[prefix .. 'flag'],
			displayName = latestResult.opponentplayers[prefix .. 'dn'],
			pageName = coach,
		})
	end

	return {coaches = coaches, nationalities = nationalities}
end

return EmptyTeamPagePreview
