---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Api/FetchPlayers
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Condition = Lua.import('Module:Condition')
local FnUtil = Lua.import('Module:FnUtil')
local Lpdb = Lua.import('Module:Lpdb')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local FetchPlayers = {}

---@param props {pageNames: string[], config: TournamentAppearancesConfig,
---parsePlayersFromPlacement: fun(players: table<string, standardPlayer>, placement: placement)}
---@return standardPlayer[]
function FetchPlayers.run(props)
	---@type table<string, standardPlayer>
	local players = {}

	Lpdb.executeMassQuery('placement', {
		conditions = FetchPlayers._buildConditions(props.pageNames, props.config),
		limit = 1000,
		order = 'date asc',
		query = 'opponentplayers, opponenttype, opponentname, parent, date, placement, opponenttemplate',
	}, FnUtil.curry(props.parsePlayersFromPlacement, players))

	return Array.extractValues(players)
end

---@param pageNames string[]
---@param config TournamentAppearancesConfig
---@return string
function FetchPlayers._buildConditions(pageNames, config)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionUtil.noneOf(ColumnName('opponentplayers'), {'', '[]'}),
		ConditionUtil.noneOf(ColumnName('opponentname'), {'TBD', 'Definitions', ''}),
		ConditionNode(ColumnName('mode'), Comparator.neq, 'award_individual'),
		ConditionUtil.anyOf(ColumnName('parent'), pageNames)
	}

	if config.restrictToFirstPrizePool then
		conditions:add(ConditionNode(ColumnName('prizepoolindex'), Comparator.eq, 1))
	end

	return tostring(conditions)
end

return FetchPlayers
