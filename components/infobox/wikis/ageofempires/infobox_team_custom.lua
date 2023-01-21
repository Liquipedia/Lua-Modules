---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Achievements = require('Module:Achievements in infoboxes')
local Class = require('Module:Class')
local GameLookup = require('Module:GameLookup')
local Lua = require('Module:Lua')
local Opponent = require('Module:OpponentLibraries').Opponent
local Table = require('Module:Table')
local TeamTemplates = require('Module:Team')

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
local CustomInjector = Class.new(Injector)

local MAX_NUMBER_OF_PLAYERS = 10

local _args
local _pagename

function CustomTeam.run(frame)
	local team = Team(frame)

	-- Automatic achievements
	team.args.achievements = Achievements.team{team = team.pagename, aka = team.args.aka}

	team.createWidgetInjector = CustomTeam.createWidgetInjector

	_args = team.args
	_pagename = team.pagename

	return team:createInfobox(frame)
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'earningscell' then
		widgets[1].name = 'Approx. Total Winnings'
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Games',
		content = _args.games and CustomTeam._getGames() or {}
	})
	return widgets
end

function CustomTeam._getGames()
	return Table.mapValues(
		Table.mapValues(mw.text.split(_args.games, ','), mw.text.trim),
		function(game)
			game = GameLookup.getName(game)
			return game .. (game ~= 'Unknown' and CustomTeam._getGameInactivity(game) or '')
		end)
end

function CustomTeam._getGameInactivity(game)
	local date = os.date('!*t')
	date.year = date.year - 1

	
	local conditions = ConditionTree(BooleanOperator.all):add{
		CustomTeam._buildTeamPlacementConditions(),
		ConditionNode(ColumnName('game'), Comparator.eq, game),
		ConditionNode(ColumnName('date'), Comparator.gt, os.date('!%F', os.time(date)))
	}

	local data = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = conditions:toString(),
			order = 'date desc',
			query = 'date',
			limit = 1
		})

	if type(data) ~= 'table' then
		error(data)
	end

	if data[1] then
		return ''
	else
		return ' <i><small>(inactive)</small></i>'
	end
end

function CustomTeam._buildTeamPlacementConditions()
	local team = _args.teamtemplate or _pagename
	local rawOpponentTemplate = TeamTemplates.queryRaw(team) or {}
	local opponentTemplate = rawOpponentTemplate.historicaltemplate or rawOpponentTemplate.templatename
	if not opponentTemplate then
		error('Missing team template for team: ' .. team)
	end

	local opponentTeamTemplates = TeamTemplates.queryHistorical(opponentTemplate) or {opponentTemplate}

	local playerConditions = CustomTeam._buildPlayersOnTeamOpponentConditions(opponentTeamTemplates)

	local opponentConditions = ConditionTree(BooleanOperator.any)
	for _, teamTemplate in pairs(opponentTeamTemplates) do
		opponentConditions:add{ConditionNode(ColumnName('opponenttemplate'), Comparator.eq, teamTemplate)}
	end

	local conditions = ConditionTree(BooleanOperator.any):add{
		ConditionTree(BooleanOperator.all):add{
			opponentConditions,
			ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.team),
		},
		playerConditions
	}
	return conditions
end

function CustomTeam._buildPlayersOnTeamOpponentConditions(opponentTeamTemplates)
	local opponentConditions = ConditionTree(BooleanOperator.any)

	local prefix = 'p'
	for _, teamTemplate in pairs(opponentTeamTemplates) do
		for playerIndex = 1, MAX_NUMBER_OF_PLAYERS do
			opponentConditions:add{
				ConditionNode(ColumnName('opponentplayers_' .. prefix .. playerIndex .. 'template'), Comparator.eq, teamTemplate),
			}
		end
	end

	return ConditionTree(BooleanOperator.all):add{
		opponentConditions,
		ConditionNode(ColumnName('opponenttype'), Comparator.neq, Opponent.team),
	}
end

return CustomTeam
