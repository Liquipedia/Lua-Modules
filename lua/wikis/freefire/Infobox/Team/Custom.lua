---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Team = Lua.import('Module:Infobox/Team')
local PlacementStats = Lua.import('Module:Infobox/Extension/PlacementStats')
local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')

local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class FreeFireInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return VNode
function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	return team:createInfobox()
end

---@return VNode
function CustomTeam:createBottomContent()
	return Html.Fragment{children = WidgetUtil.collect(
		PlacementStats.run{
			tiers = {'1', '2', '3', '4'},
			participant = self.name,
		},
		not self.args.disbanded and UpcomingTournaments.team{name = self.teamTemplate.templatename} or nil
	)}
end

return CustomTeam
