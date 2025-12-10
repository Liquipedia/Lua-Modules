---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local PlacementStats = Lua.import('Module:InfoboxPlacementStats')
local RoleOf = Lua.import('Module:RoleOf')

local Injector = Lua.import('Module:Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')
local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')

local Widgets = Lua.import('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class WildriftInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	team:setWidgetInjector(CustomInjector(team))

	-- Automatic org people
	team.args.coach = RoleOf.get{role = 'Coach'}
	team.args.manager = RoleOf.get{role = 'Manager'}
	team.args.captain = RoleOf.get{role = 'Captain'}

	return team:createInfobox()
end

---@return string?
function CustomTeam:createBottomContent()
	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		not self.args.disbanded and UpcomingTournaments.team{name = self.teamTemplate.templatename} or nil,
		PlacementStats.run{tiers = {'1', '2', '3', '4', '5'}}
	)}
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		table.insert(widgets, Cell{name = 'Abbreviation', children = {args.abbreviation}})
	end

	return widgets
end

return CustomTeam
