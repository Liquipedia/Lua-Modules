---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Info = require('Module:Info')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Injector = Lua.import('Module:Widget/Injector')
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown')
local Team = Lua.import('Module:Infobox/Team')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local Widgets = require('Module:Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Title = Widgets.Title

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

---@class StarcraftInfoboxTeam: InfoboxTeam
---@field totalEarningsWhileOnTeam number
---@field earningsWhileOnTeam table<integer, number>
local CustomTeam = Class.new(Team)

local CustomInjector = Class.new(Injector)

local EARNINGS_MODES = {team = Opponent.team}
local ALLOWED_PLACES = {'1', '2', '3', '4', '3-4'}
local PLAYER_EARNINGS_ABBREVIATION = '<abbr title="Earnings of players while on the team">Player earnings</abbr>'

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	team.args.achievements = Achievements.team()

	team:setWidgetInjector(CustomInjector(team))

	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		table.insert(widgets, Cell{name = 'Gaming Director', content = {args['gaming director']}})
	elseif id == 'earnings' then
		local displayEarnings = function(value)
			return value > 0 and '$' .. mw.getContentLanguage():formatNum(value) or nil
		end

		return {
			Cell{name = 'Approx. Total Winnings', content = {displayEarnings(self.caller.totalEarnings)}},
			Cell{name = PLAYER_EARNINGS_ABBREVIATION, content = {displayEarnings(self.caller.totalEarningsWhileOnTeam)}},
		}
	elseif id == 'achievements' then
		table.insert(widgets, Cell{name = 'Solo Achievements', content = {args['solo achievements']}})
		--need this ABOVE the history display and below the
		--achievements display, hence moved it here
		local raceBreakdown = RaceBreakdown.run(args)
		if raceBreakdown then
			Array.appendWith(widgets,
				Title{children = 'Player Breakdown'},
				Cell{name = 'Number of Players', content = {raceBreakdown.total}},
				Breakdown{children = raceBreakdown.display, classes = { 'infobox-center' }}
			)
		end
	elseif id == 'history' then
		local index = 1
		while(not String.isEmpty(args['history' .. index .. 'title'])) do
			table.insert(widgets, Cell{
				name = args['history' .. index .. 'title'],
				content = {args['history' .. index]}
			})
			index = index + 1
		end
	end
	return widgets
end

---@param region string?
---@return {display: string?, region: string?}
function CustomTeam:createRegion(region)
	return {}
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.extradata.subteams = self:_listSubTeams()

	lpdbData.extradata.playerearnings = self.totalEarningsWhileOnTeam
	for year, playerEarningsOfYear in pairs(self.earningsWhileOnTeam or {}) do
		lpdbData.extradata['playerearningsin' .. year] = playerEarningsOfYear
	end

	return lpdbData
end

---@param args table
---@return string[]
function CustomTeam:getWikiCategories(args)
	local categories = {}
	if String.isNotEmpty(args.disbanded) then
		table.insert(categories, 'Disbanded Teams')
	end
	return categories
end

-- gets a list of sub/accademy teams of the team
-- this data can be used in results queries to include
-- results of accademy teams of the current team
---@return string?
function CustomTeam:_listSubTeams()
	if String.isEmpty(self.args.subteam) and String.isEmpty(self.args.subteam1) then
		return nil
	end
	local subTeams = Team:getAllArgsForBase(self.args, 'subteam')
	local subTeamsToStore = {}
	for index, subTeam in pairs(subTeams) do
		subTeamsToStore['subteam' .. index] = mw.ext.TeamLiquidIntegration.resolve_redirect(subTeam)
	end
	return Json.stringify(subTeamsToStore)
end

---@param args table
---@return boolean
function CustomTeam:shouldStore(args)
	return Namespace.isMain() and
		not Logic.readBool(args.disable_lpdb) and
		not Logic.readBool(args.disable_storage) and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
end

---@param args table
---@return number
---@return table<integer, number>
function CustomTeam:calculateEarnings(args)
	if not self:shouldStore(args) then
		self.totalEarningsWhileOnTeam = 0
		self.earningsWhileOnTeam = {}
		return 0, {}
	end

	local total, yearly, playerTotal, playerYearly = self:getEarningsAndMedalsData(self.pagename)
	self.totalEarningsWhileOnTeam = playerTotal or 0
	self.earningsWhileOnTeam = playerYearly or {}
	return total or 0, yearly or {}
end

---@param team string
---@return number
---@return table<integer, number>
---@return number
---@return table<integer, number>
function CustomTeam:getEarningsAndMedalsData(team)
	local query = 'liquipediatier, liquipediatiertype, placement, date, '
		.. 'individualprizemoney, prizemoney, opponentplayers, opponenttype'

	local playerTeamConditions = ConditionTree(BooleanOperator.any)
	for playerIndex = 1, Info.maximumNumberOfPlayersInPlacements do
		playerTeamConditions:add{
			ConditionNode(ColumnName('opponentplayers_p' .. playerIndex .. 'team'), Comparator.eq, team),
		}
	end

	local placementConditions = ConditionTree(BooleanOperator.any)
	for _, item in pairs(ALLOWED_PLACES) do
		placementConditions:add{
			ConditionNode(ColumnName('placement'), Comparator.eq, item),
		}
	end

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDateTime),
		ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Charity'),
		ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Qualifier'),
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('prizemoney'), Comparator.gt, '0'),
			ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.team),
				ConditionNode(ColumnName('opponentname'), Comparator.eq, team),
				placementConditions,
			},
		},
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('opponentname'), Comparator.eq, team),
			ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('opponenttype'), Comparator.neq, Opponent.team),
				playerTeamConditions
			},
		},
	}

	local queryParameters = {
		conditions = conditions:toString(),
		query = query,
		order = 'weight desc, liquipediatier asc, placement asc',
	}

	local earnings = {}
	local medals = {}
	local teamMedals = {}
	local playerEarnings = 0
	earnings['total'] = {}
	medals['total'] = {}
	teamMedals['total'] = {}

	local processPlacement = function(placement)
		--handle earnings
		earnings, playerEarnings = self:_addPlacementToEarnings(earnings, playerEarnings, placement)

		--handle medals
		local mode = placement.opponenttype
		if mode == Opponent.solo then
			medals = CustomTeam._addPlacementToMedals(medals, placement)
		elseif mode == Opponent.team then
			teamMedals = CustomTeam._addPlacementToMedals(teamMedals, placement)
		end
	end

	Lpdb.executeMassQuery('placement', queryParameters, processPlacement)

	CustomTeam._setVarsFromTable(earnings)
	CustomTeam._setVarsFromTable(medals)
	CustomTeam._setVarsFromTable(teamMedals, 'team_')

	if earnings.team == nil then
		earnings.team = {}
	end

	-- to be removed after a purge run + consumer updates
	if self:shouldStore(self.args) then
		mw.ext.LiquipediaDB.lpdb_datapoint('total_earnings_players_while_on_team_' .. team, {
				type = 'total_earnings_players_while_on_team',
				name = self.pagename,
				information = playerEarnings,
		})
	end

	for _, earningsTable in pairs(earnings) do
		for key, value in pairs(earningsTable) do
			earningsTable[key] = Math.round(value)
		end
	end

	return Table.extract(earnings.team or {}, 'total'), earnings.team or {},
		Table.extract(earnings.other or {}, 'total'), earnings.other or {}
