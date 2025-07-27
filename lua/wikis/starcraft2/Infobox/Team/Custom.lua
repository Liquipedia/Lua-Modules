---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Math = Lua.import('Module:MathUtil')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Injector = Lua.import('Module:Widget/Injector')
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown')
local Team = Lua.import('Module:Infobox/Team')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local Widgets = Lua.import('Module:Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

---@class Starcraft2InfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

local CustomInjector = Class.new(Injector)

local ALLOWED_PLACES = {'1', '2', '3', '4', '3-4'}
local MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS = 20
local PLAYER_EARNINGS_ABBREVIATION = '<abbr title="Earnings of players while on the team">Player earnings</abbr>'

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	team:setWidgetInjector(CustomInjector(team))

	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'earnings' then
		local displayEarnings = function(earningsData)
			local totalEarnings = Math.sum(Array.extractValues(earningsData or {}))
			return totalEarnings > 0 and '$' .. mw.getContentLanguage():formatNum(totalEarnings) or nil
		end

		return {
			Cell{name = 'Approx. Total Winnings', content = {displayEarnings(self.caller.teamEarnings)}},
			Cell{name = PLAYER_EARNINGS_ABBREVIATION, content = {displayEarnings(self.caller.playerEarnings)}},
		}
	elseif id == 'achievements' then
		local achievements, soloAchievements = Achievements.teamAndTeamSolo()
		widgets = {}
		if achievements then
			table.insert(widgets, Title{children = 'Achievements'})
			table.insert(widgets, Center{children = {achievements}})
		end

		if soloAchievements then
			table.insert(widgets, Title{children = 'Solo Achievements'})
			table.insert(widgets, Center{children = {soloAchievements}})
		end

		--need this ABOVE the history display and below the
		--achievements display, hence moved it here
		local raceBreakdown = RaceBreakdown.run(args)
		if raceBreakdown then
			Array.appendWith(widgets,
				Title{children = 'Player Breakdown'},
				Cell{name = 'Number of Players', content = {raceBreakdown.total}},
				Breakdown{children = raceBreakdown.display, classes = {'infobox-center'}}
			)
		end

		return widgets
	elseif id == 'history' then
		local index = 1
		while(not String.isEmpty(args['history' .. index .. 'title'])) do
			table.insert(widgets, Cell{
				name = args['history' .. index .. 'title'],
				content = {args['history' .. index]}
			})
			index = index + 1
		end
	elseif id == 'staff' then
		return {}
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

	lpdbData.extradata.playerearnings = Table.extract(self.playerEarnings, 'total')
	lpdbData.extradata.teamearnings = Table.extract(self.teamEarnings, 'total')
	for year, playerEarningsOfYear in pairs(self.playerEarnings or {}) do
		lpdbData.extradata['playerearningsin' .. year] = playerEarningsOfYear
	end
	for year, teamEarningsOfYear in pairs(self.teamEarnings or {}) do
		lpdbData.extradata['teamearningsin' .. year] = teamEarningsOfYear
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
	self.teamEarnings = {total = 0}
	self.playerEarnings = {total = 0}

	if not self:shouldStore(args) then
		return 0, {}
	end

	return self:getEarningsAndMedalsData()
end

---@return number
---@return table<integer, number>
function CustomTeam:getEarningsAndMedalsData()
	self.cleanPageName = self.pagename:gsub(' ', '_')

	local playerTeamConditions = ConditionTree(BooleanOperator.any):add{
		ConditionNode(ColumnName('opponentname'), Comparator.eq, self.pagename),
		ConditionNode(ColumnName('opponentname'), Comparator.eq, self.cleanPageName),
	}

	for playerIndex = 1, MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS do
		playerTeamConditions:add{
			ConditionNode(ColumnName('opponentplayers_p' .. playerIndex .. 'team'), Comparator.eq, self.pagename),
			ConditionNode(ColumnName('opponentplayers_p' .. playerIndex .. 'team'), Comparator.eq, self.cleanPageName),
		}
	end

	local placementConditions = ConditionTree(BooleanOperator.any)
	for _, item in pairs(ALLOWED_PLACES) do
		placementConditions:add({
			ConditionNode(ColumnName('placement'), Comparator.eq, item),
		})
	end

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDateTime),
		ConditionNode(ColumnName('liquipediatier'), Comparator.neq, '-1'),
		ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Charity'),
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('prizemoney'), Comparator.gt, '0'),
			ConditionTree(BooleanOperator.all):add{
				placementConditions,
				ConditionTree(BooleanOperator.any):add{
					ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.team),
					ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.solo),
				},
			},
		},
		playerTeamConditions,
	}

	local earnings = {total = {total = 0}, team = {total = 0}, other = {total = 0}}
	self.medals = {solo = {}, team = {}}
	local processPlacement = function(placement)
		self:_addPlacementToEarnings(placement, earnings)

		--handle medals
		local mode = placement.opponenttype
		if mode == Opponent.solo or (mode == Opponent.team and self:_isCorrectTeam(placement.opponentname)) then
			CustomTeam:_addPlacementToMedals(self.medals[mode], placement)
		end
	end

	Lpdb.executeMassQuery('placement', {
		conditions = conditions:toString(),
		query = 'liquipediatier, liquipediatiertype, placement, date, opponentname, '
			.. 'individualprizemoney, prizemoney, opponentplayers, opponenttype',
		order = 'weight desc, liquipediatier asc, placement asc',
	}, processPlacement)

	local totalEarnings = Table.mapValues(earnings.total, Math.round)
	self.teamEarnings = Table.mapValues(earnings.team, Math.round)
	self.playerEarnings = Table.mapValues(earnings.other, Math.round)

	local totalEarningsTotal = Table.extract(totalEarnings, 'total')
	--due to the table extract now totalEarnings is of format `table<integer, number>`
	return totalEarningsTotal, totalEarnings --[[@as table<integer, number>]]
