---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local GameLookup = require('Module:GameLookup')
local Lua = require('Module:Lua')
local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent
local TeamTemplate = require('Module:TeamTemplate') ---@module 'commons.TeamTemplate'

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Injector = Lua.import('Module:Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

---@class AoeInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)
local CustomInjector = Class.new(Injector)

local MAX_NUMBER_OF_PLAYERS = 10
local INACTIVITY_THRESHOLD_YEARS = 1

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	-- Automatic achievements
	team.args.achievements = Achievements.team{noTemplate = true}

	team:setWidgetInjector(CustomInjector(team))

	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'region' then
		return {}
	elseif id == 'custom' then
		table.insert(widgets, Cell{name = 'Games', content = self.caller:_getGames()})
	end
	return widgets
end

---@return string[]
function CustomTeam:_getGames()
	local games = self:_queryGames()

	local manualGames = self.args.games and Array.map(
		mw.text.split(self.args.games, ','),
		function(game)
			return {game = GameLookup.getName(mw.text.trim(game))}
		end) or {}

	Array.extendWith(games, Array.filter(manualGames,
		function(entry)
			return not Array.any(games, function(e) return e.game == entry.game end)
		end
	))

	Array.sortInPlaceBy(games, function(entry) return entry.game end)

	local dateThreshold = os.date('!*t')
	dateThreshold.year = dateThreshold.year - INACTIVITY_THRESHOLD_YEARS
	dateThreshold = os.date('!%F', os.time(dateThreshold --[[@as osdateparam]]))

	local isActive = function(game)
		local placement = self:_getLatestPlacement(game)
		return placement and placement.date and placement.date >= dateThreshold
	end

	games = Array.map(
		games,
		function(entry)
			return entry.game .. (isActive(entry.game) and '' or ' <i><small>(Inactive)</small></i>')
		end)

	return games
end

---@return placement[]
function CustomTeam:_queryGames()
	local data = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = self:_buildTeamPlacementConditions():toString(),
			query = 'game',
			groupby = 'game asc',
		})

	if type(data) ~= 'table' then
		error(data)
	end

	return data
end

---@param game string
---@return placement
function CustomTeam:_getLatestPlacement(game)
	local conditions = ConditionTree(BooleanOperator.all):add{
		self:_buildTeamPlacementConditions(),
		ConditionNode(ColumnName('game'), Comparator.eq, game)
	}
	local data = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = conditions:toString(),
			query = 'date',
			order = 'date desc',
			limit = 1
		})

	if type(data) ~= 'table' then
		error(data)
	end

	return data[1]
end

---@return ConditionTree
function CustomTeam:_buildTeamPlacementConditions()
	local team = self.args.teamtemplate or self.args.name or self.pagename
	assert(TeamTemplate.exists(team), TeamTemplate.noTeamMessage(team))

	local opponentTeamTemplates = TeamTemplate.queryHistoricalNames(team)

	local playerConditions = self:_buildPlayersOnTeamOpponentConditions(opponentTeamTemplates)

	local opponentConditions = ConditionTree(BooleanOperator.any)
	Array.forEach(opponentTeamTemplates, function (teamTemplate)
		opponentConditions:add{ConditionNode(ColumnName('opponenttemplate'), Comparator.eq, teamTemplate)}
	end)

	local conditions = ConditionTree(BooleanOperator.any):add{
		ConditionTree(BooleanOperator.all):add{
			opponentConditions,
			ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.team),
		},
		playerConditions
	}
	return conditions
end

---@param opponentTeamTemplates string[]
---@return ConditionTree
function CustomTeam:_buildPlayersOnTeamOpponentConditions(opponentTeamTemplates)
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
