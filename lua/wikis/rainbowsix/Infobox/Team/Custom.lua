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
local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')

local ACHIEVEMENTS_BASE_CONDITIONS = {
	ConditionUtil.noneOf(ColumnName('liquipediatiertype'), {'Showmatch', 'Qualifier'}),
	ConditionUtil.anyOf(ColumnName('liquipediatier'), {1, 2}),
	ConditionNode(ColumnName('placement'), Comparator.eq, 1),
}

---@class RainbowsixInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return Widget
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

---@return Widget?
function CustomTeam:createBottomContent()
	if not self.args.disbanded then
		return UpcomingTournaments.team{
			name = self.args.lpdbname or self.teamTemplate.templatename,
			additionalConditions = ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Points')
		}
	end
end

return CustomTeam