end

---@param earnings table
---@param playerEarnings number
---@param data placement
---@return table
---@return number
function CustomTeam:_addPlacementToEarnings(earnings, playerEarnings, data)
	local prizeMoney = data.prizemoney
	data.opponentplayers = data.opponentplayers or {}
	local mode = data.opponenttype --[[@as string]]
	mode = EARNINGS_MODES[mode]
	if not mode then
		prizeMoney = data.individualprizemoney * self:_amountOfTeamPlayersInPlacement(data.opponentplayers)
		playerEarnings = playerEarnings + prizeMoney
		mode = 'other'
	end
	if not earnings[mode] then
		earnings[mode] = {}
	end
	local date = string.sub(data.date, 1, 4)
	earnings[mode][date] = (earnings[mode][date] or 0) + prizeMoney
	earnings[mode]['total'] = (earnings[mode]['total'] or 0) + prizeMoney
	earnings['total'][date] = (earnings['total'][date] or 0) + prizeMoney

	return earnings, playerEarnings
end

---@param medals table
---@param data placement
---@return table
function CustomTeam._addPlacementToMedals(medals, data)
	local place = CustomTeam._placements(data.placement)
	if place then
		if data.liquipediatiertype ~= 'Qualifier' then
			local tier = data.liquipediatier or 'undefined'
			if not medals[place] then
				medals[place] = {}
			end
			medals[place][tier] = (medals[place][tier] or 0) + 1
			medals[place]['total'] = (medals[place]['total'] or 0) + 1
			medals['total'][tier] = (medals['total'][tier] or 0) + 1
		end
	end

	return medals
end

---@param tbl table
---@param prefix string?
function CustomTeam._setVarsFromTable(tbl, prefix)
	for key1, item1 in pairs(tbl) do
		for key2, item2 in pairs(item1) do
			Variables.varDefine((prefix or '') .. key1 .. '_' .. key2, item2)
		end
	end
end

---@param value string
---@return string?
function CustomTeam._placements(value)
	value = mw.text.split(value or '', '-')[1]
	if value == '1' or value == '2' then
		return value
	elseif value == '3' then
		return 'sf'
	end
end

---@param players table
---@return integer
function CustomTeam:_amountOfTeamPlayersInPlacement(players)
	local amount = 0
	for playerKey in Table.iter.pairsByPrefix(players, 'p') do
		if players[playerKey .. 'team'] == self.pagename then
			amount = amount + 1
		end
	end

	return amount
end

---@param args table
function CustomTeam:defineCustomPageVariables(args)
	if not self:shouldStore(args) then
		Variables.varDefine('disable_LPDB_storage', 'true')
	end
end

return CustomTeam
