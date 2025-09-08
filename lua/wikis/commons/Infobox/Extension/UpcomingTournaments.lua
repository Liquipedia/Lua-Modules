---
-- @Liquipedia
-- page=Module:Infobox/Extension/UpcomingTournaments
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Info = Lua.import('Module:Info', {loadData = true})
local Opponent = Lua.import('Module:Opponent/Custom')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local UpcomingTournamentsWidget = Lua.import('Module:Widget/Infobox/UpcomingTournaments')

local UpcomingTournaments = {}

---@param name string|string[]
---@return Widget
function UpcomingTournaments.team(name)
	local templateNames = Array.isArray(name)
		and Array.map(name --[[@as string[] ]], TeamTemplate.resolve)
		or {TeamTemplate.resolve(name --[[@as string]] or mw.title.getCurrentTitle().text)}
	return UpcomingTournamentsWidget{
		opponentConditions = ConditionTree(BooleanOperator.all):add{
			ConditionUtil.anyOf(ColumnName('opponenttemplate'), templateNames),
			ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.team),
		}
	}
end

---@param args {name: string, prefix: string?}
---@return Widget
function UpcomingTournaments.player(args)
	local prefix = args.prefix or 'p'
	local defaultMaxPlayersPerPlacement = Info.config.defaultMaxPlayersPerPlacement or 10

	local conditions = ConditionTree(BooleanOperator.any):add(Array.map(
		Array.range(1, defaultMaxPlayersPerPlacement),
		function (playerIndex)
			return ConditionUtil.anyOf(
				ColumnName(prefix .. playerIndex, 'opponentplayers'),
				{args.name, args.name:gsub(' ', '_')}
			)
		end)
	)

	return UpcomingTournamentsWidget{
		opponentConditions = conditions
	}
end

return UpcomingTournaments
