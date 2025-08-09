---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Variables = Lua.import('Module:Variables')

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local Team = Lua.import('Module:Infobox/Team')
local Achievements = Lua.import('Module:Infobox/Extension/Achievements')

local ACHIEVEMENTS_BASE_CONDITIONS = {
	ConditionUtil.noneOf(ColumnName('liquipediatiertype'), {'Showmatch', 'Qualifier'}),
	ConditionUtil.anyOf(ColumnName('liquipediatier'), {1, 2}),
	ConditionNode(ColumnName('placement'), Comparator.eq, 1),
}

---@class RainbowsixInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	-- Automatic achievements
	team.args.achievements = Achievements.team{
		baseConditions = ACHIEVEMENTS_BASE_CONDITIONS
	}

	return team:createInfobox()
end

---@param args table
function CustomTeam:defineCustomPageVariables(args)
	Variables.varDefine('team_captain', args.captain)
end

return CustomTeam
