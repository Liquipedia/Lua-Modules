---
-- @Liquipedia
-- page=Module:Infobox/Extension/UpcomingTournaments
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Opponent = Lua.import('Module:Opponent/Custom')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local UpcomingTournamentsWidget = Lua.import('Module:Widget/Infobox/UpcomingTournaments')

local UpcomingTournaments = {}

---@param name string
---@return Widget
function UpcomingTournaments.team(name)
	local templateName = TeamTemplate.resolve(name or mw.title.getCurrentTitle().text)
	return UpcomingTournamentsWidget{
		opponentConditions = ConditionTree(BooleanOperator.all):add{
			ConditionNode(ColumnName('opponenttemplate'), Comparator.eq, templateName),
			ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.team),
		}
	}
end

return UpcomingTournaments
