---
-- @Liquipedia
-- wiki=fortnite
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local Math = require('Module:Math')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local CustomTeam = Class.new()

local _PLAYER_EARNINGS_ABBREVIATION = '<abbr title="Earnings of players while on the team">Player earnings</abbr>'
local _MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS = 10
local _EARNINGS_MODES = {team = 'team'}
local _LANGUAGE = mw.language.new('en')

local _team, _args, _earnings

local CustomInjector = Class.new(Injector)

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	_args = team.args

	team.addToLpdb = CustomTeam.addToLpdb
	team.createWidgetInjector = CustomTeam.createWidgetInjector

	return team:createInfobox(frame)
end

function CustomTeam:addToLpdb(lpdbData)
	lpdbData.earnings = _earnings

	return lpdbData
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'earnings' then
		local earningsWhileOnTeam
		_earnings, earningsWhileOnTeam = CustomTeam.calculateEarnings(_args)
		local earningsDisplay
		if _earnings == 0 then
			earningsDisplay = nil
		else
			earningsDisplay = '$' .. _LANGUAGE:formatNum(_earnings)
		end
		local earningsFromPlayersDisplay
		if earningsWhileOnTeam > 0 then
			earningsFromPlayersDisplay = '$' .. _LANGUAGE:formatNum(earningsWhileOnTeam)
		end
		return {
			Cell{name = 'Approx. Total Winnings', content = {earningsDisplay}},
			Cell{name = _PLAYER_EARNINGS_ABBREVIATION, content = {earningsFromPlayersDisplay}},
		}
	end
	return widgets
end

function CustomTeam.calculateEarnings(args)
	if not Namespace.isMain() then
		return 0, 0
	end

	local team = _team.pagename
	local query = 'individualprizemoney, prizemoney, players, date, mode'

	local playerTeamConditions = ConditionTree(BooleanOperator.any)
	for playerIndex = 1, _MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS do
		playerTeamConditions:add{
			ConditionNode(ColumnName('players_p' .. playerIndex .. 'team'), Comparator.eq, team),
		}
	end

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.neq, '1970-01-01 00:00:00'),
		ConditionNode(ColumnName('prizemoney'), Comparator.gt, '0'),
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('participantlink'), Comparator.eq, team),
			ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('mode'), Comparator.neq, 'team'),
				playerTeamConditions
			},
		},
	}

	local queryParameters = {
		conditions = conditions:toString(),
		query = query,
	}

	local earnings = {total = {}}
	local playerEarnings = 0

	local processPlacement = function(placement)
		earnings, playerEarnings = CustomTeam._addPlacementToEarnings(earnings, playerEarnings, placement)
	end

	Lpdb.executeMassQuery('placement', queryParameters, processPlacement)

	if earnings.team == nil then
		earnings.team = {}
	end

	if Namespace.isMain() then
		mw.ext.LiquipediaDB.lpdb_datapoint('total_earnings_players_while_on_team_' .. team, {
				type = 'total_earnings_players_while_on_team',
				name = _team.pagename,
				information = playerEarnings,
		})
	end

	Variables.varDefine('earnings', earnings.team.total or 0)

	return Math.round{earnings.team.total or 0}, Math.round{playerEarnings or 0}
end

function CustomTeam._addPlacementToEarnings(earnings, playerEarnings, data)
	local prizeMoney = data.prizemoney
	data.players = data.players or {}
	local mode = data.players.type or data.mode or ''
	mode = _EARNINGS_MODES[mode]
	if not mode then
		prizeMoney = data.individualprizemoney * CustomTeam._amountOfTeamPlayersInPlacement(data.players)
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

function CustomTeam._amountOfTeamPlayersInPlacement(players)
	local amount = 0
	for playerKey in Table.iter.pairsByPrefix(players, 'p') do
		if players[playerKey .. 'team'] == _team.pagename then
			amount = amount + 1
		end
	end

	return amount
end

return CustomTeam
