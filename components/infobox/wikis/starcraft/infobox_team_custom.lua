---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Info = require('Module:Info')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local Math = require('Module:Math')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent/Starcraft', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Title = Widgets.Title

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local CustomTeam = Class.new()

local CustomInjector = Class.new(Injector)
local _LANGUAGE = mw.language.new('en')

local _EARNINGS_MODES = {team = Opponent.team}
local _ALLOWED_PLACES = {'1', '2', '3', '4', '3-4'}
local _PLAYER_EARNINGS_ABBREVIATION = '<abbr title="Earnings of players while on the team">Player earnings</abbr>'

local _args
local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	_args = team.args

	team.getWikiCategories = CustomTeam.getWikiCategories
	team.addToLpdb = CustomTeam.addToLpdb
	team.createWidgetInjector = CustomTeam.createWidgetInjector
	team.calculateEarnings = CustomTeam.calculateEarnings
	team.shouldStore = CustomTeam.shouldStore
	team.defineCustomPageVariables = CustomTeam.defineCustomPageVariables

	return team:createInfobox()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Gaming Director',
		content = {_args['gaming director']}
	})
	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'earnings' then
		table.insert(widgets, Cell{name = _PLAYER_EARNINGS_ABBREVIATION,
			content = {
				_team.totalEarningsWhileOnTeam and '$' .. _LANGUAGE:formatNum(_team.totalEarningsWhileOnTeam) or nil
			}
		})
	elseif id == 'achievements' then
		table.insert(widgets, Cell{name = 'Solo Achievements', content = {_args['solo achievements']}})
		--need this ABOVE the history display and below the
		--achievements display, hence moved it here
		local playerBreakDown = CustomTeam.playerBreakDown(_args)
		if playerBreakDown.playernumber then
				table.insert(widgets, Title{name = 'Player Breakdown'})
				table.insert(widgets, Cell{name = 'Number of players', content = {playerBreakDown.playernumber}})
				table.insert(widgets, Breakdown{content = playerBreakDown.display, classes = {'infobox-center'}})
		end
	elseif id == 'history' then
		local index = 1
		while(not String.isEmpty(_args['history' .. index .. 'title'])) do
			table.insert(widgets, Cell{
				name = _args['history' .. index .. 'title'],
				content = {_args['history' .. index]}
			})
			index = index + 1
		end
	end
	return widgets
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomTeam:addToLpdb(lpdbData)
	lpdbData.region = nil
	lpdbData.extradata.subteams = CustomTeam._listSubTeams()

	lpdbData.extradata.playerearnings = _team.totalEarningsWhileOnTeam
	for year, playerEarningsOfYear in pairs(_team.earningsWhileOnTeam or {}) do
		lpdbData.extradata['playerearningsin' .. year] = playerEarningsOfYear
	end

	return lpdbData
end

function CustomTeam.getWikiCategories()
	local categories = {}
	if String.isNotEmpty(_args.disbanded) then
		table.insert(categories, 'Disbanded Teams')
	end
	return categories
end

-- gets a list of sub/accademy teams of the team
-- this data can be used in results queries to include
-- results of accademy teams of the current team
function CustomTeam._listSubTeams()
	if String.isEmpty(_args.subteam) and String.isEmpty(_args.subteam1) then
		return nil
	end
	local subTeams = Team:getAllArgsForBase(_args, 'subteam')
	local subTeamsToStore = {}
	for index, subTeam in pairs(subTeams) do
		subTeamsToStore['subteam' .. index] = mw.ext.TeamLiquidIntegration.resolve_redirect(subTeam)
	end
	return Json.stringify(subTeamsToStore)
end