end

---@param team string
---@return boolean
function CustomTeam:_isCorrectTeam(team)
	return team == self.pagename or team == self.cleanPageName
end

---@param tbl table
---@param value number
---@param year integer
function CustomTeam:_addToEarningsTable(tbl, value, year)
	tbl[year] = (tbl[year] or 0) + value
	tbl.total = tbl.total + value
end

---@param data placement
---@param earnings table
function CustomTeam:_addPlacementToEarnings(data, earnings)
	local prize = tonumber(data.prizemoney) or 0
	if prize == 0 then return end

	data.opponentplayers = data.opponentplayers or {}

	local mode = self:_isCorrectTeam(data.opponentname) and 'team' or 'other'

	if mode == 'other' then
		prize = (tonumber(data.individualprizemoney) or 0) * self:_amountOfTeamPlayersInPlacement(data.opponentplayers)
	end

	local year = tonumber(string.sub(data.date, 1, 4)) --[[@as number]]

	self:_addToEarningsTable(earnings[mode], prize, year)
	self:_addToEarningsTable(earnings.total, prize, year)
end

---@param medals table
---@param data placement
function CustomTeam:_addPlacementToMedals(medals, data)
	if data.liquipediatiertype == 'Qualifier' or not Table.includes(ALLOWED_PLACES, data.placement or '') then
		return
	end

	local place = data.placement
	local tier = data.liquipediatier or 'undefined'

	medals[tier] = medals[tier] or self:_emptyMedalsTable()
	medals.total = medals.total or self:_emptyMedalsTable()

	medals[tier].total = medals[tier].total + 1
	medals[tier][place] = medals[tier][place] + 1
	medals.total[place] = medals.total[place] + 1
	medals.total.total = medals.total.total + 1
end

---@return table
function CustomTeam:_emptyMedalsTable()
	local dataSet = Table.map(ALLOWED_PLACES, function(_, placement) return placement, 0 end)

	return Table.merge(dataSet, {total = 0})
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
		return
	end

	Variables.varDefine('playerEarnings', Json.stringify(self.playerEarnings))
	Variables.varDefine('teamEarnings', Json.stringify(self.teamEarnings))
	Variables.varDefine('medals', Json.stringify(self.medals))
end

return CustomTeam
