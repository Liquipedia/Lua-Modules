---
-- @Liquipedia
-- page=Module:Infobox/Extension/UpcomingTournaments
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
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

return UpcomingTournaments