function CustomTeam.playerBreakDown(args)
	local playerBreakDown = {}
	local playernumber = tonumber(args.player_number) or 0
	local zergnumber = tonumber(args.zerg_number) or 0
	local terrannumbner = tonumber(args.terran_number) or 0
	local protossnumber = tonumber(args.protoss_number) or 0
	local randomnumber = tonumber(args.random_number) or 0
	if playernumber == 0 then
		playernumber = zergnumber + terrannumbner + protossnumber + randomnumber
	end

	if playernumber > 0 then
		playerBreakDown.playernumber = playernumber
		if zergnumber + terrannumbner + protossnumber + randomnumber > 0 then
			playerBreakDown.display = {}
			if protossnumber > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1] = Faction.Icon{faction = 'p'} .. ' ' .. protossnumber
			end
			if terrannumbner > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1] = Faction.Icon{faction = 't'} .. ' ' .. terrannumbner
			end
			if zergnumber > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1] = Faction.Icon{faction = 'z'} .. ' ' .. zergnumber
			end
			if randomnumber > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1] = Faction.Icon{faction = 'r'} .. ' ' .. randomnumber
			end
		end
	end
	return playerBreakDown
end

function CustomTeam:calculateEarnings(args)
	if not self:shouldStore() then
		self.totalEarningsWhileOnTeam = 0
		self.earningsWhileOnTeam = {}
		return 0, {}
	else
		local total, yearly, playerTotal, playerYearly = self:getEarningsAndMedalsData(self.pagename)
		self.totalEarningsWhileOnTeam = playerTotal or 0
		self.earningsWhileOnTeam = playerYearly or {}
		return total or 0, yearly or {}
	end
end

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
	for _, item in pairs(_ALLOWED_PLACES) do
		placementConditions:add{
			ConditionNode(ColumnName('placement'), Comparator.eq, item),
		}
	end

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.neq, '1970-01-01 00:00:00'),
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
			medals = self:_addPlacementToMedals(medals, placement)
		elseif mode == Opponent.team then
			teamMedals = self:_addPlacementToMedals(teamMedals, placement)
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
	if self:shouldStore() then
		mw.ext.LiquipediaDB.lpdb_datapoint('total_earnings_players_while_on_team_' .. team, {
				type = 'total_earnings_players_while_on_team',
				name = _team.pagename,
				information = playerEarnings,
		})
	end

	for _, earningsTable in pairs(earnings) do
		for key, value in pairs(earningsTable) do
			earningsTable[key] = Math.round{value}
		end
	end

	return Table.extract(earnings.team or {}, 'total'), earnings.team,
		Table.extract(earnings.other or {}, 'total'), earnings.other
end

function CustomTeam:_addPlacementToEarnings(earnings, playerEarnings, data)
	local prizeMoney = data.prizemoney
	data.opponentplayers = data.opponentplayers or {}
	local mode = data.opponenttype
	mode = _EARNINGS_MODES[mode]
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

function CustomTeam:_addPlacementToMedals(medals, data)
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

function CustomTeam._setVarsFromTable(table, prefix)
	for key1, item1 in pairs(table) do
		for key2, item2 in pairs(item1) do
			Variables.varDefine((prefix or '') .. key1 .. '_' .. key2, item2)
		end
	end
end

function CustomTeam._placements(value)
	value = mw.text.split(value or '', '-')[1]
	if value == '1' or value == '2' then
		return value
	elseif value == '3' then
		return 'sf'
	end
end

function CustomTeam:_amountOfTeamPlayersInPlacement(players)
	local amount = 0
	for playerKey in Table.iter.pairsByPrefix(players, 'p') do
		if players[playerKey .. 'team'] == self.pagename then
			amount = amount + 1
		end
	end

	return amount
end

function CustomTeam:shouldStore(args)
	return not Logic.readBool(args.disable_smw) and
		not Logic.readBool(args.disable_lpdb) and
		not Logic.readBool(args.disable_storage) and
		not Logic.readBool(Variables.varDefault('disable_SMW_storage')) and
		Namespace.isMain()
end

function CustomTeam:defineCustomPageVariables(args)
	if not CustomTeam:shouldStore(args) then
		Variables.varDefine('disable_SMW_storage', 'true')
	end
end

return CustomTeam
