---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Class = Lua.import('Module:Class')
local Injector = Lua.import('Module:Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')
local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local ACHIEVEMENTS_BASE_CONDITIONS = {
	ConditionUtil.noneOf(ColumnName('liquipediatiertype'), {'Showmatch', 'Qualifier'}),
	ConditionUtil.anyOf(ColumnName('liquipediatier'), {1, 2}),
	ConditionNode(ColumnName('placement'), Comparator.eq, 1),
}

---@class ApexlegendsInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	team:setWidgetInjector(CustomInjector(team))

	-- Automatic achievements
	team.args.achievements = Achievements.team{
		noTemplate = true,
		baseConditions = ACHIEVEMENTS_BASE_CONDITIONS
	}

	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		table.insert(widgets, Cell{name = 'In-Game Leader', children = {args.igl}})
	end

	return widgets
end

---@return Widget?
function CustomTeam:createBottomContent()
	return UpcomingTournaments.team{name = self.teamTemplate.templatename}
end

return CustomTeam
